//
//  KMSPauseCommand.h
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import "KMSCommand.h"

@interface KMSPauseCommand : KMSCommand

@property (assign, nonatomic) CGFloat delay;

+ (KMSPauseCommand*)pauseFor:(CGFloat)delay;

@end
