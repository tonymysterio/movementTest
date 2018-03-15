//
//  motherObject.swift
//  interStellarTest
//
//  Created by sami on 2017/07/04.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import Interstellar
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



var scheduler_hibernate_Observer = Observable<Bool>()
var scheduler_unhibernate_Observer = Observable<Bool>()


class Scheduler {

    
    var maxObjects : Int = 10;
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
    
    let schedulingDelayinMs = 3000  //how often we fire housekeeping
    
    let schedulerQueue = DispatchQueue(label: "schedulerQueue", qos: .utility)
    
    var isHibernating = false;
    
//    private var objects: [String: BaseObject] {
//        return storage.objects
//    }
    
    init(storage: MainStorageForObjects, messageQueue : MessageQueue) {
        self.storage = storage
        self.messageQueue = messageQueue
        
        scheduler_hibernate_Observer.subscribe { toggle in
            
            self._hibernate();
            
        }
        
        scheduler_hibernate_Observer.subscribe { toggle in
            
            self._unhibernate()
            
        }
        
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
    func _hibernate () -> Bool {
        
        if self.isHibernating { return false }
        if (self.storage.objects.isEmpty) {
            return false
        }
        
        print("scheduler HIBERNATING")
        
        self.isHibernating = true;
        //self.interruptHousekeeping = true //dont allow housekeeping now
        
        var hibernationReplies : [DROPcategoryTypes?] = []
        //made a copy of storage objects to avoid threading issues
        let objectsCopy = storage.objects
        
        //put everybody to sleep sleep
        for ( kez , a) in objectsCopy { //just the the object
            
                schedulerQueue.sync {
                    
                    
                    let result = a._hibernate();
                    hibernationReplies.append(result)
                    
                    if result == DROPcategoryTypes.terminating {
                        
                        //should we remove immediately? separate psychokiller run
                        print("ALERT: Scheduler got terminating putting \(a.name) to hibernation - delete now" )
                        removeObject(oID : kez)
                    }
                    
                }
            }
        
        
        return true;
    }
    
    func _unhibernate () -> Bool {
        
        if !self.isHibernating { return false }
        if (self.storage.objects.isEmpty) {
            return false
        }
        print("scheduler UNHIBERNATING")
        
        //self.interruptHousekeeping = false //allow housekeeping
        
        var hibernationReplies : [DROPcategoryTypes?] = []
        //made a copy of storage objects to avoid threading issues
        let objectsCopy = storage.objects
        
        //put everybody to sleep sleep
        for ( kez , a) in objectsCopy { //just the the object
            
            schedulerQueue.sync {
                
                
                let result = a._unhibernate();
                hibernationReplies.append(result)
                
                self.isHibernating = false;
                
                if result == DROPcategoryTypes.generic {
                    
                    //should https://github.com/petermetz/cordova-plugin-ibeacon/issues/233 remove immediately? separate psychokiller run
                    print("\(a.name) persisted trough hibernation" )
                    //removeObject(oID : kez)
                    
                }
                
                if result == DROPcategoryTypes.wokeUpFromHibernation {
                    
                    //should we remove immediately? separate psychokiller run
                    print("\(a.name) woke up from hibernation" )
                    removeObject(oID : kez)
                    
                }
                
                if result == DROPcategoryTypes.terminating {
                    
                    //should we remove immediately? separate psychokiller run
                    print("\(a.name) terminated when trying to wake up from hibernation. DELETE" )
                    removeObject(oID : kez)
                    
                }
                
                
            }
        }
        
        
        return true;
    }
    
    
    
    func _housekeep () -> Bool {
        
        //ping servicestatus junction to get new stats
        serviceStatusJunctionRefresh.update(true)
        
        if (self.housekeeping == true) {
            
            //this should not happen, report a DROP error
            //this would mean motherObject is overloaded and something needs to happen
            
            initHousekeeping()  //next round of housekeeping
            return false    //try again next year
        }
        
        
        if (self.storage.objects.isEmpty) {
            
            //even if we have no housekeeping to do,
            
            
            _ = addRandomTimewaster();
            
            
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
            
            //if ( a == nil ) { continue; }
            
            if interruptHousekeeping==false  {
                
                schedulerQueue.sync {
                    
                    if self.isHibernating {
                        
                        //check if this guy is hibernating
                        if a.isHibernating {
                            return;   //do not bother with hibernating guys
                        }
                    }
                
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
                
                }   //housekeep is a synced operation
                
            } else {
                
                break;
                //going to background interrupts housekeeping
                //manually enable it when coming back from housekeeping
                
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
            
            _ = addRandomTimewaster()
            
        }
        
        
        initHousekeeping()  //next round of housekeeping
        
        return false
    }   //end housekeep
    
    func addRandomTimewaster () -> DROPcategoryTypes? {
        
        
        return DROPcategoryTypes.serviceNotAvailable
        
        //overload myseld adding more timewasters
        let oc = storage.totalObjectCount()
        let bv = maxObjects - 3
        if (oc > bv ) { return DROPcategoryTypes.maxCategoryObjectsExceeded  }
        if (maxObjects < 3 ) { return DROPcategoryTypes.serviceNotReady }
        
        schedulerQueue.sync {
            
            
            //var rh = randomIntFromInterval(min: oc,max: tp );
            var rh=1
            while ( rh > 0 ) {
                
                //add random child to random timewasters
                let newTimeWaster = Timewaster(messageQueue: nil );
                newTimeWaster.houseKeepingRole = houseKeepingRoles.slave;
                newTimeWaster.name = "timewaster"
                //talk to worryAunt about your crashing trouble
                _ = newTimeWaster.addListener(oCAT: objectCategoryTypes.debugger, oID: worryAuntID, name: "worryAunt")
                let oadd = self.addObject(oID: newTimeWaster.myID,o: newTimeWaster);
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
        }   //synced operation
                //break
                
            //}
            
            
        //}   //loop objects , silly
        return nil
        
    }
    
    func getObject (oID : String ) -> BaseObject? {
        
        //already priviledged
        return storage.objects[oID];
    
    
    }
    
    func getAgentByType ( agentType : String ) -> BaseObject? {
        
        //simply pick the first alive agent
        
        let objectsCopy = storage.objects
        for ( kez , a) in objectsCopy {
            
            if a.schedulerAgentType?.rawValue == agentType {
                if !a.terminated {
                 
                    return a;
                    
                }
                
            }
            
        }
        
        return nil;
        
    }   //
    
    func addObject (oID : String, o : BaseObject ) -> Bool {
        
        //scheduler should adhere to the same DROP protocol as anybody else
        
        
        
            //XXcannot do this because its not thread safe
        if (self.storage.totalObjectCount() > maxObjects) {
            return false;
        }
        
        //adding object with same id is bad juju and should result in a drop
        
        o.scheduler = self  //weak reference to scheduler for future access fun! can be nil!
        o.messageQueue = self.messageQueue //copy reference to mqueue here, leave storage out of mqueue
        
        //NOTE polluting scheduler with observers is BAD JUJU
        //find a better way
        
        schedulerQueue.sync {
            self.storage.addObject(label: oID, object: o) //objects[oID]=o;
            print ("scheduler added \(o.name) ")
            debuMess(text: "scheduler added \(o.name) ")
            
            let ssi = serviceStatusItem(name: o.name, data: 0, ttl: o.TTL, active: true, isProcessing : false );
            
            DispatchQueue.global(qos: .userInitiated).async {
                serviceStatusJunctionObserver.update(ssi);
            }
            
        }
        
        return true
    }
    
    func removeObject (oID : String ) -> Void {
        
        //schedulerQueue.sync {
            self.storage.removeObject(label: oID) //objects[oID]=o;
        //}
        
    }
    
    func removeObjectsByName ( name : String ) {
        
        guard let cob = self.storage.getObjectsByName(name : name ) else {
            return
        }
        for i in cob {
            
            self.removeObject(oID: i)
            
        }
        
    }
    
    
    func applicationWillResignActive() {
        
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        //give all tasks probable TTL to survive the sleep?
        //interrupt housekeeping will not create a timer that housekeeps again
        //do that manually on appdidbecome active
        //interruptHousekeeping=true;
        self._hibernate()
    }
    
    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //interruptHousekeeping=false;
        
        self._unhibernate();
        
        self._housekeep()   //start with a housekeep of all object to make things really slow
        
    }
    
    func applicationWillTerminate() {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        interruptHousekeeping=true;
        let objectsCopy = storage.objects
        for ( kez , a) in objectsCopy {
            
            _ = a._finalize()   //anything without a finalizer (writing data to disk or so such will die
            //this will be fast, basically setting everything terminated
        }
        
        
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
        
        var purgedEnough = false;
        
        for ( _ , a) in storage.objects { //just the the object
            
            //if (a != nil ) {
                
                if a.terminated { continue }    //ignore the ones going out anyways
                
                schedulerQueue.sync {
                    
                    //leave the best purge strategy for the object
                    let relief = a._purge( backPressure: remainingBackpressure )
                    //relief is the objects guesstimate how much pressure is relieved
                    //this approach targets older objects earlier in the stack
                    //and we are not wasting time purging too many objects at the same time
                    remainingBackpressure = remainingBackpressure - relief
                    cou = cou + 1
                
                    if remainingBackpressure<1 {
                    
                        print("finished releasing backpressure with _purge to \(cou) objects ")
                        purgedEnough = true
                        
                    }    //gtfo
                    
                }   //purge is also synced operation
                
                if purgedEnough { break; }
            //}
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
            
                schedulerQueue.sync {
                    if ( a.updateConfigurationValue(key: k ,val: v) ){
                    
                        updated.append(kez);
                    }
                }
                
                //busyProcessing DROP is just ignored
            }
        
        relayConfigurationValueStatus = false
        return false;
        
    }
    
    func setMaxObjects ( maxO : Int ) {
        
        self.maxObjects = maxO
        //this should trigger purges
        
    }
    func initHousekeeping () -> Void {
        
        //add jitter to scheduling?
        var jitter = randomIntFromInterval(min: 1, max: schedulingDelayinMs )
        if self.isHibernating {
            jitter = jitter + 10000;    //hibernating does not need that many housekeeps
        }
        let next = schedulingDelayinMs + jitter;
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds( next ), execute: {
            
            print("#scheduler housekeep")
            //if we were sleeping and interrupted housekeeping
            //this gets fired and we can housekeep again
            self.interruptHousekeeping = false;
            // Put your code which should be executed with a delay here
            _ = self._housekeep()
            //print("finished wasting time \(self.myID) ")
        })
        
        
    }
    
    func addAfunObjectForMe ( instructions fn: () -> BaseObject? ) -> Bool {
        
        //excepts a closure closure called instructions
        if let o = fn() {
            let result = self.addObject(oID: o.myID, o: o);
            return result
        } else {
            return false
        }
        
    }
    
    func fetchAgent( agent : String , name: String?, success : @escaping aSuccess , error : @escaping aError) {
        
        //just fetch agent and callback when we are there
        schedulerQueue.sync {
            
            if let a = self.storage.getObject(oID: name! ) {
                
                if !a.terminated {
                    DispatchQueue.global(qos: .userInitiated).async {
                        success(a);
                    }
                    return; //got our thing
                }
            }   //got our guy
            
            DispatchQueue.global(qos: .userInitiated).async {
                error();
            }
            
            
        }   //end scheduler sync
        
    } //end fetch or create
    
    
    typealias aSuccess = ( _ agent : BaseObject ) -> Void
    typealias aError = () -> Void
    
    func fetchOrCreateAgent( agent : String , name: String?, success : @escaping aSuccess , error : @escaping aError) {
        
        schedulerQueue.sync {
            
            if let a = self.storage.getObject(oID: name! ) {
                
                if !a.terminated {
                    DispatchQueue.global(qos: .userInitiated).async {
                        success(a);
                    }
                    return; //got our thing
                }
            }   //got our guy
            
            //create our guy
            if let o = createSchedulerAgent(agent: agent) {
                
                //addObject(oID: o.myID, o: o)    //scheduler adds in scheduler queue
                self.storage.addObject(label: name!, object: o) //objects[oID]=o;
                print ("scheduler added \(agent) ")
                //debuMess(text: "scheduler added \(o.name) ")
                
                let ssi = serviceStatusItem(name: name!, data: 0, ttl: o.TTL, active: true, isProcessing : false );
                
                DispatchQueue.global(qos: .userInitiated).async {
                    serviceStatusJunctionObserver.update(ssi);
                }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    success(o);
                }
                
                return;
                
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                error();
            }

            
        }   //end scheduler sync
        
    } //end fetch or create
    
