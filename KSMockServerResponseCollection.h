//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSMockServer;
@class KSMockServerRegExResponder;

/**
 Loads a group of named mock server responses from a JSON file,
 and allows you to obtain a responder using one of them.
 
 Keeping the responses in JSON is a lot simpler than
 building up the array in code.
 */

@interface KSMockServerResponseCollection : NSObject

/**
 Return a new collection, using the file at a given URL.

 @param url The URL of the response collection file.
 @return The new responder collection object.

 */

+ (KSMockServerResponseCollection*)collectionWithURL:(NSURL*)url;

/**
 Return the set of responses with a given name.

 @param name The name of the response set to use.
 @return An array of responses.
 */

- (NSArray*)responsesWithName:(NSString*)name;

/**
 Return a responder using the set of responses with a given name.
 
 @param name The name of the response set to use.
 @return A responder which uses the set of responses.
 */

- (KSMockServerRegExResponder*)responderWithName:(NSString*)name;

@end
