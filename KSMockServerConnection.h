//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSMockServer;
@class KSMockServerResponder;

/**
 Object which uses the supplied KSMockServerResponder to respond to incoming data on a given socket.
 */

@interface KSMockServerConnection : NSObject<NSStreamDelegate>

/**
 Return a new connection on a given socket.
 
 @param socket The system socket to respond on.
 @param responder A KSMockServerResponder object which is responsible for receiving input and responding to it.
 @param server The server which received the original connection.
 
 @return A new connection.
 */

+ (KSMockServerConnection*)connectionWithSocket:(int)socket responder:(KSMockServerResponder*)responder server:(KSMockServer*)server;

/**
 Return a new connection on a given socket.

 @param socket The system socket to respond on.
 @param responder A KSMockServerResponder object which is responsible for receiving input and responding to it.
 @param server The server which received the original connection.

 @return A new connection.
 */

- (id)initWithSocket:(int)socket responder:(KSMockServerResponder*)responder server:(KSMockServer *)server;

/**
 Disconnect the streams we're managing.
 */

- (void)cancel;

@end
