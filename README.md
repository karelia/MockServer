Mock Server
===========

A server which runs locally and "pretends" to be something else.

You provide the server with an optional port to run on, and a list of responses.

The responses consist of an array of arrays. Each of the inner arrays is in this format:

    @[pattern, command, command...]

The pattern is a regular expression which is matched against input received by the server.
The commands are NSString, NSData, or NSNumber objects, which are processed when
the pattern has been matched.

NSData objects are sent back directly as output.
NSString objects are also sent back, except for the constant CloseCommand string, which closes the connection instead.
NSNumber objects are interpreted as times, in seconds, to pause before sending back further output.

The server includes a facilty for loading these response arrays easily from a JSON file.

## Ports

If you give the server no port, it is assigned one at random. You can discover this using the <[KMSServer port]> property, so that
you can pass it on to the test code that will be making a connection.

This is generally preferrable to setting a fixed port, as the system doesn't always free up ports instantly, so if you
run multiple tests on a fixed port in quick succession you may find that the server fails to bind.

## Data Transfers

As well as listening on it's assigned port, the server listens on a second port which can be used to fake FTP
passive data connections.

Any connection on this port will cause the contents of the <[KMSServer data]> property to be sent back, followed by
the connection closing.

## Substitions

There is a subsitituion system which allows the output that is sent back to vary somewhat based on context.
You can use variables `$0`, `$1`, `$2` etc in a response, to refer to parts of the pattern that was matched against.

Other substitutions that are currently implemented:

    $address     the IP address of the server; should be 127.0.0.1
    $server      a fake name for the server, to return (eg in FTP responses)
    $pasv        the IP address and port number of the data connection, in FTP format (eg 127,0,0,1,120,12)
    $size        the size of the server's data property
    $date        the current date & time in RFC1123 format

## For More Information

See the [documentation](http://karelia.github.com/MockServer/Documentation/).

See also the KMSTests.m file for some examples of usage, and the ftp.json and webdav.json files for examples of responses.