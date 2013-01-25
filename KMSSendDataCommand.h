//
//  KMSSendDataCommand.h
//  MockServer
//
//  Created by Sam Deane on 25/01/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import "KMSCommand.h"

@interface KMSSendDataCommand : KMSCommand

@property (strong, nonatomic) NSData* data;

+ (KMSSendDataCommand*)sendData:(NSData*)data;

@end
