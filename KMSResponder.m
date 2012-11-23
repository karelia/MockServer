//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import "KMSResponder.h"
#import "KMSServer.h"

@interface KMSResponder()

@end

@implementation KMSResponder

#pragma mark - Object Lifecycle

#pragma mark - Public API

- (NSArray*)initialResponse
{
    return nil;
}

- (NSArray*)responseForRequest:(NSString*)request substitutions:(NSDictionary*)substitutions
{
    return nil;
}

@end
