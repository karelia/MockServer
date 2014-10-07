//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

/***
 Some example tests which use a KMSRegExResponder.
 These tests build up the responses array manually in code. Alternatively, you can use KMSResponseCollection to load them from a JSON file.
 */

#import "KMSServer.h"
#import "KMSRegExResponder.h"
#import "KMSSendStringCommand.h"
#import "KMSPauseCommand.h"
#import "KMSCloseCommand.h"

#import <XCTest/XCTest.h>

@interface KMSManualTests : XCTestCase

@end

@implementation KMSManualTests

static NSString *const HTTPHeader = @"HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=iso-8859-1\r\n\r\n";
static NSString*const HTTPContent = @"<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\"><html><head><title>example</title></head><body>example result</body></html>\n";

- (NSArray*)httpResponses
{
    NSArray* responses = @[
    @[ @"^GET .* HTTP.*", [KMSSendStringCommand sendString:HTTPHeader], [KMSSendStringCommand sendString:HTTPContent], [KMSPauseCommand pauseFor:0.1], [KMSCloseCommand closeCommand]],
    @[@"^HEAD .* HTTP.*", [KMSSendStringCommand sendString:HTTPHeader], [KMSCloseCommand closeCommand]],
    ];

    return responses;
}

- (KMSServer*)setupServerWithResponses:(NSArray*)responses
{
    KMSRegExResponder* responder = [KMSRegExResponder responderWithResponses:responses];
    KMSServer* server = [KMSServer serverWithPort:0 responder:responder];

    XCTAssertNotNil(server, @"got server");
    [server start];
    BOOL started = server.running;
    XCTAssertTrue(started, @"server started ok");
    return started ? server : nil;
}

- (NSString*)stringForScheme:(NSString*)scheme path:(NSString*)path method:(NSString*)method server:(KMSServer*)server
{
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://127.0.0.1:%ld%@", scheme, (long)server.port, path]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method;
    return [self stringForRequest:request server:server];
}

- (NSString*)stringForScheme:(NSString*)scheme path:(NSString*)path server:(KMSServer*)server
{
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://127.0.0.1:%ld%@", scheme, (long)server.port, path]];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    return [self stringForRequest:request server:server];
}

- (NSString*)stringForRequest:(NSURLRequest*)request server:(KMSServer*)server
{
    __block NSString* string = nil;

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse* response, NSData* data, NSError* error)
     {
         if (error)
         {
             NSLog(@"got error %@", error);
         }
         else
         {
             string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
         }

         [server pause];
     }];

    [server runUntilPaused];

    return [string autorelease];
}

#pragma mark - Tests

- (void)testHTTPGet
{
    KMSServer* server = [self setupServerWithResponses:[self httpResponses]];
    if (server)
    {
        NSString* string = [self stringForScheme:@"http" path:@"/index.html" method:@"GET" server:server];
        XCTAssertEqualObjects(string, HTTPContent, @"wrong response");
    }

    [server stop];
}

- (void)testHTTPHead
{
    KMSServer* server = [self setupServerWithResponses:[self httpResponses]];
    if (server)
    {
        NSString* string = [self stringForScheme:@"http" path:@"/index.html" method:@"HEAD" server:server];
        XCTAssertEqualObjects(string, @"", @"wrong response");
    }

    [server stop];
}

@end