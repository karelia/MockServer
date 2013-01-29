//
//  KMSSendStringCommand.m
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import "KMSSendStringCommand.h"
#import "KMSConnection.h"
#import "KMSServer.h"

@implementation KMSSendStringCommand

+ (KMSSendStringCommand*)sendString:(NSString *)string
{
    KMSSendStringCommand* result = [[KMSSendStringCommand alloc] init];
    result.string = string;

    return [result autorelease];
}

- (void)dealloc
{
    [_string release];

    [super dealloc];
}

- (NSTimeInterval)performOnConnection:(KMSConnection*)connection server:(KMSServer*)server
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
