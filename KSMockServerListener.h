//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KSMockServerListener : NSObject

typedef BOOL (^ConnectionBlock)(int socket);

@property (readonly, nonatomic) NSUInteger port;

+ (KSMockServerListener*)listenerWithPort:(NSUInteger)port connectionBlock:(ConnectionBlock)block;

- (id)initWithPort:(NSUInteger)port connectionBlock:(ConnectionBlock)block;

- (BOOL)start;
- (void)stop:(NSString*)reason;

@end
