//  Created by Sam Deane on 18/12/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Represents an entry in the server's transcript.
 
 As it runs, the server records each input, output, and command that it executes.
 
 Unit tests can use this information, for example, to check that the client code is sending the right input.
 */

@interface KMSTranscriptEntry : NSObject

/**
 Transcript types.
 */
typedef NS_ENUM(NSUInteger, KMSTranscriptEntryType)
{
    KMSTranscriptInput,
    KMSTranscriptOutput,
    KMSTranscriptEvent,
    KMSTranscriptCommand
} ;

/**
 The type of entry.
 */

@property (assign, nonatomic) KMSTranscriptEntryType type;

/**
 The value of the transcript entry.
 */

@property (strong, nonatomic) id value;

/**
 Returns a new transcript entry with a given type and value.
 
 @param type The type of the new entry.
 @param value The value of the new entry.
 @return The new transcript entry.
 */

+ (KMSTranscriptEntry*)entryWithType:(KMSTranscriptEntryType)type value:(id)value;

@end
