//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MockServerLog NSLog
#define MockServerAssert(x) assert((x))

/**

 A server which runs locally and "pretends" to be something else.

 You provide the server with an optional port to run on, and a list of responses.

 The responses consist of an array of arrays, in this format:
 pattern, command, command...

 The pattern is a regular expression which is matched against input received by the server.
 The commands are NSString, NSData, or NSNumber objects, which are processed when
 the pattern has been matched.

 See the [documentation](http://karelia.github.com/MockServer/Documentation/).

 See also the MockServerTests.m file for some examples.

 */

@interface KSMockServer : NSObject<NSStreamDelegate>

/**
 This data will automatically be sent when something connects to the passive data connection.
 */

@property (strong, nonatomic) NSData* data;

/** 
 The port that the server is running on.
 */

@property (readonly, nonatomic) NSUInteger port;

/**
 YES if the server is running. NO if the stop method has been called.
 */

@property (readonly, atomic) BOOL running;

/** 
 Make a server that uses the given responses.
 The server will listen on an automatically allocated port.
 
 @param responses An array of responses that the server uses to respond to connections.
 @return A new auto-released server instance.
 */

+ (KSMockServer*)serverWithResponses:(NSArray*)responses;

/**
 Make a server that uses the given responses, and listens on a given port.

 @note The system doesn't always free up ports instantly, so if you run multiple tests on a fixed port in quick succession you may find that the server fails to bind.

 @param port The port to listen on.
 @param responses An array of responses that the server uses to respond to connections.
 @return A new auto-released server instance.
 */

+ (KSMockServer*)serverWithPort:(NSUInteger)port responses:(NSArray*)responses;

/**
 Initialise with a given set of responses, listening on a given port.

 @note The system doesn't always free up ports instantly, so if you run multiple tests on a fixed port in quick succession you may find that the server fails to bind.

 @param port The port to listen on.
 @param responses An array of responses that the server uses to respond to connections.
 @return A new auto-released server instance.
 */

- (id)initWithPort:(NSUInteger)port responses:(NSArray*)responses;

/**
 Start the server.
 */

- (void)start;

/**
 Stop the server.
 */

- (void)stop;

/**
 Loop in the current run loop until something calls stop on the server.
 
 Typically you start the server, initiate the network operation that you want
 to test, then call [KSMockServer runUntilStopped] in your test case. 

 In a completion block or delegate method of your network operation, you 
 can then call [KSMockServer stop] on the server, at which point your test case will continue
 executing and you can verify that you got the results you were expecting.
 
 */

- (void)runUntilStopped;


/**
 Returns a standard set of variable substitutions.
 
 @note needs more explanation
 */

- (NSDictionary*)standardSubstitutions;

@end

/**
 When the server encounters this as an output item,
 it closes the connection.
 */

extern NSString *const CloseCommand;

/**
 The server interprets a response with this key specially.
 When the connection is first opened, the data associated
 with this key is immediately sent back.
 */

extern NSString *const InitialResponseKey;
