//
//  KMSCloseCommand.h
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import "KMSCommand.h"

/**
 Command which causes the connection to close.
 */

@interface KMSCloseCommand : KMSCommand

/**
 Returns a new close command object.
 
 @return The close command.
 */

+ (KMSCloseCommand*)closeCommand;

@end
