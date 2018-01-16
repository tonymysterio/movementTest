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

class MapCombiner : BaseObject  {
    
    let pullQueue = DispatchQueue(label: "PullRunsFromDiskQueue", qos: .utility)
    let runQueue = DispatchQueue(label: "runQueueManipulation", qos: .utility)
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
    let user = "samui@hastur.org"
    
    var simplifyTolerance : Float = 0.0000591102 //good default, 394 turns into 166 pts
    var compileSnapshotWithTimeout = true;
    var newDataForSnap = false;
    
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
                    var hits = 0;
                    for i in cachedRunHashesWithinArea {
                        if let run = cache.getRun(hash: i){
                            //if let ok = self.runs.append( run : run ) {
                                self.runs.append( run : run )
                                hits = hits + 1;
                            //}
                            
                        }   //found in cache
                        
                    }
                    
                    print ("run cache hits \(hits)");
                
                    self.newDataForSnap = true;
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
            DispatchQueue.global(qos: .utility).async {
                self.addRun( run : run )
            }
        }
        
        //hoodoRunStreamListener pages us when it reads a run from stream etc
        runStreamReaderDataArrivedObserver.subscribe
            { run in
                
                if self.isProcessing { return }
                DispatchQueue.global(qos: .utility).async {
                    self.addRun( run : run )
                }
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
        if (compileSnapshotWithTimeout && !self.isProcessing) {
            
            //autocompile only when data has changed
            if self.runs.o.count>0 && self.newDataForSnap {
                if self.hasTimeoutExpired (timestamp : lastInsertTimestamp , timeoutInMs : 1){
                    //eager waiters of snapshots get candy
                    self.createSnapshot()
                }
            }
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
        
        let d = location1.distance(from: location2)
        
        //clearly outside my area
        if d > self.getWithinArea {
            return true;
        }
        
        
        
        return false;
        
    }
    
    func addRun ( run : Run ) {
        
        //is this run in our visibilitee? if not, filter out
        //filter with geohash distance, dont reserve memory for stuff 1000km away
        var lat : CLLocationDegrees = 0
        var lon : CLLocationDegrees = 0
        
        if let loca = Geohash.decode(run.geoHash) {
            
            lat = loca.latitude
            lon = loca.longitude
            
            let location1 = CLLocation(latitude: loca.latitude, longitude: loca.longitude)
            let location2 = CLLocation(latitude: initialLocation.lat, longitude: initialLocation.lon)
            
            let d = location1.distance(from: location2)
            if d == 0 { return  }
            if d > self.getWithinArea {
                return;
            }
            
            //print(d);
        }
                
        if !run.isValid {
            return }  //this wont happen
        
        if !run.isClosed() {
            return;     //dont bother with non closed runs
        }
        
        self.pullQueue.sync { [weak self] in
            
            if let ok = self?.runs.append( run : run ) {
                
                //process when time has passed
                lastInsertTimestamp = Date().timeIntervalSince1970
                newDataForSnap = true;  //flag we have new shit on the block
                //print("mapcombiner added run ")
                self?._pulse(pulseBySeconds: 10)
                
                //when mapCombiner finds something that is going to be displayed on the screen,
                //notify user with something, data is incoming!
                mapCombinerPertinentDataFound.update(locationMessage( timestamp : self!.getWithinArea , lat : lat, lon: lon ))
                //var mapCombinerPertinentDataFound = Observable<locationMessage>()
                
            }
            
        }
        
    }   //end addRun
    
    func createSnapshot () -> DROPcategoryTypes? {
        
        //let point = Waypoint(WKT: "POINT(10 45)")
        //let polygon = Geometry.create("POLYGON((35 10, 45 45.5, 15 40, 10 20, 35 10),(20 30, 35 35, 30 20, 20 30))")
        let currentRunsCount = self.runs.o.count
        
        newDataForSnap = false;
        
        
        if self.isProcessing {
            return DROPcategoryTypes.busyProcessesing
            
        }
        
        if  currentRunsCount == 0 {
            return DROPcategoryTypes.serviceNotReady
            
        }
        
        print ("createSnapshot called with \(currentRunsCount)")
        self._pulse(pulseBySeconds: 5)    //give secs for the job
        
        //ignore further additions
        self.startProcessing()
        //data might appear after this,just copy the existing items and pass to createSnapshots
        self.runQueue.sync { [weak self] in
            //if self is lost, bugger off
            //https://www.swiftbysundell.com/posts/capturing-objects-in-swift-closures
            guard let strongSelf = self else {
                return
            }
            
            if let currentRuns = strongSelf.runs.getWithinArea(lat: strongSelf.initialLocation.lat,lon: strongSelf.initialLocation.lon,distanceInMeters: strongSelf.getWithinArea) {
                
                //pushes the snap output thru an observer if one gets produced
                strongSelf.createSnapshotFromRuns(runs: currentRuns , lat: initialLocation.lat,lon: initialLocation.lon, getWithinArea: strongSelf.getWithinArea )
                
            } else {
                print ("createSnapshot: no valid runs in this area out of \(strongSelf.runs.o.count) ")
                //no data with current location. let this guy TTL unless we get some data
                self?.finishProcessing()
                
            }
            
        }
        
        return nil
        
    }   //end create snacreateSnapshot
    
    func createSnapshotFromRuns ( runs : Runs , lat: CLLocationDegrees , lon: CLLocationDegrees , getWithinArea : Double ) {
        
        
        
        switch (self.filteringMode) {
            
        case (.world):
            self.createSnapshotFromRunsForWorld ( runs: runs , lat : lat, lon : lon , getWithinArea : getWithinArea )
        case (.personal):
            self.createSnapshotFromRunsForPersonal ( runs: runs )
            
        default: self.createSnapshotFromRunsForLocalCompetition ( runs: runs )
        }
        
    }
    
    func createSnapshotFromRunsForWorld ( runs : Runs , lat: CLLocationDegrees , lon: CLLocationDegrees , getWithinArea : Double ) {
        //its all there, put it into a stack
        
        
        print ("createSnapshotFromRunsForWorld called with distance filtered \(runs.o.count)")
        
        self._pulse(pulseBySeconds: 5)    //give secs for the job
        
        let r = runs.allSorted()
        var mapPolylineSet = [[CLLocationCoordinate2D]]()
        
        var simplifyTolerance = self.calculateSimplifyToleranceForView(getWithinArea: getWithinArea)
        var runHashes = Set<String>();
        
        //older areas on the background
        for i in r!.o {
            
            //let myPolyline = MKPolyline(coordinates: coords, count: coords.count)
            //make polylines
            //let tolerance : Float = 0.001 //to 5.0
            //the invoker of mapCombiner asks for tolerance for this map view
            
            if let fco = i.spikeFilteredCoordinates() {
                
                let simplifiedCoords = i.simplify(tolerance: simplifyTolerance )
                 mapPolylineSet.append(simplifiedCoords!)
                
            }
            
            //append also non included hashes so cache wont dirty a snap because something that
            //was not originally included happened again
            runHashes.insert(i.hash)
            
            //let coords = simplifiedCoords.map { CLLocationCoordinate2DMake($0.lon, $0.lat) }
            
            //let coords = i.coordinates.map { CLLocationCoordinate2DMake($0.lon, $0.lat) }
            //let myPolyline = MKPolyline(coordinates: coords, count: coords.count)
           
            
        }
        
        //do this in background queue
        let newSnap = mapSnapshot( coordinates : mapPolylineSet , filteringMode : self.filteringMode , lat : lat , lon: lon , getWithinArea : getWithinArea , hashes : runHashes , dirty : false,id :"msna"+String(Date().timeIntervalSince1970))
        
        /*let o : [MKPolyline]
        let filteringMode : mapFilteringMode //throw everything in as default
        let lat : CLLocationDegrees
        let lon : CLLocationDegrees
        let getWithinArea : Double */
        
        //let mapsnapshot cache listen to this and save the snap for future use
        //when new runs arrive from somewhere, the snap cache gets dirtied
        //if snap cache has no data, mapCombiner is called for rescue
        
        mapSnapshotObserver.update(newSnap) //mapView is listening
        
        self._pulse(pulseBySeconds: 5)    //give secs until going out
        
        self.finishProcessing();
        
        //self._finalize();   //discard me when a snap is done
        
    }
    
    func calculateSimplifyToleranceForView ( getWithinArea : Double ) -> Float {
        
        //get witin area 1000 - 50000m
        //0.0000591102 - 0.0002
        
        let gwStep : Float = (50000 - 1500) / 100
        let gwSpan = Float(getWithinArea) / gwStep;
        let gwSpanNeg : Float = 100 - gwSpan;
        
        let varia : Float = (0.0002 - 0.0000591102) / 100;
        let f : Float = varia * gwSpanNeg
        return f
    }
    
    func createSnapshotFromRunsForPersonal ( runs : Runs ) {
        guard let personalRuns = runs.readByUser(user: self.user) else {
            //notify about no personal runs?
            
            self.finishProcessing()
            self._pulse(pulseBySeconds: 300)    //live a bit longer
            return;
        }
    }
    
    func createSnapshotFromRunsForLocalCompetition ( runs : Runs ) {
        
        //pull clans out, then mix and macho
        
    }
    
    
    
    func changeFilteringMode ( filteringMode : mapFilteringMode ) {
        
        //might not be a good idea. run map combine with current filtering, then die?
        if self.isProcessing { return }
        self.filteringMode = filteringMode
        
    }
    
    func changeSimplifyTolerance ( tolerance : Float ) {
        
        if self.isProcessing { return }
        self.simplifyTolerance = tolerance
        
    }
    
}
