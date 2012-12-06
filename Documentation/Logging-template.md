MockServer has some internal logging, which can be useful when you're trying to work out what's going on.

The code uses two macros: KMSLog, and KMSLogDetail.

By default, these are both defined to work like NSLog, but you can override this behaviour by including `#define` definitions of them in your prefix file.


## Disabling Logging

For example, to turn off the detailed logging, add this to your .pch file (before it imports KMSServer.h):

    #define KMSLogDetail(...)   do { } while(0)
    
To turn off all logging, also add this:


    #define KMSLog(...)         do { } while(0)


## Redirecting Logging

You can also use this technique to redirect the logging elsewhere, or to prefix it.

Here's an example which prefixes each log output with "MockServer: ".


    #define KMSLog(...) do { NSString* s = [NSString stringWithFormat:__VA_ARGS__]; NSLog(@"MockServer: %@", s); } while (0)
    
    #define KMSLogDetail KMSLog
