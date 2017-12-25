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

var runReceivedObservable = Observable<Run>()



class PullRunsFromDisk: BaseObject  {

    let queue = DispatchQueue(label: "PullRunsFromDiskQueue", qos: .utility)
    let path = "runData"
    //dont store runs here
    
    //pull from disk
    //send with runReceivedObservable¥

    //recipients include mapCombiner (make map)
    //runsListView
    //kill this when finished (no caching here now)
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
            
            
            guard let files = try? Disk.retrieve(self.path, from: .caches, as: [Data]) else  {
                //no files found
                self.finishProcessing()
                return
            }
        
            for i in files {
                if let j = String(data:i, encoding:.utf8) {
                    
                    let decoder = JSONDecoder()
                
                    if let run = try! decoder.decode(Run?.self, from: i) {
                    
                        //send to mapCombiner , hoodoRunStreamListener
                        print (run.coordinates.count)
                        runReceivedObservable.update(run)
                        self._pulse(pulseBySeconds: 2)
                    }
                
                }
            
            }
        
            self.finishProcessing()
        
        }   //and async operazione
        
        
    }
}
