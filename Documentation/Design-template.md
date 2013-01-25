This document describes at a high level the design of the Mock Server system.

The intention is to provide a proxy object that can run on the local machine and stand in for a server.

This allows us to write unit tests that expect to run against a particular kind of server, without them actually needing a proper internet connection.

Because the stand-in servers are actually faked, it also allows us to script particular situations, such as the server rejecting credentials sent to it. This is a real help when testing alternate paths through networking code, particular with regard to error handling.



Key Classes
-----------

Essentially the design revolves around the interation of these classes: <KMSServer>, <KMSCommand>, <KMSConnection>, <KMSListener>, <KMSResponseCollection> and a subclass of <KMSResponder>.

The <KMSServer> is the focus and holds references to all the other objects. 

The abstract <KMSResponder> class is responsible for the actual behaviour of the server. We currently provide one concrete subclass of this - <KMSRegExResponder> - which works by pattern matching. You'll can create one of these to pass to the <KMSServer> object, or you can use the <KMSResponseCollection> class to generate them from a JSON file defining their contents.

The internal <KMSConnection> and <KMSListener> classes are responsible for implementing the networking. Their function is mentioned below, but you shouldn't need to deal with them directly.

Instances of <KMSCommand> represent actions to perform on the connection in response to incoming data. Typically these do things like sending back data, pausing, or closing the connection.

Listening For Connections
-------------------------

When started, the server creates two <KMSListener> objects.

One of these is the "main" listener, and uses the port that was specified when the server object was created.

The second of these is a "data" listener, which is used to simulate data connections (eg a passive connection for FTP). This always uses a system assigned port. See "Passive Data Requests" below for more about this listener.


Connecting To The Main Port
---------------------------

When a connection is made on the main socket, the server creates a <KMSConnection> object to service it, and associates a <KMSResponder> object with the connection.

In general with unit tests it should only really be dealing with a single connection at a time. However, there are situations such as the HTTP authentication handshake where a response on the first connection can cause it to close and a second connection attempt be made. In these situations the second connection may occur before the first has completely finished closing.

For this reason, the server can accept multiple simultaneous connections. It just spawns a new <KMSConnection> for each one, using the same responder object.

Each <KMSConnection> object lives on the current run loop, reading input from the stream that it's associated with, passing it to the <KMSResponder> object, and acting on the commands that it gets back (generally by sending back data). When it is closed (externally, or in response to a close command), it tells the server, which then releases it.

Responding To Requests
----------------------

When a <KMSConnection> receives input, it passes the input to its associated <KMSResponder> object.

The role of the responder object is to process input, and return a list of <KMSCommand> objects to execute.

<KMSResponder> is an abstract class. Currently there is a single implementation - <KMSRegExResponder>.

This class uses pattern matching to select one from a series of pre-baked responses. It is given a list of patterns, and works through them in order until one matches.

It then returns the list of commands associated with that pattern.

See the documentation for <KMSCommand> and its subclasses for a list of the built-in commands that can be returned.

Before returning the command list, substitutions are performed on any that are text-based. This allows you to add a certain amount of dynamism to the responses that are returned, by substituting in things like the address of the server, the current time, and so on. This is sufficient to mimic the behaviour of a lot of servers. For more complex cases, custom command subclasses can be written, which are free to produce completely dynamic responses based on the current state of the responder, connection and server.

A <KMSResponder> also has an <initialResponse> property. The list of commands associated with this property is returned automatically by the associated <KMSConnection> when a connection first starts. 

Setting this property is essential for faking any protocol that starts by sending something back to the client. For example, an FTP server typically starts by sending something like this: "220 10.1.1.23 FTP server (ACME FTP Server v1.1) ready.\r\n".

To make life easier, the <KMSResponseCollection> class allows you to create <KMSRegExResponder> objects by loading the response data from disk. See the ftp.json, webdav.json and http.json files for examples of the file format.

Passive Data Requests
---------------------

Some protocols require the use of additional data connections - for example FTP data downloads/uploads in passive mode use a second port that the server listens on. The server passes the details of this port back to the client on the main connection, and the client then connects to the second port to perform the data transfer.

To support this, the server also listens on a second port, and the <KMSRegExResponder> includes some text substutions which allow the port details to be returned in the correct FTP format (if necessary we can add other substititions to support other protocols).

In a real ftp server, a listener on this second connection would be created dynamically in response to incoming commands, and in theory many listeners could exist at once serving multiple connections.

In our case we simplify the handling of data connections by only supporting a single data listener, and by setting it up once when the server starts. The assumption here is that a test will only need one of these connections at any one time.

Currently, when a connection is received on this port, the server immediately sends back the contents of its data property, and then closes the connection. Internally the server uses a second <KMSRegExResponder>, attached to a <KMSConnection>, to achieve this.

This behaviour is sufficient to simulate an FTP data download, but may not be adequate for other server protocols that we wish to support. As such, this area may require additional work in the future.


Setting Up Responder Responses
------------------------------

Some of the unit test examples set up the table of responder patterns and commands in code. Others use the <KMSResponseCollection> class to load the responses from a JSON file.

See the <Responses> guide for more information on how to do this using either method.