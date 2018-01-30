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
        
        //let junction to do this so logic keeps in one place
        
        /*runAreaProgressObserver.subscribe { run in
            
            DispatchQueue.global(qos: .utility).async {
                self.CommitOfCurrentRun( run : run )
            }
        }*/
        
        
        return nil
        
    }
    
    func CommitOfCurrentRun ( run: Run ) {
        
        //save current run
        if self.isProcessing {
            
            return
            
        }
        
        
        
        
        let filename = self.path + "/currentRun.json";
        writeQueue.sync {
            
            self.startProcessing()
            
            do {
                try Disk.save(run, to: .applicationSupport, as: filename )
                
                self.lastInsertTimestamp = Date().timeIntervalSince1970
                
                //do not observe run closes here
                //run dataIO junction should take care of this
                
                /*if !run.isClosed() {
                    
                    
                    _pulse(pulseBySeconds: 600)  //expect more data to follow
                    
                }   else {
                    
                    runAreaCompletedObserver.update(run)
                    self.finishProcessing()
                    //runStreamRecorder throws this to disk
                    //self.FinalCommitOfCurrentRun( run : run )
                    return
                    //_pulse(pulseBySeconds: 1)  //get rid of this item as its done its job
                    
                }*/
                
                self.finishProcessing()
                
            } catch {
                // ...
                //cannot write for some reason
                
                self.finishProcessing()
                _pulse(pulseBySeconds: 600)
                
            }
            
            
        }
        
    }   //commit of current run
    
    func CommitOfCurrentBorkedRun ( run: Run ) {
        
        //save current run
        if self.isProcessing {
            
            return
            
        }
        
        let lat = run.coordinates.last!.lat
        let lon = run.coordinates.last!.lon
        
        let nameGeo = Geohash.encode(latitude: lat, longitude: lon)
        let filename = "borkedRun/"+nameGeo+".json"
        
        writeQueue.sync {
            
            self.startProcessing()
            
            do {
                try Disk.save(run, to: .applicationSupport, as: filename )
                
                self.lastInsertTimestamp = Date().timeIntervalSince1970
                
                self.finishProcessing()
                
            } catch {
                // ...
                //cannot write for some reason
                
                self.finishProcessing()
                _pulse(pulseBySeconds: 600)
                
            }
            
            
        }
        
    }   //commit of currentBorked run
    
    //persisting objects need hibernate extend
    override func _hibernate_extend () -> DROPcategoryTypes? {
        
        if self.terminated { return DROPcategoryTypes.terminating }
        self._pulse(pulseBySeconds: 1000000)    //keep me going
        
        return DROPcategoryTypes.persisting
    }
    
    func ReadOfCurrentRun() {
        
        //fish out current run
        if self.isProcessing {
            
            return
            
        }
        _ = self.startProcessing()
       
        let filename = self.path + "/currentRun.json";
        //this will crash
        //readQueue.sync (){
            
            if let data = try? Disk.retrieve(filename, from: .applicationSupport, as: Data.self) {
                
                if let j = String(data:data, encoding:.utf8) {
                    let decoder = JSONDecoder()
                    if let run = try? decoder.decode(Run?.self, from: j.data(using: .utf8)!) {
                        
                        print (run!.coordinates.count)
                        print("ReadOfCurrentRun: finished scanning files")
                        
                        if !run!.isValid {
                            
                            //runrecoder junction notify of illegal run objects when pulling from disk,meshnetting
                            print(#function + "borked current run received")
                            
                            borkedRunReceivedObserver.update(run!)
                            _ = self._teardown();   //not needed anymore
                            
                            return;
                            
                        }
                        
                        currentRunReceivedObserver.update(run!)
                    }
                }
                        
                
                
                //readQueue.sync {
                    
                    //let ruru = run! as Run;
                    //let t = run?.spikeFilteredCoordinates()
                    //tell runRecorderJunction that we are continuing from a run
                    //let tt = run?.totalDistance()
                    //let ttt = run?.isClosed()
                
                    
                //}
                
                _pulse(pulseBySeconds: 600)
                
                self.finishProcessing();
                
                if !self.isProcessing {
                    
                    //get rid of me. runrecorderjunction will wake me up sometime
                }
                
                
                return
                
                
            } else {
                
                self.finishProcessing();
                return
                
            }
            
        
        
        
    }
    
}

