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

@interface KMSServer()

@property (strong, nonatomic) NSMutableArray* connections;
@property (strong, nonatomic) KMSListener* dataListener;
@property (strong, nonatomic) KMSListener* listener;
@property (strong, nonatomic) NSOperationQueue* queue;
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

NSString *const CloseCommand = @"«close»";
NSString *const DataCommand = @"«data»";
NSString *const InitialResponseKey = @"«initial»";

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
        self.queue = [NSOperationQueue currentQueue];
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
            @synchronized(self.connections)
            {
                KMSConnection* connection = [KMSConnection connectionWithSocket:socket responder:nil server:self];
                [self.connections addObject:connection];
            }

            return YES;
        }];
    }

    return self;
}

- (void)dealloc
{
    [_connections release];
    [_data release];
    [_dataListener release];
    [_queue release];
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
        KMSLog(@"server started on port %ld", self.port);
        self.state = KMSRunning;
    }
}

- (void)pause
{
    [self.queue addOperationWithBlock:^{
        KMSLogDetail(@"pause requested");
        self.state = KMSPauseRequested;
    }];
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
    [self.queue addOperationWithBlock:^{
        [self stopConnections];
    }];
}

- (void)stopConnections
{
    [self.listener stop:@"stopped externally"];
    [self.dataListener stop:@"stopped externally"];

    @synchronized(self.connections)
    {
        NSArray* connections = [self.connections copy];
        for (KMSConnection* connection in connections)
        {
            [connection cancel];
        }
        [connections release];
        NSAssert([self.connections count] == 0, @"all connections should have closed");
    }

    self.state = KMSStopped;
}

- (void)runUntilPaused
{
    KMSAssert(self.state != KMSStopped);

    KMSLogDetail(@"running until paused");
    while (self.state != KMSPauseRequested)
    {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
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
    @synchronized(self.connections)
    {
        __block KMSServer* server = self;
        self.dataListener = [KMSListener listenerWithPort:0 connectionBlock:^BOOL(int socket) {

            KMSLogDetail(@"got connection on data listener");

            NSData* data = server.data;
            if (!data)
            {
                data = [@"Test data" dataUsingEncoding:NSUTF8StringEncoding];
            }

            NSArray* responses = @[ @[InitialResponseKey, data, @(0.1), CloseCommand ] ];
            KMSRegExResponder* responder = [KMSRegExResponder responderWithResponses:responses];
            KMSConnection* connection = [KMSConnection connectionWithSocket:socket responder:responder server:server];
            [self.connections addObject:connection];
            
            return YES;
        }];
        
        [self.dataListener start];
    }
}

- (void)disposeDataListener
{
}

#pragma mark - Streams

- (void)connectionDidClose:(KMSConnection*)connection
{
    @synchronized(self.connections)
    {
        NSAssert([self.connections indexOfObject:connection] != NSNotFound, @"connection should be in our list");
        KMSLogDetail(@"connection %@ closed", connection);
        [self.connections removeObject:connection];
    }
}

@end
