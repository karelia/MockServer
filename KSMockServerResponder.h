//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSMockServer;

/**
 Object which responds to incoming data by outputting a list of commands.
 
 The default implementation of this class works by matching the input against a list
 of regular expression patterns, but subclasses could implement other schemes,
 (in theory they could even implement proper server implications, although that's
 not the intention).
 
 Commands, in this context, means an array of  NSString, NSData, or NSNumber
 objects.

 NSData objects are sent back directly as output.
 NSString objects are also sent back, except for the constant CloseCommand string, which closes the connection instead.
 NSNumber objects are interpreted as times, in seconds, to pause before sending back further output.

 */

@interface KSMockServerResponder : NSObject

/**
 The commands to execute when a connection is first made.
 */

@property (strong, nonatomic, readonly) NSArray* initialResponse;

/**
 Return a new responder object, using an array of responses.
 
 The responses consist of an array of arrays. Each of the inner arrays is in this format:

     @[pattern, command, command...]

 The pattern is a regular expression which is matched against input received by the server.

 */

+ (KSMockServerResponder*)responderWithResponses:(NSArray*)responses;

/**
 Initialise a new responder object, using an array of responses.

 The responses consist of an array of arrays. Each of the inner arrays is in this format:

 @[pattern, command, command...]

 The pattern is a regular expression which is matched against input received by the server.

 */

- (id)initWithResponses:(NSArray*)responses;

/**
 Return a list of commands in response to a given input request.
 
 @param request The incoming request.
 @param substitutions A dictionary of global substitution values to use when formulating the responses.
 
 @return An array of NSString, NSData or NSNumber "coimmands".

 */

- (NSArray*)responseForRequest:(NSString*)request substitutions:(NSDictionary*)substitutions;

@end
