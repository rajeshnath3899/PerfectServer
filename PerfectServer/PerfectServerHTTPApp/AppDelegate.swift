//
//  AppDelegate.swift
//  PerfectServerHTTPApp
//
//  Created by Kyle Jessup on 2015-10-25.
//	Copyright (C) 2015 PerfectlySoft, Inc.
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


import Cocoa
import PerfectLib

let KEY_SERVER_PORT = "server.port"
let KEY_SERVER_ADDRESS = "server.address"
let KEY_SERVER_ROOT = "server.root"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	static var sharedInstance: AppDelegate {
		return NSApplication.sharedApplication().delegate as! AppDelegate
	}
	
	var httpServer: HTTPServer?
	let serverDispatchQueue = dispatch_queue_create("HTTP Server Accept", DISPATCH_QUEUE_SERIAL)
	
	var serverPort: UInt16 = 8181 {
		didSet {
			NSUserDefaults.standardUserDefaults().setValue(Int(self.serverPort), forKey: KEY_SERVER_PORT)
			NSUserDefaults.standardUserDefaults().synchronize()
		}
	}
	var serverAddress: String {
        
        		didSet {
			NSUserDefaults.standardUserDefaults().setValue(self.serverAddress, forKey: KEY_SERVER_ADDRESS)
			NSUserDefaults.standardUserDefaults().synchronize()
		}
	}
	var documentRoot: String = "./webroot/" {
		didSet {
			NSUserDefaults.standardUserDefaults().setValue(self.documentRoot, forKey: KEY_SERVER_ROOT)
			NSUserDefaults.standardUserDefaults().synchronize()
		}
	}
	
	override init() {
		let r = UInt16(NSUserDefaults.standardUserDefaults().integerForKey(KEY_SERVER_PORT))
		if r == 0 {
			self.serverPort = 8181
		} else {
			self.serverPort = r
		}
		self.serverAddress = NSUserDefaults.standardUserDefaults().stringForKey(KEY_SERVER_ADDRESS) ?? "0.0.0.0"
		self.documentRoot = NSUserDefaults.standardUserDefaults().stringForKey(KEY_SERVER_ROOT) ?? "./webroot/"
	}
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		
		let ls = PerfectServer.staticPerfectServer
		ls.initializeServices()
        
        self.serverAddress = getIFAddresses()[0]

		
		do {
			try self.startServer()
		} catch {
			
		}
	}

    
    func getIFAddresses() -> [String] {
        var addresses = [String]()
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
        if getifaddrs(&ifaddr) == 0 {
            
            // For each interface ...
            for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
                let flags = Int32(ptr.memory.ifa_flags)
                var addr = ptr.memory.ifa_addr.memory
                
                // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                        
                        // Convert interface address to a human readable string:
                        var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                        if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                            if let address = String.fromCString(hostname) {
                                addresses.append(address)
                            }
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return addresses
    }    
	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
	
	@IBAction
	func startServer(sender: AnyObject) {
		do { try self.startServer() } catch {}
	}
	
	@IBAction
	func stopServer(sender: AnyObject) {
		self.stopServer()
	}
	
	func serverIsRunning() -> Bool {
		guard let s = self.httpServer else {
			return false
		}
		let tcp = NetTCP()
		defer {
			tcp.close()
		}
		
		do {
			try tcp.bind(s.serverPort, address: s.serverAddress)
			return false
		} catch {
			
		}
		return true
	}
	
	func startServer() throws {
        
        PerfectServerModuleInit()
        
		try self.startServer(serverPort, address: serverAddress, documentRoot: documentRoot)
	}
	
	func startServer(port: UInt16, address: String, documentRoot: String) throws {
        
		guard nil == self.httpServer else {
			print("Server already running")
			return
		}
		dispatch_async(self.serverDispatchQueue) { [unowned self] in
			do {
                
				try Dir(documentRoot).create()
                
                do {
                
                    if self.documentRoot == "./webroot/" {
                    
                  try self.createIndexHtmlFile()
                        
                    }
                    
                }

                catch let e {
                    print("Exception raised writing a index file \(e)")
                
                 }
                
				self.httpServer = HTTPServer(documentRoot: documentRoot)
                
                
                //make a https call
                
                
                let certificatePath = NSBundle.mainBundle().pathForResource("Certificate", ofType: "pem")
                let privateKeyPath = NSBundle.mainBundle().pathForResource("PrivateKey", ofType: "pem")
                
                try self.httpServer!.start(port, sslCert: certificatePath!, sslKey: privateKeyPath!, bindAddress: address)
                
                //make a http call
                
			//	try self.httpServer!.start(port, bindAddress: address)
                
                
                
			} catch let e {
				print("Exception in server run loop \(e) \(address):\(port)")
			}
			print("Exiting server run loop")
		}
	}

	func stopServer() {
		if let _ = self.httpServer {
			self.httpServer!.stop()
			self.httpServer = nil
		}
	}
    
    
    
   
    
    
    func createIndexHtmlFile () throws {
        
        let path = NSBundle.mainBundle().pathForResource("index", ofType: "html")
        
        let htmlContent = try? NSString(contentsOfFile: path! as String, encoding: NSUTF8StringEncoding) as String
        
        let docRoot = self.documentRoot + "index.html"
        
            if let htmContent = htmlContent {
                
                try htmContent.writeToFile(docRoot, atomically: true, encoding: NSUTF8StringEncoding)
            }
        
       
        
    }

}


