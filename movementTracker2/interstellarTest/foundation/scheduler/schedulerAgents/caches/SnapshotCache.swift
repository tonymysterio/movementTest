//
//  SnapshotCache.swift
//  movementTracker2
//
//  Created by sami on 2018/01/05.
//  Copyright © 2018年 pancristal. All rights reserved.
//

import Foundation
import Interstellar
//import GEOSwift
import MapKit
import Disk

struct snapshotContainer {
    
    var list = [mapSnapshot]();
    var dirtySnaps = Set<String>();
    
    mutating func dirtyApplicableWithNewRunData ( lat : CLLocationDegrees , lon: CLLocationDegrees , hash : String , getWithinArea : Double ) -> [String]? {
        
        //new run has arrived. see if it applies to the snapshot range
        //dirty the snapshot if this is new data for it
        //the snapshots contain .hashes of runs that were fed to the snap
        //not caring about if they got included or not
        if list.count == 0 { return nil; }
        
        if let sreg = self.snapsInRegion(lat: lat, lon: lon, getWithinArea: getWithinArea) {
            var dirtyIDs = [String]();
            for f in sreg {
                
                if f.hashes.contains(hash) {
                    continue;   //this is already here
                }
                dirtyIDs.append(f.id);
                dirtySnaps.insert(f.id);
            }
            
            if dirtyIDs.count == 0 { return nil }
            return dirtyIDs;
        }
        
        return nil;
    }
    
    func snapsInRegion ( lat : CLLocationDegrees, lon : CLLocationDegrees , getWithinArea : Double ) -> [mapSnapshot]? {
        
        
        //var cachesnapshotContainergrees = 0
        //var lon : CLLocationDegrees = 0
        
        var c = [mapSnapshot]()
        
        let location1 = CLLocation(latitude: lat, longitude: lon)
        
        for i in list {
            
            let location2 = CLLocation(latitude: i.lat, longitude: i.lon)
            let d = location1.distance(from: location2)
            //if d == 0 { continue; }
            if d > getWithinArea {
                    continue;
                }
                
            c.append(i);
            
        }   //list
        
        if c.count == 0 { return nil; }
        
        return c;
        
    }   //snapsInRegion
    
    mutating func append ( snap : mapSnapshot) {
        
        guard let closest = self.snapsInRegion(lat: snap.lat, lon: snap.lon, getWithinArea: snap.getWithinArea) else {
            
            list.append(snap);
            return;
        }
        
        //we have a collection of deprecating snaps
        
        for f in closest
        {
            self.dirtySnaps.insert(f.id)    //purge dirty snaps
        }
        
        list.append(snap);
    }
    
}



class SnapshotCache : BaseObject  {
    
    let ioQueue = DispatchQueue(label: "SnapshotCacheIOQueue", qos: .utility)
    let dataQueue = DispatchQueue(label: "SnapshotCacheDataQueue", qos: .utility)
    let path = "runCache" //runData"
    //dont store runs here
    var cache = snapshotContainer();
    var cacheIsDirty = false;
    var getWithinArea : Double = 0;
    
    var lastInsertTimestamp = Date().timeIntervalSince1970
    
    func _initialize () -> DROPcategoryTypes? {

        self.name = "snapshotCache"
        self.myID = "snapshotCache"
        self.myCategory = objectCategoryTypes.cache;
        
        self.myHibernationStrategy = hibernationStrategy.persist  //dont hibernate
        self.myMemoryPressureStrategy = memoryPressureStrategy.purgeCaches  //release memory thru _purge
        
        
        //disappears
        _pulse(pulseBySeconds: 60)
        
        //read cache file from disk
        
        
        //if for some reason we cannot store to disk, give this
        //DROPcategoryTypes.serviceNotAvailable
        
        //if disk space is low, return
        //DROPcategoryTypes.lowDiskspace
        
        
        
        //filter irrelevant runs by distance
        mapSnapshotObserver.subscribe{ snapshot in
            //mapCombiner is finished with a snapshot
            self.addSnapshot( snap : snapshot )
            
        }
        
        //pullRunsFromDisk also shouts here
        runReceivedObservable.subscribe{ run in
            
            //disk reader vibes with this
            
            self.addRun( run : run )
            
            
        }
        
        return  nil
    }
    

    override func _housekeep_extend() -> DROPcategoryTypes? {
    
        _pulse(pulseBySeconds: 6000); //keep me alive
        return nil;
    
    }

    //persisting objects need hibernate extend
    override func _hibernate_extend () -> DROPcategoryTypes? {
    
        if self.terminated { return DROPcategoryTypes.terminating }
        self._pulse(pulseBySeconds: 1000000)    //keep me going
    
        return DROPcategoryTypes.persisting
    }

    override func _purge ( backPressure : Int ) -> Int {
    
        //default purge. all objects obey to purge except .debugger, .uniqueServiceProvider
        if myCategory == objectCategoryTypes.debugger { return backPressure }
        if myCategory == objectCategoryTypes.uniqueServiceProvider { return backPressure }
    
        //get flushing the caches
    
        return backPressure;
    
    }
    
    func addSnapshot ( snap : mapSnapshot ) {
        
        dataQueue.sync (){
            
            self.cache.append( snap: snap)
            
        }
        
    }
    
    func getApplicableSnapshot ( lat : CLLocationDegrees, lon : CLLocationDegrees , getWithinArea : Double) -> mapSnapshot? {
        
        self.getWithinArea = getWithinArea; //runs incoming need this too
        
        if let closest = self.cache.snapsInRegion(lat: lat, lon: lon, getWithinArea: getWithinArea) {
            
            var gSna = [mapSnapshot]();
            
            for i in closest {
                if self.cache.dirtySnaps.contains(i.id) {
                    continue;
                }
                let sizeDiff = getWithinArea - i.getWithinArea;
                
                if sizeDiff < 2000 {
                    //bigger view, more to stuff, bigger like 2km bigger
                    gSna.append(i)
                }
                
                
            }
            
            
            if gSna.count == 0 {
                return nil;
                
            }
            
            return gSna.last;   //heh heh, the last one is the best one
            
        }
        
        return nil;
        
    }
    
    
    func addRun ( run: Run ) {
        
        //dirty applicable caches, if this run is missing from snapshot
        if let loca = Geohash.decode(run.geoHash) {
            
            if let  dirty = self.cache.dirtyApplicableWithNewRunData(lat : loca.latitude, lon : loca.longitude, hash: run.hash, getWithinArea: self.getWithinArea ) {
                self.cacheIsDirty = true;
                print("SNAPCACHE addRun dirtied snapshots  \(self.getWithinArea)");
            } else {
                if self.cacheIsDirty {
                    self.cacheIsDirty = false;
                }
            }
         }
        
        
        
    }

}
