//
//  PerfectHandlers.swift
//  WebSockets Server
//
//  Created by Kyle Jessup on 2016-01-06.
//  Copyright PerfectlySoft 2016. All rights reserved.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectLib
import MySQL
import Cocoa

/* MySQL */

// host where mysql server is
let HOST = "127.0.0.1"
// mysql username
let USER = "root"
// mysql root password
let PASSWORD = "Apple9916" // make your password something MUCH safer!!!
// database name
let SCHEMA = "stpn"
// table name
let DONOR_INFO = "Donors"
let NGO_INFO = "Ngos"


let DB_PATH = PerfectServer.staticPerfectServer.homeDir() + serverSQLiteDBs + "StudentDB"
// This is the function which all Perfect Server modules must expose.
// The system will load the module and call this function.
// In here, register any handlers or perform any one-time tasks.
public func PerfectServerModuleInit() {
	
	// Initialize the routing system
	Routing.Handler.registerGlobally()
	
	// Add a default route which lets us serve the static index.html file
	Routing.Routes["*"] = { _ in return StaticFileHandler() }
    
    
    // Add the endpoint for getting the student details
    
    // register a route for gettings posts for SQlite DB's
   /* Routing.Routes["GET", "/names"] = { _ in
        
        return GetNamesHandler()
    }
    
    
    Routing.Routes["GET", "/id/{id}"] = { _ in
     
        return  GetIdHandler()
        
    }*/
    
    // register a route for gettings posts for sechema in  MySQL server
    
    
        Routing.Routes["POST", "/register"] = { _ in
    
            return RegistrationHandler()
        }
    
    
    Routing.Routes["POST", "/login"] = { _ in
        
        return  LoginHandler()
        
    }
    
    /* Connecting to MySQL schema */
    
    
    let mysql = MySQL()
    
    let connection = Transactions.checkMySqlConnection(mysql)
    
    guard connection.result else {
        // verify we connected successfully
        print(connection.errormessage)
        return
    }
    
    // defering close ensure the connection is close when we're done here.
    defer {
        
        mysql.close()
    }
    
    // create DB schema if needed
    var schemaExists = mysql.selectDatabase(SCHEMA)
    if !schemaExists {
        schemaExists = mysql.query("CREATE SCHEMA \(SCHEMA) DEFAULT CHARACTER SET utf8mb4;")
    }
    
//    let tableSuccess = mysql.query("CREATE TABLE IF NOT EXISTS \(DONOR_INFO) (id INT(11) AUTO_INCREMENT, Content varchar(255), PRIMARY KEY (id))")
    
    
    let table = Transactions.createDonorInfoTable(mysql)
    
    
    guard schemaExists && table.result else {
        print(mysql.errorMessage())
        return
    }
    
    
    
}







class RegistrationHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        
         let reqData = request.postBodyString
      
    
        let jsonDecoder = JSONDecoder() // JSON decoder
        do {
            // decode(_:) returns a JSONValue, which is just an alias to Any
            // because we know the request will be a dictionary, we can just force
            // the downcast to JSONDictionaryType. In a real production web service,
            // you would include error checking here to validate the request that it is what
            // we expect. For the purpose of this tutorial, we're gonna lean
            // on the side of danger
            let json = try jsonDecoder.decode(reqData) as! JSONDictionaryType
            print("received request JSON: \(json.dictionary)")
            
               // again, error check is VERY important here
            
            let name = json.dictionary["name"] as? String
            
            let pwd = json.dictionary["pwd"] as? String

            let mobno = json.dictionary["mobno"] as? String

            let address = json.dictionary["address"] as? String

            let emailId = json.dictionary["mailid"] as? String

            
            if let name = name ,pwd = pwd , mobno = mobno , address = address , mailid = emailId {
                
             
                let query = Transactions.insertIntoDonorsTable(name, pwd: pwd, mobno: mobno, address: address, mailid: mailid)
                
                guard query.result else {
                    print(query.errormessage)
                    response.setStatus(500, message: "Server Error")
                    response.requestCompletedCallback()
                    return
                }
                
              
      
                
            }
            
            else {
                // bad request, bail out
                response.setStatus(400, message: "Bad Request")
                response.requestCompletedCallback()
                return
            }

            
            
            response.setStatus(201, message: "Created")
        } catch {
            print("error decoding json from data: \(reqData)")
            response.setStatus(400, message: "Bad Request")
        }
    
        
            do {
                // encode the random content into JSON
                let jsonEncoder = JSONEncoder()
                let respString = try jsonEncoder.encode(["content": "Successful Registration"])
                
                // write the JSON to the response body
        
        
                response.appendBodyString(respString)
                response.addHeader("Content-Type", value: "application/json")
                response.setStatus(200, message: "OK")
            } catch {
                response.setStatus(500, message: "Server Error")
            }
        
        response.requestCompletedCallback()

        
        }
        
    }


class LoginHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        do {
            let reqData = request.postBodyString
            
            
            let jsonDecoder = JSONDecoder() // JSON decoder
            do {
                // decode(_:) returns a JSONValue, which is just an alias to Any
                // because we know the request will be a dictionary, we can just force
                // the downcast to JSONDictionaryType. In a real production web service,
                // you would include error checking here to validate the request that it is what
                // we expect. For the purpose of this tutorial, we're gonna lean
                // on the side of danger
                let json = try jsonDecoder.decode(reqData) as! JSONDictionaryType
                print("received request JSON: \(json.dictionary)")
                
                // again, error check is VERY important here
                
                let emailId = json.dictionary["mailid"] as? String
                
                let pwd = json.dictionary["pwd"] as? String
                
                
                
                if let pwd = pwd , emailId = emailId {
                    
                    
                    let query = Transactions.validateUser(emailId, password: pwd)
                    
                    guard query.result else {
                        
                        print(query.errormessage)
                        response.setStatus(401, message: query.errormessage)
                        response.requestCompletedCallback()
                        return
                    }
                    
                    
                    
                    
                }
                    
                else {
                    // bad request, bail out
                    response.setStatus(400, message: "Bad Request")
                    response.requestCompletedCallback()
                    return
                }
                
                
            } catch {
                print("error decoding json from data: \(reqData)")
                response.setStatus(400, message: "Bad Request")
            }
            
            
            do {
                // encode the random content into JSON
                let jsonEncoder = JSONEncoder()
                let respString = try jsonEncoder.encode(["content": "Successful Login"])
                
                // write the JSON to the response body
                
                
                response.appendBodyString(respString)
                response.addHeader("Content-Type", value: "application/json")
                response.setStatus(200, message: "OK")
            } catch {
                response.setStatus(500, message: "Server Error")
            }
            
            response.requestCompletedCallback()
            
            
        }
        
        
        
    }
    


}


// A WebSocket service handler must impliment the `WebSocketSessionHandler` protocol.
// This protocol requires the function `handleSession(request: WebRequest, socket: WebSocket)`.
// This function will be called once the WebSocket connection has been established,
// at which point it is safe to begin reading and writing messages.
//
// The initial `WebRequest` object which instigated the session is provided for reference.
// Messages are transmitted through the provided `WebSocket` object.
// Call `WebSocket.sendStringMessage` or `WebSocket.sendBinaryMessage` to send data to the client.
// Call `WebSocket.readStringMessage` or `WebSocket.readBinaryMessage` to read data from the client.
// By default, reading will block indefinitely until a message arrives or a network error occurs.
// A read timeout can be set with `WebSocket.readTimeoutSeconds`.
// When the session is over call `WebSocket.close()`.
class EchoHandler: WebSocketSessionHandler {
	
	// The name of the super-protocol we implement.
	// This is optional, but it should match whatever the client-side WebSocket is initialized with.
	let socketProtocol: String? = "echo"
	
	// This function is called by the WebSocketHandler once the connection has been established.
	func handleSession(request: WebRequest, socket: WebSocket) {
		
		// Read a message from the client as a String.
		// Alternatively we could call `WebSocket.readBytesMessage` to get binary data from the client.
		socket.readStringMessage {
			// This callback is provided:
			//	the received data
			//	the message's op-code
			//	a boolean indicating if the message is complete (as opposed to fragmented)
			string, op, fin in
			
			// The data parameter might be nil here if either a timeout or a network error, such as the client disconnecting, occurred.
			// By default there is no timeout.
			guard let string = string else {
				// This block will be executed if, for example, the browser window is closed.
				socket.close()
				return
			}
			
			// Print some information to the console for informational purposes.
			print("Read msg: \(string) op: \(op) fin: \(fin)")
			
			// Echo the data we received back to the client.
			// Pass true for final. This will usually be the case, but WebSockets has the concept of fragmented messages.
			// For example, if one were streaming a large file such as a video, one would pass false for final.
			// This indicates to the receiver that there is more data to come in subsequent messages but that all the data is part of the same logical message.
			// In such a scenario one would pass true for final only on the last bit of the video.
			socket.sendStringMessage(string, final: true) {
				
				// This callback is called once the message has been sent.
				// Recurse to read and echo new message.
				self.handleSession(request, socket: socket)
			}
		}
	}
    
}




