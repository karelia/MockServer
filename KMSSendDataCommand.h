//
//  KMSSendDataCommand.h
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import "KMSCommand.h"

/**
 Command which sends raw data down the connection.
 */

@interface KMSSendDataCommand : KMSCommand

/**
 The data to send.
 */

@property (strong, nonatomic) NSData* data;

/**
 Return a new command to send some data.

 @param data The data to send.
 @return The new command.
 */

+ (KMSSendDataCommand*)sendData:(NSData*)data;

@end
