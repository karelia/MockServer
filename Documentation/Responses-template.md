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

There are currently two special values that can be used in the responses.

The pattern: "«initial»" is used to define a response that will always be sent immediately when the connection starts.

A response of "«close»" is not sent back to the client. Instead it is interpreted as an instruction to close the connection.



Defining Responses In Code
--------------------------

