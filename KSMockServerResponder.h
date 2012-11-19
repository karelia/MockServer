//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSMockServer;

/**
 Object which responds to incoming data by outputting a list of commands.

 */

@interface KSMockServerResponder : NSObject

/**
 The commands to execute when a connection is first made.
 */

@property (strong, nonatomic, readonly) NSArray* initialResponse;

/**
 Return a list of commands in response to a given input request.
 
 @param request The incoming request.
 @param substitutions A dictionary of global substitution values to use when formulating the responses.
 
 @return An array of NSString, NSData or NSNumber "coimmands".

 */

- (NSArray*)responseForRequest:(NSString*)request substitutions:(NSDictionary*)substitutions;

@end
