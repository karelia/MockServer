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
    if ([self setupServerWithScheme:@"ftp" responses:@"ftp"])
    {
        // set up the data that the server will return
        NSString* testData = @"This is some test data";
        self.server.data = [testData dataUsingEncoding:NSUTF8StringEncoding];

        // setup an ftp request
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"ftp://user:pass@127.0.0.1:%ld/test.txt", (long)self.server.port]];
        NSURLRequest* request = [NSURLRequest requestWithURL:url];

        // perform the request using NSURLConnection
        // stringForRequest is a KMSTestCase helper which deals with the simple case of an NSURLConnection request
        // for other types of request you may need to do more work, but if you examine the source of stringForRequest you'll see that the basic
        // principle is quite straightfoward
        NSString* string = [self stringForRequest:request];

        // check that we got back what we were expecting
        STAssertEqualObjects(string, testData, @"got the wrong response: %@", string);
    }
}

@end