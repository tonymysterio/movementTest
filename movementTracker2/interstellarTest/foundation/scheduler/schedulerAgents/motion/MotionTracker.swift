//
//  MotionTracker.swift
//  interStellarTest
//
//  Created by sami on 2017/07/18.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation

//listens to locationEvents from locationLogger
//lets be able to prime this with previous events
//long TTL, finalize if we run out of TTL
//trust locationLogger not to send redundant data

//you could have multiple locationTrackers with data passed over XMPP
//detect collisions with other people, proximity
//make a subclass of this that reacts to specific events

//track location
//when you add motionTracker from outside, remember to add listener


class MotionTracker : BaseObject {
    
    var isLogging = false;
    var isPaused = false;   //gps off, something that is not fatal
    var isInitialized = false //
    var loggerData : [motionMessage] = []  //my shit goes in here
    var storeLoggerDataOnFinalize = false   //all data is disposable by default
    
    
    
    //init(){
    
    //override say with something that talks to all locationlistener category objects
    //if nobody is listening, dont extend our TTL. nobody is listening, nobody cares, terminate
    //say is for soft messages caught with _listen_extend
    
    
    //self.name = "motionLogger"
    //self.myID = "motionlogger"
    
    //self.myCategory = objectCategoryTypes.unique
    
    //}
    
    func _initialize () -> DROPcategoryTypes? {
        
        
        myCategory = objectCategoryTypes.motionlistener
        name = "motionTracker"
        
        /*
         
         let queue1 = Observable<CMDeviceMotion>()
         let queue2 = Observable<CMGyroData>()
         
         CM?.deviceMotionUpdateInterval = 1
         
         CM?.startDeviceMotionUpdates(to: OperationQueue.main) { motion, error in
         
         queue1.update(motion!)  //shove it down into the observable queue to be merged later
         motion?.userAcceleration
         motion?.gravity
         motion?.attitude
         
         print(motion ?? "nil" )
         }
         
         CM?.startGyroUpdates(to: OperationQueue.main) { gyro, error in
         
         queue2.update(gyro!)
         print(gyro ?? "nil" )
         }
         
         
         
         let mergedQueue = queue1.merge(queue2)
         
         mergedQueue.subscribe { t in
         
         //where to put this. maybe on appDelegate to handle meaningful concurrent events?
         //return observable to viewController?
         //logic should happen here though
         
         
         }
         
         //let t = CM.sta
         */
        
        return nil
    }
    
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        
        
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
    
    override func _finalize () -> DROPcategoryTypes? {
        
        if (self.terminated) { return DROPcategoryTypes.terminating; }
        if (self.isFinalizing) { return DROPcategoryTypes.finalizing }
        
        //isFinalizing never needs to change to false again.
        self.isFinalizing = true
        
        //finalize is called if this guy has to save data or something
        if storeLoggerDataOnFinalize == false {
            
            return _teardown()
            
        }
        
        //finalize ends in teardown
        
        //bake my data to json, send it to dbStorage
        
        
        return _teardown()
        
    }
    
    
    
}
