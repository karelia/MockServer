//
//  KMSPauseCommand.m
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import "KMSPauseCommand.h"
#import "KMSServer.h"

@implementation KMSPauseCommand

+ (KMSPauseCommand*)pauseFor:(NSTimeInterval)delay
{
    KMSPauseCommand* result = [[KMSPauseCommand alloc] init];
    result.delay = delay;

    return [result autorelease];
}

- (NSTimeInterval)performOnConnection:(KMSConnection*)connection server:(KMSServer*)server
{
    KMSLog(@"paused for %lf seconds", self.delay);
    return self.delay;
}

@end
