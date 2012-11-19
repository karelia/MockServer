//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import "KSMockServerResponder.h"
#import "KSMockServer.h"

@interface KSMockServerResponder()

@end

@implementation KSMockServerResponder

@synthesize initialResponse = _initialResponse;

#pragma mark - Object Lifecycle

- (void)dealloc
{
    [_initialResponse release];

    [super dealloc];
}

#pragma mark - Public API

- (NSArray*)responseForRequest:(NSString*)request substitutions:(NSDictionary*)substitutions
{
    return nil;
}

@end
