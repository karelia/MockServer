//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import "KMSRegExResponder.h"
#import "KMSServer.h"
#import "KMSCommand.h"

@interface KMSRegExResponder()

@property (strong, nonatomic) NSArray* requests;
@property (strong, nonatomic) NSArray* responses;
@property (copy, nonatomic, readwrite) NSArray* initialResponse;

@end

@implementation KMSRegExResponder

@synthesize initialResponse = _initialResponse;
@synthesize requests = _requests;
@synthesize responses = _responses;

#pragma mark - Object Lifecycle

+ (KMSRegExResponder*)responderWithResponses:(NSArray *)responses
{
    KMSRegExResponder* server = [[KMSRegExResponder alloc] initWithResponses:responses];

    return [server autorelease];
}

- (id)initWithResponses:(NSArray *)responses
{
    if ((self = [super init]) != nil)
    {
        // process responses array - we pull out some special responses, and pre-calculate all the regular expressions
        NSRegularExpressionOptions options = NSRegularExpressionDotMatchesLineSeparators;
        NSMutableArray* processed = [NSMutableArray arrayWithCapacity:[responses count]];
        NSMutableArray* expressions = [NSMutableArray arrayWithCapacity:[responses count]];
        for (NSArray* response in responses)
        {
            NSUInteger length = [response count];
            if (length > 0)
            {
                NSString* pattern = response[0];
                NSArray* commands = [KMSCommand commandArrayFromObjectArray:[response subarrayWithRange:NSMakeRange(1, length - 1)]];
                if ([pattern isEqualToString:InitialResponsePattern])
                {
                    
                    self.initialResponse = commands;
                }
                else
                {
                    NSError* error = nil;
                    NSRegularExpression* expression = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:&error];
                    if (expression)
                    {
                        [expressions addObject:expression];
                        [processed addObject:commands];
                    }
                }
            }
        }
        self.requests = expressions;
        self.responses = processed;
    }

    return self;
}

- (void)dealloc
{
    [_initialResponse release];
    [_responses release];
    [_requests release];
    
    [super dealloc];
}

#pragma mark - Public API

- (NSArray*)responseForRequest:(NSString*)request substitutions:(NSDictionary*)substitutions
{
    NSArray* commands = nil;
    NSRange wholeString = NSMakeRange(0, [request length]);

    NSUInteger count = [self.requests count];
    for (NSUInteger n = 0; n < count; ++n)
    {
        NSRegularExpression* expression = self.requests[n];
        NSTextCheckingResult* match = [expression firstMatchInString:request options:0 range:wholeString];
        if (match)
        {
            KMSLogDetail(@"matched with request pattern %@", expression);
            NSArray* rawCommands = self.responses[n];
            commands = [self substitutedCommands:rawCommands match:match request:request substitutions:substitutions];
            break;
        }
    }

    return commands;
}

- (void)addSubstitutionsForMatch:(NSTextCheckingResult*)match request:(NSString*)request toDictionary:(NSMutableDictionary*)dictionary
{
    // always add the request as $0
    [dictionary setObject:request forKey:@"$0"];

    // add any matched subgroups
    if (match)
    {
        NSUInteger count = match.numberOfRanges;
        for (NSUInteger n = 1; n < count; ++n)
        {
            NSString* token = [NSString stringWithFormat:@"$%ld", (long) n];
            NSRange range = [match rangeAtIndex:n];
            NSString* replacement = [request substringWithRange:range];
            [dictionary setObject:replacement forKey:token];
        }
    }
}

- (NSArray*)substitutedCommands:(NSArray*)commands match:(NSTextCheckingResult*)match request:(NSString*)request substitutions:(NSDictionary*)serverSubstitutions
{
    NSMutableDictionary* substitutions = [NSMutableDictionary dictionary];
    [substitutions addEntriesFromDictionary:serverSubstitutions];
    [self addSubstitutionsForMatch:match request:request toDictionary:substitutions];

    NSMutableArray* substitutedCommands = [NSMutableArray arrayWithCapacity:[commands count]];
    for (id command in commands)
    {
        KMSCommand* substituted = [command substitutedWithValues:substitutions];
        [substitutedCommands addObject:substituted];
    }

    return substitutedCommands;
}

@end
