//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@class KMSServer;
@class KMSResponseCollection;

/**
 Base class for unit tests that use KMSServer.
 
 This class simplfies the setup and execution of KMSServer unit tests.
 
 It's not the only way to use the KMSServer class, but if you're happy to load 
 responses from a JSON file, it makes things simple.
 
 The basic format for a test using this class is:
 
 - (void)testSomething
 {
    if ([self setupServerWithScheme:@"ftp" responses:@"ftp"])
    {
        // make your network request here
 
        [self runUntilPaused];

        // test your results here
    }
 }

 Your network request should ensure that it calls [self pause] from its delegate method or completion callback.
 The runUntilPaused call will sit pumping the current run loop until this happens - which is what gives the
 networking code that you're testing time to do its thing.

 */

@interface KMSTestCase : SenTestCase

@property (strong, nonatomic) KMSServer* server;
@property (strong, nonatomic) NSString* user;
@property (strong, nonatomic) NSString* password;
@property (strong, nonatomic) KMSResponseCollection* responses;
@property (strong, nonatomic) NSURL* url;

/**
 Setup a test using responses from a given JSON file.
 
 The set called "default" from the responses file is loaded. You can change to another set later by calling <useResponseSet>.

 @param responsesFile The name of the responses file. This should be a JSON file, added as a resource to the unit test bundle.
 @return YES if the test server got set up ok.
 */

- (BOOL)setupServerWithResponseFileNamed:(NSString*)responsesFile;

/**
 Clean up after a test.
 This is called automatically by tearDown, but you can also call it yourself if you want to call setupServerWithScheme:responses: again with different settings.
 */

- (void)cleanupServer;

/** 
 Switch the current server to use a different response set.
 You can use this to change the responses you're doing mid-test. For example, you might make a request
 with one set of response that pretends to reject a password, then switch response set and make the same
 request again with a set that pretends to accept the password.
 
 @param name The name of the response set to use.
 */

- (void)useResponseSet:(NSString*)name;

/**
 Return a URL by appending a path to the root URL for the server.
 
 This will include the local address and port assigned to the server object, and the scheme that you passed in when you set it up.
 
 @param path The path to append.
 @return The full URL.
 */

- (NSURL*)URLForPath:(NSString*)path;

/** 
 Perform an [NSURLConnection sendAsynchronousRequest] call to the mock server, and return the result as
 an NSString.
 
 This helper deals with calling <runUntilPaused> to pump the event loop until the request is done, and then
 calling <pause> to pause the server and return control to the test.
 
 @param request The request to perform.

 */

- (NSString*)stringForRequest:(NSURLRequest*)request;

/**
 Pump the current event loop until something calls <pause> on the server.
 */

- (void)runUntilPaused;

/**
 Calls <pause> on the server to cause <runUntilPaused> to return.
 
 After this call, it's ok to call <runUntilPaused> again to perform more work.
 */

- (void)pause;

/**
 Calls <resume> on the server after a call to <runUntilPaused>/<pause>.

 After this call, it's ok to call <runUntilPaused>/<pause> again to perform more work.
 */

- (void)resume;

@end
