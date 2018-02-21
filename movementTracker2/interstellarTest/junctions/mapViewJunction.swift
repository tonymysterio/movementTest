//
//  mapViewJunction.swift
//  interStellarTest
//
//  Created by sami on 2017/12/12.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import Interstellar

/*var runRecoderToggleObserver = Observable<Bool>()
var runAreaCompletedObserver = Observable<Run>()
var runAreaProgressObserver = Observable<Run>()
var runRecorderAbortObserver = Observable<Bool>()
var locationMessageObserver = Observable<locationMessage>()*/

//personal, world, localCompetition

//turn mapcombiner on off
var mapCombinerToggleObserver = Observable<Bool>()
//for setting simplification level
var mapCombinerToleranceObserver = Observable<Float>()


var stopAllMapCombinersObserver = Observable<Float>()

var mapFilteringModeToggleObserver = Observable<mapFilteringMode>()
var currentLocationMessageObserver = Observable<locationMessage>()
var mapSnapshotObserver = Observable<mapSnapshot>()
//map screen might need thi
var requestForMapCombiner = Observable<locationMessage>()
var requestForMapDataProvider = Observable<locationMessage>()

//when mapCombiner finds something that is going to be displayed on the screen,
//notify user with something, data is incoming!
var mapCombinerPertinentDataFound = Observable<locationMessage>()

var mapViewJunctionSignificantViewChange = Observable<locationMessage>()


class mapViewJunction {
    
    //var recording = false;
    //var myRecorderObjectID = "";
    //weak var myLocationTracker : LocationLogger?
    //weak var myLiveRunStreamListener : liveRunStreamListener?
    //weak var myPedometer : Pedometer?
    var getWithinArea : Double = 1500; //zoomLevelInMeters
    let junctionQueue = DispatchQueue(label: "MapJunctionQueue", qos: .utility)
    var mapDataProviderInitialized = false; //HACK not to run pullRunsFromDisk again
    
    var initialLocation = locationMessage( timestamp : 0 , lat : 65.822299, lon: 24.2002689 )
    
    init () {
        
        stopAllMapCombinersObserver.subscribe{ toggle in
            
            //DispatchQueue.global(qos: .utility).async {
                
                self.stopAllMapCombiners();
            //}
        }
        
        mapCombinerToggleObserver.subscribe{ toggle in
            
            DispatchQueue.global(qos: .utility).async {
                
                if toggle {
                
                //just create a new one, all the battery power in the world
                self.addMapCombiner(locMessage: locationMessage( timestamp : 0 , lat : 65.822299, lon: 24.2002689 ))
                
                //read stored runs if any
                let mc = PullRunsFromDisk(messageQueue: messageQueue)
                //ignore runs from outside my scope
                mc.initialLocation = locationMessage( timestamp : 0 , lat : 65.822299, lon: 24.2002689 );
                mc._initialize()
                scheduler.addObject(oID: mc.myID, o: mc)
                
                mc.scanForRuns()
                
                } else {
                
                //scheduler pages all combiner with quite
                scheduler.removeObjectsByName(name: "mapCombiner")
                
                }
            
            }
        }
        
        mapCombinerToleranceObserver.subscribe{ tolerance in
            DispatchQueue.global(qos: .utility).async {
                //adjust simplifier tolerance
                self.mapCombinerToleranceSet ( tolerance : tolerance)
            }
        }
        
        mapFilteringModeToggleObserver.subscribe { filteringMode in
            
            //tell MapCombiner to change mode
            //self.recordCompleted(run : run)
            DispatchQueue.global(qos: .utility).async {
                self.mapFilteringModeToggle(filteringMode : filteringMode)
            }
        }
        
        requestForMapCombiner.subscribe {locationMessage in
            
            //DispatchQueue.global(qos: .userInitiated).async {
                self.addMapCombiner(locMessage : locationMessage )
            //}
        }
        
        requestForMapDataProvider.subscribe {locationMessage in
            //DispatchQueue.global(qos: .utility).async {
                self.addMapDataProvider(locMessage : locationMessage )
            //}
        }
        
        mapViewJunctionSignificantViewChange.subscribe {locationMessage in
            //when user jumps to current location far away from tornio
            let m = 1;
            
        }
        
        //runRecorder shows intent we want to record a runinit
        //this might not happen, lets not care about it
        /*runRecoderToggleObserver.subscribe { toggle in
            self.recordStatusChange( toggle : toggle)
            
        }*/
        
        /*runAreaCompletedObserver.subscribe { run in
            self.recordCompleted(run : run)
            
        }
        
        LocationLoggerMessageObserver.subscribe
            { locationMessage in
                self.locationMessageGotFromLocationLogger(locationMessage : locationMessage)
                
        }
        
        runAreaProgressObserver.subscribe { run in
            self.runAreaProgress( run : run )
            
        }*/
        
    }
        
