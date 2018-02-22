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
var liveRunAreaCompletedObserver = Observable<Run>()
var liveRunAreaProgressObserver = Observable<Run>()
var runRecorderAbortObserver = Observable<Bool>()
var locationMessageObserver = Observable<locationMessage>()

//for map, where are we now
//requested with currentlocation request

var requestCurrentLocationObserver = Observable<Bool>()
var requestCommitOfCurrentRunObserver = Observable<Bool>()
var requestReadOfCurrentRunObserver = Observable<Bool>()
var requestCommitOfCurrentBorkedRunObserver = Observable<Bool>()

//runrecoder junction notify of illegal run objects when pulling from disk,meshnetting
var borkedRunReceivedObserver = Observable<Run>()


var currentRunReceivedObserver = Observable<Run>()

var runRecorderSavedRun = Observable<Run>();
var runRecorderSavedFinishedRun = Observable<Run>();

class runRecorderJunction {
    
    var pushFakeData = false; //true;    //LocationLoggerMessageObserver affects 290 this file, readOfCurrentRun dishes out one location at a time
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
        if pushFakeData {
            
            
            
        }
        
        
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
        
        getCurrentRunDataIO();
        
        
        
    }
    
    func locationMessageGotFromLocationLogger (locationMessage : locationMessage) {
        
        print("loc mess got")
        //if we have any live LiveRunStreamListeners they should pick up this signal automagically
        self.initialLocation = locationMessage
        
    }
    func liveRunRecordCompleted( run : Run ) {
        
        //my subclass told me
        //maybe pulling a current run triggered this
        
        DispatchQueue.main.async {
            //runStreamRecorder is bad news because it will save whatever is thrown at it
            //liverunstreamlistener will page us a few times from its housekeep after the
            //recording is finished and runStreamRecorder is still alive
            //no new coordinates get added. make runStreamRecorder ignore if the previous saved has is sent over again
            //TODO:
            
            if let rsr = self.getRunStreamRecorder() {
            
                //set closetime and proper geohash
                var r2 = run;
                
                r2.finalizeRun();
                rsr.storeFinishedRun(run: r2, success: {
                    (run, filename) in
                    print("liveRunRecordCompleted storeFinishedRun success \(filename)");
                    
                    
                    
                    ////runRecorderSavedFinishedRun.update(run);
                    //peerDataRequesterRunArrivedSavedObserver.update(hash)   //ping packetExchage about a run saved
                    
                    
                },Cerror: {
                    (errorType) in
                    
                    print("liveRunRecordCompleted storeFinishedRun error \(errorType)");
                    
                });
                
                //pings with runRecorderSavedFinalizedRun
                
                
                
            } else {
            
                print("runrecorder junction: failed to getRunStreamRecorder!");
            
            }
        
        }
        //todo: destroy processes for recording a run
        
    }
    
    func liveRunAreaProgress (run : Run) {
        
        //more data came in, lets store it to local storage
        //this would better belong to file access junction
        
        //dig the boring scheduler thing out
        
        //var runStreamRecorder : RunStreamRecorder
        /*if !run.isClosed() {
            //dont bother with non closed runs
            return;
        }*/
        
        if pushFakeData {
            //dont resave faked data as currentRun
            return;
        }
        
        if run.isReadyForTemporarySave() == false {
            return;
        }
        
        //calculate live run distances for display here
        
        
        
        DispatchQueue.main.async {
            
            //run stream recorder is born when we are recording a run and that run has enough daatta
            
            if let mlt = storage.getObject(oID: "currentRunDataIO") as! CurrentRunDataIO? {
                
                mlt.CommitOfCurrentRun(run: run,success: { (filename) in
                    
                    print("liveRunAreaProgress CommitOfCurrentRun success \(filename) " );
                    
                },Cerror: { (errorCode) in
                    
                    
                    print("liveRunAreaProgress CommitOfCurrentRun fail \(errorCode) " )

                    
                })
                
            }
            
            
            /*if let rsr = self.getRunStreamRecorder(){
            
                rsr.storeCurrentRun(run: run)
            
            }*/
            
        
        }
        
        
    }
    
    func reset(){
        
        recording = false;
        //drop the reference to recording object
        DispatchQueue.main.async {
            
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
        /*if let mlt = storage.getObject(oID: "locationLogger") as! MotionLogger? {
            mlt.reset();    //stop mozion updates
        }
        */
        
        //dont kill location logger here? because something else might be using it?
        }
    }
    func requestCurrentLocation () {
        
        //answer for map screen button tap
        
        //map view is requesting for location probably
        if let mlt = storage.getObject(oID: "locationLogger") as! LocationLogger? {
            
            //myLocationTracker = mlt
            mlt._pulse(pulseBySeconds: 600000)
            
            //will talk thru observable
            //map screen listens to this
            currentLocationMessageObserver.update (mlt.requestCurrentLocation());
            //LocationLoggerMessageObserver.update (mlt.requestCurrentLocation());
            
            //if this exists, we could pry the current location now
            
            
        } else {
            
            initLocationServices()
            
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
            rdIO.ReadOfCurrentRun (success: { [weak self] (run) in
                
                //let ran = run;
                //poprint(ran);
                //let rvalid = run.isValid;
                //let rClosed = run.isClosed();
                //if (run.isValid && run.isClosed() ) {
                    
                    print(#function);
                    print("run.coordinates.count = \(run.coordinates.count)");
                    print("run.spikeFilteredCoordinates = \(run.spikeFilteredCoordinates()?.count)");
                    print("run.totalDistance = \(run.totalDistance())");
                    print("run.distanceBetweenStartAndEndSpikeFiltered = \(run.distanceBetweenStartAndEndSpikeFiltered())")
                    print("run.geohash = \(run.geoHash)");
                    print("run.computeGeoHash = \(run.computeGeoHash())");
                    
                    print("run pulled \(run.hash) at \(run.geoHash) ")
                    
                    print (run.totalDistance());
                    //print("tit");
                    //start fakepushing coords
                    self?.currentRunReceived(run: run);
                //}
                
            }, error: {
                
                print ("ReadOfCurrentRun failed");
            })
            
        }
        
    }
    
    func CommitOfCurrentRun (  ) {
    
        if !self.recording {
            //stop run first
            return;
        }
        
        if let mstl = getLiveRunStreamListener() {
            
            if let run = mstl.currentRun {
                
                if let rdIO = getCurrentRunDataIO() {
                    rdIO.CommitOfCurrentRun(run: run , success: {
                        (filename) in
                        print("CommitOfCurrentRun success \(filename)");
                        
                    },Cerror: {
                        (errorType) in
                        
                        print("CommitOfCurrentRun success \(errorType)");
                        
                    });
                    
                }
            }
            
        }
        
        return;
        
        //do we have a run writer?
        if let rdIO = getCurrentRunDataIO() {
            
            //CurrentRunDataIO gets its data thru observer runAreaProgressObserver
            if pushFakeData {
                //this means we are on a real run.
                pushFakeData = false;
                
                
                
            }
            
        }
        
        //let run writer to save this
    
    }
    
    func CommitOfCurrentBorkedRun (){
        
        //see if we have a pulled run
        if let mstl = getLiveRunStreamListener() {
            
            if let run = mstl.currentRun {
                
                if let rdIO = getCurrentRunDataIO() {
                    
                    rdIO.CommitOfCurrentBorkedRun ( run: run, success : { filename in
                        
                        print ("CommitOfCurrentBorkedRun ok \(filename)" )
                        
                    },Cerror : { dropCode in
                        
                        print ("CommitOfCurrentBorkedRun error \(dropCode)" )
                        
                    });
                }
            }
            
        }
        
        
    }
    
    func currentRunReceived (run : Run) {
        
        if recording { return }
        //get the show going.
        //our initiator has already called reset
        //reset();
        
        //ghetto way to start the recording circus
        
        if !pushFakeData {
            guard let locationTracker = getLocationLogger() else {
                print ("locationTracker could not be initialized. deadness");
                return;
            }
        }
        
        if let mstl = getLiveRunStreamListener() {
            
            if pushFakeData {
                //dish run coords one by one
                //dont worry about the read run being garbage
                print(#function)
                print(run.coordinates.count);
                print(run.distanceBetweenStartAndEndSpikeFiltered());
                print(run.totalDistance());
                sendstoredCurrentRunCoordinateOneByOneForLiveRunStreamListener(run:run,coordinate: 0);
                
            } else {
                
                
                
         
            
                if !mstl.primeWithRun( run: run ) {
                
                
                
                } else {
                    //the run was garbage, timeouted, whatever, probably got messed up on disk write
                
                }
            }
            
        }
        
        let pedo = getPedometer()
        let IO = getCurrentRunDataIO()
        
        if !pushFakeData { liveRunAreaProgressObserver.update(run) }
        recording = true;
        
    }
    
    let storedCurrentRunCoordinate = 0;
    
    func sendstoredCurrentRunCoordinateOneByOneForLiveRunStreamListener ( run : Run, coordinate : Int ) {
        
        let coc = run.coordinates.count;
        print (coordinate)
        print (coc);
        if coordinate > run.coordinates.count - 1 {
            return;
        }
        
        if let coor = run.coordinates[coordinate] as coordinate?  {
            
            //fake as regular locationloggeer message
            LocationLoggerMessageObserver.update(locationMessage(timestamp: coor.timestamp , lat: coor.lat, lon: coor.lon ))
            let nextCoo = coordinate + 1;
            
            let deadlineTime = DispatchTime.now() + .seconds(1)
            //push next coord sfter a second
            DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
                self.sendstoredCurrentRunCoordinateOneByOneForLiveRunStreamListener(run:run,coordinate: nextCoo)
            })
            
    
    
        } else {
            
            print (#function)
            print ("all coordinates sent to LocationLoggerMessageObserver")
            
        }
    
        
        
    }
    
    func getCurrentRunDataIO () -> CurrentRunDataIO? {
        
        if let mlt = storage.getObject(oID: "currentRunDataIO") as! CurrentRunDataIO? {
            return mlt;
        }
        
        var rdIO = CurrentRunDataIO( messageQueue : nil );
        rdIO.myID = "currentRunDataIO";
        rdIO.name = "currentRunDataIO";
        rdIO.myCategory = objectCategoryTypes.generic;
        rdIO._pulse(pulseBySeconds: 10);
        //rdIO.initialLocation = locMessage;   //make it look at the right place
        //rdIO.getWithinArea = self.getWithinArea //
        rdIO._initialize()
        
        if (scheduler.addObject(oID: rdIO.myID, o: rdIO)) {
            
            return rdIO
        }
        
        return nil
        
        
    }
    
    func getRunStreamRecorderStatus () -> Bool {
        //sort of deprecated
        if let runStreamRecorder = storage.getObject(oID: "runStreamRecorder") as? RunStreamRecorder {
            
            if runStreamRecorder.terminated { return false; }
            
            return true;
        }
        
        return false;
        
    }
    
    func getLiveRunStreamListenerStatus () -> Bool {
        
        //this guy is ON if we are recording run coords
        if let liveRunStreamListener = storage.getObject(oID: "liveRunStreamListener") as? liveRunStreamListener {
            
            if liveRunStreamListener.terminated { return false; }
            
            return true;
        }
        
        return false;
        
    }
    
    func getRunStreamRecorder () -> RunStreamRecorder? {
        
        if let runStreamRecorder = storage.getObject(oID: "runStreamRecorder") as? RunStreamRecorder {
            
            return runStreamRecorder
            
        }
            
            let rsr = RunStreamRecorder(messageQueue: messageQueue)
            rsr.myID = "runStreamRecorder";
            rsr.name = "runStreamRecorder";
            rsr.myCategory = objectCategoryTypes.generic;
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
            
            //myLocationTracker = mlt
            mlt._pulse(pulseBySeconds: 600000)
            
            //will talk thru observable
            //map screen listens to this
            LocationLoggerMessageObserver.update (mlt.requestCurrentLocation());
            
            //if this exists, we could pry the current location now
            
            
        } else {
            
            DispatchQueue.main.async {
                let myLocationTracker = LocationLogger( messageQueue : messageQueue )
                
                myLocationTracker._initialize()
                scheduler.addObject(oID: myLocationTracker.myID, o: myLocationTracker)
                //myLocationTracker.addListener(oCAT: worryAunt.myCategory, oID: worryAunt.myID, name: worryAunt.name)
                myLocationTracker._pulse(pulseBySeconds: 60000)
            
            }
        }
        
    }
    
    func applicationDidBecomeActive () {
        
        //coming out from backgraound
        //if we are not on a run, start gps services
        if let loloc = storage.getObject(oID: "locationLogger") as! LocationLogger? {
            
            //loc logger is on
            if let lslistener = storage.getObject(oID: "liveRunStreamListener") as! liveRunStreamListener? {
                
                loloc.setBackgroundModeDependingOnActiveRunState(toggle: true)
                loloc.setLocationUpdateStatus(toggle: true)
                
                } else {
                
                loloc.setBackgroundModeDependingOnActiveRunState(toggle: false)
                loloc.setLocationUpdateStatus(toggle: true)
                
            }
        
        }
        
        
        
    }
    
    func applicationWillResignActive () {
        
        //sms came, phone call came, different app activated
        //if we are not on a run, stop gps services
        if let loloc = storage.getObject(oID: "locationLogger") as! LocationLogger? {
            
            //loc logger is on
            if let lslistener = storage.getObject(oID: "liveRunStreamListener") as! liveRunStreamListener? {
                
                loloc.setBackgroundModeDependingOnActiveRunState(toggle: true)
                loloc.setLocationUpdateStatus(toggle: true)
                
            } else {
                
                loloc.setBackgroundModeDependingOnActiveRunState(toggle: false)
                loloc.setLocationUpdateStatus(toggle: false)    //no need of loc updates while we are on background
            }
            
        }
        
    }
    
    init () {
        
        runRecoderToggleObserver.subscribe { toggle in
            //DispatchQueue.main.async {
                self.recordStatusChange( toggle : toggle)
            //h}
        }
        
        liveRunAreaCompletedObserver.subscribe { run in
            //liveRunStreamListener deducts if something is complete or not
            //DO NOT put this logic elsewhere
            //DispatchQueue.global(qos: .utility).async {
                self.liveRunRecordCompleted(run : run)
            //}
        }
        
        runRecorderSavedFinishedRun.subscribe { run in
            
            //run was completed and saved, put it to caches, drty snaps
            //mapViewJunction might want to display the map now
            
            if let runcache = storage.getObject(oID: "runCache") as! RunCache?  {
                runcache.addRun(run: run);
                
                //throw it in the cache
                if let snapcache = storage.getObject(oID: "snapshotCache") as! SnapshotCache?  {
                
                    //try to get a snap to display immeziately
                    snapcache.addRun(run: run);
                
                }
            
            }
            
        }
        LocationLoggerMessageObserver.subscribe
            { locationMessage in
                //DispatchQueue.global(qos: .utility).async {
                    self.locationMessageGotFromLocationLogger(locationMessage : locationMessage)
                //}
        }
        
        liveRunAreaProgressObserver.subscribe { run in
            //comes from runstreamlistener, queue .userInteraction
            //coordinate or event added on the run
            //DispatchQueue.global(qos: .utility).async {
                self.liveRunAreaProgress( run : run )
            //}
            
        }
        
        requestCurrentLocationObserver.subscribe { toggle in
            
            //this has to be main because it might start a location manager that has to be in
            //the main queue
            //DispatchQueue.global(qos: .utility).async {
            
                self.requestCurrentLocation()
            //}
        }
        
        requestCommitOfCurrentRunObserver.subscribe { toggle in
            //user taps a button to save to disk
            DispatchQueue.global(qos: .utility).async {
                self.CommitOfCurrentRun()
            }
        }
        
        
        requestReadOfCurrentRunObserver.subscribe{ toggle in
            
            //user taps a button to load from disk
            DispatchQueue.global(qos: .userInitiated).async {
                self.ReadOfCurrentRun()
            }
            
        }
        
        currentRunReceivedObserver.subscribe { run in
            
            // currentRunDataIO has retrieved something of a current run
            //this has to be main because it might start a location manager that has to be in
            //the main queue
            DispatchQueue.main.async {
                self.currentRunReceived( run : run )
            }
            
            
        }
        
        requestCommitOfCurrentBorkedRunObserver.subscribe{ toggle in
            //user taps a button to save to disk
            DispatchQueue.global(qos: .utility).async {
                self.CommitOfCurrentBorkedRun()
            }
        }
    }
    
    
    
    
}
