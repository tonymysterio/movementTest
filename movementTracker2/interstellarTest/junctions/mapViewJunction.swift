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

var mapFilteringModeToggleObserver = Observable<mapFilteringMode>()
var currentLocationMessageObserver = Observable<locationMessage>()
var mapSnapshotObserver = Observable<mapSnapshot>()

class mapViewJunction {
    
    //var recording = false;
    //var myRecorderObjectID = "";
    //weak var myLocationTracker : LocationLogger?
    //weak var myLiveRunStreamListener : liveRunStreamListener?
    //weak var myPedometer : Pedometer?
    
    init () {
        
        
        mapFilteringModeToggleObserver.subscribe { filteringMode in
            
            //tell MapCombiner to change mode
            //self.recordCompleted(run : run)
            self.mapFilteringModeToggle(filteringMode : filteringMode)
            
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
            if let mlt = storage.getObject(oID: "MapCombiner") as! MapCombiner? {
            
                mlt.changeFilteringMode (filteringMode : filteringMode )
            
        }
     
    
    
        
    }
}
