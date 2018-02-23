//
//  pullRunsFromDisk.swift
//  interStellarTest
//
//  Created by sami on 2017/11/25.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import Disk
import Interstellar
import MapKit

var runReceivedObservable = Observable<Run>()


struct RunLoader {
    
    let filename : String
    let queue = DispatchQueue(label: "PullRunQueue", qos: .background)
    
    typealias Fsuccess = ( _ run : Run) -> Void
    typealias Ferror = ()  -> Void
    //let queue = DispatchQueue(label: "runLoaderQueue", qos: .background)
    
    func load( success: Fsuccess , error : Ferror )  {
        
        let falename = "runData/"+filename+".json";
        //queue.sync {
            
        
        if let run = try? Disk.retrieve(falename, from: .applicationSupport, as: Run.self) {
            
            /*if let j = String(data:data, encoding:.utf8) {
                let decoder = JSONDecoder()
                if let run = try? decoder.decode(Run?.self, from: j.data(using: .utf8)!) {
                    
                    //print(run);
                    let t = 1;
                    success(run!);
                
                } else {
                    
                    error();
                }
            }*/
            
            success(run)
            
        } else {
            
            error();
        }
        
        //}
        
    }   //end load
    
}

class PullRunsFromDisk: BaseObject  {

    let queue = DispatchQueue(label: "PullRunsFromDiskQueue", qos: .userInitiated)
    let path = "runData"
    //filter runs by area eventually
    var initialLocation = locationMessage( timestamp : 0 , lat : 65.822299, lon: 24.2002689 )
    //dont store runs here
    var getWithinArea : Double = 3000;
    var myExhangedHashes = exchangedHashes()
    var initialPull = false;
    var ignoredCachedHashes = Set<String>();
    var files = [RunLoader]();
    var filesPrimed = false;
    var filesPulling = false;
    //pull from disk
    //send with runReceivedObservable¥

    //recipients include mapCombiner (make map)
    //runsListView
    //kill this when finished (no caching here now)
    
    //TODO: caching
    //when cache is hit (with run hash), extend life by a reasonalbe amount of time
    //react to memory warning. flush cache
    
    
    func _initialize () -> DROPcategoryTypes? {
        
        
        
        myCategory = objectCategoryTypes.uniqueServiceProvider  //only one file accessor at a time
        self.name = "PullRunsFromDisk"
        self.myID = "PullRunsFromDisk"
        self.myCategory = objectCategoryTypes.uniqueServiceProvider
        
        /*if self.isLowPowerModeEnabled() {
            //dont allow map combining on low power mode
            //
            self._teardown();
            return DROPcategoryTypes.lowBattery;
            
        }*/
        
        //disappears
        _pulse(pulseBySeconds: 60)
        
        //if for some reason we cannot store to disk, give this
        //DROPcategoryTypes.serviceNotAvailable
        
        //if disk space is low, return
        //DROPcategoryTypes.lowDiskspace
        
        return nil
        
    }
    
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        //maybe give a list of hits and misses in saving
        
