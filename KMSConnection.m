//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KMSConnection.h"

#import "KMSServer.h"
#import "KMSListener.h"
#import "KMSResponder.h"
#import "KMSTranscriptEntry.h"
#import "KMSCommand.h"
#import "KMSCloseCommand.h"

@interface KMSConnection()

@property (strong, nonatomic) NSMutableArray* commands;
@property (strong, nonatomic) NSInputStream* input;
@property (strong, nonatomic) NSOutputStream* output;
@property (strong, nonatomic) NSMutableData* outputData;
@property (strong, nonatomic) KMSResponder* responder;
@property (strong, nonatomic) KMSServer* server;
@property (assign, nonatomic) int socket;

#if DEBUG

@property (strong, nonatomic) NSString* lastDisconnectReason;

#endif

@end

@implementation KMSConnection

@synthesize input   = _input;
@synthesize output = _output;
@synthesize outputData = _outputData;
@synthesize responder = _responder;
@synthesize server = _server;

#pragma mark - Object Lifecycle

+ (KMSConnection*)connectionWithSocket:(int)socket responder:(KMSResponder*)responder server:(KMSServer*)server
{
    KMSConnection* connection = [[KMSConnection alloc] initWithSocket:socket responder:responder server:server];

    return [connection autorelease];
}

- (id)initWithSocket:(int)socket responder:(KMSResponder*)responder server:(KMSServer*)server
{
    if ((self = [super init]) != nil)
    {
        self.server = server;
        self.responder = responder;
        self.outputData = [NSMutableData data];

        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocket(NULL, socket, &readStream, &writeStream);

        self.socket = socket;
        self.input = [self setupStream:(NSStream*)readStream mode:InputRunMode];
        self.output = [self setupStream:(NSStream*)writeStream mode:OutputRunMode];

        CFRelease(readStream);
        CFRelease(writeStream);
    }

    return self;
}

- (void)dealloc
{
    KMSAssert((_input == nil) && (_output == nil));

    [_input release];
    [_output release];
    [_outputData release];
    [_server release];

#if DEBUG
    [_lastDisconnectReason release];
#endif

    [super dealloc];
}

#pragma mark - Public API

- (void)open
{
    [self.input open];
    [self.output open];
}

- (void)cancel
{
    dispatch_async(self.server.queue, ^{
        [self disconnectStreams:@"cancelled"];
    });
}

- (void)appendOutput:(NSData*)output
{
    // this should only be called from within a performOnConnection call on a command
    // so we should already be on our serial queue
    KMSAssert(self.server.currentQueueTargetsServerQueue);

    [self.outputData appendData:output];
    [self processOutput];
}

#pragma mark - Data Processing

- (void)processInput
{
    KMSAssert(self.server.currentQueueTargetsServerQueue);

    uint8_t buffer[32768];
    NSInteger bytesRead = [self.input read:buffer maxLength:sizeof(buffer)];
    if (bytesRead == -1)
    {
        [self disconnectStreams:[NSString stringWithFormat:@"read error %@", [self.input streamError]]];
    }

    else if (bytesRead == 0)
    {
        [self disconnectStreams:@"no more data to read"];
    }

    else
    {
        NSDictionary* substitutions = [self.server standardSubstitutions];
        NSString* request = [[NSString alloc] initWithBytes:buffer length:bytesRead encoding:NSUTF8StringEncoding];
        [self.server.transcript addObject:[KMSTranscriptEntry entryWithType:KMSTranscriptInput value:request]];
        KMSLog(@"got request '%@'", request);
        NSArray* commands = [self.responder responseForRequest:request substitutions:substitutions];
        if (!commands)
        {
            // if nothing matched, close the connection
            // to prevent this, add a key of ".*" as the last response in the array
            commands = @[[KMSCloseCommand closeCommand]];
        }

        [self queueCommands:commands];

        [request release];
    }
}

- (void)close
{
    KMSLogDetail(@"closed connection");
    [self.server.transcript addObject:[KMSTranscriptEntry entryWithType:KMSTranscriptCommand value:CloseCommandToken]];
    [self disconnectStreams:@"closed as part of response"];
}

- (void)queueCommands:(NSArray*)commands
{
    KMSAssert(self.server.currentQueueTargetsServerQueue);

    if (!self.commands)
    {
        self.commands = [NSMutableArray array];
    }
    
    BOOL wasEmpty = [self.commands count] == 0;
    [self.commands addObjectsFromArray:commands];
    if (wasEmpty)
    {
        [self processNextCommand];
    }
}

