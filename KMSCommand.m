//
//  KMSCommand.m
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import "KMSCommand.h"
#import "KMSConnection.h"
#import "KMSServer.h"

#import "KMSPauseCommand.h"
#import "KMSSendDataCommand.h"
#import "KMSSendStringCommand.h"
#import "KMSSendServerDataCommand.h"
#import "KMSCloseCommand.h"

@implementation KMSCommand

+ (NSArray*)commandArrayFromObjectArray:(NSArray*)array
{
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[array count]];
    for (id item in array)
    {
        KMSCommand* command = [item asKMSCommand];
        if (command)
        {
            [result addObject:command];
        }
    }

    return result;
}

- (KMSCommand*)asKMSCommand
{
    return self;
}

- (NSTimeInterval)performOnConnection:(KMSConnection*)connection server:(KMSServer*)server
{
    return 0;
}

- (KMSCommand*)substitutedWithValues:(NSDictionary *)values
{
    return self;
}

@end

#pragma mark - NSObject 

@implementation NSObject(KMSCommand)

- (KMSCommand*)asKMSCommand
{
    return nil;
}

@end

#pragma mark - NSString

@implementation NSString(KMSCommand)

- (KMSCommand*)asKMSCommand
{
    KMSCommand* result = nil;

    if ([self isEqual:CloseCommandToken])
    {
        result = [KMSCloseCommand closeCommand];
    }
    else if ([self isEqual:DataCommandToken])
    {
        result = [KMSSendServerDataCommand sendServerData];
    }
    else
    {
        result = [KMSSendStringCommand sendString:self];
    }

    return result;
}

@end

#pragma mark - NSData

@implementation NSData(KMSCommand)

- (KMSCommand*)asKMSCommand
{
    return [KMSSendDataCommand sendData:self];
}

@end

#pragma mark - NSNumber

@implementation NSNumber(KMSCommand)

- (KMSCommand*)asKMSCommand
{
    return [KMSPauseCommand pauseFor:[self doubleValue]];
}

@end