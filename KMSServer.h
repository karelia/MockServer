//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KMSState.h"

#ifndef KMSLog
#define KMSLog(...) do { if ([KMSServer loggingLevel] > KMSLoggingOff) NSLog(__VA_ARGS__); } while (0)
#endif

#ifndef KMSLogDetail
#define KMSLogDetail(...) do { if ([KMSServer loggingLevel] == KMSLoggingDetail) NSLog(__VA_ARGS__); } while (0)
#endif

#ifndef KMSAssert
#define KMSAssert(x) assert((x))
#endif

@class KMSResponder;
@class KMSConnection;


typedef NS_ENUM(NSUInteger, KMSLogLevel)
{
    KMSLoggingOff,
    KMSLoggingBasic,
    KMSLoggingDetail
};


/**

 A server which runs locally and "pretends" to be something else.

 You provide the server with an optional port to run on, and a list of responses.

 The responses consist of an array of arrays, in this format:
 pattern, command, command...

 The pattern is a regular expression which is matched against input received by the server.
 The commands are instances of KMSCommand, which are performed when
 the pattern has been matched.

 See the [documentation](http://karelia.github.com/MockServer/Documentation/).

 See also the KMSTests.m file for some examples.

 */

@interface KMSServer : NSObject

/**
 This data will automatically be sent when something connects to the passive data connection.
 */

@property (strong, nonatomic) NSData* data;

/** 
 The port that the server is running on.
 */

@property (readonly, nonatomic) NSUInteger port;

@property (assign, nonatomic) dispatch_queue_t queue;

/**
 YES if the server is running. NO if the stop method has been called.
 */

@property (readonly, atomic, getter = isRunning) BOOL running;

/**
 Current state of the server. 
 Will be KMSReady until started, KMSRunning whilst running, KMSPauseRequested when pause is called, and KMSPaused after runUntilPaused returns.
 */

@property (assign, atomic) KMSState state;

/**
 Responder object that reacts to input.
 */

@property (strong, nonatomic) KMSResponder* responder;

/**
 Transcript of all data sent and received, and all commands processed.
 */

@property (strong, nonatomic) NSMutableArray* transcript;




/** 
 Make a server that uses the given responder object to reply to incoming requests.
 The server will listen on an automatically allocated port.
 
 @param responder An object that replies to incoming requests.
 @return A new auto-released server instance.
 */

+ (KMSServer*)serverWithResponder:(KMSResponder*)responder;

/**
 Make a server that uses the given responder object to reply to incoming requests, and listens on a given port.

 @note The system doesn't always free up ports instantly, so if you run multiple tests on a fixed port in quick succession you may find that the server fails to bind.

 @param port The port to listen on.
 @param responder An object that replies to incoming requests.
 @return A new auto-released server instance.
 */

+ (KMSServer*)serverWithPort:(NSUInteger)port responder:(KMSResponder*)responder;

/**
 The logging level to use.
 
 This is a global setting which determines how much logging MockServer spits out.
 The default is KMSLoggingOff.
 
 @return The current logging level.
 */

+ (KMSLogLevel)loggingLevel;

/**
 Set the logging level to use.

 This is a global setting which determines how much logging MockServer spits out.
 The default is KMSLoggingOff.

 @param level The new logging level.
 */

+ (void)setLoggingLevel:(KMSLogLevel)level;

/**
 Initialise with a given set of responses, listening on a given port.

 @note The system doesn't always free up ports instantly, so if you run multiple tests on a fixed port in quick succession you may find that the server fails to bind.

 @param port The port to listen on.
 @param responder An object that replies to incoming requests.
 @return A new server instance.
 */

- (id)initWithPort:(NSUInteger)port responder:(KMSResponder*)responder;

/**
 Start the server.
 */

- (void)start;

/**
 Temporarily stop the server.
 This causes <runUntilPaused> to return.
 It doesn't actually do anything to the server other than
 change its state variable - the underlying networking code
 will actually still be running.
 
 To perform another test, call <resume> (to reset the server
 state), and you can then call <runUntilPaused> again.
 */

- (void)pause;

/**
 Continue again after calling <runUntilPaused>/<pause>.
 This doesn't actually do anything to underlying networking
 code, which will still be running, but it resets the server's
 state variable in preparation for another set of calls to
 <runUntilPaused>/<pause>.
 */

- (void)resume;

/**
 Stop the server.
 This causes <runUntilPaused> to return.
 The listeners will be shut down at this point, so only
 call this when you are done with the server.
 */

- (void)stop;

/**
 Loop in the current run loop until something calls pause or stop on the server.
 
 Typically you start the server, initiate the network operation that you want
 to test, then call runUntilPaused in your test case.

 In a completion block or delegate method of your network operation, you 
 can then call <stop> on the server (or <pause> if you want to continue with
 more operations), at which point this method will return, and your test case
 will resume executing.
 
 */

- (void)runUntilPaused;


/**
 Returns a standard set of variable substitutions.
 
 @note needs more explanation
 */

- (NSDictionary*)standardSubstitutions;

/**
 Called by a connection when it closes.
 
 *Not intended to be called by user code.*
 
 @param connection The connection that closed.
 */

- (void)connectionDidClose:(KMSConnection*)connection;

/**
 Called by a connection to check the current queue.
 
 *Not intended to be called by user code.*
 */

- (BOOL)currentQueueTargetsServerQueue;

@end

/**
 When the server encounters this as an output item,
 it writes back the contents of its data property.
 */

extern NSString *const DataCommandToken;

/**
 When the server encounters this as an output item,
 it closes the connection.
 */

extern NSString *const CloseCommandToken;

/**
 The server interprets a response with this pattern specially.
 When the connection is first opened, the data associated
 with this key is immediately sent back.
 */

extern NSString *const InitialResponsePattern;

extern NSString *const ListenerRunMode;
extern NSString *const InputRunMode;
extern NSString *const OutputRunMode;
