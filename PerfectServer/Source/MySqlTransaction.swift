//
//  MySqlTransaction.swift
//  PerfectServer
//
//  Created by Rajeshnath Chyarngayil Vishwanath on 20/04/16.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

import Foundation
import MySQL


/* MySQL */

// host where mysql server is
let HOST = "127.0.0.1"
// mysql username
let USER = "root"
// mysql root password
let PASSWORD = "stpn277" // make your password something MUCH safer!!!
// database name
let SCHEMA = "stpn"
// table name
let DONOR_INFO = "Donors"
let NGO_INFO = "Ngos"

let SUCCESS = "Success"

class Transactions {
    
    
    class func sqlDBconfig()->(result:Bool,message:String) {
        
        /* Connecting to MySQL schema */
        
        let mysql = MySQL()
        let connection = self.checkMySqlConnection(mysql)
        
        guard connection.result else {
            // verify we connected successfully
            print(connection.errormessage)
            
            return (false,connection.errormessage)
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
        
        let table = self.createDonorInfoTable(mysql)
        guard schemaExists && table.result else {
            
            print(mysql.errorMessage())
            
            return (false,connection.errormessage)
        }
        
        return (true,SUCCESS)
        
    }
     
    class func checkMySqlConnection(mySql:MySQL) -> (result:Bool,errormessage:String) {
        
        let result = mySql.connect(HOST, user: USER, password: PASSWORD)
        
        return (result,mySql.errorMessage())
        
    }
    
    
    class func createDonorInfoTable(mySql:MySQL)-> (result:Bool,errormessage:String) {
       
        let tableSuccess = mySql.query("CREATE  TABLE \(DONOR_INFO) (id INTEGER   AUTO_INCREMENT PRIMARY KEY NOT NULL , name VARCHAR(40), pwd blob NOT NULL, mobno VARCHAR(15), address VARCHAR(50), mailid VARCHAR(75) NOT NULL, UNIQUE KEY (mailid))")
        
        guard tableSuccess else {
            
            // query failed, report error
            print(mySql.errorMessage())
            
            return(false,mySql.errorMessage())
            
        }
        
        defer {
            
            mySql.close()
        }
        
        return(tableSuccess,SUCCESS)
    }
    
    class func validateUser(mailid:String,password:String)->(result:Bool,errormessage:String) {
        
        let mysql = MySQL()
        
        let connection = self.checkMySqlConnection(mysql)
        
        guard connection.result else {
            
            print(connection.errormessage)
            return (false,connection.errormessage)
            
        }

        
        // select the db we're using
        mysql.selectDatabase(SCHEMA)
        let querySuccess = mysql.query("SELECT pwd FROM \(DONOR_INFO) WHERE mailid='\(mailid)'")
        
        guard querySuccess else {
            // query failed, report error
            print(mysql.errorMessage())
            //        response.setStatus(500, message: "Server Error")
            //        response.requestCompletedCallback()
            
            return(false,mysql.errorMessage())
            
        }
        
        let results = mysql.storeResults()!
        var content = ""
        
         results.forEachRow { row in
                // each row is a of type MySQL.MySQL.Results.Type.Element
                // which is just a typealias for [String]
                print("fetched: \(row)")
                content = row[0] // element 0 will be Content because it was the first (and only) colum in our query
            
        }
        
        guard content == password.sha1() else {
            
            return(false,"Invalid Credentials")
        }
        
        defer {
            mysql.close()
        }
        
        return (querySuccess,SUCCESS)
        
    }
    
  class  func insertIntoDonorsTable(name:String,pwd:String,mobno:String,address:String,mailid:String) -> (result:Bool,errormessage:String) {
    
       let mysql = MySQL()
       let connection = self.checkMySqlConnection(mysql)
    
       guard connection.result else {
        
        print(connection.errormessage)

        return (false,connection.errormessage)

    }
    
    // select the db we're using
    mysql.selectDatabase(SCHEMA)
    let pwd_hash = pwd.sha1()
    let querySuccess = mysql.query("INSERT INTO \(DONOR_INFO) (name, pwd, mobno, address, mailID) VALUES ('\(name)','\(pwd_hash)','\(mobno)','\(address)','\(mailid)')")
    
    guard querySuccess else {
        // query failed, report error
        print(mysql.errorMessage())
//        response.setStatus(500, message: "Server Error")
//        response.requestCompletedCallback()
        return(false,mysql.errorMessage())
        
    }
    
    defer {
        mysql.close()
    }
        
 return (querySuccess,SUCCESS)
   
  }
    
}

extension String {
    
    func sha1() -> String {
        
        let data = self.dataUsingEncoding(NSUTF8StringEncoding)!
        var digest = [UInt8](count:Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
        
        CC_SHA1(data.bytes, CC_LONG(data.length), &digest)
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joinWithSeparator("")
    }
    
}