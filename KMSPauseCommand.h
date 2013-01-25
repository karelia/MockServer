//
//  KMSPauseCommand.h
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import "KMSCommand.h"

/**
 A command which inserts a pause into the connection's output stream.
 */


@interface KMSPauseCommand : KMSCommand

/**
 The delay time (in seconds) of the pause.
 */

@property (assign, nonatomic) NSTimeInterval delay;

/**
 Returns a new command which pauses for given delay.
 
 @param delay The time (in seconds) to pause for.
 @return The pause command.
 */

+ (KMSPauseCommand*)pauseFor:(NSTimeInterval)delay;

@end
