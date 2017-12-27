//
//  preferencesSignalJunction.swift
//  interStellarTest
//
//  Created by sami on 2017/11/14.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import Interstellar

var maxObjectsSliderObserver = Observable<Float>()
var maxCatObjectsSliderObserver = Observable<Float>()

class preferenceSignalJunction {
    
    //signals from ui to scheduler
    //var maxObjectsSliderObserver = Observable<Float>()
    //var maxCatObjectsSliderObserver = Observable<Float>()
    //var motionLoggerToggleObserver = Observable<Bool>()
    //var locationLoggerToggleObserver = Observable<Bool>()
    
    func initialize () {
        
        print("preferenceSignalJunction - listening to UI actions preferences")
        
        //after getting some lovely run objos, save them to disk! Brilliant!
        
    }
    //this stuff is in appdelegate
    //func signalListeners () {
    init () {
        
        maxObjectsSliderObserver.subscribe { sliderVal in
            
            print(sliderVal)
            //let dum = scheduler.relayConfigurationValue(k: liveConfigurationTypes.maxObjects, v: sliderVal);
            scheduler.setMaxObjects(maxO: Int(sliderVal))
        }
        
        maxCatObjectsSliderObserver.subscribe { sliderVal in
            
            print(sliderVal)
            //this will pass a value to all objects scheduler is handling
            let dum = scheduler.relayConfigurationValue(k: liveConfigurationTypes.maxCategoryObjects, v: sliderVal);
            
            //print ( dum )
            
        }
        
        
    }   //end signal listeners for this view controller
    
    
}
    //var objects = [ String : BaseObject]()
    
    //var scheduler: Scheduler!
    //var messageQueue : MessageQueue!
    

