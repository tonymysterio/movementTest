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

//initialize these at appdelegate or they wont exist
let storage = MainStorageForObjects()
let messageQueue = MessageQueue(storage: storage)
let scheduler = Scheduler( storage: storage ,messageQueue : messageQueue );

let runRecorderJunct = runRecorderJunction() //listens to run recording requests
let runDataIO = runDataIOJunction() //pulling sending run dataaz
let prefSignalJunction = preferenceSignalJunction()
let mapJunction = mapViewJunction()
let packetExchange = PacketExchangeJunction()
let serviceStatus = serviceStatusJunction()
let playerRoster = PlayerRoster();

var SchedulerAgentGroups = schedulerAgentGroups();



struct notificationMeiwaku {
    
    let title : String
    let subtitle : String
    let body : String
    let sound : Bool
    let vibrate : Bool
}

//dont put observers here, put them with each producer


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

//peerDataProvider needs a list of hashes
struct orderedHashList : Codable {
    let list: [String]
}

struct exchangedHashes {
    
    //peer data provider keeps track of what whas sent to which user
    //this data gets purged when peerDataProvider TTL's
    var list : [String: storedHashes];
    //list : [String: storedHashes] = [:]
    init(){
        
        list  = [:]
    }
    
    mutating func merge ( hashes : exchangedHashes ) {
        
        //getting a bulk of hashes user : hash
        if hashes.list.count == 0 { return; }
        for (key , i) in hashes.list {
            
            for ii in i.list {
                
                self.insertForUser(user: key, hash: ii )
                
            }
            
            
        }
        
    }
    
    func missingFromMe ( hashes : orderedHashList ) -> orderedHashList? {
        
        if list.isEmpty { return hashes }
        //turn ohl into set
        
        var all = Set<String>()
        for f in self.list {
            
            for ff in f.value.list {
                all.insert(ff)
            }
            
        }
        
        var missing  = [String]() //orderedHashList();
        
        for i in hashes.list {
            if !all.contains(i) {
                missing.append(i)
            }
        }
        
        if missing.isEmpty { return nil }
        
        return orderedHashList(list : missing);
        
    }
    
    
    mutating func addMockItemToGetPullingFromTarget (){
        
        self.insertForUser(user: "mock", hash:"mock")
        
    }
    
    mutating func insertForUser ( user : String , hash : String ) -> Bool {
        
        if list[user] == nil {
            list[user] = storedHashes(list: [hash])
            return true
        }
        list[user]!.list.insert(hash)
        
        return true
    
    }
    
    func isEmpty () -> Bool {
        
        if self.list.isEmpty { return true }
        return false
        
    }
    
    func getAll () -> Set<String>? {
     
        if self.isEmpty() { return nil }
        var all = Set<String>()
        for f in self.list {
            
            for ff in f.value.list {
                all.insert(ff)
            }
            
        }
        
        return all;
        
    }
    
    func orderAllLatestFirst () -> orderedHashList? {
        
        if self.isEmpty() { return nil }
        let all = self.getAll()
        var ord = Set<String>()
        while ord.count < all!.count {
            
            for f in self.list {
                
                for ff in f.value.list {
                    
                    if !ord.contains(ff) {
                        ord.insert(ff)
                        break;
                    }
                    
                }   //loop all hashes
                
            } //loop all keys
            
        } //fill ord evenly with old crap
        let r = ord.reversed()
        let ohl = orderedHashList(list:r)
        
        return ohl   //
        
    }
    
    func doIhaveHash ( hash : String ) -> Bool {
        
        //just dig thru everything and fish out if we have da hash
        
        for f in self.list {
            
            for ff in f.value.list {
                if ff == hash {
                    return true;
                }
            }
            
        }
        
        return false;
        
    }
    
    func findUnique ( users: [String]? ) -> Set<String>? {
        
        //whoever might be talking to us now
        //naturally arrages to oldest first?
        
        return nil
    }
    
    func findMissingFromMe ( user: String ) -> Set<String>? {
        
        let mine = list[user] //can be nil
        let notMine = list.filter { $0.key != user } //everyone but me
        if notMine == nil { return nil }    //nobody around
    
        var prevSet = Set<String>()
        for i in notMine {
            
            //prevSet.union(notMine[i.value])    //grab common
        
        }
        
        //request from the end of the list
        //when new runs arrive and are accepted, there will be a new instance of this object to scan
        
        return prevSet
        
    }
    
