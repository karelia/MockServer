//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@class KMSServer;
@class KMSResponseCollection;

@interface KMSTestCase : SenTestCase

@property (strong, nonatomic) KMSServer* server;
@property (assign, nonatomic) BOOL running;
@property (strong, nonatomic) NSString* user;
@property (strong, nonatomic) NSString* password;
@property (strong, nonatomic) KMSResponseCollection* responses;
@property (strong, nonatomic) NSURL* url;
@property (strong, nonatomic) NSMutableString* transcript;

/**
 Setup a test using a given scheme and the response from a given JSON file.
 
 @param scheme The URL scheme to use - eg ftp.
 @param responsesFile The name of the responses file. This should be a JSON file, added as a resource to the unit test bundle.
 @return YES if the test server got set up ok.
 */

- (BOOL)setupServerWithScheme:(NSString*)scheme responses:(NSString*)responsesFile;

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
 
 This helper deals with calling <runUntilStopped> to pump the event loop until the request is done, and then
 calling <pause> to pause the server and return control to the test.
 */

- (NSString*)stringForRequest:(NSURLRequest*)request;

/**
 Pump the current event loop until something calls <pause> or <stop> on the server.
 */

- (void)runUntilStopped;

/**
 Calls <stop> on the server to cause <runUntilStopped> to return.

 After this call, the server will have been shut down so it's not possible to call <runUntilStopped> again to perform more work.
 */

- (void)stop;

/**
 Calls <pause> on the server to cause <runUntilStopped> to return.
 
 After this call, it's ok to call <runUntilStopped> again to perform more work.
 */

- (void)pause;

@end
