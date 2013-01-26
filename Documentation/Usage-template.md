MockServer can be used in a number of different ways, but to simlpify things I've tried to make it easy to use it in what I think is the most likely scenario: as part of a suite of unit tests using the standard SenTestKit framework that ships with Xcode.

To do this, you need to make just two things:

- a responses file
- a unit test class that inherits from <KMSTestCase>.

Response file examples for ftp, http and webdav can be found in the MockServer project, and you may be able to use one of these directly.

Some example unit tests are also available, but in this document I'll take you through how you might create one from scratch.

## Imports

After making a new source file, you first need to import the MockServer headers that you need. You'll definitely need `KMSTestCase.h`, and probably also `KMSServer.h`:

    #import "KMSTestCase.h"
    #import "KMSServer.h"

## A Class And A Test

Next, you want to declare your unit test class, inheriting from <KMSTestCase>:
	
    @interface KMSCollectionTests : KMSTestCase
    
    @end
    

## Set Up Server

As a simple example, we'll just implement a single test, which performs an FTP request.

    @implementation KMSCollectionTests
	
	- (void)testFTP
	{

First, we need to set up a new mock server instance, and start it running.

Luckily KMSTestCase has a method that does all the hard work for us: <[KMSTestCase setupServerWithResponseFileNamed:]>.

This method takes the name of a response file, and sets up a MockServer instance, running on a dynamically allocated port, and using the "default" set of responses from the response file, which should be added as a resource to your unit test bundle.

We have to check the result of this call (which is a BOOL), in case anything goes wrong with the setup.

		 
		// setup a server object, using the ftp: scheme and taking
		// the "default" set of responses from the "ftp.json" file.
    	if ([self setupServerWithResponseFileNamed:@"ftp"])
    	{
			

Because we're going to fake a download, the next thing we have to do is to give the server some data to return to us when it pretends to respond to the download response.

This is the way MockServer works generally. It doesn't actually perform as a server at all in any real sense; instead, you give it the thing you want it to return, then run the real client code that sends a request to it, then check that the client code got back the thing that you asked MockServer to return.

So, to set some data to be returned, we use the <[KMSServer data]> property:

			
	        // set up the data that the server will return
	        NSString* testData = @"This is some test data";
	        self.server.data = [testData dataUsingEncoding:NSUTF8StringEncoding];
			

## Make A Request

Next, we need to make an NSURLRequest object that we're going to use in our client code to do our actual FTP request.

Because the server is using a dynamically allocated port, we can't hard code the URL into the test; we have to figure it out on the fly. We do this by grabbing the port number back from the server, grabbing the scheme from the responses collection, and building up a URL from that information.

Luckily <KMSTestCase> provides a helper method to simplify this.

In this case we're going to pretend to download a file called "test.txt" from the root of the FTP server:

	
			// setup an ftp request
			NSURL* url = [self URLForPath:@"test.txt"];
			NSURLRequest* request = [NSURLRequest requestWithURL:url];
	

## Perform The Download

Next, we want to actually peform the download. 

Because this is a unit test, the first instinct might be to do this synchronously. After all, a unit test is just one method, and we can't perform a test on what we got back until we've actually got it. For an asynchronous case we'd have to give back control to the main loop for a while until we somehow know that the request is done, and that all sounds a bit complicated.

To test in real-world conditions though, we really do want to do things asynchronously. A synchronous test at this point really isn't a good idea, since (hopefully) we aren't going to be writing synchronous downloads in our apps.

Luckily, MockServer and KMSTestCase have this covered. <KMSTestCase> has a two methods: <runUntilPaused>, and <pause>.

The first of these hands back control to the main run loop, and pumps it until something calls <pause>. If we arrange to call this in our completion handler, we can happily set up an asynchronous request, wait for it to do it's thing, and then return control to our unit test so that we can check the results.

Here's the code:

	
		__block NSString* string = nil;
		
		[NSURLConnection sendAsynchronousRequest:request 
			queue:[NSOperationQueue currentQueue] 
			completionHandler:
				^(NSURLResponse* response, NSData* data, NSError* error)
				 {
				     if (error)
				     {
				         NSLog(@"got error %@", error);
				     }
				     else
				     {
				         string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				     }
			 
				     [self pause];
				 }];
		 
		[self runUntilPaused];

## Test The Results

Finally, we can check that we got back whatever it is that we were expecting to get back.

In this case we should receive the test string that we asked MockServer to return to us:

        STAssertEqualObjects(string, testData, @"got the wrong response: %@", string);

And that, as they say, is that.

By using <KMSTestCase>, most of the setup work and all of the cleanup work is done for us, and we can just concentrate on the code that performs whatever network operation it is that we're trying to test, and then checks the results to verify that they are ok.

Clearly there's more going on under the hood of <KMSTestCase>, but most of it is just housekeeping and for a lot of situations it should be sufficient for your needs.

You can obviously use <KMSServer> directly if you need to do something more complicated - examining the source code of <KMSTestCase> should give you everything you need.