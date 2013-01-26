The <KMSRegExResponder> expects an array containing responses.

You can either create this array in code, or you can use the <KMSResponseCollection> class to load the responses from a JSON file.

Defining Responses Using JSON
-----------------------------

JSON is chose here in preference to the plist format, as it allows the embedding of \r and \n. Server protocols are often very sensitive to things like the exact format of end of line separators - expecting CR/LF pairs for example - so being able to embed explicit line feeds and carriage returns is helpful.

The format of the JSON files is illustrated by this example:

    {
        "sets":
        {
            "default": {
                "responses": [ "initial", "response1", "response2" ],
            },

            "bad pass": {
                "responses": [ "initial", "response1", "response3" ],
            },

        },

        "responses":
        {
            "initial" : {
                "pattern" : "«initial»",
                "commands" : [
                              "220 $address FTP server ($server) ready.\r\n"
                              ]
            },

            "response1" : {
                "pattern" : "USER (\\w+)",
                "commands" : [
                              "331 User $1 accepted, provide password.\r\n"
                              ],
                "comment" : "Response to a USER command, indicating that the user has been accepted."

            },

            "response2" : {
                "pattern" : "PASS (\\w+)",
                "commands" : [
                              "230 User user logged in.\r\n"
                              ],
                "comment" : "Response to a PASS command, indicating that the user/pass combination was ok."
            },

            "response3" : {
                "pattern" : "PASS (\\w+)",
                "commands" : [
                              "530 Login incorrect.\r\n"
                              ],
                "comment" : "Response to a PASS command, indicating that the user/pass combination was bad."
            }
    }


In this case we give responses for the USER/PASS handshake for an ftp server.

We define two "sets". The default one gives the response that you'd expect if the USER/PASS values were correct. The "bad pass" one gives the response you'd expect if the given credentials were incorrect.

There are currently three special values that can be used in the responses.

The pattern: "«initial»" is used to define a response that will always be sent immediately when the connection starts.

A response of "«close»" is not sent back to the client. Instead it is interpreted as an instruction to close the connection.

A response of "«data»" causes the value of the <[KMSServer data]> property to be sent back to the client.



Defining Responses In Code
--------------------------

To define responses in code, you simply need to make an array of arrays.

Each of the inner arrays is in this format:

    @[pattern, command, command...]

When defining responses in code, commands should generally be supplied as subclasses of the KMSCommand class. 

However, to support loading data from text files, instances of NSData, NSString or NSNumber are also accepted directly, and
are converted into the appropriate KMSCommand subclass.

- NSData objects become <KMSSendDataCommand> instances.
- NSNumber objects become <KMSPauseCommand> instances.
- NSString objects generally become <KMSSendStringCommand> instances.

There are a couple of special constants that you can use when defining your responses.

The pattern **InitialResponseKey** is used to define a response that will always be sent immediately when the connection starts.

A response of **DataCommand** becomes a <KMSSendServerDataCommand> instance. This is interpreted as an instruction to send back the value of the [KMSServer data] property.

A response of **CloseCommand** becomes a <KMSCloseCommand> instance. This is interpreted as an instruction to close the connection.

Once you have your array of arrays, simple call <[KMSRegExResponder responderWithResponses:]> passing it in.
