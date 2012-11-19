This document describes at a high level the design of the Mock Server system.

The intention is to provide a proxy object that can run on the local machine and stand in for a server.

This allows us to write unit tests that expect to run against a particular kind of server, without them actually needing a proper internet connection.

Because the stand-in servers are actually faked, it also allows us to script particular situations, such as the server rejecting credentials sent to it. This is a real help when testing alternate paths through networking code, particular with regard to error handling.



Key Classes
-----------

Essentially the design revolves around the interation of four classes: <KSMockServer>, <KSMockServerConnection>, <KSMockServerListener>, and a subclass of <KSMockServerResponder>.

The <KSMockServer> is the focus and holds references to all the other objects. By default it is also the only object that user code interacts with directly, other than creating and passing in a <KSMockServerResponder> instance for it to use.


Listening For Connections
-------------------------

When started, the server creates two <KSMockServerListener> objects.

One of these is the "main" listener, and uses the port that was specified when the server object was created.

The second of these is a "data" listener, which is used to simulate data connections (eg a passive connection for FTP). This always uses a system assigned port.


Connecting To The Main Port
---------------------------

When a connection is made on the main socket, the server creates a <KSMockServerConnection> object to service it, and associates a <KSMockServerResponder> object with the connection.

A normal server would spawn a connection and keep listening for additional connections on the same port, on the assumption that simultaneous requests could come in from multiple clients.

The <KSMockServer> currently assumes that it's only going to be used by unit tests, and as such that it's only going to receive a single connection. This is only for the sake of simplicity - it isn't an inherent part of the design and it would be easy enough to expand the implementation to allow simultaneous connections if required.

The <KSMockServerConnection> object really just lives in a loop, reading input from the stream that it's associated with, passing it to the <KSMockServerResponder> object, and acting on the commands that it gets back (generally by sending back data).

Responding To Requests
----------------------

When a <KSMockServerConnection> receives input, it passes the input to its associated <KSMockServerResponder> object.

The role of the responder object is to process input, and return a list of "commands" to execute.

<KSMockServerResponder> is an abstract class. Currently there is a single implementation - <KSMockServerRegExResponder>.

This class uses pattern matching to select one from a series of pre-baked responses. It is given a list of patterns, and works through them in order until one matches.

It then returns the list of "commands" associated with that pattern.

These commands currently consist of NSString, NSData, or NSNumber objects.

- NSData objects are sent back directly as output.
- NSString objects are also sent back, except for the constant CloseCommand string, which closes the connection instead.
- NSNumber objects are interpreted as times, in seconds, to pause before sending back further output.

The class also performs text substitutions on the NSString items that it returns. This allows you to add a certain amount of dynamism to the responses that are returned.

A <KSMockServerResponder> also has an <initialResponse> property. The list of commands associated with this property is returned automatically by the associated <KSMockServerConnection> when a connection first starts. 

Setting this property is essential for faking any protocol that starts by sending something back to the client. For example, an FTP server typically starts by sending something like this: "220 10.1.1.23 FTP server (ACME FTP Server v1.1) ready.\r\n".


Passive Data Requests
---------------------

Some protocols require the use of additional data connections - for example FTP data downloads/uploads in passive mode use a second port that the server listens on. The server passes the details of this port back to the client on the main connection, and the client then connects to the second port to perform the data transfer.

To support this, the server also listens on a second port, and the <KSMockServerRegExResponder> includes some text substutions which allow the port details to be returned in the correct FTP format (if necessary we can add other substititions to support other protocols).

In a real ftp server, a listener on this second connection would be created dynamically in response to incoming commands, and in theory many listeners could exist at once serving multiple connections.

As with the KSMockServer only supporting a single connection on the main port, we also simplify the handling of data connections by only supporting a single data listener, and by setting it up once when the server starts. The assumption here is that a test will only need one of these connections at any one time.

Currently, when a connection is received on this port, the server immediately sends back the contents of its data property, and then closes the connection. Internally the server uses a second <KSMockServerRegExResponder>, attached to a <KSMockServerConnection>, to achieve this.

This behaviour is sufficient to simulate an FTP data download, but may not be adequate for other server protocols that we wish to support. As such, this area may require additional work in the future.


Setting Up Responder Responses
------------------------------

The current unit test examples set up the table of responder patterns and commands in code.

In theory, there's no reason why this table couldn't be loaded from a data file instead, and for complex examples this may well be preferrable.

The only complication with this is that server protocols are often very sensitive to things like the exact format of end of line separators - expecting CR/LF pairs for example.

If you load in the patterns and responses from a file, you need to ensure that the loading mechanism deals with this adequately and doesn't end up processing away some of these separators.