    typealias aGroupSuccess = ( _ group : [BaseObject]? ) -> Void
    typealias aGroupError = () -> Void

    func fetchOrCreateAgentGroup ( group : [String] , success : @escaping aGroupSuccess , error : @escaping aGroupError) {
        
        //a guy like start a run on runrecorder junction will find this useful
        //it returns a closure with agents on the group order
        //error, didnt happen, try again
        //TODO get this on scheduler thread
        schedulerQueue.sync {
            
        
            var ag = [BaseObject]();
            for f in group {
            
                if let g = self.getAgentByType(agentType: f) {
                
                    ag.append(g as! BaseObject);
                
                    } else {
                
                    //didnt exist, create. let the receiver to initialize and what ever
                    if let o = createSchedulerAgent(agent: f) {
                    
                        //addObject(oID: o.myID, o: o)    //scheduler adds in scheduler queue
                        self.storage.addObject(label: f, object: o) //objects[oID]=o;
                        print ("scheduler added \(f) ")
                        //debuMess(text: "scheduler added \(o.name) ")
                        
                        let ssi = serviceStatusItem(name: o.name, data: 0, ttl: o.TTL, active: true, isProcessing : false );
                        
                        DispatchQueue.global(qos: .userInitiated).async {
                            serviceStatusJunctionObserver.update(ssi);
                        }
                        
                        ag.append(o as BaseObject);
                    
                    }
                }
            
            }
        
            if ag.isEmpty {
                DispatchQueue.global(qos: .userInitiated).async {
                    error();
                }
            }
        
            //XXXreturned values are still on scheduler thread for manipulation
            //XXXmake sure the agents user their own queues for whatever
            //force the callback to use some other queue so i can carry on with whatever
            DispatchQueue.global(qos: .userInitiated).async {
                success(ag);    //return created or existing agents
            }
            
        
        }   //doing this on scheduler queue
        
    }
    
    func randomIntFromInterval (min : Int, max : Int) -> Int
    {
        let r = max - min + 1;
        return min + Int(arc4random_uniform(UInt32(r)))
    }

}



