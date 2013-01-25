//
//  KMSCommand.h
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KMSConnection;
@class KMSServer;

@interface KMSCommand : NSObject

- (CGFloat)performOnConnection:(KMSConnection*)connection server:(KMSServer*)server;
- (KMSCommand*)substitutedWithValues:(NSDictionary*)values;

@end

@interface KMSSendDataCommand : KMSCommand

@property (strong, nonatomic) NSData* data;

+ (KMSSendDataCommand*)sendData:(NSData*)data;

@end

@interface KMSSendStringCommand : KMSCommand

@property (strong, nonatomic) NSString* string;

+ (KMSSendStringCommand*)sendString:(NSString*)string;

@end

@interface KMSSendServerDataCommand : KMSCommand

+ (KMSSendServerDataCommand*)sendServerData;

@end

@interface KMSPauseCommand : KMSCommand

@property (assign, nonatomic) CGFloat delay;

+ (KMSPauseCommand*)pauseFor:(CGFloat)delay;

@end

@interface KMSCloseCommand : KMSCommand

+ (KMSCloseCommand*)closeCommand;

@end

@interface NSObject(KMSCommand)

- (KMSCommand*)asKMSCommand;

@end