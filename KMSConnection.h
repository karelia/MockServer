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
 Open the connection.

 Called by the server once it's added the connection to it's list.

 */

- (void)open;


/**
 Close the connection.

 Generally only called by the KMSCloseCommand.

 */

- (void)close;


/**
 Disconnect the streams we're managing.
 */

- (void)cancel;


/**
 Append some data to the connection's output buffer.
 
 The connection will attempt to send the contents of the buffer immediately, 
 but won't necessarily manage to send it all at once. The rest will be send automatically
 when the connection is ready for it.

 Commands (such as KMSSendDataCommand or KMSSendStringCommand) use this
 to queue up their output.

 @param output The data to append to the output buffer.

 */

- (void)appendOutput:(NSData*)output;

@end
