//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Object which responds to incoming data by outputting a list of commands.
 
 This is an abstract class. Subclasses can choose to perform some sort of
 pattern matching to choose from a set of predefined responses (see <KMSRegExResponder>),
 or they can implement a state machine or some other complex behaviour.
 In theory they could even implement proper server implications, although that's not really the intention
 of the KMSServer system.
 */

@interface KMSResponder : NSObject

/**
 The commands to execute when a connection is first made.
 */

- (NSArray*)initialResponse;

/**
 Return a list of commands in response to a given input request.
 
 @param request The incoming request.
 @param substitutions A dictionary of global substitution values to use when formulating the responses.
 
 @return An array of NSString, NSData or NSNumber "coimmands".

 */

- (NSArray*)responseForRequest:(NSString*)request substitutions:(NSDictionary*)substitutions;

@end
