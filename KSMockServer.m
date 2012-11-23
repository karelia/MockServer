//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sys/socket.h>
#import <netinet/in.h>   // for IPPROTO_TCP, sockaddr_in

#import "KSMockServer.h"
#import "KSMockServerConnection.h"
#import "KSMockServerListener.h"
#import "KSMockServerRegExResponder.h"

@interface KSMockServer()

@property (strong, nonatomic) NSMutableArray* connections;
@property (strong, nonatomic) KSMockServerListener* dataListener;
@property (strong, nonatomic) KSMockServerListener* listener;
@property (strong, nonatomic) NSOperationQueue* queue;
@property (strong, nonatomic) NSDateFormatter* rfc1123DateFormatter;
@property (assign, atomic) BOOL running;


@end

@implementation KSMockServer

@synthesize connections = _connections;
@synthesize data = _data;
@synthesize dataListener = _dataListener;
@synthesize listener = _listener;
@synthesize queue = _queue;
@synthesize responder = _responder;
@synthesize rfc1123DateFormatter = _rfc1123DateFormatter;
@synthesize running = _running;

NSString *const CloseCommand = @"«close»";
NSString *const InitialResponseKey = @"«initial»";

#pragma mark - Object Lifecycle

+ (KSMockServer*)serverWithResponder:(KSMockServerResponder*)responder
{
    KSMockServer* server = [[KSMockServer alloc] initWithPort:0 responder:responder];

    return [server autorelease];
}

+ (KSMockServer*)serverWithPort:(NSUInteger)port responder:(KSMockServerResponder*)responder
{
    KSMockServer* server = [[KSMockServer alloc] initWithPort:port responder:responder];

    return [server autorelease];
}

- (id)initWithPort:(NSUInteger)port responder:(KSMockServerResponder*)responder
{
    NSAssert(responder != nil, @"should be given a valid responder");

    if ((self = [super init]) != nil)
    {
        self.queue = [NSOperationQueue currentQueue];
        self.responder = responder;
        self.connections = [NSMutableArray array];

        NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
        [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
        [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
        self.rfc1123DateFormatter = formatter;

        self.listener = [KSMockServerListener listenerWithPort:port connectionBlock:^BOOL(int socket) {
            MockServerAssert(socket != 0);

            MockServerLogDetail(@"received connection");
            @synchronized(self.connections)
            {
                KSMockServerConnection* connection = [KSMockServerConnection connectionWithSocket:socket responder:nil server:self];
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

    [super dealloc];
}

#pragma mark - Public API

- (void)start
{
    BOOL success = [self.listener start];
    if (success)
    {
        [self makeDataListener];

        MockServerAssert(self.port != 0);
        MockServerLog(@"server started on port %ld", self.port);
        self.running = YES;
    }
}

- (void)pause
{
    self.running = NO;
}

- (void)stop
{
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
        for (KSMockServerConnection* connection in connections)
        {
            [connection cancel];
        }
        [connections release];
        NSAssert([self.connections count] == 0, @"all connections should have closed");
    }

    self.running = NO;
}

- (void)runUntilStopped
{
    self.running = YES;
    while (self.running)
    {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
        }
    }
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
        __block KSMockServer* server = self;
        self.dataListener = [KSMockServerListener listenerWithPort:0 connectionBlock:^BOOL(int socket) {

            MockServerLogDetail(@"got connection on data listener");

            NSData* data = server.data;
            if (!data)
            {
                data = [@"Test data" dataUsingEncoding:NSUTF8StringEncoding];
            }

            NSArray* responses = @[ @[InitialResponseKey, data, CloseCommand ] ];
            KSMockServerRegExResponder* responder = [KSMockServerRegExResponder responderWithResponses:responses];
            KSMockServerConnection* connection = [KSMockServerConnection connectionWithSocket:socket responder:responder server:server];
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

- (void)connectionDidClose:(KSMockServerConnection*)connection
{
    @synchronized(self.connections)
    {
        NSAssert([self.connections indexOfObject:connection] != NSNotFound, @"connection should be in our list");
        [self.connections removeObject:connection];
        MockServerLogDetail(@"connection %@ closed", connection);
    }
}

@end