        //what is schedulers strategy towards failed file puts?
        if filesPrimed && !filesPulling {
            
            filesPulling = true;
            // Remove last item
            //let lastItem = a.removeLast()
            queue.async {
                self.getPulling();
            }
            
        }
        
        
        return nil
        
    }
    
    func getPulling () {
        
        
        var storedError: NSError?
        let downloadGroup = DispatchGroup()
        
        //self.startProcessing();
        
        for hash in self.files {
            
            if let cache = storage.getObject(oID: "runCache") as! RunCache? {
                
                if let rit = cache.getRun(hash: hash.filename){
                    continue;
                }
            }
            
            downloadGroup.enter()
            self.startProcessing();
            
            let r = hash.load(success: { (run) in
                
                
                
                
                //let ran = run;
                //poprint(ran);
                //let rvalid = run.isValid;
                //let rClosed = run.isClosed();
                    if (run.isValid && run.isClosed() ) {
                    
                        print(#function);
                        print("run.coordinates.count = \(run.coordinates.count)");
                        print("run.spikeFilteredCoordinates = \(run.spikeFilteredCoordinates()?.count)");
                        print("run.totalDistance = \(run.totalDistance())");
                        print("run.distanceBetweenStartAndEndSpikeFiltered = \(run.distanceBetweenStartAndEndSpikeFiltered())")
                        print("run.geohash = \(run.geoHash)");
                        print("run.computeGeoHash = \(run.computeGeoHash())");
                        
                        self.myExhangedHashes.insertForUser(user: run.user, hash: run.hash)
                        self.initialPull = true;
                    
                        self._pulse(pulseBySeconds: 2)
                        runReceivedObservable.update(run)
                    
                        print("run pulled \(run.hash) at \(run.geoHash) ")
                        
                        print (run.totalDistance());
                        //print("tit");
                        
                    }
                
                    self.finishProcessing()
                
                    downloadGroup.leave()
                }, error: {
                    
                    self.finishProcessing()
                    downloadGroup.leave()
                })
                            //PhotoManager.sharedManager.addPhoto(photo)
        }
        
        /*downloadGroup.notify(queue: DispatchQueue.main) { // 2
            completion?(storedError)
        }*/
        
    }
    
    func pullRunx ( filename : String ) {
        
        let filename = "runData/currentRun.json";
        //this will crash
        //readQueue.sync (){
        
        if let data = try? Disk.retrieve(filename, from: .applicationSupport, as: Data.self) {
            
            if let j = String(data:data, encoding:.utf8) {
                let decoder = JSONDecoder()
                if let run = try? decoder.decode(Run?.self, from: j.data(using: .utf8)!) {
                    
                }
            }
        }
        
        
    }
    
    func scanForRuns () {
        
        if filesPrimed { return }
        //let path =  String(describing: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first);
        //doing this from main queue
        //let fileManager = FileManager.default;
        self.startProcessing()
        
        var hadCachedData = false;
        if let cache = storage.getObject(oID: "runCache") as! RunCache? {
            if let cachedHashes = cache.cachedHashes() {
                self.ignoredCachedHashes = cachedHashes;
                
                if let cuha = cache.cachedUserHashes() {
                    
                    for i in cuha {
                        
                        self.myExhangedHashes.insertForUser(user: i[0], hash: i[1])
                        
                    }
                    //tell peer data provider what we got
                    peerDataProviderExistingHashesObserver.update(self.myExhangedHashes);
                }
                
            }
            
        }
        
        queue.async (){
        // Get contents in directory: '.' (current one)
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0];
        let luss : String = documentsURL.path + "/runData/";
        
        if let urlEncoded = luss.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            let url = URL(string: urlEncoded);
            
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: url! , includingPropertiesForKeys: nil)
                for i in fileURLs {
                    
                    let last4 = i.path.suffix(5);
                    if last4 == ".json" {
                        
                        let lim = i.path.split(separator: "/")
                        if let lam  = lim.last?.split(separator: ".") {
                            //print (lam[0]);
                            let luxor = String(lam[0]);
                            
                            if !self.ignoredCachedHashes.contains(luxor) {
                                let rloader = RunLoader(filename: luxor);
                                self.files.append(rloader) //just the filename part for Disk to read
                            }
                        }
                        
                        
                    }
                    
                }
                
                if self.files.count == 0 {
                    print("diskreader no new data found")
                    
                    self.finishProcessing();
                    self._teardown();
                }
                
                self.filesPrimed = true;
                self._pulse(pulseBySeconds: 60);
                self.finishProcessing();
                print (fileURLs);
                // process files
            } catch {
                //print("Error while enumerating files \(destinationFolder.path): \(error.localizedDescription)")
                print("diskreader no data found - bailing out")
                self.finishProcessing();
                self._teardown();
            }
            
        }
        
        //let url = URL(string: luss)
        }   //end async
        
        return;
        
        
        
        self.startProcessing()
        
        //var hadCachedData = false;
        if let cache = storage.getObject(oID: "runCache") as! RunCache? {
            if let cachedHashes = cache.cachedHashes() {
                self.ignoredCachedHashes = cachedHashes;
                
                if let cuha = cache.cachedUserHashes() {
                    
                    for i in cuha {
                        
                        self.myExhangedHashes.insertForUser(user: i[0], hash: i[1])
                        
                    }
                    //tell peer data provider what we got
                    peerDataProviderExistingHashesObserver.update(self.myExhangedHashes);
                }
                
            }
            
        }
        
        //this will crash
        queue.async (){
            
            let location1 = CLLocation(latitude: self.initialLocation.lat, longitude: self.initialLocation.lon)
            let area = self.getWithinArea
            
            guard let files = try? Disk.retrieve(self.path, from: .applicationSupport, as: [Data].self) else  {
            //guard let files = try? Disk.retrieve(self.path, from: .caches, as: [Data].self) else  {
                //no files found
                self.finishProcessing()
                return
            }
            //print(files);
            for i in files {
                
                //queue.async (){
                    
                    if let j = String(data:i, encoding:.utf8) {
                    
                    
                    
                    let decoder = JSONDecoder()
                
                    if let run = try! decoder.decode(Run?.self, from: i) {
                        
                        if (run.isValid || run.isClosed() ) {
                            
                        
                        self.myExhangedHashes.insertForUser(user: run.user, hash: run.hash)
                        self.initialPull = true;
                        
                        self._pulse(pulseBySeconds: 2)
                        runReceivedObservable.update(run)
                        
                        print("run pulled \(run.hash) at \(run.geoHash) ")
                            
                        } else {
                            
                            //print("ignored run at scan for runs disk");
                        
                        }
                        
                        
                        //ignore stuff outside my area
                        /*if let loca = Geohash.decode(run.geoHash) {
                            
                            let location2 = CLLocation(latitude: loca.latitude, longitude: loca.longitude)
                            let d = location1.distance(from: location2)
                            
                            if d == 0 { continue }
                            if d > area {
                                continue ;
                            }
                        }*/
                        
                        
                        //send to mapCombiner , hoodoRunStreamListener
                        //print (run.coordinates.count)
                        
                        
                        
                        
                    }
                
                }   //decipherable data
                    
                //}   //end async
            
            }   //all data
            
            if (!self.myExhangedHashes.isEmpty()) {
                
                //peerDataProvider wants to know
                //peerDataExhanger wants to know
                peerDataProviderExistingHashesObserver.update(self.myExhangedHashes)
                
            }
            
            print("pullrunsfromdisk: finished scanning files")
            self.finishProcessing()
        
        }   //and async operazione
        
        
    }
    
        
    func scanForRunHashes()  {
            
            //peerDataProvider wants to know
            //peerDataExhanger wants to know
            if (!self.myExhangedHashes.isEmpty()) {
                
                //peerDataProvider wants to know
                //peerDataExhanger wants to know
                peerDataProviderExistingHashesObserver.update(self.myExhangedHashes)
                return;
                
            }
            
            //no cache primed
            if self.isProcessing {
                
                //we are looking for data now, there will be a observer message
                return
                
            }
            
            self.scanForRuns()
            
            
        }   //end of scan run hashes
        
    
}
