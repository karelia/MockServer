//
//  KMSCloseCommand.m
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import "KMSCloseCommand.h"
#import "KMSConnection.h"

@implementation KMSCloseCommand

+ (KMSCloseCommand*)closeCommand
{
    KMSCloseCommand* result = [[KMSCloseCommand alloc] init];

    return [result autorelease];
}

- (NSTimeInterval)performOnConnection:(KMSConnection*)connection server:(KMSServer*)server
{
    [connection close];

    return 0;
}

@end
