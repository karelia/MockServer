//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import "KMSResponseCollection.h"
#import "KMSRegExResponder.h"
#import "KMSServer.h"

@interface KMSResponseCollection()

@property (strong, nonatomic) NSDictionary* sets;
@property (strong, nonatomic) NSDictionary* responses;

@end

@implementation KMSResponseCollection

#pragma mark - Object Lifecycle

+ (KMSResponseCollection*)collectionWithURL:(NSURL *)url
{
    KMSResponseCollection* collection = [[KMSResponseCollection alloc] initWithURL:url];

    return [collection autorelease];
}

- (id)initWithURL:(NSURL*)url
{
    KMSAssert(url != nil);

    if ((self = [super init]) != nil)
    {
        NSError* error = nil;
        NSData* data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
        NSDictionary* info = nil;
        if (data)
        {
            info = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        }

        if (info)
        {
            self.sets = info[@"sets"];
            self.responses = info[@"responses"];
            self.scheme = info[@"scheme"];
        }
        else
        {
            KMSLog(@"failed to load response collection with error: %@", error);
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

- (NSArray*)responsesWithName:(NSString*)name
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
            KMSLog(@"unknown response %@ in set %@", responseName, name);
        }
    }

    return responses;
}

- (KMSRegExResponder*)responderWithName:(NSString *)name
{
    NSArray* responses = [self responsesWithName:name];

    return [KMSRegExResponder responderWithResponses:responses];
}

@end
