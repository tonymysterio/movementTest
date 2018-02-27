//
//  MapCombiner.swift
//  interStellarTest
//
//  Created by sami on 2017/11/25.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import Interstellar
//import GEOSwift
import MapKit

class StartAndEndpointsAnalysis : BaseObject  {
    
    let pullQueue = DispatchQueue(label: "PullRunsFromDiskQueue", qos: .utility)
    //put run manipulation to background in case it takes too long
    //at least we get a warning about why ios killed our app, too much cpu usage
    
    let runQueue = DispatchQueue(label: "runQueueManipulation", qos: .background)
    let path = "Library/Application support/" //runData"
    //dont store runs here
    var runs = Runs()
    var lastInsertTimestamp = Date().timeIntervalSince1970
    let combineAfterIntervalSecons = 1
    var filteringMode = mapFilteringMode.world  //throw everything in as default
    var initialLocation = locationMessage( timestamp : 0 , lat : 65.822299, lon: 24.2002689 )
    var Lat : CLLocationDegrees = 65.822299
    var Lon : CLLocationDegrees = 24.2002689
    var getWithinArea : Double = 15000; //zoomLevelInMeters
    
    var simplifyTolerance : Float = 0.0000591102 //good default, 394 turns into 166 pts
    var newDataForAnalysis = false;
    var analyzeSnapshotWithTimeout = true;
    //the invoker of mapCombiner asks for tolerance for this map view
    
    //pull from disk
    //send with runReceivedObservable¥
    
    //when we go to map page and need to see previous runs
    //start this component. wait . thats too late.
    //should this guy live long? its ok to be purged with heaps of runs, then read from disk again with pullRunsFromDisk
    //just pass a snapshot for the map to view then
    //only the map view needs this so prime this there?
    
    
    //hasTimeoutExpired
    //recipients include mapCombiner (make map)
    //runsListView
    //kill this when finished (no caching here now)
    
    //if we get a mapFilteringModeToggleObserver on mapViewJunction, junction calls my
    
    func mapZoomLevels (target : Double) -> Double {
        
        if target > 50000 { return 50000 }
        if target > 25000 { return 25000 }
        if target > 15000 { return 15000 }
        if target > 10000 { return 10000 }
        if target > 7000 { return 7000 }
        if target > 4999 { return 5000 }
        if target > 2999 { return 3000 }
        
        return 1500;
        
    }
    
