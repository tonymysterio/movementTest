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


class liveRunStreamListener : BaseObject  {
    
    var processing = false;
    var lastProcessedBuffer = 0;
    var totalPassedBuffers = 0;
    var totalSuccessfullBuffers = 0;
    var totalParsedObjects = 0 ;
    var maxBuffers = 10;
    
    let queue = DispatchQueue(label: "liveRunStreamListener", qos: .utility)
    var currentRun : Run?
    
    func _initialize () -> DROPcategoryTypes? {
        
        myCategory = objectCategoryTypes.locationlistener
        self.name = "liveRunStreamListener"
        self.myID = "liveRunStreamListener"
        self.myCategory = objectCategoryTypes.locationlistener
        
        self.myHibernationStrategy = hibernationStrategy.persist  //dont hibernate
        self.myMemoryPressureStrategy = memoryPressureStrategy.persist //dont care
        
        //disappears
        _pulse(pulseBySeconds: 6000000)
        
        LocationLoggerMessageObserver.subscribe
            { locationMessage in
                self.locationMessageGotFromLocationLogger(lm : locationMessage)
                
        }
        
        return nil
        
    }
    
    func simplifyRun ( run : Run ) -> [CLLocationCoordinate2D]? {
        
        
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
    
    func prime (user : Player) {
        
        let startTime =  Date().timeIntervalSince1970
        
        let mid = startTime;
        //let clan = "camphastur"
        let geoHash  = "123"
        let ver = "z.0"
        
        let run = Run(missionID: mid, user: user.name, clan: user.clan, geoHash: geoHash, version: ver, hash: "", startTime: startTime, closeTime: 0, coordinates: [])
        
        currentRun = run
        
        
    }
    
    func primeWithRun ( run : Run ) -> Bool {
        
        //when pulling a incomplete run, prime 
        //runrecorderjunction currentRunReceived
        
        //check if run is not garbage data
        
        currentRun = run
        
        return true;
        
    }
    
    func locationMessageGotFromLocationLogger (lm : locationMessage) {
        
        //stuff that comes from observer. location logger sends me these via an observable
        //debounce here if necessary
        
        addRunCoordinate(timestamp: lm.timestamp, lat: lm.lat, lon: lm.lon)
        
    }
    
    func addRunCoordinate ( timestamp : Double , lat : CLLocationDegrees , lon : CLLocationDegrees) -> DROPcategoryTypes? {
        
        if currentRun == nil {
            if let pl = playerRoster.getPlayer(name: "samui@hastur.com") {
                prime(user : pl )
                
            }
        }
        
        guard let inse = currentRun?.addCoordinate(coord: coordinate(timestamp: timestamp, lat: lat, lon: lon)) else {
            return DROPcategoryTypes.duplicate
        }
        
        _pulse(pulseBySeconds: 16000)   //more listeningu time_pulse(pulseBySeconds: 16000)   //more listeningu time
        
        
        //maybe the map is listening to display my run
        //maybe runRecorderJunction has a currentRunSaver for us to throw this to storage
        
        //runAreaProgressObserver.update(currentRun!)     //
        
        if !(currentRun?.isClosed())! {
            
            runAreaProgressObserver.update(currentRun!)
            return nil
        }
        
        //we have a closed run, tell somebody to save the daattum
        
        //somebody might be observing this. ui, runRecorderJunction
        
        runAreaCompletedObserver.update(currentRun!)
        
        return nil
    }
    
    override func _LISTEN_extend(o: internalMessage) -> DROPcategoryTypes? {
        
            switch o.o {
            //the following creates the following variables for the scope
            case let .LocationMessage(type, oCAT, oID, timestamp, lat, lon):
                
                //26.12.2017 THIS IS ALL DEPRECATED. get the data thru an observable
                
                print (" \(o.from) run message. \(type) drowning with daatta. ")
                addRunCoordinate(timestamp: timestamp, lat: lat, lon: lon)
                
               
                //loc message! wait for the next one
                _ = self._pulse(pulseBySeconds: 600000 )
                
            default:
                break
                
            }
            
            
            
            
            return nil
        
    }   //end of listen extend
    
    
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        
        
        return nil
        
    }
    
    //persisting objects need hibernate extend
    override func _hibernate_extend () -> DROPcategoryTypes? {
        
        if self.terminated { return DROPcategoryTypes.terminating }
        self._pulse(pulseBySeconds: 1000000)    //keep me going
        
        return DROPcategoryTypes.persisting
    }
    
    
    
}



