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



class PullRunsFromDisk: BaseObject  {

    let queue = DispatchQueue(label: "PullRunsFromDiskQueue", qos: .utility)
    let path = "runData"
    //filter runs by area eventually
    var initialLocation = locationMessage( timestamp : 0 , lat : 65.822299, lon: 24.2002689 )
    //dont store runs here
    var getWithinArea : Double = 3000;
    var myExhangedHashes = exchangedHashes()
    var initialPull = false;
    
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
        
        //disappears
        _pulse(pulseBySeconds: 60)
        
        //if for some reason we cannot store to disk, give this
        //DROPcategoryTypes.serviceNotAvailable
        
        //if disk space is low, return
        //DROPcategoryTypes.lowDiskspace
        
        return nil
        
    }
    
    
    func scanForRuns () {
        
        
        self.startProcessing()
        
        //this will crash
        queue.async (){
            
            let location1 = CLLocation(latitude: self.initialLocation.lat, longitude: self.initialLocation.lon)
            let area = self.getWithinArea
            
            guard let files = try? Disk.retrieve(self.path, from: .caches, as: [Data].self) else  {
                //no files found
                self.finishProcessing()
                return
            }
        
            for i in files {
                if let j = String(data:i, encoding:.utf8) {
                    
                    
                    
                    let decoder = JSONDecoder()
                
                    if let run = try! decoder.decode(Run?.self, from: i) {
                        
                        self.myExhangedHashes.insertForUser(user: run.user, hash: run.hash)
                        self.initialPull = true;
                        
                        self._pulse(pulseBySeconds: 2)
                        //ignore stuff outside my area
                        if let loca = Geohash.decode(run.geoHash) {
                            
                            let location2 = CLLocation(latitude: loca.latitude, longitude: loca.longitude)
                            let d = location1.distance(from: location2)
                            
                            if d == 0 { continue }
                            if d > area {
                                continue ;
                            }
                        }
                        
                        
                        //send to mapCombiner , hoodoRunStreamListener
                        print (run.coordinates.count)
                        
                        
                        runReceivedObservable.update(run)
                        
                    }
                
                }   //decipherable data
            
            }   //all data
            
            if (!self.myExhangedHashes.isEmpty()) {
                
                //peerDataProvider wants to know
                //peerDataExhanger wants to know
                peerDataProviderExistingHashesObserver.update(self.myExhangedHashes)
                
            }
            
            print("pullrunsfromdisk: finished scanning files")
            self.finishProcessing()
        
        }   //and async operazione
        
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
}
