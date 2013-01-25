//
//  KMSSendStringCommand.h
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import "KMSCommand.h"

@interface KMSSendStringCommand : KMSCommand

@property (strong, nonatomic) NSString* string;

+ (KMSSendStringCommand*)sendString:(NSString*)string;

@end

