//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import "KSMockServerResponseCollection.h"
#import "KSMockServerRegExResponder.h"
#import "KSMockServer.h"

@interface KSMockServerResponseCollection()

@property (strong, nonatomic) NSDictionary* sets;
@property (strong, nonatomic) NSDictionary* responses;

@end

@implementation KSMockServerResponseCollection

#pragma mark - Object Lifecycle

+ (KSMockServerResponseCollection*)collectionWithURL:(NSURL *)url
{
    KSMockServerResponseCollection* collection = [[KSMockServerResponseCollection alloc] initWithURL:url];

    return [collection autorelease];
}

- (id)initWithURL:(NSURL*)url
{
    if ((self = [super init]) != nil)
    {
        NSError* error = nil;
        NSData* data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
        NSDictionary* info = @{};
        if (data)
        {
            info = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        }

        if (info)
        {
            self.sets = info[@"sets"];
            self.responses = info[@"responses"];
        }
        else
        {
            [self release];
            self = nil;
        }
    }

    return self;
}

- (void)dealloc
{
    [_sets release];
    [_responses release];

    [super dealloc];
}

- (KSMockServerRegExResponder*)responderWithName:(NSString *)name
{
    NSMutableArray* responses = [NSMutableArray array];

    NSDictionary* set = self.sets[name];
    NSArray* responseNames = set[@"responses"];
    for (NSString* responseName in responseNames)
    {
        NSDictionary* response = self.responses[responseName];
        if (response)
        {
            NSMutableArray* array = [NSMutableArray array];
            [array addObject:response[@"pattern"]];
            [array addObjectsFromArray:response[@"commands"]];
            [responses addObject:array];
        }
        else
        {
            MockServerLog(@"unknown response %@ in set %@", responseName, name);
        }
    }

    return [KSMockServerRegExResponder responderWithResponses:responses];
}

@end
