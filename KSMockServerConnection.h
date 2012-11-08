//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KSMockServer;
@class KSMockServerResponder;

@interface KSMockServerConnection : NSObject<NSStreamDelegate>

+ (KSMockServerConnection*)connectionWithSocket:(int)socket responder:(KSMockServerResponder*)responder server:(KSMockServer*)server;

- (id)initWithSocket:(int)socket responder:(KSMockServerResponder*)responder server:(KSMockServer *)server;

- (void)cancel;

@end
