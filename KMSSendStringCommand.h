//
//  KMSSendStringCommand.h
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import "KMSCommand.h"

/**
 Command which sends a string down the connection.
 
 The string can have substitutions performed on it before sending,
 so can be modified at runtime.
 */

@interface KMSSendStringCommand : KMSCommand

/**
 The string to send.
 */

@property (strong, nonatomic) NSString* string;

/**
 Returns a new command to send a given string.
 
 @param string The string to send.
 @return The new command.
 */

+ (KMSSendStringCommand*)sendString:(NSString*)string;

@end

