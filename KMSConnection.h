//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KMSServer;
@class KMSResponder;

/**
 Object which uses the supplied KMSResponder to respond to incoming data on a given socket.
 */

@interface KMSConnection : NSObject<NSStreamDelegate>

/**
 Return a new connection on a given socket.
 
 @param socket The system socket to respond on.
 @param responder A KMSResponder object which is responsible for receiving input and responding to it.
 @param server The server which received the original connection.
 
 @return A new connection.
 */

+ (KMSConnection*)connectionWithSocket:(int)socket responder:(KMSResponder*)responder server:(KMSServer*)server;

/**
 Return a new connection on a given socket.

 @param socket The system socket to respond on.
 @param responder A KMSResponder object which is responsible for receiving input and responding to it.
 @param server The server which received the original connection.

 @return A new connection.
 */

- (id)initWithSocket:(int)socket responder:(KMSResponder*)responder server:(KMSServer*)server;

/**
 Disconnect the streams we're managing.
 */

- (void)cancel;

@end