    func setInitialLocation (loc : locationMessage) {
        
        let area = mapZoomLevels(target: self.getWithinArea);
        self.initialLocation = locationMessage(timestamp: area, lat: loc.lat, lon: loc.lon);
        
        
    }
    func _initialize () -> DROPcategoryTypes? {
        
        //myCategory = objectCategoryTypes.uniqueServiceProvider  //only one file accessor at a time
        //self.name = "mapCombiner"
        //self.myID = "mapCombiner"
        self.myCategory = objectCategoryTypes.mapCombiner
        
        //map viewcontroller is the only one who needs heaps of run data possibly
        /*if self.isLowPowerModeEnabled() {
         //dont allow map combining on low power mode
         //
         self._teardown();
         return DROPcategoryTypes.lowBattery;
         
         }*/
        
        //maybe be selective about combining modes
        
        
        //disappears
        _pulse(pulseBySeconds: 60)
        
        var hadCachedData = false;
        //prime my data from RunCache if such a thing is alive
        if let cache = storage.getObject(oID: "runCache") as! RunCache? {
            if let cachedRunHashesWithinArea = cache.runsInRegion(lat: initialLocation.lat, lon: initialLocation.lon, getWithinArea: self.getWithinArea) {
                
                //returns a set of hashes
                hadCachedData = true;
                //self.pullQueue.sync { [weak self] in
                let area = mapZoomLevels(target: self.getWithinArea);
                
                if cachedRunHashesWithinArea.count > 400 {
                    
                    let sirdalud = cache.runsInRegion(lat: initialLocation.lat, lon: initialLocation.lon, getWithinArea: area) ;
                }
                
                var hits = 0;
                for i in cachedRunHashesWithinArea {
                    if let run = cache.getRun(hash: i){
                        //if let ok = self.runs.append( run : run ) {
                        self.addRun(run: run);
                        hits = hits + 1;
                        //}
                        
                    }   //found in cache
                    
                }
                
                print ("run cache hits \(hits)");
                
                self.newDataForAnalysis = true;
                //}   //start fetching cached daatta
                
            }
        }   //end cache monstrosity
        
        if !hadCachedData {
            //cache is empty? no local data?
            //do a pull runs From Disk and populate the cache
            
        }
        
        
        //if for some reason we cannot store to disk, give this
        //DROPcategoryTypes.serviceNotAvailable
        
        //if disk space is low, return
        //DROPcategoryTypes.lowDiskspace
        
        
        
        //filter irrelevant runs by distance
        
        //pullRunsFromDisk also shouts here
        runReceivedObservable.subscribe{ run in
            //if crunching numbers, happily ignore what is coming in
            //there is another mapcombiner instance to handle the updates
            //page user via UI to refresh the map with new data in order to
            //lessen processing load
            
            if self.isProcessing { return }
            //DispatchQueue.global(qos: .utility).async {
            self.addRun( run : run )
            //}
        }
        
        //hoodoRunStreamListener pages us when it reads a run from stream etc
        runStreamReaderDataArrivedObserver.subscribe
            { run in
                
                if self.isProcessing { return }
                //DispatchQueue.global(qos: .utility).async {
                self.addRun( run : run )
                //}
        }
        
        if hadCachedData {
            return DROPcategoryTypes.readyImmediately   //map junction could ask me to crunch
            //numbers immediately based on the cache data
        }
        
        return nil
        
    }
    
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        //let the map comp die. next time we get a transmission of run data, we can start from fresh
        //self._pulse(pulseBySeconds: 60);    //stay alive
        if (analyzeSnapshotWithTimeout && !self.isProcessing) {
            
            //autocompile only when data has changed
            /*if self.runs.o.count>0 && self.newDataToAnalyze {
                if self.hasTimeoutExpired (timestamp : lastInsertTimestamp , timeoutInMs : 1){
                    //eager waiters of snapshots get candy
                    print("housekeep extend \(self.name) creating snap with timeout")
                    self.createSnapshot()
                }
            }*/
            
            
        }
        return nil
    }
    
    func closeEnoughTo ( locMessage : locationMessage ) -> Bool {
        
        //when trying to create a new mapCombiner, we might be asked are you already doing the job
        if self.terminated { return false; }
        
        let arDif = locMessage.timestamp - self.getWithinArea;
        //if the request is for a bigger chunk of the map, autolose
        if arDif > 1000 {
            
            return false;
        }
        
        let location1 = CLLocation(latitude: locMessage.lat, longitude: locMessage.lon)
        let location2 = CLLocation(latitude: initialLocation.lat, longitude: initialLocation.lon)
        
        let d = location1.distance(from: location2) as Double;
        
        //clearly outside my area
        if d > self.getWithinArea {
            return true;
        }
        
        
        
        return false;
        
    }
    
    func addRun ( run : Run ) {
        
        
        //TODO: if compiling a map, dont add this
        /*if self.isProcessing {
         return;
         }*/
        
        if !run.isValid {
            
            return
            
        }  //this might happen
        
        pullQueue.sync { [weak self] in
            
            var lat : CLLocationDegrees = 0
            var lon : CLLocationDegrees = 0
            
            //is this run in our visibilitee? if not, filter out
            //filter with geohash distance, dont reserve memory for stuff 1000km away
            let comGeoHash = run.computeGeoHash();
            //runStreamReaderDataArrivedObserver
            if let loca = Geohash.decode(comGeoHash) {
                
                lat = loca.latitude
                lon = loca.longitude
                
                let location1 = CLLocation(latitude: loca.latitude, longitude: loca.longitude)
                let location2 = CLLocation(latitude: initialLocation.lat, longitude: initialLocation.lon)
                
                let d = location1.distance(from: location2) as Double;
                if d == 0 { return  }
                if d > (self?.getWithinArea)! {
                    return;
                }
                
                //print(d);
            }
            
            if let ok = self?.runs.append( run : run ) {
                
                //process when time has passed
                //self?.lastInsertTimestamp = Date().timeIntervalSince1970
                //self?.newDataForSnap = true;  //flag we have new shit on the block
                //print("mapcombiner added run ")
                self?._pulse(pulseBySeconds: 10)
                
                //when mapCombiner finds something that is going to be displayed on the screen,
                //notify user with something, data is incoming!
                mapCombinerPertinentDataFound.update(locationMessage( timestamp : self!.getWithinArea , lat : lat, lon: lon ))
                //var mapCombinerPertinentDataFound = Observable<locationMessage>()
                
            }
            
            
        }   //end of pullQueue sync
        
        
        /*if !run.isClosed() {
         return;     //dont bother with non closed runs
         }*/
        
        
    }   //end addRun
    
    
}

