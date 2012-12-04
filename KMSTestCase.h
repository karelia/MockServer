//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@class KMSServer;
@class KMSResponseCollection;

@interface KMSTestCase : SenTestCase

@property (strong, nonatomic) KMSServer* server;
@property (assign, nonatomic) BOOL running;
@property (strong, nonatomic) NSString* user;
@property (strong, nonatomic) NSString* password;
@property (strong, nonatomic) KMSResponseCollection* responses;
@property (strong, nonatomic) NSURL* url;
@property (strong, nonatomic) NSMutableString* transcript;

- (BOOL)setupSessionWithScheme:(NSString*)scheme responses:(NSString*)responsesFile;
- (void)useResponseSet:(NSString*)name;

- (NSURL*)URLForPath:(NSString*)path;

- (void)runUntilStopped;
- (void)stop;
- (void)pause;

@end