    func initialize () {
        
        print("mapViewJunction here")
        
        //DispatchQueue.global(qos: .utility).async {
            
            self.addRunCache();
            self.addSnapCache();
        
            //detect a clean install without snapcaches
            //if no snaps on disk, fire pullruns from disk to give our run cache some data
            //self.addMapDataProvider ( locMessage : self.initialLocation );
        
        //}
        
    }
    
    func initializeForMapview (){
        
        
        
    }
    
    func mapFilteringModeToggle ( filteringMode : mapFilteringMode ) {
        
            //user wants to see different data on his map
            if let mlt = storage.getObject(oID: "mapCombiner") as! MapCombiner? {
            
                mlt.changeFilteringMode (filteringMode : filteringMode )
            
            }
     
    
    
        
    }
    
    func mapCombinerToleranceSet ( tolerance : Float ) {
        
        if let mlt = storage.getObject(oID: "mapCombiner") as! MapCombiner? {
            
            if tolerance < 0.00001 {
                
                mlt.changeSimplifyTolerance (tolerance: 0.00001);
                return;
            }
            
            if tolerance > 0.0002 {
                
                mlt.changeSimplifyTolerance (tolerance: 5);
                return;
            }
            
            mlt.changeSimplifyTolerance (tolerance: tolerance);
            return;
            
        }
        
        
        
        
    }
    
    func stopAllMapCombiners () {
        
        //exiting map screen, getting into data exchange.. flush dat shit
        //maybe extend so that only outside areas are stopped
        
        //returns array of ID's
        if let mcs = scheduler.getCategoryObjects(oCAT: .mapCombiner ) {
            
            for i in mcs {
                
                print(i);
                if let mm = scheduler.getObject(oID: i) as! MapCombiner? {
                    mm._finalize();
                    print("terminated \(i) ");
                }
            }
        
        }
    }
    
    
    
    
    func getLocalMapCombiners (locMessage : locationMessage) -> Bool {
        
        //check if we have somebody working on this
        //let mapZoom = mapZoomLevels(target: locMessage.timestamp)
        
        //returns array of ID's
        if let mcs = scheduler.getCategoryObjects(oCAT: .mapCombiner ) {
            
            for i in mcs {
                
                print(i);
                if let mm = scheduler.getObject(oID: i) as! MapCombiner? {
                    
                    //if the mapCombiner thinks hes got it, returns true
                    if mm.closeEnoughTo(locMessage : locMessage) {
                        print("on the job \(i) for lat \(locMessage.lat) lon \(locMessage.lon) dsi \(locMessage.timestamp)");
                        return true;
                    }
                    
                    
                }
                
            }
            
            
        }
        
        
        return false;
        
    }
    
    
    func addMapCombiner ( locMessage : locationMessage ){
        
        //cad add multiple
        junctionQueue.sync {
            
        
            let someBodyOnTheJobAlready = self.getLocalMapCombiners(locMessage:locMessage);
            if someBodyOnTheJobAlready {
            
                return;
            }
        
        //keep caching here. send snapshot if cached
        var gwa :Double = 2500;
        if locMessage.timestamp > 2000 && locMessage.timestamp < 50000 {
            //sneaking view radius through timestamp, naughty
            self.getWithinArea = locMessage.timestamp
            //calculate simplification level in mapcombiner
            gwa = locMessage.timestamp;
        }
            
            
            
        
        
        
        let mapCombiner = MapCombiner( messageQueue : nil );
        
        //should be a global funktion
        let area = mapCombiner.mapZoomLevels(target: locMessage.timestamp);
            
        let name = "mapCombiner_"+Geohash.encode(latitude: locMessage.lat, longitude: locMessage.lon) + "_" + String(area);
            
        mapCombiner.myID = name; //"mapCombiner";
        mapCombiner.name = name //"mapCombiner";
        mapCombiner.myCategory = objectCategoryTypes.mapCombiner
        mapCombiner._pulse(pulseBySeconds: 600);
        mapCombiner.setInitialLocation(loc: locMessage);
        //mapCombiner.initialLocation = locMessage;   //make it look at the right place
        //mapCombiner.getWithinArea = gwa //
        let rep = mapCombiner._initialize()
        
        scheduler.addObject(oID: mapCombiner.myID, o: mapCombiner)
        
        if rep == DROPcategoryTypes.readyImmediately {
            //lets start working?
            //serviceNotReady is returned if no runs
            mapCombiner.createSnapshot();
        }
        
        }   //end queue
    }
    
