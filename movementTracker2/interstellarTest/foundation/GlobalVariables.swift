//
//  globalVariables.swift
//  interStellarTest
//
//  Created by sami on 2017/07/24.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import UIKit
import CoreData
import Interstellar
import MapKit

let storage = MainStorageForObjects()
let messageQueue = MessageQueue(storage: storage)
let scheduler = Scheduler( storage: storage ,messageQueue : messageQueue );

let runRecorder = runRecorderJunction() //listens to run recording requests
let runDataIO = runDataIOJunction() //pulling sending run dataaz

//dont put observers here, put them with each producer

//makign this into an enum means updating the base object every time a new variation is created
enum objectCategoryTypes: String {
    
    case generic = "generic" //string out of enums!
    case user = "user"
    case group = "group"
    case debugger = "debugger"
    case uniqueServiceProvider = "uniqueServiceProvider"  //can only have one of these running at any time
    //like gps logger, motion logger...
    case motionlistener = "motionlistener"  //listens to coreMotion events
    case locationlistener = "locationlistener" //listens to coreLocation events
    
    static func allValues() -> [objectCategoryTypes] {
        return [.generic, .user, .group, .debugger, .uniqueServiceProvider ,.motionlistener , .locationlistener]
    }
}


//typealias CommMessage = [ String : Any] //comm messages from other objectos

struct internalMessage  {
    
    let from : String
    let to : String
    let name : String
    let o : CommMessage //attached message as dictionary
    
}  //targetID, senderID, Dictionary that is the message

//locationLogger sends locationMessages to locationTrackers
import CoreMotion

enum CommMessage {
    case LocationMessage(type : String , oCAT : objectCategoryTypes , oID: String, timestamp : Double, lat : CLLocationDegrees, lon : CLLocationDegrees)
    
    case EXIT(type : String , reason : String, oCAT : objectCategoryTypes , oID: String, exitcode : String )
    case DROP(type : String , reason : String, oCAT : objectCategoryTypes , oID: String, dropCode : DROPcategoryTypes , latency : Double )
    case CRASH(type : String , reason : String, oCAT : objectCategoryTypes , oID: String, exitCode : String , latency : Double )
    case MotionMessage(type : String , oCAT : objectCategoryTypes , oID: String,  rotationRate : CMRotationRate, attitude : CMAttitude)
    //jsonStreamReader sends these
    case RunMessage(type : String , oCAT : objectCategoryTypes , oID: String,  run : Run )
    
    
    //case AnyKindOfMessage(userInfo: [String: Any])
}

struct locationMessage  {
    
    
    let timestamp : Double
    let lat : CLLocationDegrees //attached message as dictionary
    let lon : CLLocationDegrees //attached message as dictionary
    
    
}  //targetID, senderID, Dictionary that is the message


enum liveConfigurationTypes: String {
    
    case maxCategoryObjects = "maxCategoryObjects" //string out of enums!
    case maxListeners = "maxListeners"
    
    static func allValues() -> [liveConfigurationTypes] {
        return [.maxCategoryObjects, .maxListeners ]
    }
}


enum houseKeepingRoles {
    
    case master
    case slave
        
}


enum boResult<T> {
    case Success(T)
    case Error(NSError)
}

enum DROPcategoryTypes {
    case generic
    case maxCategoryObjectsExceeded //i cannot handle more tasks of this type, hard limit hit
    case maxListenerObjectsExceeded //trying to register too many listeners
    case lowMemory  //i cannot allocate resources for my task
    case lowDiskspace   //motherObj told me I dont have diskspace for you picture
    case busyProcessesing   //crunching thru a number set now, dont bother me now
    case busyProcessingExceedingLatencyWarningGap
    case busyProcessingExceedingLatencyKillGap
    case terminating    //dont housekeep me now, im trying to terminate
    case busyHousekeeping //somebody called me already, leave me alone
    case purging //im purging shit now, leave me alone
    case finalizing //finalizing, leave me alone
    case serviceNotReady    //gps not available, no net..
    case serviceNotAvailable //no such feature on the hpone
    case serviceNotActivated //turn gps on on your phone
    case duplicate  //anything considered duplicate data
    //dont give a DROP when terminating
}

//wrap in class to pass it as a pointer

struct mapSnapshot {
    
    let coordinates : [[CLLocationCoordinate2D]]
    let filteringMode : mapFilteringMode //throw everything in as default
    let lat : CLLocationDegrees
    let lon : CLLocationDegrees
    let getWithinArea : Double
}

class MainStorageForObjects {
    
    var queue = DispatchQueue(label: "MainStorageForObjectsQueue")
    var objects = [ String : BaseObject]();
    func addObject(label: String, object: BaseObject) -> Void {
        queue.async {
            self.objects[label] = object
        }
    }
    
    func getCategoryObjects( oCAT : objectCategoryTypes) -> [String]? {
        
        //return a collection of objects belonging to specific category, like, get all
        //motionlisteners to talk to them
        if self.objects.isEmpty { return nil }
        
        var ns = [String]()
        for a in self.objects {
            
            if (a.value.myCategory == oCAT) {
                
                ns.append(a.value.myID)
                
                
            }
            
            
        }   //loop all objects
        
        if ns.isEmpty { return nil }
        
        return ns
        
    }
    
    func removeObject(label: String) -> Void {
        queue.async {
            
            if ( self.objects[label] == nil ) {
                let t=1;
            }
            self.objects[label] = nil
            //print ("MainStorageForObjects:: removed oID \(label) ")
        }
    }
    func getObject(oID : String) -> BaseObject? {
        return self.objects[oID];
    }
    func totalObjectCount () -> Int {
        return self.objects.count
    }
    
    func isEmpty () -> Bool {
        
        return self.objects.isEmpty
    }
    
}

//EVIL SHIT. do not do this here
//everything that a viewController needs to listen is an observable here
//baseObject talk to these hooks to communicate with UI items

import CoreLocation
var myCurrentGpsLocation = Observable<CLLocation>()



//spring cleaning
extension String {
    var unescaped: String {
        let entities = ["\0": "\\0",
                        "\t": "\\t",
                        "\n": "\\n",
                        "\r": "\\r",
                        "\"": "\\\"",
                        "\'": "\\'",
                        ]
        
        return entities
            .reduce(self) { (string, entity) in
                string.replacingOccurrences(of: entity.value, with: entity.key)
            }
            .replacingOccurrences(of: "\\\\(?!\\\\)", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}



