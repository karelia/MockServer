//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sys/socket.h>
#import <netinet/in.h>   // for IPPROTO_TCP, sockaddr_in

#import "KMSServer.h"
#import "KMSConnection.h"
#import "KMSListener.h"
#import "KMSRegExResponder.h"

#import "KMSSendDataCommand.h"
#import "KMSPauseCommand.h"
#import "KMSCloseCommand.h"

@interface KMSServer()

@property (strong, nonatomic) NSMutableArray* connections;
@property (strong, nonatomic) KMSListener* dataListener;
@property (strong, nonatomic) KMSListener* listener;
@property (strong, nonatomic) NSDateFormatter* rfc1123DateFormatter;

@end

@implementation KMSServer

@synthesize connections = _connections;
@synthesize data = _data;
@synthesize dataListener = _dataListener;
@synthesize listener = _listener;
@synthesize queue = _queue;
@synthesize responder = _responder;
@synthesize rfc1123DateFormatter = _rfc1123DateFormatter;
@synthesize running = _running;
@synthesize transcript = _transcript;

static void *queueIdentifierKey;

NSString *const CloseCommandToken = @"«close»";
NSString *const DataCommandToken = @"«data»";
NSString *const InitialResponsePattern = @"«initial»";

NSString *const ListenerRunMode = @"kCFRunLoopDefaultMode";
NSString *const InputRunMode = @"InputRunMode"; //NSDefaultRunLoopMode
NSString *const OutputRunMode = @"OutputRunMode"; //NSDefaultRunLoopMode

#pragma mark - Object Lifecycle

+ (KMSServer*)serverWithResponder:(KMSResponder*)responder
{
    KMSServer* server = [[KMSServer alloc] initWithPort:0 responder:responder];

    return [server autorelease];
}

+ (KMSServer*)serverWithPort:(NSUInteger)port responder:(KMSResponder*)responder
{
    KMSServer* server = [[KMSServer alloc] initWithPort:port responder:responder];

    return [server autorelease];
}

