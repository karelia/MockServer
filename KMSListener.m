//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sys/socket.h>
#import <netinet/in.h>   // for IPPROTO_TCP, sockaddr_in

#import "KMSListener.h"

#import "KMSServer.h"
#import "KMSConnection.h"
#import "KMSResponder.h"

@interface KMSListener()
{
    CFSocketRef _listener;
    CFRunLoopSourceRef _source;
}

@property (copy, nonatomic) ConnectionBlock connectionBlock;
@property (assign, nonatomic) NSUInteger port;

@end

@implementation KMSListener

#pragma mark - Object Lifecycle

+ (KMSListener*)listenerWithPort:(NSUInteger)port connectionBlock:(ConnectionBlock)block
{
    KMSListener* listener = [[KMSListener alloc] initWithPort:port connectionBlock:block];

    return [listener autorelease];
}

- (id)initWithPort:(NSUInteger)port connectionBlock:(ConnectionBlock)block
{
    if ((self = [super init]) != nil)
    {
        self.connectionBlock = block;
        self.port = port;
        KMSLogDetail(@"made listener at port %ld", (long) port);
    }

    return self;
}

- (void)dealloc
{
    KMSAssert(_listener == nil);

    [super dealloc];
}

#pragma mark - Public API


#pragma mark - Start / Stop

- (BOOL)start
{
    int socket;

    BOOL success = [self makeSocket:&socket];
    if (success)
    {
        success = [self bindSocket:socket];
    }

    if (success)
    {
        success = [self listenOnSocket:socket];
    }

    if (success && (self.port == 0))
    {
        success = [self retrievePortForSocket:socket];
    }

    if (success)
    {
        success = [self makeCFSocketForSocket:socket];
    }

    if (success)
    {
        KMSAssert(self.port != 0);
        KMSLog(@"listener started on port %ld", (unsigned long)self.port);
    }
    else
    {
        [self stop:@"Start failed"];
        if (socket != -1)
        {
            int err = close(socket);
            if (!err)
            {
                KMSLog(@"couldn't close socket %d", socket);
            }
        }
    }

    return success;
}

- (void)stop:(NSString*)reason
{
    if (_source)
    {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), _source, (CFStringRef)ListenerRunMode);
        CFRelease(_source);
        _source = nil;
    }

    if (_listener)
    {
        CFSocketInvalidate(_listener);
        CFRelease(_listener);
        _listener = nil;
    }

    self.connectionBlock = nil;

    KMSLogDetail(@"listener stopped because: %@", reason);
}


#pragma mark - Sockets

- (void)acceptConnectionOnSocket:(int)socket
{
    KMSAssert(socket >= 0);

    // suppress the SIGPIPE signal
    int value = 1;
    setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &value, sizeof(value));

    BOOL ok = self.connectionBlock(socket);
    if (!ok)
    {
        KMSLogDetail(@"connection failed, closing socket");
        int error = close(socket);
        KMSAssert(error == 0);
    }
}

static void callbackAcceptConnection(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    KMSListener* obj = (KMSListener*)info;
    KMSAssert(type == kCFSocketAcceptCallBack);
    KMSAssert(obj && (obj->_listener == s));
    KMSAssert(data);

    if (obj && data && (type == kCFSocketAcceptCallBack))
    {
        int socket = *((int*)data);
        [obj acceptConnectionOnSocket:socket];
    }
}

- (BOOL)makeSocket:(int*)socketOut
{
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (socketOut)
        *socketOut = fd;

    BOOL result = (fd != -1);

    if (result)
    {
        KMSLogDetail(@"got socket %d", fd);
    }
    else
    {
        KMSLog(@"couldn't make socket");
    }

    return result;
}

- (BOOL)bindSocket:(int)socket
{
    struct sockaddr_in  addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len    = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port   = htons(self.port);
    addr.sin_addr.s_addr = INADDR_ANY;
    int err = bind(socket, (const struct sockaddr *) &addr, sizeof(addr));
    BOOL result = (err == 0);
    if (!result)
    {
        KMSLog(@"couldn't bind socket %d, error %d", socket, err);
    }
    
    return result;
}

- (BOOL)listenOnSocket:(int)socket
{
    int err = listen(socket, 5);
    BOOL result = err == 0;

    if (!result)
    {
        KMSLog(@"couldn't listen on socket %d", socket);
    }

    return result;
}

- (BOOL)retrievePortForSocket:(int)socket
{
    // If we bound to port 0 the kernel will have assigned us a port.
    // use getsockname to find out what port number we actually got.
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len    = sizeof(addr);
    addr.sin_family = AF_INET;
    addr.sin_port   = htons(self.port);
    addr.sin_addr.s_addr = INADDR_ANY;
    socklen_t addrLen = sizeof(addr);
    int err = getsockname(socket, (struct sockaddr *) &addr, &addrLen);
    BOOL result = (err == 0);
    if (result)
    {
        KMSAssert(addrLen == sizeof(addr));
        self.port = ntohs(addr.sin_port);
    }
    else
    {
        KMSLog(@"couldn't retrieve socket port");
    }

    return result;
}

- (BOOL)makeCFSocketForSocket:(int)socket
{
    CFSocketContext context = { 0, (void *) self, NULL, NULL, NULL };

    KMSAssert(_listener == NULL);
    _listener = CFSocketCreateWithNative(NULL, socket, kCFSocketAcceptCallBack, callbackAcceptConnection, &context);

    BOOL result = (_listener != nil);
    if (result)
    {
        _source = CFSocketCreateRunLoopSource(NULL, _listener, 0);
        KMSAssert(_source);
        CFRunLoopAddSource(CFRunLoopGetMain(), _source, (CFStringRef) ListenerRunMode);
    }
    else
    {
        KMSLog(@"couldn't make CFSocket for socket %d", socket);
    }
    
    return result;
}

@end
