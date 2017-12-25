//
//  motherObject.swift
//  interStellarTest
//
//  Created by sami on 2017/07/04.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation

//mother object runs all subObjects  on background thread
//runs housekeep for everything 

//if housekeep returns false, the housekeeper has EXITED or CRASHED
//in that case delete the object

//mother object listens to date change alerts, low mem alerts, going to sleep, low power mode alerts
//low disk space alerts, 
//asks children to react to these on the next housekeep

//motherObject does not have to react on DROP messages, the object will EXIT when its TTL naturally drops to zero
//

//didReceiveMemoryWarning - when app has not enough mem
//https://github.com/ashleymills/Reachability.swift

//isReachable  (cellular)
//isReachableViaWifi
//isReachableNotReachable

//https://developer.apple.com/library/content/documentation/Performance/Conceptual/EnergyGuide-iOS/LowPowerMode.html
//lowPowerModeEnabled

//https://developer.apple.com/documentation/foundation/nsdate#//apple_ref/c/data/NSSystemClockDidChangeNotification

//static let NSSystemClockDidChange: NSNotification.Name

//gpsFound  gpsLost

enum Status: String {
    
    case generic = "generic" //string out of enums!
    case user = "user"
    case group = "group"
    
    static func allValues() -> [objectCategoryTypes] {
        return [.generic, .user, .group]
    }
}

enum schedulerDistressCodes {
    
    case networkLost    //wifi and cell gone
    case networkWifiLost  //wifi gone, cell left
    case networkFound   //cell online
    case didReceiveMemoryWarning //when memory is low
    case didReceiveStorageWarning //when storage is running out
    case NSSystemClockDidChange //react to time changes, network message timestamps adjust
    case lowPowerModeEnabled //battery low, all systems down
    case gpsFound //gps is no
    case gpsLost    //gps is no more
    
}

//scheduler DOES NOT listen to MQTT etc messages. instead it calls children and get DROP and tries to do something
//mailoop needs to oversee scheduler and kick it back to the land of the living
//mainloop needs to oversee messageQueue too 
//also schedulers can crash, should the objects stack be somewhere
//when a new scheduler is spawned, everything in object stack should call it 
//with nobody housekeeping the objects, they will just sit there forever and TTL will not go down
//maybe the scheduler will just do a housekeep round on everything on init, send a purge to all (first purge is not that serious) and not care about the results (excluding EXIT!) on the init round. caring about the results might lead to another scheduler crash. anyway the objects get one housekeep and anything thats really old has a chance to timeout and die 
//  if the scheduler crashes before it removes

class Scheduler {

    
    var maxObjects = 10;
    //the kill gaps come from baseobject
    
    //let maxLatencyWarningGap = 5.648778915405273  //if things take too long, warm , kill
    //let maxLatencyKillGap = 23.648778915405273
    
    var purgingWithHouseKeep = 0    //if motherobject is DROPping because memory pressure or
                                    //exceeding the maxobjects limit, ask children to purge stuff
    var housekeeping = false
    var interruptHousekeeping = false;  //if we get a distress signal, interrupt housekeeping, forget the timer
                                        //do what we need to do and re-establish housekeeping after that
    var relayConfigurationValueStatus = false;  //if we are relaying, ignore multiple accesses
    
    var storage: MainStorageForObjects   //weak refrence to avoid crashing
    var messageQueue : MessageQueue     //scheduler creates objects to storage. should storage hold messageQueue
    
    
    var worryAuntID = "tat";        //attach listener to worryAunt for debugging purposes
    
    let schedulingDelayinMs = 1000  //how often we fire housekeeping
    
//    private var objects: [String: BaseObject] {
//        return storage.objects
//    }
    
    init(storage: MainStorageForObjects, messageQueue : MessageQueue) {
        self.storage = storage
        self.messageQueue = messageQueue
    
    }
    
    /*func prime (storage: MainStorageForObjects, messageQueue : MessageQueue) {
        self.storage = storage
        self.messageQueue = messageQueue
        
    }*/
    