- (id)initWithPort:(NSUInteger)port responder:(KMSResponder*)responder
{
    NSAssert(responder != nil, @"should be given a valid responder");

    if ((self = [super init]) != nil)
    {
        dispatch_queue_t queue = dispatch_queue_create("com.karelia.mockserver", 0);
        self.queue = queue;
        dispatch_queue_set_specific(queue, &queueIdentifierKey, self, NULL);
        self.responder = responder;
        self.connections = [NSMutableArray array];
        self.transcript = [NSMutableArray array];
        
        NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
        [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
        [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
        self.rfc1123DateFormatter = formatter;

        self.listener = [KMSListener listenerWithPort:port connectionBlock:^BOOL(int socket) {
            KMSAssert(socket != 0);

            KMSLogDetail(@"received connection");
            dispatch_async(dispatch_get_main_queue(), ^{
                KMSConnection* connection = [KMSConnection connectionWithSocket:socket responder:nil server:self];
                dispatch_async(queue, ^{
                    [self.connections addObject:connection];
                    [connection open];
                    KMSLogDetail(@"connection added %@", connection);
                });
            });

            return YES;
        }];
    }

    return self;
}

- (void)dealloc
{
    KMSAssert([self.connections count] == 0);
    dispatch_release(_queue);
    _queue = nil;

    [_connections release];
    [_data release];
    [_dataListener release];
    [_responder release];
    [_transcript release];
    
    [super dealloc];
}

#pragma mark - Public API

- (void)start
{
    BOOL success = [self.listener start];
    if (success)
    {
        [self makeDataListener];

        KMSAssert(self.port != 0);
        KMSLog(@"server started on port %ld", (unsigned long)self.port);
        self.state = KMSRunning;
    }
}

- (void)pause
{
    KMSLogDetail(@"pause requested");
    self.state = KMSPauseRequested;
}

- (void)resume
{
    KMSAssert(self.state != KMSPauseRequested);

    KMSLogDetail(@"resumed");
    self.state = KMSRunning;
}

- (BOOL)isRunning
{
    return self.state == KMSRunning;
}

- (void)stop
{
    KMSLogDetail(@"stop requested");
    [self stopConnections];
}

- (void)stopConnections
{
    [self.listener stop:@"stopped externally"];
    [self.dataListener stop:@"stopped externally"];

    dispatch_async(self.queue, ^{
        NSArray* connections = self.connections;
        for (KMSConnection* connection in connections)
        {
            [connection cancel];
        }
    });

    self.state = KMSStopped;
}

- (void)runUntilPaused
{
    KMSAssert(self.state != KMSStopped);

    KMSLogDetail(@"running until paused");
    while (self.state != KMSPauseRequested)
    {
        @autoreleasepool {
            NSRunLoop* loop = [NSRunLoop currentRunLoop];
            [loop runMode:NSRunLoopCommonModes beforeDate:[NSDate date]];
            [loop runMode:ListenerRunMode beforeDate:[NSDate date]];
            [loop runMode:InputRunMode beforeDate:[NSDate date]];
            [loop runMode:OutputRunMode beforeDate:[NSDate date]];
        }
    }
    self.state = KMSPaused;
    KMSLogDetail(@"now paused");
}

- (NSUInteger)port
{
    return self.listener.port;
}

#pragma mark - Substitutions


- (NSDictionary*)standardSubstitutions
{
    NSUInteger extraPort = self.dataListener.port;
    NSDictionary* substitutions =
    @{
    @"$address" : @"127.0.0.1",
    @"$server" : @"fakeserver 20121107",
    @"$size" : [NSString stringWithFormat:@"%ld", (long) [self.data length]],
    @"$pasv" : [NSString stringWithFormat:@"127,0,0,1,%ld,%ld", extraPort / 256L, extraPort % 256L],
    @"$date" : [self.rfc1123DateFormatter stringFromDate:[NSDate date]],
    };

    return substitutions;
}

#pragma mark - Data Connection

- (void)makeDataListener
{
    dispatch_async(self.queue, ^{
            __block KMSServer* server = self;
            self.dataListener = [KMSListener listenerWithPort:0 connectionBlock:^BOOL(int socket) {

                KMSLogDetail(@"got connection on data listener");

                NSData* data = server.data;
                if (!data)
                {
                    data = [@"Test data" dataUsingEncoding:NSUTF8StringEncoding];
                }

                NSArray* responses = @[ @[InitialResponsePattern, [KMSSendDataCommand sendData:data], [KMSPauseCommand pauseFor:0.1], [KMSCloseCommand closeCommand] ] ];
                KMSRegExResponder* responder = [KMSRegExResponder responderWithResponses:responses];
                dispatch_async(dispatch_get_main_queue(), ^{
                    KMSConnection* connection = [KMSConnection connectionWithSocket:socket responder:responder server:server];
                    dispatch_async(self.queue, ^{
                        [self.connections addObject:connection];
                        [connection open];
                    });
                });

                return YES;
            }];
            
            [self.dataListener start];
    });
}

- (void)disposeDataListener
{
}

#pragma mark - Streams

- (void)connectionDidClose:(KMSConnection*)connection
{
    dispatch_async(self.queue, ^{
        NSAssert([self.connections indexOfObject:connection] != NSNotFound, @"connection should be in our list");
        KMSLogDetail(@"connection %@ closed", connection);
        [self.connections removeObject:connection];
    });
}

#pragma mark - Logging

static KMSLogLevel gLoggingLevel = KMSLoggingOff;

+ (KMSLogLevel)loggingLevel
{
    return gLoggingLevel;
}

+ (void)setLoggingLevel:(KMSLogLevel)level
{
    gLoggingLevel = level;
}

#pragma mark - Debugging

- (BOOL)currentQueueTargetsServerQueue {
    return dispatch_get_specific(&queueIdentifierKey) == self;
}

@end
