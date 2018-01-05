import Foundation
import Interstellar
//import GEOSwift
import MapKit
//import Disk

struct RunCacheDisk : Codable {
    var list = [String: Run]()
    var dirty = false;
    
    //var path = "runCache/runCach.json"
    mutating func append (run : Run) {
        
        list[run.hash] = run;
        dirty = true;
        
    }
    
    func GetRun ( hash: String) -> Run? {
        
        guard let r = list[hash] else {
            return nil;
        }
        return r;
    }
    
    mutating func cachedHashes () -> Set<String>? {
        
        var c = Set<String>()
        for i in list {
            
            c.insert(i.value.hash)
        }
        
        if c.count == 0 { return nil; }
        dirty = false;
        return c;
        
    }
    
    mutating func runsInRegion ( lat : CLLocationDegrees, lon : CLLocationDegrees , getWithinArea : Double ) -> Set<String>? {
        
        
        //var lat : CLLocationDegrees = 0
        //var lon : CLLocationDegrees = 0
        
        var c = Set<String>()
        let location1 = CLLocation(latitude: lat, longitude: lon)
        
        for i in list {
        
            if let loca = Geohash.decode(i.value.geoHash) {
            
                let location2 = CLLocation(latitude: loca.latitude, longitude: loca.longitude)
            
                let d = location1.distance(from: location2)
                if d == 0 { continue; }
                if d > getWithinArea {
                    continue;
                }
            
                c.insert(i.value.hash)
            }
            
        }   //list
        
        if c.count == 0 { return nil; }
        dirty = false;
        return c;
        
    }   //runsInRegion
    
}

class RunCache : BaseObject  {
    
    let ioQueue = DispatchQueue(label: "RunCacheIOQueue", qos: .utility)
    let dataQueue = DispatchQueue(label: "RunCacheDatQueue", qos: .utility)
    let path = "runCache" //runData"
    //dont store runs here
    var cache = RunCacheDisk()
    
    var lastInsertTimestamp = Date().timeIntervalSince1970

    func _initialize () -> DROPcategoryTypes? {
        
        //myCategory = objectCategoryTypes.uniqueServiceProvider  //only one file accessor at a time
        self.name = "runCache"
        self.myID = "runCache"
        self.myCategory = objectCategoryTypes.cache
        
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
        
        //pullRunsFromDisk also shouts here
        runReceivedObservable.subscribe{ run in
            
            //disk reader vibes with this
            
            self.addRun( run : run )
            
        }
        
        //hoodoRunStreamListener pages us when it reads a run from stream etc
        //maybe do this only when we have written to disk
        
        /*runStreamReaderDataArrivedObserver.subscribe
            { run in
                self.addRun( run : run )
                
        }*/
        
        
        
        return nil
        
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
    
    func addRun ( run : Run ) {
        
        
        self.dataQueue.sync { [weak self] in
            
            cache.append(run: run)
            
        }
        
    }   //end addRun
    
    func getRun ( hash : String ) -> Run? {
        
        return cache.GetRun(hash:hash)
        
    }
    
    func cachedHashes () -> Set<String>? {
        
        //somebody requests for hashes via direct call to me
        return cache.cachedHashes()
        
    }
    
    func runsInRegion ( lat : CLLocationDegrees, lon : CLLocationDegrees , getWithinArea : Double ) -> Set<String>? {
    
        return cache.runsInRegion(lat:lat,lon: lon,getWithinArea: getWithinArea )
    
    }
    
    //dont disk cache runs. they just take too much space
    //plus you have to read them from disk again anyways
    
    /*func primeCacheFromDisk () {
        
        
        let filename = self.path + "/currentRun.json";
        //this will crash
        //readQueue.sync (){
        
        if let run = try? Disk.retrieve(filename, from: .caches, as: Run?.self) {
        
    }*/

}