    func initHousekeep () -> Bool
    {
        //if init housekeep fails , we are in deep trouble
        return true;
        
    }
    func _housekeep () -> Bool {
        
        if (self.housekeeping == true) {
            
            //this should not happen, report a DROP error
            //this would mean motherObject is overloaded and something needs to happen
            
            initHousekeeping()  //next round of housekeeping
            return false    //try again next year
        }
        if (self.storage.objects.isEmpty) {
            
            //even if we have no housekeeping to do,
            
            
            addRandomTimewaster();
            
            
            initHousekeeping()  //next round of housekeeping
            return true;
        }
        
        housekeeping = true;
        
        //what happens if child object housekeep returns false?
        
        //delete this object, check impact on memory pressure etc immediately
        //maybe a huge object with lots of data, might help to alleviate current problem
        
        //make note of this, how many items purged
        var housekeepReplies : [DROPcategoryTypes?] = []
        //made a copy of storage objects to avoid threading issues
        let objectsCopy = storage.objects
        for ( kez , a) in objectsCopy { //just the the object
            
            if ( a == nil ) { continue; }
            
            if interruptHousekeeping==false {
                
                let result = a._housekeep();
                housekeepReplies.append(result)
                if result == DROPcategoryTypes.terminating {
                    
                    //should we remove immediately? separate psychokiller run
                    print("ALERT: Scheduler got terminating from a housekeepee \(a.name) - delete now" )
                    removeObject(oID : kez)
                }
                
                if result == DROPcategoryTypes.busyProcessingExceedingLatencyWarningGap {
                    
                    //should we remove immediately? separate psychokiller run
                    //print("ALERT: Scheduler got busyProcessingExceedingLatencyWarningGap from a housekeepee \(a.name) - " )
                    //removeObject(oID : kez)
                }
                
                if result == DROPcategoryTypes.busyProcessingExceedingLatencyKillGap {
                    
                    //should we remove immediately? separate psychokiller run
                    print("ALERT: Scheduler got busyProcessingExceedingLatencyKillGap from a housekeepee \(a.name) - delete now" )
                    removeObject(oID : kez)
                }
                
                //busyProcessing DROP is just ignored
                //let maxLatencyWarningGap = 5.648778915405273  //if things take too long, warm , kill
                //let maxLatencyKillGap = 23.648778915405273
                
                
            }
            
            //print (housekeepReplies)
            
        }   //finish housekeeping everybody
        
        //do housekeeping before any purging
        if (self.storage.totalObjectCount() > maxObjects) {
            
            purgingWithHouseKeep = purgingWithHouseKeep + 1
            _trigger_purge (backPressure: purgingWithHouseKeep) //backpressure count should affect victims willingness to purge
            //interruptHousekeeping = true    //dont add any objects now
            
        } else {
            
            purgingWithHouseKeep = 0
            //interruptHousekeeping = false
        }
        
        housekeeping = false;
        
        if (interruptHousekeeping == false ) {
            
            //initHousekeeping()  //next round of housekeeping
            
            addRandomTimewaster()
            
            
            
            
            
        }
        
        initHousekeeping()  //next round of housekeeping
        
        return false
    }   //end housekeep
    
    func addRandomTimewaster () -> DROPcategoryTypes? {
        
        
        //return DROPcategoryTypes.serviceNotAvailable
        
        //overload myseld adding more timewasters
        let oc = storage.totalObjectCount()
        let bv = maxObjects - 3
        if (oc > bv ) { return DROPcategoryTypes.maxCategoryObjectsExceeded  }
        if (maxObjects < 3 ) { return DROPcategoryTypes.serviceNotReady }
        let tp = (maxObjects-2)
        
        //var rh = randomIntFromInterval(min: oc,max: tp );
        var rh=1
        
        var cou = 0;
        while ( rh > 0 ) {
                
                //add random child to random timewasters
                var newTimeWaster = Timewaster(messageQueue: nil );
                newTimeWaster.houseKeepingRole = houseKeepingRoles.slave;
                newTimeWaster.name = "timewaster"
                //talk to worryAunt about your crashing trouble
                newTimeWaster.addListener(oCAT: objectCategoryTypes.debugger, oID: worryAuntID, name: "worryAunt")
                var oadd = self.addObject(oID: newTimeWaster.myID,o: newTimeWaster);
                if (oadd == true ){
                    //when scheduler is overloaded, it should ask children to purge
                    //make this happen in another thread?
                    
                    //overly complicated. just make this thing to overload
                    //var rez = addObject(oCAT : objectCategoryTypes.generic,  oID: newTimeWaster.myID, name: "newTimeWasterSlave");
                    
                    print("Schdeuler: added  timewaster  \(newTimeWaster.myID) ")
                } else {
                    
                    print("Schdeuler: failed adding exceeding quota ")
                    break
            }
            
            rh=rh-1
            
        }
        
                //break
                
            //}
            
            
        //}   //loop objects , silly
        return nil
        
    }
    
    func getObject (oID : String ) -> BaseObject? {
    
        return storage.objects[oID];
    
    
    }
    
