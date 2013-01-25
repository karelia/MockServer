//
//  KMSSendServerDataCommand.m
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import "KMSSendServerDataCommand.h"
#import "KMSConnection.h"
#import "KMSServer.h"

@implementation KMSSendServerDataCommand

+ (KMSSendServerDataCommand*)sendServerData
{
    KMSSendServerDataCommand* result = [[KMSSendServerDataCommand alloc] init];

    return [result autorelease];
}

- (NSTimeInterval)performOnConnection:(KMSConnection*)connection server:(KMSServer*)server
{
    KMSAssert(server.data);
    KMSLog(@"queued server.data as output");
    [connection appendOutput:server.data];

    return 0;
}

@end
