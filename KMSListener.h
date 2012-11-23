//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Object which listens on a given socket and executes a block
 when an incoming connection is received.
 */

@interface KMSListener : NSObject

/**
 Block which is run when a connection happens.
 */

typedef BOOL (^ConnectionBlock)(int socket);

/**
 The port we're listening on.
 */

@property (readonly, nonatomic) NSUInteger port;

/**
 Returns a new listener object for a given port.
 
 @param port The port to listen on. Passing zero here causes the system to allocate a port.
 @param block The block to execute when a connection is received.
 
 @return The new listener.
 */

+ (KMSListener*)listenerWithPort:(NSUInteger)port connectionBlock:(ConnectionBlock)block;

/**
 Initialise a new listener object for a given port.

 @param port The port to listen on. Passing zero here causes the system to allocate a port.
 @param block The block to execute when a connection is received.

 @return The new listener.
 */

- (id)initWithPort:(NSUInteger)port connectionBlock:(ConnectionBlock)block;

/**
 Start listening.
 
 @return YES if we manage to start ok.
 */

- (BOOL)start;

/**
 Stop listening.
 
 @param reason The reason we're stopping (used for logging only).
 */

- (void)stop:(NSString*)reason;

@end