- (void)processNextCommand
{
    KMSAssert(self.server.currentQueueTargetsServerQueue);

    NSUInteger count = [self.commands count];
    if (count)
    {
        KMSCommand* command = self.commands[0];
        [command retain];
        [self.commands removeObjectAtIndex:0];

        NSTimeInterval delay = [command performOnConnection:self server:self.server];
        if (count > 1)
        {
            dispatch_time_t nextTimeToProcess = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
            dispatch_after(nextTimeToProcess, self.server.queue, ^(void){
                [self processNextCommand];
            });
        }

        [command release];
    }
}


- (void)processOutput
{
    KMSAssert(self.server.currentQueueTargetsServerQueue);

    NSUInteger bytesToWrite = [self.outputData length];
    if (bytesToWrite)
    {
        NSUInteger written = [self.output write:[self.outputData bytes] maxLength:bytesToWrite];
        if (written != -1)
        {
            [self.outputData replaceBytesInRange:NSMakeRange(0, written) withBytes:nil length:0];
            [self.server.transcript addObject:[KMSTranscriptEntry entryWithType:KMSTranscriptOutput value:self.outputData]];

            KMSLogDetail(@"wrote %ld bytes", (long)written);
        }
        else
        {
            [self disconnectStreams:[NSString stringWithFormat:@"write error %@", [self.output streamError]]];
        }
    }
}

#pragma mark - Streams

- (id)setupStream:(NSStream*)stream mode:(NSString*)mode
{
    KMSAssert(stream);
    KMSAssert([NSThread isMainThread]);

    [stream setProperty:@(NO) forKey:(NSString*)kCFStreamPropertyShouldCloseNativeSocket];

    stream.delegate = self;
    [stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:mode];

    return stream;
}

- (void)disconnectStreams:(NSString*)reason
{
    dispatch_async(self.server.queue, ^{
        NSInputStream* input = self.input;
        NSOutputStream* output = self.output;
        if (input || output)
        {
            KMSLogDetail(@"disconnecting: %@", reason);

            #if DEBUG
                self.lastDisconnectReason = reason;
            #endif

            KMSAssert(input && output);

            // do final stream cleanup on the main queue
            input.delegate = nil;
            output.delegate = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                [input close];
                [output close];
            });

            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                close(self.socket);
            });

            // release the streams here, and tell the server that they're gone
            // the block above still holds a reference to them until it's done and they've actually been properly closed
            [self.server connectionDidClose:self];
            KMSLogDetail(@"disconnected: %@", reason);
            self.input = nil;
            self.output = nil;

            [self.server.transcript addObject:[KMSTranscriptEntry entryWithType:KMSTranscriptEvent value:reason]];
        }
        else
        {
            KMSLog(@"attempting to disconnect again: %@\nalready closed because:%@", reason, self.lastDisconnectReason);
        }
    });
}

- (NSString*)nameForStream:(NSStream*)stream
{
    NSString* result;
    if (stream == self.input)
    {
        result = @"input";
    }
    else if (stream == self.output)
    {
        result = @"output";
    }
    else
    {
        result = @"unknown";
    }

    return result;
}

- (KMSResponder*)responder
{
    KMSResponder* result = _responder;
    if (!result)
    {
        result = self.server.responder;
    }

    return result;
}

- (void)stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode
{
    NSInputStream* input = self.input;
    NSOutputStream* output = self.output;

    if ((input != nil) && (output != nil))    // if events come in after we've been shut down, ignore them...
    {
        KMSAssert((stream == input) || (stream == output));
        switch (eventCode)
        {
            case NSStreamEventOpenCompleted:
            {
                KMSLogDetail(@"opened %@ stream", [self nameForStream:stream]);
                if (stream == input)
                {
                    dispatch_async(self.server.queue, ^{
                        [self queueCommands:self.responder.initialResponse];
                    });
                }
                break;
            }

            case NSStreamEventHasBytesAvailable:
            {
                KMSAssert(stream == input);     // should never happen for the output stream
                dispatch_async(self.server.queue, ^{
                    [self processInput];
                });
                break;
            }

            case NSStreamEventHasSpaceAvailable:
            {
                KMSAssert(stream == output);     // should never happen for the input stream
                dispatch_async(self.server.queue, ^{
                    [self processOutput];
                });
                break;
            }

            case NSStreamEventErrorOccurred:
            {
                KMSLog(@"got error for %@ stream", [self nameForStream:stream]);
                dispatch_async(self.server.queue, ^{
                    [self disconnectStreams:[NSString stringWithFormat:@"%@ error %@", [self nameForStream:stream], [stream streamError]]];
                });
                break;
            }

            case NSStreamEventEndEncountered:
            {
                KMSLogDetail(@"got eof for %@ stream", [self nameForStream:stream]);
                break;
            }
                
            default:
            {
                KMSLog(@"unknown event for %@ stream", [self nameForStream:stream]);
                KMSAssert(NO);
                break;
            }
        }
    }
    else
    {
        NSLog(@"received an event whilst being disposed");
    }
}

@end
