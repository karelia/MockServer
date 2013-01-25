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

@implementation KMSCommand

- (CGFloat)performOnConnection:(KMSConnection*)connection server:(KMSServer*)server
{
    return 0;
}

- (KMSCommand*)substitutedWithValues:(NSDictionary *)values
{
    return self;
}

@end

@implementation KMSPauseCommand

+ (KMSPauseCommand*)pauseFor:(CGFloat)delay
{
    KMSPauseCommand* result = [[KMSPauseCommand alloc] init];
    result.delay = delay;

    return [result autorelease];
}

- (CGFloat)performOnConnection:(KMSConnection*)connection server:(KMSServer*)server
{
    KMSLog(@"paused for %lf seconds", self.delay);
    return self.delay;
}

@end

@implementation KMSSendDataCommand

+ (KMSSendDataCommand*)sendData:(NSData *)data
{
    KMSSendDataCommand* result = [[KMSSendDataCommand alloc] init];
    result.data = data;

    return [result autorelease];
}

- (CGFloat)performOnConnection:(KMSConnection*)connection server:(KMSServer*)server
{
    KMSLog(@"queued data %@", self.data);
    [connection appendOutput:self.data];
    
    return 0;
}

@end

@implementation KMSSendStringCommand

+ (KMSSendStringCommand*)sendString:(NSString *)string
{
    KMSSendStringCommand* result = [[KMSSendStringCommand alloc] init];
    result.string = string;

    return [result autorelease];
}

- (CGFloat)performOnConnection:(KMSConnection*)connection server:(KMSServer*)server
{
    // log just the first line of the output
    NSString* log = self.string;
    NSRange range = [log rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
    if (range.location != NSNotFound)
    {
        log = [NSString stringWithFormat:@"%@… (%ld bytes)", [log substringToIndex:range.location], (long) [log length]];
    }
    KMSLog(@"queued output %@", log);

    [connection appendOutput:[self.string dataUsingEncoding:NSUTF8StringEncoding]];

    return 0;
}

- (KMSCommand*)substitutedWithValues:(NSDictionary*)substitutions
{
    KMSCommand* result;

    BOOL containsTokens = [self.string rangeOfString:@"$"].location != NSNotFound;
    if (containsTokens)
    {
        NSMutableString* substituted = [NSMutableString stringWithString:self.string];
        [substitutions enumerateKeysAndObjectsUsingBlock:^(id key, id replacement, BOOL *stop) {
            [substituted replaceOccurrencesOfString:key withString:replacement options:0 range:NSMakeRange(0, [substituted length])];
        }];

        KMSLogDetail(@"expanded response %@ as %@", self.string, substituted);
        result = [KMSSendStringCommand sendString:substituted];
    }
    else
    {
        result = self;
    }

    return result;
}

@end

@implementation KMSSendServerDataCommand

+ (KMSSendServerDataCommand*)sendServerData
{
    KMSSendServerDataCommand* result = [[KMSSendServerDataCommand alloc] init];

    return [result autorelease];
}

- (CGFloat)performOnConnection:(KMSConnection*)connection server:(KMSServer*)server
{
    KMSAssert(server.data);
    KMSLog(@"queued server.data as output");
    [connection appendOutput:server.data];

    return 0;
}

@end

@implementation KMSCloseCommand

+ (KMSCloseCommand*)closeCommand
{
    KMSCloseCommand* result = [[KMSCloseCommand alloc] init];

    return [result autorelease];
}

- (CGFloat)performOnConnection:(KMSConnection*)connection server:(KMSServer*)server
{
    [connection close];

    return 0;
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

    if ([self isEqual:CloseCommand])
    {
        result = [KMSCloseCommand closeCommand];
    }
    else if ([self isEqual:DataCommand])
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