    func addObject (oID : String, o : BaseObject ) -> Bool {
        
        //scheduler should adhere to the same DROP protocol as anybody else
        
        
        
            //XXcannot do this because its not thread safe
        if (self.storage.totalObjectCount() > maxObjects) {
            return false;
        }
        
        //adding object with same id is bad juju and should result in a drop
        
        o.scheduler = self  //weak reference to scheduler for future access fun! can be nil!
        o.messageQueue = self.messageQueue //copy reference to mqueue here, leave storage out of mqueue
        
        self.storage.addObject(label: oID, object: o) //objects[oID]=o;
        print ("scheduler added \(o.name) ")
        return true
        
    }
    
    func removeObject (oID : String ) -> Void {
        
        self.storage.removeObject(label: oID) //objects[oID]=o;
        
        return
        
        if (self.storage.objects[oID] != nil) { print ("removeObject \(oID)") }
        
        self.storage.objects[oID] = nil ; //good bye cruel world
    }
    
    
    func LISTENtoDistressCode ( code : schedulerDistressCodes ) -> Void {
        
        interruptHousekeeping=true;
        //loop through my objects and call their distress handlers
        
        
        
    }
    
    func _trigger_purge (backPressure : Int ) -> Void {
        
        if (self.storage.objects.isEmpty) {
            
            
            return
        }
        
        //what happens if child object housekeep returns false?
        
        //delete this object, check impact on memory pressure etc immediately
        //maybe a huge object with lots of data, might help to alleviate current problem
        
        //make note of this, how many items purged
        var remainingBackpressure = backPressure
        var cou = 0
        
        //how about flatMapping storage.objects to get rid of the nills
        
        
        for ( _ , a) in storage.objects { //just the the object
            
            if (a != nil ) {
                
                if a.terminated { continue }    //ignore the ones going out anyways
                
                //leave the best purge strategy for the object
                let relief = a._purge( backPressure: remainingBackpressure )
                //relief is the objects guesstimate how much pressure is relieved
                //this approach targets older objects earlier in the stack
                //and we are not wasting time purging too many objects at the same time
                remainingBackpressure = remainingBackpressure - relief
                cou = cou + 1
                
                if remainingBackpressure<1 {
                    
                    print("finished releasing backpressure with _purge to \(cou) objects ")
                    break }    //gtfo
            }
        }
        
    }
    
    func getCategoryObjects( oCAT : objectCategoryTypes) -> [String]? {
        
        //motiontracker might want to call this
        //when motionLogger died, it might want to push data into motionTrackers
        //get id'S of the trackers, add listeners
        
        //otherwise manually add the listeners
        
        return self.storage.getCategoryObjects( oCAT : oCAT )
        
    }
    
    func relayConfigurationValue (k : liveConfigurationTypes, v : Any? ) -> Bool {
        
        
        
        //maxListeners, maxCategoryObjects
        //updateConfigurationValue
        //these values are read only for the object so updating these should be ok any time
        
        if (self.storage.isEmpty()) {
            
            return false;
        }
        
        if (relayConfigurationValueStatus == true) {
            
            return false;   //silent drop
        }
        
        relayConfigurationValueStatus = true
        
        var updated = [String]()

        let objectsCopy = storage.objects
        for ( kez , a) in objectsCopy { //just the the object
            
            if ( a == nil ) { continue; }
            //dont care if we are terminating or whatever
            
                if ( a.updateConfigurationValue(key: k ,val: v) ){
                    
                    updated.append(kez);
                }
                
                
                //busyProcessing DROP is just ignored
            }
        
        relayConfigurationValueStatus = false
        return false;
        
    }
    
    
    func initHousekeeping () -> Void {
        
        //add jitter to scheduling?
        let jitter = randomIntFromInterval(min: 1, max: schedulingDelayinMs )
        let next = schedulingDelayinMs + jitter;
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds( next ), execute: {
            
            print("#house")
            
            // Put your code which should be executed with a delay here
            _ = self._housekeep()
            //print("finished wasting time \(self.myID) ")
        })
        
        
    }
    
    func addAfunObjectForMe ( instructions fn: () -> BaseObject? ) -> Bool {
        
        //excepts a closure closure called instructions
        if let o = fn() {
            var result = self.addObject(oID: o.myID, o: o);
            return result
        } else {
            return false
        }
        
    }
    
    func randomIntFromInterval (min : Int, max : Int) -> Int
    {
        let r = max - min + 1;
        return min + Int(arc4random_uniform(UInt32(r)))
    }

}



