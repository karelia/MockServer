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

@interface KMSConnection()

@property (strong, nonatomic) NSMutableArray* commands;
@property (strong, nonatomic) NSInputStream* input;
@property (strong, nonatomic) NSOutputStream* output;
@property (strong, nonatomic) NSMutableData* outputData;
@property (assign, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) KMSResponder* responder;
@property (strong, nonatomic) KMSServer* server;

@end

@implementation KMSConnection

@synthesize input   = _input;
@synthesize output = _output;
@synthesize outputData = _outputData;
@synthesize queue = _queue;
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

        self.queue = dispatch_queue_create("com.karelia.mockserver.connection", 0);
        
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocket(NULL, socket, &readStream, &writeStream);

        self.input = [self setupStream:(NSStream*)readStream];
        self.output = [self setupStream:(NSStream*)writeStream];
    }

    return self;
}

- (void)dealloc
{
    dispatch_release(_queue);
    _queue = nil;

    [_input release];
    [_output release];
    [_outputData release];
    [_server release];

    
    [super dealloc];
}

#pragma mark - Public API

- (void)cancel
{
    [self disconnectStreams:@"cancelled"];
}

#pragma mark - Data Processing

- (void)processInput
{
    uint8_t buffer[32768];
    NSInteger bytesRead = [self.input read:buffer maxLength:sizeof(buffer)];
    if (bytesRead == -1)
    {
        [self disconnectStreams:@"read error"];
    }

    else if (bytesRead == 0)
    {
        [self disconnectStreams:@"no more data"];
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
    [self.server.transcript addObject:[KMSTranscriptEntry entryWithType:KMSTranscriptCommand value:CloseCommand]];
    [self.output close];
    [self.input close];
}

- (void)queueCommands:(NSArray*)commands
{
    dispatch_async(self.queue, ^{
        BOOL isEmpty = [self.commands count] == 0;
        [self.commands addObjectsFromArray:commands];
        if (isEmpty)
        {
            [self processNextCommand];
        }
    });
}

- (void)processNextCommand
{
    KMSAssert(dispatch_get_current_queue() == self.queue);

    KMSCommand* command = self.commands[0];
    [self.commands removeObjectAtIndex:0];

    NSTimeInterval delay = [command performOnConnection:self server:self.server];
    if ([self.commands count] > 0)
    {
        dispatch_time_t nextTimeToProcess = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
        dispatch_after(nextTimeToProcess, self.queue, ^(void){
            [self processNextCommand];
        });
    }
}

- (void)appendOutput:(NSData*)output
{
    [self.outputData appendData:output];
    [self processOutput];
}

- (void)processOutput
{
    NSUInteger bytesToWrite = [self.outputData length];
    if (bytesToWrite)
    {
        NSUInteger written = [self.output write:[self.outputData bytes] maxLength:bytesToWrite];
        [self.outputData replaceBytesInRange:NSMakeRange(0, written) withBytes:nil length:0];
        [self.server.transcript addObject:[KMSTranscriptEntry entryWithType:KMSTranscriptOutput value:self.outputData]];

        KMSLogDetail(@"wrote %ld bytes", (long)written);
    }
}

#pragma mark - Streams

- (id)setupStream:(NSStream*)stream
{
    KMSAssert(stream);

    [stream setProperty:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket];
    stream.delegate = self;
    [stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [stream open];
    CFRelease(stream);

    return stream;
}

- (void)cleanupStream:(NSStream*)stream
{
    @synchronized(stream)
    {
        if (stream)
        {
            stream.delegate = nil;
            [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [stream close];
        }
    }
}
- (void)disconnectStreams:(NSString*)reason
{
    [self cleanupStream:self.input];
    self.input = nil;

    [self cleanupStream:self.output];
    self.output = nil;

    [self.server connectionDidClose:self];
    KMSLogDetail(@"disconnected: %@", reason);
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
    KMSAssert((stream == self.input) || (stream == self.output));

    switch (eventCode)
    {
        case NSStreamEventOpenCompleted:
        {
            KMSLogDetail(@"opened %@ stream", [self nameForStream:stream]);
            if (stream == self.input)
            {
                [self processCommands:self.responder.initialResponse];
            }
            break;
        }

        case NSStreamEventHasBytesAvailable:
        {
            KMSAssert(stream == self.input);     // should never happen for the output stream
            [self processInput];
            break;
        }

        case NSStreamEventHasSpaceAvailable:
        {
            KMSAssert(stream == self.output);     // should never happen for the input stream
            [self processOutput];
            break;
        }

        case NSStreamEventErrorOccurred:
        {
            KMSLog(@"got error for %@ stream", [self nameForStream:stream]);
            [self disconnectStreams:@"Stream open error"];
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

@end
