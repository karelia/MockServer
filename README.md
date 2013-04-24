Mock Server
===========

A server which runs locally and pretends to be something else.

You provide the server with an optional port to run on, and a responder object which is responsible for taking some input from the port and providing some output to send back.

The default responder class works by pattern matching the input, and takes an array of predefined responses.

The responses consist of an array of arrays. Each of the inner arrays is in this format:

    @[pattern, command, command...]

The pattern is a regular expression which is matched against input received by the server.

The commands are subclasses of <KMSCommand>. Predefined command classes are provided which send data back to the client (after performing text substitutions to customise the content), pause for a while, and close the connection. Other command classes can easily be defined to perform custom actions, such as pausing for a random time, or sending
back some dynamically generated content.

The server includes a facilty for loading these response arrays easily from a JSON file.

## Ports

If you give the server no port, it is assigned one at random. You can discover this using the <[KMSServer port]> property, so that
you can pass it on to the test code that will be making a connection.

This is generally preferrable to setting a fixed port, as the system doesn't always free up ports instantly, so if you
run multiple tests on a fixed port in quick succession you may find that the server fails to bind.

## Data Transfers

As well as listening on its assigned port, the server listens on a second port which can be used to fake FTP
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

## Requirements

MockServer expects the modern runtime, and uses the latest syntax. It doesn't use ARC yet, but really only because I haven't got round to it.

Currently I've only tested it on the Mac, but I think it should work on iOS. Let me know if you encounter any issues.

## Usage

See the <Usage> document for a quick introduction into using MockServer with unit tests.

## For More Information

See the full [documentation](http://karelia.github.com/MockServer/Documentation/) on the web (if you're reading this on the web, that link probably refers to this page!).

See MockServer's own [unit tests](https://github.com/karelia/MockServer/tree/master/UnitTests) for some examples. KMSManualTests.m and KMSCollectionTests.m illustrate usage, and the ftp.json and webdav.json files give examples of responses files.

If you find issues or have suggestions, please [report them on github](https://github.com/karelia/MockServer/issues), or [mail me](http://www.bornsleepy.com/contact).

**Note about the documentation**: The web version of this documentation was built with appledoc and the [gendoc script](https://github.com/samdeane/gendoc). 
For some reason that I haven't figured out yet, appledoc seems to get some of the index links wrong, so clicking on the MockServer link at the top-left may sometimes give you a 404 error. Sorry about that - it's a known issue which I'll try to fix!
