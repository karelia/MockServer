//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import "KMSResponder.h"

/**
 Object which responds to incoming data by outputting a list of commands.
 
 This class works by matching the input against a list of regular expression patterns.
 
 Commands, in this context, means an array of  NSString, NSData, or NSNumber
 objects.

 NSData objects are sent back directly as output.
 NSString objects are also sent back, except for the constant CloseCommand string, which closes the connection instead.
 NSNumber objects are interpreted as times, in seconds, to pause before sending back further output.

 */

@interface KMSRegExResponder : KMSResponder


/**
 Return a new responder object, using an array of responses.
 
 The responses consist of an array of arrays. Each of the inner arrays is in this format:

     @[pattern, command, command...]

 The pattern is a regular expression which is matched against input received by the server.

 @param responses An array of patterns and commands.
 @return The new responder object.

 */

+ (KMSRegExResponder*)responderWithResponses:(NSArray*)responses;


/**
 Initialise a new responder object, using an array of responses.

 The responses consist of an array of arrays. Each of the inner arrays is in this format:

     @[pattern, command, command...]

 The pattern is a regular expression which is matched against input received by the server.

 @param responses An array of patterns and commands.
 @return The new responder object.
 */

- (id)initWithResponses:(NSArray*)responses;

@end
