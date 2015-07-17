//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

/***
 Some example tests which use the KMSTestCase class to load responses from a JSON file.
 
 Using KMSTestCase simplifies the setup and teardown of the test for you, leaving you pretty much just having
 to fill in the bit of code that does the actual network request, and the bit that checks the response.
 */


#import "KMSTestCase.h"
#import "KMSServer.h"

@interface KMSCollectionTests : KMSTestCase

@end

@implementation KMSCollectionTests

#pragma mark - Tests

- (void)testFTP
{
    // setup a server object, using the ftp: scheme and taking the "default" set of responses from the "ftp.json" file.
    if ([self setupServerWithResponseFileNamed:@"ftp"])
    {
        // set up the data that the server will return
        NSString* testData = @"This is some test data";
        self.server.data = [testData dataUsingEncoding:NSUTF8StringEncoding];

        // setup an ftp request
        NSURL* url = [self URLForPath:@"test.txt"];
        NSURLRequest* request = [NSURLRequest requestWithURL:url];

        // perform the request using NSURLConnection
        // stringForRequest is a KMSTestCase helper which deals with the simple case of an NSURLConnection request that gets back a string
        NSString* string = [self stringForRequest:request];

        // check that we got back what we were expecting
        XCTAssertEqualObjects(string, testData, @"got the wrong response: %@", string);
    }
}

- (void)testFTPExplicit
{
    // test like the above one, but which doesn't use [self stringForRequest]
    
    // setup a server object, using the ftp: scheme and taking the "default" set of responses from the "ftp.json" file.
    if ([self setupServerWithResponseFileNamed:@"ftp"])
    {
        // set up the data that the server will return
        NSString* testData = @"This is some test data";
        self.server.data = [testData dataUsingEncoding:NSUTF8StringEncoding];

        // setup an ftp request
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"ftp://user:pass@127.0.0.1:%ld/test.txt", (long)self.server.port]];
        NSURLRequest* request = [NSURLRequest requestWithURL:url];

        // perform the request using NSURLConnection
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse* response, NSData* data, NSError* error)
         {
             if (error)
             {
                 XCTFail(@"got error %@", error);
             }
             else
             {
                 NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                 XCTAssertEqualObjects(string, testData, @"got the wrong response: %@", string);
             }

             [self pause];
         }];

        [self runUntilPaused];

        // check that we got back what we were expecting
    }
}

- (void)testMultiple
{
    // setup a server object, using the ftp: scheme and taking the "default" set of responses from the "ftp.json" file.
    if ([self setupServerWithResponseFileNamed:@"ftp"])
    {
        // setup an ftp request
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"ftp://user:pass@127.0.0.1:%ld/test.txt", (long)self.server.port]];
        NSURLRequest* request = [NSURLRequest requestWithURL:url];

        __block NSString* string = nil;

        // perform the request once
        self.server.data = [@"this is a test" dataUsingEncoding:NSUTF8StringEncoding];

        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse* response, NSData* data, NSError* error)
         {
             if (error)
             {
                 XCTFail(@"got error %@", error);
             }
             else
             {
                 string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             }

             [self pause];
         }];

        NSLog(@"send request for test.txt");
        [self runUntilPaused];
        XCTAssertEqualObjects(string, @"this is a test", @"got the wrong response: %@", string);

        [self.server resume];

        // perform the test again
        self.server.data = [@"this is another test" dataUsingEncoding:NSUTF8StringEncoding];
        url = [NSURL URLWithString:[NSString stringWithFormat:@"ftp://user:pass@127.0.0.1:%ld/another.txt", (long)self.server.port]];
        request = [NSURLRequest requestWithURL:url];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse* response, NSData* data, NSError* error)
         {
             if (error)
             {
                 XCTFail(@"got error %@", error);
             }
             else
             {
                 string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             }

             [self pause];
         }];

        NSLog(@"send request for another.txt");
        [self runUntilPaused];
        XCTAssertEqualObjects(string, @"this is another test", @"got the wrong response: %@", string);
    }
}

@end