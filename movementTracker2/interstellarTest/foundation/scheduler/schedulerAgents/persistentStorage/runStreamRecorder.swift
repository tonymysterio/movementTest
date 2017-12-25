//
//  timewaster.swift
//  interStellarTest
//
//  Created by sami on 2017/07/04.
//  Copyright © 2017年 pancristal. All rights reserved.
//

//25.11.2017 dont care about dropping
//maybe talk to debugger about what erreurs happen

import Foundation
import Disk

class RunStreamRecorder : BaseObject  {
    
    //this can save codable structs
    //keep the reader separate for now
    
    var processing = false;
    var lastProcessedBuffer = 0;
    var totalPassedBuffers = 0;
    var totalSuccessfullBuffers = 0;
    var totalParsedObjects = 0 ;
    var maxBuffers = 10;
    
    let queue = DispatchQueue(label: "runStreamRecorderQueue", qos: .utility)
    let path = "runData"
    
    func _initialize () -> DROPcategoryTypes? {
        
        myCategory = objectCategoryTypes.uniqueServiceProvider  //only one file accessor at a time
        self.name = "runStreamRecorder"
        self.myID = "runStreamRecorder"
        self.myCategory = objectCategoryTypes.uniqueServiceProvider
        
        //disappears
        _pulse(pulseBySeconds: 6000000)
        
        //if for some reason we cannot store to disk, give this
        //DROPcategoryTypes.serviceNotAvailable
        
        //if disk space is low, return
        //DROPcategoryTypes.lowDiskspace
        
        return nil
        
    }
    
    func storeRun (run : Run ) {
        
        //just store a run. its up to the app to create its Runs struct and query from there
        //anyway keep Runs out of global object and just pass the struct to map component / stats
        //what ever that needs the runs object
        
        //store all the runs on all the clients?// hash for runs?
        
        //replicating runs:
        //filter by locality, exchange hashes
        //proof of stake = amount of runs done, exchanged, bandwidth given
        
        //hash a list of transactions, how much da
        
        self.startProcessing()
        
        do {
            let fname = path + "/" + run.hash + ".json"
            try Disk.save(run, to: .caches, as: fname)
            
            print("storing captured run \(fname) ")
            
            //on successfull storage
            self._pulse(pulseBySeconds: 120)    //expect next write in a few mins
            self.finishProcessing()
            
        } catch {
            
            //maybe page run recorder junction
            self._pulse(pulseBySeconds: 120)
            self.finishProcessing()
        }
        
        
        
    }   //storeRun
    
    
    func storeCurrentRun (run : Run ) {
    
        //store current run
        //if a current run exists, just overwrite it with no mercy
        self.startProcessing()
        
        do {
            let fname = "currentRun/" + run.hash + ".json"
            try Disk.save(run, to: .caches, as: fname)
            
            self._pulse(pulseBySeconds: 120)
            
            self.finishProcessing()
            //on successfull storage
            
        } catch {
            
            self._pulse(pulseBySeconds: 120) 
            self.finishProcessing()
            
        }
        
        
        
    
    }
    
    override func _LISTEN_extend(o: internalMessage) -> DROPcategoryTypes? {
        
        switch o.o {
        //the following creates the following variables for the scope
        case let .RunMessage(type, oCAT, oID, run) :
            
            print (" \(oCAT): \(oID) RunMessage. \(type) Oh dear. ")
            
            //loc message! wait for the next one
            _ = self._pulse(pulseBySeconds: 60 )
            
            queue.async {
                
                //self.startProcessing() NOT COOL, in case of an error
                self.storeRun(run: run)
                //self.finishProcessing()
                //self.simplifyRun(run: run)
            }
            
        default:
            
            break
            
        }
        
        
        
        
        return nil
        
    }   //end of listen extend
    
    
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        //maybe give a list of hits and misses in saving
        
        //what is schedulers strategy towards failed file puts?
        //
        
        return nil
        
    }
    
    
    
}



