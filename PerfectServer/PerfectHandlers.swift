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
    
    // register a route for gettings posts
    Routing.Routes["GET", "/names"] = { _ in
        
        return GetNamesHandler()
    }
    
    
    Routing.Routes["GET", "/id/{id}"] = { _ in
     
        return  GetIdHandler()
        
    }
    
    do {
        
        let sqlite = try SQLite(DB_PATH)
        try sqlite.execute("CREATE TABLE IF NOT EXISTS student (id INTEGER PRIMARY KEY, name STRING , course STRING)")
    } catch {
        
        print("Failure creating database at " + DB_PATH)
    }
	
	// Add the endpoint for the WebSocket example system
	Routing.Routes["GET", "/echo"] = {
		_ in
		
		// To add a WebSocket service, set the handler to WebSocketHandler.
		// Provide your closure which will return your service handler.
		return WebSocketHandler(handlerProducer: {
			(request: WebRequest, protocols: [String]) -> WebSocketSessionHandler? in
			
			// Check to make sure the client is requesting our "echo" service.
			guard protocols.contains("echo") else {
				return nil
			}
			
			// Return our service handler.
			return EchoHandler()
		})
	}
}


class GetNamesHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        do {
            
            
            let sqlite = try SQLite(DB_PATH)
            defer {
                sqlite.close()  // defer ensures we close our db connection at the end of this request
            }
            
            // query the db for a random post
            let name = "name"
            try sqlite.forEachRow("SELECT \(name) FROM student ORDER BY RANDOM()") {
                (statement: SQLiteStmt, i:Int) -> () in
                
                do {
                    let content = statement.columnText(0)
                    
                    // encode the random content into JSON
                    let jsonEncoder = JSONEncoder()
                    let respString = try jsonEncoder.encode([name: content])
                    
                    // write the JSON to the response body
                    response.appendBodyString(respString)
                    response.addHeader("Content-Type", value: "application/json")
                    response.setStatus(200, message: "OK")
                } catch {
                    response.setStatus(400, message: "Bad Request")
                }
            }
            
        } catch {
            response.setStatus(400, message: "Bad Request")
        }
        
        response.requestCompletedCallback()
    }
}


class GetIdHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        do {
            
            let urlparam = request.urlVariables
            
            guard let id = urlparam["id"] else {
                
                return
            }
            
            let sqlite = try SQLite(DB_PATH)
            defer {
                sqlite.close()  // defer ensures we close our db connection at the end of this request
            }
            
            // query the db for a random post
            let name = "name"
            try sqlite.forEachRow("SELECT name FROM student WHERE id == \(id)") {
                (statement: SQLiteStmt, i:Int) -> () in
                
                do {
                    let content = statement.columnText(0)
                    
                    // encode the random content into JSON
                    let jsonEncoder = JSONEncoder()
                    let respString = try jsonEncoder.encode([name: content])
                    
                    // write the JSON to the response body
                    response.appendBodyString(respString)
                    response.addHeader("Content-Type", value: "application/json")
                    response.setStatus(200, message: "OK")
                } catch {
                    response.setStatus(400, message: "Bad Request")
                }
            }
            
        } catch {
            response.setStatus(400, message: "Bad Request")
        }
        
        response.requestCompletedCallback()
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


