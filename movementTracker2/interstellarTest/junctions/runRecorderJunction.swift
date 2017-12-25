//
//  runRecorderJunction.swift
//  interStellarTest
//
//  Created by sami on 2017/11/17.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import Interstellar

var runRecoderToggleObserver = Observable<Bool>()
var runAreaCompletedObserver = Observable<Run>()
var runAreaProgressObserver = Observable<Run>()
var runRecorderAbortObserver = Observable<Bool>()
var locationMessageObserver = Observable<locationMessage>()

class runRecorderJunction {
    
    var recording = false;
    var myRecorderObjectID = "";
    weak var myLocationTracker : LocationLogger?
    weak var myLiveRunStreamListener : liveRunStreamListener?
    weak var myPedometer : Pedometer?
    
    func initialize () {
        
        print("runRecorderJunction here")
        
    }
    
    func recordStatusChange ( toggle : Bool ) {
        
        if !toggle {
            //stop recording. kill
            recording = false;
            reset()
            return;
        }
        
        //locationtracker is unique, should exist
        //this service should not kill the existing tracker, somebody else might be interested
        
        if (myLocationTracker==nil) {
            //start recording, we need a location tracker for this
            if let mlt = storage.getObject(oID: "locationLogger") as! LocationLogger? {
                
                    myLocationTracker = mlt
                    _ = myLocationTracker?._pulse(pulseBySeconds: 600000)
                
                } else {
                
                let myLocationTracker = LocationLogger( messageQueue : messageQueue )
                myLocationTracker._initialize()
                scheduler.addObject(oID: myLocationTracker.myID, o: myLocationTracker)
                //myLocationTracker.addListener(oCAT: worryAunt.myCategory, oID: worryAunt.myID, name: worryAunt.name)
                myLocationTracker._pulse(pulseBySeconds: 60000)
                
                
                }
            
        } else {
            
            //check if its live
            //assume its live
            
        }
        
        //we need a listener to record the coordinattoos
        //listener will ping with run data when we have sctuffo
        
        //liveRunStreamListener
        
        //create new, assume that old one is terminaattod
        let myLiveRunStreamListener = liveRunStreamListener(messageQueue: messageQueue);
        myLiveRunStreamListener._initialize()
        scheduler.addObject(oID: myLiveRunStreamListener.myID, o: myLiveRunStreamListener )
        myLocationTracker?.addListener(oCAT: myLiveRunStreamListener.myCategory, oID: myLiveRunStreamListener.myID, name: myLiveRunStreamListener.name)
        
        //kick pedometer on too
        if myPedometer == nil {
            
            let myPedometer = Pedometer(messageQueue: messageQueue)
            scheduler.addObject(oID: myPedometer.myID, o: myPedometer )
            myPedometer._initialize()
            
            //pedometer just appends interstellar messages, viewcontroller listens
            
        }
        
        
        recording = true;
        
    }
    
    func locationMessageGotFromLocationLogger (locationMessage : locationMessage) {
        
        print("loc mess got")
        //if we have any live LiveRunStreamListeners they should pick up this signal automagically
        
        
    }
    func recordCompleted( run : Run ) {
        
        //my subclass told me
        
        
    }
    
    func runAreaProgress (run : Run) {
        
        //more data came in, lets store it to local storage
        //this would better belong to file access junction
        
        //dig the boring scheduler thing out
        
        //var runStreamRecorder : RunStreamRecorder
        
        var rsr : RunStreamRecorder
        
        if let runStreamRecorder = storage.getObject(oID: "runStreamRecorder") as? RunStreamRecorder {
            rsr = runStreamRecorder
        } else {
            
            rsr = RunStreamRecorder(messageQueue: messageQueue)
            rsr._pulse(pulseBySeconds: 60);
            rsr._initialize()
            rsr.houseKeepingRole = houseKeepingRoles.slave;
            
        }
        
        rsr._pulse(pulseBySeconds: 10)  //youve got ten seconds buddy
        //failure to store is not my problem, best effort here boys and girls
        rsr.storeCurrentRun(run: run)
        
        
    }
    
    func reset(){
        
        recording = false;
        //drop the reference to recording object
        if let mlt = storage.getObject(oID: "liveRunStreamListener") as! liveRunStreamListener? {
            mlt._finalize()
        }
        
        if let mlt = storage.getObject(oID: "pedometer") as! Pedometer? {
            mlt._finalize()
        }
        
        
        
        //the runStreamRecorder will be purged automatically in due course
        
        //dont kill location logger here? because something else might be using it?
        
    }
    
    init () {
        
        runRecoderToggleObserver.subscribe { toggle in
            self.recordStatusChange( toggle : toggle)
            
        }
        
        runAreaCompletedObserver.subscribe { run in
            self.recordCompleted(run : run)
            
        }
        
        LocationLoggerMessageObserver.subscribe
            { locationMessage in
            self.locationMessageGotFromLocationLogger(locationMessage : locationMessage)
            
        }
        
        runAreaProgressObserver.subscribe { run in
            self.runAreaProgress( run : run )
            
        }
        
        
    }
    
    
    
    
}
