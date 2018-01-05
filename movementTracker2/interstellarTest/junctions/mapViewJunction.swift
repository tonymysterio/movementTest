//
//  mapViewJunction.swift
//  interStellarTest
//
//  Created by sami on 2017/12/12.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import Interstellar

/*var runRecoderToggleObserver = Observable<Bool>()
var runAreaCompletedObserver = Observable<Run>()
var runAreaProgressObserver = Observable<Run>()
var runRecorderAbortObserver = Observable<Bool>()
var locationMessageObserver = Observable<locationMessage>()*/

//personal, world, localCompetition

//turn mapcombiner on off
var mapCombinerToggleObserver = Observable<Bool>()
//for setting simplification level
var mapCombinerToleranceObserver = Observable<Float>()

var mapFilteringModeToggleObserver = Observable<mapFilteringMode>()
var currentLocationMessageObserver = Observable<locationMessage>()
var mapSnapshotObserver = Observable<mapSnapshot>()
//map screen might need thi
var requestForMapCombiner = Observable<locationMessage>()
var requestForMapDataProvider = Observable<locationMessage>()

//when mapCombiner finds something that is going to be displayed on the screen,
//notify user with something, data is incoming!
var mapCombinerPertinentDataFound = Observable<locationMessage>()


class mapViewJunction {
    
    //var recording = false;
    //var myRecorderObjectID = "";
    //weak var myLocationTracker : LocationLogger?
    //weak var myLiveRunStreamListener : liveRunStreamListener?
    //weak var myPedometer : Pedometer?
    var getWithinArea : Double = 1500; //zoomLevelInMeters
    
    init () {
        
        //map functions need run cache
        if let cache = storage.getObject(oID: "runCache") as! RunCache?  {
            
        } else {
            let runcache = RunCache( messageQueue : nil );
            //mapCombiner.myID = "mapCombiner";
            //mapCombiner.name = "mapCombiner";
            //mapCombiner.myCategory = objectCategoryTypes.generic
            //mapCombiner._pulse(pulseBySeconds: 600);
            //mapCombiner.initialLocation = locMessage;   //make it look at the right place
            //mapCombiner.getWithinArea = self.getWithinArea //
            runcache._initialize()
            let tta = scheduler.addObject(oID: runcache.myID, o: runcache);
            
            let tt = 1;
        }
        
        
        mapCombinerToggleObserver.subscribe{ toggle in
            
            if toggle {
                
                //just create a new one, all the battery power in the world
                self.addMapCombiner(locMessage: locationMessage( timestamp : 0 , lat : 65.822299, lon: 24.2002689 ))
                
                //read stored runs if any
                let mc = PullRunsFromDisk(messageQueue: messageQueue)
                //ignore runs from outside my scope
                mc.initialLocation = locationMessage( timestamp : 0 , lat : 65.822299, lon: 24.2002689 );
                mc._initialize()
                scheduler.addObject(oID: mc.myID, o: mc)
                
                mc.scanForRuns()
                
            } else {
                
                //scheduler pages all combiner with quite
                scheduler.removeObjectsByName(name: "mapCombiner")
                
            }
            
        }
        
        mapCombinerToleranceObserver.subscribe{ tolerance in
            
            //adjust simplifier tolerance
            self.mapCombinerToleranceSet ( tolerance : tolerance)
            
        }
        
        mapFilteringModeToggleObserver.subscribe { filteringMode in
            
            //tell MapCombiner to change mode
            //self.recordCompleted(run : run)
            self.mapFilteringModeToggle(filteringMode : filteringMode)
            
        }
        
        requestForMapCombiner.subscribe {locationMessage in
            
            self.addMapCombiner(locMessage : locationMessage )
            
        }
        
        requestForMapDataProvider.subscribe {locationMessage in
            
            self.addMapDataProvider(locMessage : locationMessage )
            
        }
        
        
        
        //runRecorder shows intent we want to record a runinit
        //this might not happen, lets not care about it
        /*runRecoderToggleObserver.subscribe { toggle in
            self.recordStatusChange( toggle : toggle)
            
        }*/
        
        /*runAreaCompletedObserver.subscribe { run in
            self.recordCompleted(run : run)
            
        }
        
        LocationLoggerMessageObserver.subscribe
            { locationMessage in
                self.locationMessageGotFromLocationLogger(locationMessage : locationMessage)
                
        }
        
        runAreaProgressObserver.subscribe { run in
            self.runAreaProgress( run : run )
            
        }*/
        
    }
        
    func initialize () {
        
        print("mapViewJunction here")
        
    }
    
    func mapFilteringModeToggle ( filteringMode : mapFilteringMode ) {
        
            //user wants to see different data on his map
            if let mlt = storage.getObject(oID: "mapCombiner") as! MapCombiner? {
            
                mlt.changeFilteringMode (filteringMode : filteringMode )
            
            }
     
    
    
        
    }
    
    func mapCombinerToleranceSet ( tolerance : Float ) {
        
        if let mlt = storage.getObject(oID: "mapCombiner") as! MapCombiner? {
            
            if tolerance < 0.00001 {
                
                mlt.changeSimplifyTolerance (tolerance: 0.00001);
                return;
            }
            
            if tolerance > 0.0002 {
                
                mlt.changeSimplifyTolerance (tolerance: 5);
                return;
            }
            
            mlt.changeSimplifyTolerance (tolerance: tolerance);
            return;
            
        }
        
        
        
        
    }
    
    func addMapCombiner ( locMessage : locationMessage ){
        
        //cad add multiple
        //keep caching here. send snapshot if cached
        
        if locMessage.timestamp > 1000 && locMessage.timestamp < 50000 {
            //sneaking view radius through timestamp, naughty
            self.getWithinArea = locMessage.timestamp
            //calculate simplification level in mapcombiner
            
        }
        
        var mapCombiner = MapCombiner( messageQueue : nil );
        mapCombiner.myID = "mapCombiner";
        mapCombiner.name = "mapCombiner";
        mapCombiner.myCategory = objectCategoryTypes.generic
        mapCombiner._pulse(pulseBySeconds: 600);
        mapCombiner.initialLocation = locMessage;   //make it look at the right place
        mapCombiner.getWithinArea = self.getWithinArea //
        mapCombiner._initialize()
        
        scheduler.addObject(oID: mapCombiner.myID, o: mapCombiner)
        
    }
    
    func addMapDataProvider ( locMessage : locationMessage ){
        
        if locMessage.timestamp > 1000 && locMessage.timestamp < 50000 {
            //sneaking view radius through timestamp, naughty
            self.getWithinArea = locMessage.timestamp
            //calculate simplification level in mapcombiner
            
        }
        
        //read stored runs if any
        let mc = PullRunsFromDisk(messageQueue: messageQueue)
        //ignore runs from outside my scope
        mc.initialLocation = locMessage;
        mc.getWithinArea = self.getWithinArea;
        mc._initialize()
        scheduler.addObject(oID: mc.myID, o: mc)
        
        mc.scanForRuns()
        
    }
    
    
}
