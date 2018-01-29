//
//  MotionLogger.swift
//  interStellarTest
//
//  Created by sami on 2017/07/13.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import CoreMotion
import Interstellar
//
//  timewaster.swift
//  interStellarTest
//
//  Created by sami on 2017/07/04.
//  Copyright © 2017年 pancristal. All rights reserved.
//

//worrier wont send messages
struct motionMessage  {
    
    let from : String
    let to : String
    let o : CommMessage //attached message as dictionary
    
}  //targetID, senderID, Dictionary that is the message

//when logging starts, data starts to accumulate to loggerData
//the accumulation automatically stops when gps etc sensor is off
//setting is paused is for manual pausing of data recording

//DO NOT log data here. just pass it to any listeners i might have
//listeners will deal with the data any way they please
//listeners will finalize when idle for too long or whatever

//when adding motionLogger (unique), look for any listeners (category motionlistener) and plug them to this location logger with addlistener. listeners dont talk back to logger

class MotionLogger : BaseObject {
    
    var isLogging = false;
    var isPaused = false;   //gps off, something that is not fatal
    var isInitialized = false //
    var loggerData : [motionMessage] = []  //my shit goes in here
    var storeLoggerDataOnFinalize = false //as default, we wont store anything
                                            //something else must observe the data and decide if its worth keeping
    
    var CM : CMMotionManager?
    let queue1 = Observable<CMDeviceMotion>()
    let queue2 = Observable<CMGyroData>()
    //var mergedQueue = Observable<Any>()
    var mergedQueueToken: ObserverToken?    //dont initialize, make optional
    
    //init(){
        
        
        //self.name = "motionLogger"
        //self.myID = "motionlogger"
        
        //self.myCategory = objectCategoryTypes.unique
        
    //}
    
    func _initialize () -> DROPcategoryTypes? {
        
        myCategory = objectCategoryTypes.uniqueServiceProvider
        name = "motionLogger"
        
        if (CM==nil){
            CM = CMMotionManager();
        }
        
        print(CM?.isDeviceMotionAvailable ?? "nope")
        print(CM?.isMagnetometerAvailable ?? "nope")
        print(CM?.isGyroAvailable ?? "nope")
        print(CM?.isAccelerometerAvailable ?? "nope")

        if (CM?.isDeviceMotionAvailable == false ) {
            
            _teardown()
            return DROPcategoryTypes.serviceNotAvailable
        }
        
        /*if (CM?.isDeviceMotionActive == false ) {
            
            //bitch and complain, activate this frikking service
            return DROPcategoryTypes.serviceNotActivated
            
        }*/
        
       

        CM?.deviceMotionUpdateInterval = 1
        
        CM?.startDeviceMotionUpdates(to: OperationQueue.main) { motion, error in
            
            self.queue1.update(motion!)  //shove it down into the observable queue to be merged later
            motion?.userAcceleration
            motion?.gravity
            motion?.attitude
            
            print(motion ?? "nil" )
        }
        
        CM?.startGyroUpdates(to: OperationQueue.main) { gyro, error in
            
            self.queue2.update(gyro!)
            //print(gyro ?? "nil" )
        }
        
        let mergedQueue = queue1.merge(queue2)
        
        mergedQueueToken = mergedQueue.subscribe { t in
            
            if self.terminated {
                mergedQueue.unsubscribe(self.mergedQueueToken!)
                //mergedQueue.unsubscribe(mergedQueueToken)
                return  //thats enough
            }
            
            //where to put this. maybe on appDelegate to handle meaningful concurrent events?
            //return observable to viewController?
            //logic should happen here though
            //let p = motionMessage
            let u = t.1.rotationRate
            let xu = t.0.attitude
            
            //var o = [ "type" : "motionMessage", "rotationRate" : u ,"attitude": xu ] as [String : Any];
            
            let o = CommMessage.MotionMessage(type: "motionMessage", oCAT: self.myCategory, oID: self.myID, rotationRate: u, attitude: xu)
                
            
            
            //var o = [ "type" : "motionMessage", "CMDeviceMotion" : t.0 ,"CMGyroData": t.1 ] as [String : Any];
            
            //DispatchQueue.main.async {
                self.SAY(o: o)  //tell anybody who is interested
            //}
        }

        if let motionTrackers = self.scheduler?.getCategoryObjects(oCAT: objectCategoryTypes.motionlistener) {
            //if we have listeners, lets push our updates to them
            for a in motionTrackers {
                
                _ = self.addListener(oCAT: objectCategoryTypes.motionlistener, oID: a, name: "motionlistener")
                
            }
            
            
        }   //any live motionTrackers that existed before me got listening to me now
        isInitialized = true
        return nil
    }
    
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        //somebody turns motionmanager off as a joke
        if (CM == nil){
            let res = _initialize()
            if res != nil {
                
                //we got a major hiccup. ask scheduler to kill us
                return res
                
            }
            //consider this as a service. if were not ready, try to kickstart us
            self._pulse(pulseBySeconds: 60 )    //keep on living
            return DROPcategoryTypes.serviceNotReady
            
        }
        
