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

// This is the function which all Perfect Server modules must expose.
// The system will load the module and call this function.
// In here, register any handlers or perform any one-time tasks.
public func PerfectServerModuleInit() {
	
	// Initialize the routing system
	Routing.Handler.registerGlobally()
	
	// Add a default route which lets us serve the static index.html file
	Routing.Routes["*"] = { _ in return StaticFileHandler() }
    
    // Register a route for  posts for register
    
        Routing.Routes["POST", "/register"] = { _ in
    
            return RegistrationHandler()
        }
    
    // Register a route for  posts for Login
    
    Routing.Routes["POST", "/login"] = { _ in
        
        return  LoginHandler()
        
    }
    
    
  // Schema and sql connection creation
    
    let status = Transactions.sqlDBconfig()
    
    guard status.result else {
        
        return
        
    }
    
}

/* new user registartion */

class RegistrationHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        
         let reqData = request.postBodyString
         var statusMessage = "success"
    
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
                    statusMessage = "failed"
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
                let respString = try jsonEncoder.encode(["status": statusMessage])
                
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


/* authentication handler */

class LoginHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        do {
            
            var statusMessage = "success"
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
                        statusMessage = "failure"
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
                let respString = try jsonEncoder.encode(["status": statusMessage])
                
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

