//
//  KMSSendServerDataCommand.h
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import "KMSCommand.h"

/**
 Command which sends the value of the server's data property down the connection.
 */

@interface KMSSendServerDataCommand : KMSCommand

+ (KMSSendServerDataCommand*)sendServerData;

@end