    func findMissingFromUser ( me : String , user : String ) {
        
        //i may have something this user wants
        //return latest first
        
    }
    
    func findLatestExcluding ( excludedHashes : Set<String> ) -> Set<String>? {
        
        //so we got a list of hashes we dont need
        //see if we have something after excluding these
        
        return nil
        
    }
    
}

struct storedHashes {
    
    var list : Set<String>
    
}

struct locationMessage  {
    
    
    let timestamp : Double
    let lat : CLLocationDegrees //attached message as dictionary
    let lon : CLLocationDegrees //attached message as dictionary
    
    
}  //targetID, senderID, Dictionary that is the message


enum liveConfigurationTypes: String {
    
    case maxCategoryObjects = "maxCategoryObjects" //string out of enums!
    case maxListeners = "maxListeners"
    case maxObjects = "maxObjects"
    static func allValues() -> [liveConfigurationTypes] {
        return [.maxCategoryObjects, .maxListeners , .maxObjects ]
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
    case lowBattery //not going to do it with low battery
    
    case lowDiskspace   //motherObj told me I dont have diskspace for you picture
    case busyProcessesing   //crunching thru a number set now, dont bother me now
    case persisting //im not going to sleep even on background, fuck off
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
    case hibernating
    case wokeUpFromHibernation
    case readyImmediately   //something that relies on the cache is ready to its thing
    //file access related
    case fileNotFound
    case fileWriteFailed
    case duplicateSavedData  //trying to save same data twice
    
}

enum distressCodes {
    
    //when these things happen, trust scheduler to call appropriate hook on object immediately
    //instead of listening trough observable
    //terminate outgoing JSON requests when net is lost
    //as a rule, all outgoing requests should be triggered thru user interaction. refresh map etc
    
    case networkLost    //no WLAN, no CELL
    case lowPowerWarning    //
    case goingBackground    //
    
}

//wrap in class to pass it as a pointer

struct mapSnapshot {
    
    let coordinates : [[CLLocationCoordinate2D]]
    let filteringMode : mapFilteringMode //throw everything in as default
    let lat : CLLocationDegrees
    let lon : CLLocationDegrees
    let getWithinArea : Double
    let hashes : Set<String>   //contains also hashes of things not accepted on the snap
    var dirty : Bool;
    let id : String;
    
    mutating func setDirty (){
        
        dirty = true;
        
    }
    
}

class MainStorageForObjects {
    
    var queue = DispatchQueue(label: "MainStorageForObjectsQueue")
    var objects = [ String : BaseObject]();
    func addObject(label: String, object: BaseObject) -> Void {
        queue.sync {
            print ("MainStorageForObjects added \(label) under MainStorageForObjectsQueue");
            self.objects[label] = object
        }
    }
    
    func getObjectsByName( name : String ) -> [String]? {
        
        //return a collection of objects belonging to specific category, like, get all
        //motionlisteners to talk to them
        if self.objects.isEmpty { return nil }
        
        var ns = [String]()
        for a in self.objects {
            
            if (a.value.name == name) {
                
                ns.append(a.value.myID)
                
                
            }
            
            
        }   //loop all objects
        
        if ns.isEmpty { return nil }
        
        return ns
        
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
    
    //this is for anybody overseen by scheduler
    
    func getObject(oID : String) -> BaseObject? {
        
        if let o = self.objects[oID] {
            
            if o.terminated {
                return nil
                
            }  //non supervisors dont need to see dead objects
            
            return o
        }
        
        return nil
    }
    
    //scheduler has its own direct access to objects
    
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

/*func shuffle<T>(_ array:inout [T]){
    
    var temp = [T]()
    
    for _  in array{
        
        /*Generating random number with length*/
        let random = arc4random_uniform(UInt32(array.count))
        /*Take the element from array*/
        let elementTaken = array[Int(random)]
        /*Append it to new tempArray*/
        temp.append(elementTaken)
        /*Remove the element from array*/
        array.remove(at: Int(random))
        
    }
    /* array = tempArray*/
    array = temp
}*/

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}





