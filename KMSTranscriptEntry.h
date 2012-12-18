//  Created by Sam Deane on 18/12/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KMSTranscriptEntry : NSObject

typedef enum
{
    KMSTranscriptInput,
    KMSTranscriptOutput,
    KMSTranscriptCommand
} KMSTranscriptEntryType;

@property (assign, nonatomic) KMSTranscriptEntryType type;
@property (strong, nonatomic) id value;

+ (KMSTranscriptEntry*)entryWithType:(KMSTranscriptEntryType)type value:(id)value;

@end
