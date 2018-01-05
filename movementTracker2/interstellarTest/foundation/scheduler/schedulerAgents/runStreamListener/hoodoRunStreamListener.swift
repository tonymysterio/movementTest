//
//  timewaster.swift
//  interStellarTest
//
//  Created by sami on 2017/07/04.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class hoodoRunStreamListener : BaseObject  {
    
    //general PLACE to keep our runs? unwise? mapCombiner has its own copy of the same data?
    //run dataIO junction
    
    var processing = false;
    var lastProcessedBuffer = 0;
    var totalPassedBuffers = 0;
    var totalSuccessfullBuffers = 0;
    var totalParsedObjects = 0 ;
    var maxBuffers = 10;
    
    let queue = DispatchQueue(label: "hoodoRunCleanerQueue", qos: .utility)
    var unprocessedRuns = [Run]()
    var processedRuns = [Run]()
    var runs = Runs();
    
    func _initialize () -> DROPcategoryTypes? {
        
        
        myCategory = objectCategoryTypes.locationlistener
        self.name = "hoodoRunStreamListener"
        self.myID = "hoodoRunStreamListener"
        self.myCategory = objectCategoryTypes.locationlistener
        
        if self.isLowPowerModeEnabled() {
            //dont allow map combining on low power mode
            //
            self._teardown();
            return DROPcategoryTypes.lowBattery;
            
        }
        
        //disappears
        _pulse(pulseBySeconds: 6000000)
        
        runReceivedObservable.subscribe
            { run in
                self.addRun( run : run )
                
        }
        
        
        return nil
        
    }
    
    func addRun ( run : Run ) -> DROPcategoryTypes?  {
        
        //stuff can come from jsonStreamReader or pullRunsFromDisk
        
        
        return nil
    }
    
    func simplifyRun ( run : Run ) -> [CLLocationCoordinate2D]? {
        
        if let sor = runs.allSorted() {
            
            let upc = sor.o.map{ $0.missionID }
            print (upc)
            
        
        }
        if let dis = runs.getWithinArea(lat: 24.200481, lon: 65.822289999999995, distanceInMeters: 1000000) {
            
            if let locNames = dis.readUniqueUsers() {
                print ("dist filtered names")
                print (locNames)
                
            }
            
            
        }
        if let unius = runs.readUniqueUsers(){
            print(unius)
        }
        
        if let unics = runs.readUniqueClans(){
            print(unics)
        }
        //24.200481
        //65.822289999999995
        var points : [CLLocationCoordinate2D] = []
        for co in run.coordinates {
            
            points.append(CLLocationCoordinate2D( latitude: CLLocationDegrees(co.lon), longitude: CLLocationDegrees(co.lat) ))
            
        }
        
        let tolerance : Float = 0.001 //to 5.0
        let simplified = SwiftSimplify.simplify(points, tolerance: tolerance, highQuality: false)
        
        
        print(points.count)
        print(simplified.count)
        return points
    }
    
    override func _LISTEN_extend(o: internalMessage) -> DROPcategoryTypes? {
        
        switch o.o {
        //the following creates the following variables for the scope
        case let .RunMessage(type, oCAT, oID, run) :
        
            print (" \(oCAT): \(oID) RunMessage. \(type) Oh dear. ")
            
            //loc message! wait for the next one
            _ = self._pulse(pulseBySeconds: 60 )
            
            queue.async {
                if self.runs.append(run: run) {
                    self.unprocessedRuns.append(run)
                    
                } else {
                    //
                    print("BS run came in, fuck it")
                }
                
                //nasty unfiltered run to fly to runDataIOjunction that saves it to disk
                runStreamReaderDataArrivedObserver.update(run);
                //also tell mapcombiner. it will filter stuff outside its area
                //runReceivedObservable.update(run);
                self.simplifyRun(run: run)
            }
            
        default:
            
            break
            
        }
        
        
        
        
        return nil
        
    }   //end of listen extend
    
    
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        //should we do this at listener level. listen_extend DOES NOT CONTAIN anything vital
        //just ignore the request with a DROP, the request will come again if its important
        if unprocessedRuns.count != 0 {
            
            self.startProcessing()
            
            _pulse(pulseBySeconds: 30)
            if let nirg = self.simplifyRun(run: unprocessedRuns.first!) {
                
                _pulse(pulseBySeconds: 60)
            }
            
            queue.async {
                
                
                self.unprocessedRuns.remove(at: 0)
                //self.simplifyRun(run: run)
            }
            
            self.finishProcessing()
            
        }
        
        return nil
        
    }
    
    
    
}


