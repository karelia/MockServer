//  Created by Sam Deane on 18/12/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import "KMSTranscriptEntry.h"

@implementation KMSTranscriptEntry

+ (KMSTranscriptEntry*)entryWithType:(KMSTranscriptEntryType)type value:(id)value
{
    KMSTranscriptEntry* entry = [[KMSTranscriptEntry alloc] init];
    entry.type = type;
    entry.value = value;

    return [entry autorelease];
}

- (void)dealloc
{
    [_value release];

    [super dealloc];
}

- (NSString*)description
{
    NSArray* typeStrings = @[@"Input", @"Output", @"Command"];
    NSString* valueString = [self.value description];
    NSRange range = [valueString rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
    if (range.location != NSNotFound)
    {
        valueString = [NSString stringWithFormat:@"%@…", [valueString substringToIndex:range.location]];
    }
    if ([valueString length] > 20)
    {
        valueString = [NSString stringWithFormat:@"%@…", [valueString substringToIndex:19]];
    }
    
    return [NSString stringWithFormat:@"<%@: %@>", typeStrings[self.type], valueString];
}

@end