        self._pulse(pulseBySeconds: 60 )    //keep on living
        
        return nil
        
    }
    
    
    override func _LISTEN_extend(o: internalMessage) -> DROPcategoryTypes? {
        
        //who would logger listen to
        
        
            
        
        self._pulse(pulseBySeconds: 60 )
        return nil
        
    }   //end of listen extend
    
    
    func addEntry ( e : motionMessage ) -> DROPcategoryTypes? {
        
        return nil
        
        
    }
    
    func reset () {
        
        // runrecorderjunction reset calls this
        
        CM?.stopGyroUpdates()   //stop gyro too
        
        CM?.stopDeviceMotionUpdates()   //dont ask for updates anymore
        
    }
    
    func restart () {
        
        CM?.startDeviceMotionUpdates(to: OperationQueue.main) { motion, error in
            
            self.queue1.update(motion!)  //shove it down into the observable queue to be merged later
           /* motion?.userAcceleration
            motion?.gravity
            motion?.attitude
            
            print(motion ?? "nil" ) */
        }
        
    }
    
    override func _finalize () -> DROPcategoryTypes? {
        
        if (self.terminated) { return DROPcategoryTypes.terminating; }
        if (self.isFinalizing) { return DROPcategoryTypes.finalizing }
        
        //isFinalizing never needs to change to false again.
        self.isFinalizing = true
        
        CM?.stopGyroUpdates()   //stop gyro too
        
        CM?.stopDeviceMotionUpdates()   //dont ask for updates anymore
        
        
        
        //mergedQueue.unsubscribe(mergedQueueToken)
        
        //finalize is called if this guy has to save data or something
        if storeLoggerDataOnFinalize == false {
            
            return _teardown()
            
        }
        
        
        //finalize ends in teardown
        
        //bake my data to json, send it to dbStorage
        
        return _teardown()
    }
    
    override func _purge ( backPressure : Int ) -> Int {
        
        //default purge. all objects obey to purge except .debugger, .uniqueServiceProvider
        /*if backPressure < uniqueServiceProviderBackPressureLimit {
         
         return backPressure
         
         }*/
        
        //uniqServiceProviders can try to stay alive and force lesser processes to die
        //by just removing one tick of backpressure
        
        //if im processing, do x
        //backpressure is 1 (warning) 99999999... (GTFO now)
        
        if (backPressure > purgeRequestEXITtreshold ) {
            
            self._finalize()
            let rema = backPressure - purgeRequestEXITtreshold
            return rema //too much back pressure, just bail out
        }
        
        isPurging = true
        
        let b = Double ( backPressure * 30 )
        let TTLdeducted = self.TTL - b //deduct by one housekeep round
        
        if (TTLdeducted < self.uxT()){
            
            self._finalize()    //some objects need finalize, timewaster does not
            return backPressure
        }
        
        TTL = TTLdeducted   //_pulse() will keep this up if something meaningful happens
        //in timewasters case it never does and we will teardown
        //some other object would do purge in a different way, block incoming data..
        
        return 1    //down by one click
        
        
        //returns a guesstimate how much pressure is relieved with my action
        
        //if not, just drop my TTL
        //the objects are somewhere else anyway
        //Scheduler just asks me to purge, i react how i react
        
        //objects die out with TTL only, nothing stays for too long anyway
        
        //default purge does absolutely nothing. you are stuck with us baby
        
        return 0
    }

    
}
