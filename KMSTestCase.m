//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import "KMSTestCase.h"
#import "KMSServer.h"
#import "KMSRegExResponder.h"
#import "KMSResponseCollection.h"

@implementation KMSTestCase

- (void)dealloc
{
    [_password release];
    [_responses release];
    [_server release];
    [_url release];
    [_user release];

    [super dealloc];
}

- (void)tearDown
{
    [self cleanupServer];
}

- (BOOL)setupServerWithResponseFileNamed:(NSString *)responsesFile
{
    self.user = @"user";
    self.password = @"pass";

    NSURL* url = [[NSBundle bundleForClass:[self class]] URLForResource:responsesFile withExtension:@"json"];
    if (url)
    {
        self.responses = [KMSResponseCollection collectionWithURL:url];
        KMSRegExResponder* responder = [self.responses responderWithName:@"default"];
        if (responder)
        {
            self.server = [KMSServer serverWithPort:0 responder:responder];
            STAssertNotNil(self.server, @"got server");

            if (self.server)
            {
                [self.server start];
                BOOL started = self.server.running;
                STAssertTrue(started, @"server started ok");

                self.url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://127.0.0.1:%ld", self.responses.scheme, (unsigned long)self.server.port]];
            }
        }
    }
    else
    {
        KMSLog(@"no response file called '%@'", responsesFile);
    }

    return self.server != nil;
}

- (void)cleanupServer
{
    [self.server stop];
    self.user = nil;
    self.password = nil;
    self.url = nil;
    self.responses = nil;
    self.server = nil;
}

- (void)useResponseSet:(NSString*)name
{
    KMSResponder* responder = [self.responses responderWithName:name];
    if (responder)
    {
        self.server.responder = responder;
    }
}

- (NSURL*)URLForPath:(NSString*)path
{
    NSURL* url = [self.url URLByAppendingPathComponent:path];
    return url;
}

- (NSString*)stringForRequest:(NSURLRequest*)request
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

         [self pause];
     }];

    [self runUntilPaused];

    return [string autorelease];
}

- (void)runUntilPaused
{
    [self.server runUntilPaused];
}

- (void)pause
{
    [self.server pause];
}

- (void)resume
{
    [self.server resume];
}



@end