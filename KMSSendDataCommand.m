//
//  KMSSendDataCommand.m
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import "KMSSendDataCommand.h"
#import "KMSConnection.h"
#import "KMSServer.h"

@implementation KMSSendDataCommand

+ (KMSSendDataCommand*)sendData:(NSData *)data
{
    KMSSendDataCommand* result = [[KMSSendDataCommand alloc] init];
    result.data = data;

    return [result autorelease];
}

- (void)dealloc
{
    [_data release];

    [super dealloc];
}

- (NSTimeInterval)performOnConnection:(KMSConnection*)connection server:(KMSServer*)server
{
    KMSLog(@"queued data %@", self.data);
    [connection appendOutput:self.data];

    return 0;
}

@end
