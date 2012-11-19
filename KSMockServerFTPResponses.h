//
//  Created by Sam Deane on 06/11/2012.
//  Copyright 2012 Karelia Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 A collection of stock responses that can be used to fake an FTP server.
 
 These responses cover many of the typical commands that an FTP server needs to implement.
 */

@interface KSMockServerFTPResponses : NSObject

/**
 Typical response returned by an FTP server when the connection begins.
 
 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)initialResponse;

/**
 Response to a USER command, indicating that the user has been accepted.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)userOkResponse;

/**
 Response to a PASS command, indicating that the user/pass combination was ok.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)passwordOkResponse;

/**
 Response to a PASS command, indicating that the user/pass combination was bad.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)passwordBadResponse;

/**
 Response to a SYS command. Pretends to be a UNIX server.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)sysReponse;

/**
 Response to the PWD command. Pretends that the current path is '/'.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)pwdResponse;

/** 
 Response to the TYPE command. Pretends to have changed to the requested type.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)typeResponse;

/** 
 Response to the CWD command. Pretends to change directory.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)cwdResponse;

/** 
 Response to the PASV command.
 
 Returns details of the server's data listener in the correct format for an FTP client to use.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)pasvResponse;

/**
 Response to a SIZE command.
 
 Returns the size of any NSData object attached to the server's <data> property.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)sizeResponse;

/** 
 Response to a RETR command, which is used to retrieve a file.
 
 Pretends to start listening for a client connection (actually the listener is already listening), then
 pauses for a bit and finally returns an indication that the data has been sent. This is fake, as the
 sending of the data isn't synchronised with this response in any way, but the
 delay should ensure that the data actually has gone by the time the response is received.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)retrResponse;

/**
 Response to a LIST command, which is used to retrieve a directory listing.
 
 This works like the RETR response, so you should first set up the server's <data> property
 with the directory listing that you actually want to have returned.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */
 
+ (NSArray*)listResponse;

/**
 Response to a MKD command. Pretends to create the directory as requested.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)mkdResponse;

/**
 Response to a MKD command. Pretends to fail because the directory already existed.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)mkdFileExistsResponse;

/** 
 Response to a STOR command. 
 
 Much like a RETR command, except that it's pretending to upload rather than download.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)storResponse;

/** 
 Response to a DELE command. Pretends to successfully delete the file.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)deleResponse;

/**
 Response to a DELE command. Pretends to fail because the file didn't exist.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)deleFileDoesntExistResponse;

/**
 Response to an unknown command. Sends back the correct 500 response code, along with the command.

 @return Array containing the regexp pattern to match against, and a list of commands that will be sent back to the client.
 */

+ (NSArray*)commandNotUnderstoodResponse;

/**
 Returns an array of many of the above responses, which can be passed directly to <KSMockServerRegExResponder responderWithResponses:>.
 
 It includes all of the "good" responses.

 @return Array of response arrays.
 */

+ (NSArray*)standardResponses;

/**
 Returns an array of many of the above responses, which can be passed directly to <KSMockServerRegExResponder responderWithResponses:>.

 It includes responses that fake the server refusing to accept the given user credentials.

 @return Array of response arrays.
 */

+ (NSArray*)badLoginResponses;

@end
