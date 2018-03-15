//
//  pedometer.swift
//  interStellarTest
//
//  Created by sami on 2017/11/17.
//  Copyright © 2017年 pancristal. All rights reserved.
//


import Foundation
import CoreMotion
import Interstellar

struct pedometerMessage {
    
    let steps : Int
    let distance : Double
    let averageActivePace : Double
    let currentPace : Double
    
}

var pedometerMessageObserver = Observable<pedometerMessage>()

class Pedometer : BaseObject {
    
    var isLogging = false;
    var isPaused = false;   //gps off, something that is not fatal
    let PM = CMPedometer()
    
    var timer = Timer()
    let timerInterval = 1.0
    var timeElapsed:TimeInterval = 0.0
    
    //https://makeapppie.com/2017/02/14/introducing-core-motion-make-a-pedometer/
    var numberOfSteps:Int! = nil
    var distance:Double! = nil
    var averagePace:Double! = nil
    var pace:Double! = nil
    
    func _initialize() {
        
        schedulerAgentType = schedulerAgents.pedometer;
        myCategory = objectCategoryTypes.motionlistener
        self.name = "pedometer"
        self.myID = "pedometer"
        self.myCategory = objectCategoryTypes.motionlistener
        
        //disappears
        _pulse(pulseBySeconds: 6000000)
        
        
        //pedometer = CMPedometer()
        PM.startUpdates(from: Date(), withHandler: { (pedometerData, error) in
            if let pedData = pedometerData{
                self.isLogging = true
                
                var di : Double  = 0
                var aap : Double = 0
                var cp : Double = 0
                
                let steps = Int(pedData.numberOfSteps)
                
                if let distance = pedData.distance{
                    di = Double(distance)
                }
                if let averageActivePace = pedData.averageActivePace {
                    aap = Double(averageActivePace)
                }
                if let currentPace = pedData.currentPace {
                    cp = Double(currentPace)
                }
                
                let newPedo = pedometerMessage(steps: steps, distance: di, averageActivePace: aap, currentPace: cp)
                pedometerMessageObserver.update(newPedo)
                //self.stepsLabel.text = "Steps:\(pedData.numberOfSteps)"
                self._pulse(pulseBySeconds: 30)
                
            } else {
                //self.stepsLabel.text = "Steps: Not Available"
                //this basically means pedometer is not available
                //just terminate and dont care
                self.isLogging = false;
                self._finalize()
                
            }
        })
        
        isInitialized = true;
        
    }
    
    override func _finalize () -> DROPcategoryTypes? {
        
        if (self.terminated) { return DROPcategoryTypes.terminating; }
        if (self.isFinalizing) { return DROPcategoryTypes.finalizing }
        
        //isFinalizing never needs to change to false again.
        self.isFinalizing = true
        
        if PM != nil {
            PM.stopUpdates()
        }
        //finalize is called if this guy has to save data or something
        
        //finalize ends in teardown
        
        //bake my data to json, send it to dbStorage
        
        
        return _teardown()
        
    }
    
    
    func timeIntervalFormat(interval:TimeInterval)-> String{
        var seconds = Int(interval + 0.5) //round up seconds
        let hours = seconds / 3600
        let minutes = (seconds / 60) % 60
        seconds = seconds % 60
        return String(format:"%02i:%02i:%02i",hours,minutes,seconds)
    }
    // convert a pace in meters per second to a string with
    // the metric m/s and the Imperial minutes per mile
    func paceString(title:String,pace:Double) -> String{
        var minPerMile = 0.0
        let factor = 26.8224 //conversion factor
        if pace != 0 {
            minPerMile = factor / pace
        }
        let minutes = Int(minPerMile)
        let seconds = Int(minPerMile * 60) % 60
        return String(format: "%@: %02.2f m/s \n\t\t %02i:%02i min/mi",title,pace,minutes,seconds)
    }
    
    func computedAvgPace()-> Double {
        if let distance = self.distance{
            pace = distance / timeElapsed
            return pace
        } else {
            return 0.0
        }
    }
    
    func miles(meters:Double)-> Double{
        let mile = 0.000621371192
        return meters * mile
    }
    
    
}
