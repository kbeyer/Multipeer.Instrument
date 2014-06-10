//
//  EventLogger.swift
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

import Foundation

let BASE_API_URL = "http://localhost:3000/"

class EventLogger{
    
    init(){
        
    }
    
    class var shared : EventLogger {
        get {
            struct Static {
                static var instance : EventLogger? = nil
                static var token : dispatch_once_t = 0
            }
            
            dispatch_once(&Static.token) { Static.instance = EventLogger() }
            
            return Static.instance!
        }
    }
    
    /*
    func log(msg: MPIMessage) {
        persist(msg)
    }
    
    func persist(message: MPIMessage) {
        if (message != nil) {
            return //validation
        }
        
        
        // serialize as JSON dictionary
        var jsonDict = MTLJSONAdapter.JSONDictionaryFromModel(message)
            
        var messagesUrl = BASE_API_URL.stringByAppendingPathComponent("messages")
        
        var request = NSMutableURLRequest(URL: messagesUrl)
        request.HTTPMethod = "POST"
            
        var jsonData = NSJSONSerialization(JSONObjectWithData:jsonDict, options:0, error:nil)
        request.HTTPBody = data;
            
        request.addValue("application/json", forHTTPHeaderField:"Content-Type")
            
        var config = NSURLSessionConfiguration.defaultSessionConfiguration()
        var urlSession = NSURLSession(configuration:config)
            
        var dataTask = urlSession.dataTaskWithRequest(request, completionHandler:
            { data, response, error in
                if (!error) {
                    var responseArray = NSJSONSerialization.JSONObjectWithData(data, options:0, error:NULL)
                    NSLog("recieved response")
                }
            })
        dataTask.resume()
    }*/
    
}