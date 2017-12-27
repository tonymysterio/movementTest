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

var requestCurrentLocationObserver = Observable<Bool>()
var requestCommitOfCurrentRunObserver = Observable<Bool>()
var requestReadOfCurrentRunObserver = Observable<Bool>()

var currentRunReceivedObserver = Observable<Run>()

class runRecorderJunction {
    
    var recording = false;
    var myRecorderObjectID = "";
    weak var myLocationTracker : LocationLogger?
    weak var myLiveRunStreamListener : liveRunStreamListener?
    weak var myPedometer : Pedometer?
    var initialLocation = locationMessage( timestamp : 0 , lat : 65.822299, lon: 24.2002689 )
    
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
        
        guard let locationTracker = getLocationLogger() else {
            return
        }
        recording = true;
        
        //we need a listener to record the coordinattoos
        //listener will ping with run data when we have sctuffo
        
        //liveRunStreamListener
        
        //create new, assume that old one is terminaattod
        let mstl = getLiveRunStreamListener()
        
        let pedo = getPedometer()
        
        //get run disk recorder up and running
        
        getCurrentRunDataIO()
        
        
        
    }
    
    func locationMessageGotFromLocationLogger (locationMessage : locationMessage) {
        
        print("loc mess got")
        //if we have any live LiveRunStreamListeners they should pick up this signal automagically
        self.initialLocation = locationMessage
        
    }
    func recordCompleted( run : Run ) {
        
        //my subclass told me
        
        
    }
    
    func runAreaProgress (run : Run) {
        
        //more data came in, lets store it to local storage
        //this would better belong to file access junction
        
        //dig the boring scheduler thing out
        
        //var runStreamRecorder : RunStreamRecorder
        /*if !run.isClosed() {
            //dont bother with non closed runs
            return;
        }*/
        
        if let rsr = getRunStreamRecorder(){
            
            rsr.storeCurrentRun(run: run)
            
        }
        
        
        
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
        
        if let mlt = storage.getObject(oID: "currentRunDataIO") as! CurrentRunDataIO? {
            mlt._finalize()
        }
        
        //the runStreamRecorder will be purged automatically in due course
        
        //dont kill location logger here? because something else might be using it?
        
    }
    func requestCurrentLocation () {
        
        //map view is requesting for location probably
        if (self.myLocationTracker == nil) {
            initLocationServices()
            
        } else {
            
            
            
        }
        
        //spit out the location I know
        locationMessageObserver.update(self.initialLocation)
        
    }
    
    func ReadOfCurrentRun () {
        
        if self.recording {
            //stop run first
            return;
        }
        
        self.reset();   //get rid of anything run recording related
        //read current from disk
        
        //if available, prime with existing run
        if let rdIO = getCurrentRunDataIO() {
            
            //ask for current run
            rdIO.ReadOfCurrentRun()
        }
        
    }
    
    func CommitOfCurrentRun (  ) {
    
        if !self.recording {
            //stop run first
            return;
        }
        
        //do we have a run writer?
        if let rdIO = getCurrentRunDataIO() {
            
            //CurrentRunDataIO gets its data thru observer runAreaProgressObserver
            
            
        }
        
        //let run writer to save this
    
    }
    
    func currentRunReceived (run : Run) {
        
        if recording { return }
        //get the show going.
        //our initiator has already called reset
        //reset();
        
        //ghetto way to start the recording circus
        
        guard let locationTracker = getLocationLogger() else {
            print ("locationTracker could not be initialized. deadness");
            return;
        }
        if let mstl = getLiveRunStreamListener() {
            
            mstl.primeWithRun( run: run )
            
        }
        
        let pedo = getPedometer()
        let IO = getCurrentRunDataIO()
        
        runAreaProgressObserver.update(run)
        recording = true;
        
    }
    
    func getCurrentRunDataIO () -> CurrentRunDataIO? {
        
        if let mlt = storage.getObject(oID: "currentRunDataIO") as! CurrentRunDataIO? {
            return mlt;
        }
        
        var rdIO = CurrentRunDataIO( messageQueue : nil );
        /*rdIO.myID = "currentRunDataIO";
        rdIO.name = "currentRunDataIO";
        rdIO.myCategory = objectCategoryTypes.generic */
        rdIO._pulse(pulseBySeconds: 10);
        //rdIO.initialLocation = locMessage;   //make it look at the right place
        //rdIO.getWithinArea = self.getWithinArea //
        rdIO._initialize()
        
        if (scheduler.addObject(oID: rdIO.myID, o: rdIO)) {
            
            return rdIO
        }
        
        return nil
        
        
    }
    
    func getRunStreamRecorder () -> RunStreamRecorder? {
        
        if let runStreamRecorder = storage.getObject(oID: "runStreamRecorder") as? RunStreamRecorder {
            
            return runStreamRecorder
            
        }
            
            let rsr = RunStreamRecorder(messageQueue: messageQueue)
            rsr._pulse(pulseBySeconds: 60);
            rsr._initialize()
            rsr.houseKeepingRole = houseKeepingRoles.slave;
            return rsr
        
        if scheduler.addObject(oID: rsr.myID, o: rsr) {
            return rsr
        }
        
        return nil
        
        
    }
    
    func getLocationLogger () -> LocationLogger? {
        
        //start recording, we need a location tracker for this
        if let mlt = storage.getObject(oID: "locationLogger") as! LocationLogger? {
                
            mlt._pulse(pulseBySeconds: 600000)
            return mlt
                
        }
                
        let myLocationLogger = LocationLogger( messageQueue : messageQueue )
        myLocationLogger._initialize()
        //myLocationTracker.addListener(oCAT: worryAunt.myCategory, oID: worryAunt.myID, name: worryAunt.name)
        myLocationLogger._pulse(pulseBySeconds: 60000)
        
        if scheduler.addObject(oID: myLocationLogger.myID, o: myLocationLogger) {
            return myLocationLogger
        }
  
        return nil
    }
    
    func getLiveRunStreamListener () -> liveRunStreamListener? {
        
        if let mlt = storage.getObject(oID: "liveRunStreamListener") as! liveRunStreamListener? {
            
            mlt._pulse(pulseBySeconds: 600000)
            return mlt
            
        }
        
        //create new, assume that old one is terminaattod
        let myLiveRunStreamListener = liveRunStreamListener(messageQueue: messageQueue);
        myLiveRunStreamListener._initialize()
        myLiveRunStreamListener._pulse(pulseBySeconds: 60000);
        
        if scheduler.addObject(oID: myLiveRunStreamListener.myID, o: myLiveRunStreamListener ){
            //myLocationTracker?.addListener(oCAT: myLiveRunStreamListener.myCategory, oID: myLiveRunStreamListener.myID, name: myLiveRunStreamListener.name)
            
            return myLiveRunStreamListener
        }
        
        return nil
    
    }
    
    func getPedometer () -> Pedometer? {
        
        if let mlt = storage.getObject(oID: "pedometer") as! Pedometer? {
            
            mlt._pulse(pulseBySeconds: 600000)
            return mlt
            
        }
        let myPedometer = Pedometer(messageQueue: messageQueue)
        
        myPedometer._initialize()
        myPedometer._pulse(pulseBySeconds: 600000)
        
        if scheduler.addObject(oID: myPedometer.myID, o: myPedometer ) {
            return myPedometer;
        }
        
        return nil
    }
    
    func initLocationServices () {
        
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
        
        requestCurrentLocationObserver.subscribe { toggle in
            self.requestCurrentLocation()
            
        }
        
        requestCommitOfCurrentRunObserver.subscribe { toggle in
            //user taps a button to save to disk
            self.CommitOfCurrentRun()
            
        }
        
        
        requestReadOfCurrentRunObserver.subscribe{ toggle in
            
            //user taps a button to load from disk
            self.ReadOfCurrentRun()
            
        }
        
        currentRunReceivedObserver.subscribe { run in
            
            // currentRunDataIO has retrieved something of a current run
            self.currentRunReceived( run : run )
            
        }
    }
    
    
    
    
}