    func addMapDataProvider ( locMessage : locationMessage ){
        
        //HACK not to start pullRuns again
        if mapDataProviderInitialized == true {
            return
            
        }
        
        //requestForMapDataProvider
        if let runcache = storage.getObject(oID: "PullRunsFromDisk") as! PullRunsFromDisk?  {
            
            print("requestForMapDataProvider requested via mapviewjunction on addMapDataProvider. already running, deny")
            return;
        }
        
        
        //junctionQueue.sync {
        DispatchQueue.main.async {
            
            var gwa : Double = 2500;
            if locMessage.timestamp > 2000 && locMessage.timestamp < 50000 {
                //sneaking view radius through timestamp, naughty
                self.getWithinArea = locMessage.timestamp
                //calculate simplification level in mapcombiner
                gwa = locMessage.timestamp;
            }
        
            //read stored runs if any
            let mc = PullRunsFromDisk(messageQueue: messageQueue)
            //ignore runs from outside my scope
            mc.initialLocation = locMessage;
            mc.getWithinArea = gwa; //self.getWithinArea;
            mc.name = "PullRunsFromDisk"
            mc.myID = "PullRunsFromDisk"
            mc.myCategory = objectCategoryTypes.uniqueServiceProvider
        
            mc._initialize();
            scheduler.addObject(oID: mc.myID, o: mc);
            
            self.mapDataProviderInitialized = true;
            
            mc.scanForRuns()
        
        }
        
    }
    
    func addRunCache (){
        //map functions need run cache
        if let runcache = storage.getObject(oID: "runCache") as! RunCache?  {
            
        } else {
            let runcache = RunCache( messageQueue : nil );
            //mapCombiner.myID = "mapCombiner";
            //mapCombiner.name = "mapCombiner";
            //mapCombiner.myCategory = objectCategoryTypes.generic
            //mapCombiner._pulse(pulseBySeconds: 600);
            //mapCombiner.initialLocation = locMessage;   //make it look at the right place
            //mapCombiner.getWithinArea = self.getWithinArea //
            runcache._initialize()
            let tta = scheduler.addObject(oID: runcache.myID, o: runcache);
            
            let tt = 1;
        }
        
    }
    
    func addSnapCache (){
        
        //map functions need run cache
        if let snapcache = storage.getObject(oID: "snapshotCache") as! SnapshotCache?  {
            
        } else {
            let snapcache = SnapshotCache( messageQueue : nil );
            //mapCombiner.myID = "mapCombiner";
            //mapCombiner.name = "mapCombiner";
            //mapCombiner.myCategory = objectCategoryTypes.generic
            //mapCombiner._pulse(pulseBySeconds: 600);
            //mapCombiner.initialLocation = locMessage;   //make it look at the right place
            //mapCombiner.getWithinArea = self.getWithinArea //
            snapcache._initialize()
            let tta = scheduler.addObject(oID: snapcache.myID, o: snapcache);
            
            let tt = 1;
        }
        
    }
}
