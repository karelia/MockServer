//
//  KMSCommand.h
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KMSConnection;
@class KMSServer;

/**
 Performs an action on a connection, such as sending some data down it.
 */

@interface KMSCommand : NSObject

/**
 Given an array of objects, return an array of commands.
 
 This routine is primarily used for converting arrays of objects loaded from disc.
 
 Any command object will just be returned untouched.
 NSData objects are converted into KMSSendDataCommand objects.
 NSNumber objects are converted into KMSPauseCommand objects.
 NSString objects are generally converted into either KMSSendStringCommands.
 A few specific string values are converted into other command objects.
 
 @param array The input array
 @return An array guaranteed to contain only KMSCommand objects.
*/

+ (NSArray*)commandArrayFromObjectArray:(NSArray*)array;

/**
 Perform the command that this object represents, using a given connection on a given server.
 
 @param connection The connection to perform on.
 @param server The server that the connection belongs to.
 */

- (NSTimeInterval)performOnConnection:(KMSConnection*)connection server:(KMSServer*)server;

/**
 Perform text substitutions on the command.
 Most commands will do nothing here, and just return themselves unchanged.
 Text-based commands however may return a new version of themselves, with variables such as $server replaced by actual values.
 
 @param values A dictionary of keys and values to substitute into the command.
 @return The substituted command. May or may not be the original command.
 */

- (KMSCommand*)substitutedWithValues:(NSDictionary*)values;

@end





@interface NSObject(KMSCommand)

- (KMSCommand*)asKMSCommand;

@end