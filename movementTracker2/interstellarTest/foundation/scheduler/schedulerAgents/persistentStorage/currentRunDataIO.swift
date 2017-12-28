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

//var runReceivedObservable = Observable<Run>()



class CurrentRunDataIO: BaseObject  {
    
    let readQueue = DispatchQueue(label: "currentRunDataIOReadQueue", qos: .utility)
    let writeQueue = DispatchQueue(label: "currentRunDataIOReadQueue", qos: .utility)
    var lastInsertTimestamp = Date().timeIntervalSince1970
    let path = "currentRun"
    //filter runs by area eventually
    var initialLocation = locationMessage( timestamp : 0 , lat : 65.822299, lon: 24.2002689 )
    //dont store runs here
    var getWithinArea : Double = 3000;
    
    
    //pull from disk
    //send with runReceivedObservable¥
    
    //recipients include mapCombiner (make map)
    //runsListView
    //kill this when finished (no caching here now)
    func _initialize () -> DROPcategoryTypes? {
        
        myCategory = objectCategoryTypes.uniqueServiceProvider  //only one file accessor at a time
        self.name = "currentRunDataIO"
        self.myID = "currentRunDataIO"
        self.myCategory = objectCategoryTypes.uniqueServiceProvider
        
        self.myHibernationStrategy = hibernationStrategy.persist  //dont hibernate
        self.myMemoryPressureStrategy = memoryPressureStrategy.persist
        
        //disappears
        _pulse(pulseBySeconds: 60)
        
        //if for some reason we cannot store to disk, give this
        //DROPcategoryTypes.serviceNotAvailable
        
        //if disk space is low, return
        //DROPcategoryTypes.lowDiskspace
        
        //im listening to updates from
        //if I exist, i will commit no questions asked
        
        runAreaProgressObserver.subscribe { run in
            
            self.CommitOfCurrentRun( run : run )
            
        }
        
        
        return nil
        
    }
    
    func CommitOfCurrentRun ( run: Run ) {
        
        //save current run
        if self.isProcessing { return }
        
        let filename = self.path + "currentRun.json";
        writeQueue.sync {
            
            self.startProcessing()
            
            do {
                try Disk.save(run, to: .caches, as: filename )
                
                self.lastInsertTimestamp = Date().timeIntervalSince1970
                
                if !run.isClosed() {
                    
                    
                    _pulse(pulseBySeconds: 600)  //expect more data to follow
                    
                }   else {
                    
                    //runStreamRecorder throws this to disk
                    //self.FinalCommitOfCurrentRun( run : run )
                    return
                    //_pulse(pulseBySeconds: 1)  //get rid of this item as its done its job
                    
                }
                
                self.finishProcessing()
                
            } catch {
                // ...
                //cannot write for some reason
                
                self.finishProcessing()
                _pulse(pulseBySeconds: 600)
                
            }
            
            
        }
        
    }   //commit of current run
    
    
    func ReadOfCurrentRun() {
        
        //fish out current run
       
        
        //this will crash
        readQueue.sync (){
            
            
            
            guard let files = try? Disk.retrieve(self.path, from: .caches, as: [Data].self) else  {
                //no files found
                //self.finishProcessing()
                return
            }
            
            for i in files {
                if let j = String(data:i, encoding:.utf8) {
                    
                    let decoder = JSONDecoder()
                    
                    if let run = try! decoder.decode(Run?.self, from: i) {
                        
                        //ignore stuff outside my area
                        
                        //send to mapCombiner , hoodoRunStreamListener
                        print (run.coordinates.count)
                        print("ReadOfCurrentRun: finished scanning files")
                        
                        //tell runRecorderJunction that we are continuing from a run
                        currentRunReceivedObserver.update(run)
                        _pulse(pulseBySeconds: 600)
                        
                        if !self.isProcessing {
                            
                            //get rid of me. runrecorderjunction will wake me up sometime
                        }
                        
                    }
                    
                }
                
            }
            
            
            self.finishProcessing()
            
        }   //and async operazione
        
    }
    
}

