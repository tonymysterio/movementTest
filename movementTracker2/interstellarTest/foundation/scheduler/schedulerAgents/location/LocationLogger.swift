//
//  LocationLogger.swift
//  interStellarTest
//
//  Created by sami on 2017/07/14.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import CoreLocation
import Interstellar

//send locationMessages to locationTrackers


//when logging starts, data starts to accumulate to loggerData
//the accumulation automatically stops when gps etc sensor is off
//setting is paused is for manual pausing of data recording

//DO NOT log data here. just pass it to any listeners i might have
//listeners will deal with the data any way they please
//listeners will finalize when idle for too long or whatever

//when adding locationLogger (unique), look for any listeners (category locationlistener) and plug them to this location logger with addlistener. listeners dont talk back to logger



var LocationLoggerMessageObserver = Observable<locationMessage>()

class LocationLogger : BaseObject {
    
    var isLogging = false;
    var isPaused = false;   //gps off, something that is not fatal
    var isInitialized = false //
    
    var previousLat : CLLocationDegrees = 0.0
    var previousLon : CLLocationDegrees = 0.0
    
    var CL : CLLocationManager?
    
    var initialLocation = locationMessage( timestamp : 0 , lat : 65.822299, lon: 24.2002689 )
    
    //kalman filter to clean the gps spikes
    var hcKalmanFilter : HCKalmanAlgorithm?
    //var myNewStartLocation : CLLocation?     //prime this
    let passUnfilteredGPSdata = false   //but honestly, why?
    
    //init(){
    
    //override say with something that talks to all locationlistener category objects
    //if nobody is listening, dont extend our TTL. nobody is listening, nobody cares, terminate
    //say is for soft messages caught with _listen_extend
    
    
    //self.name = "motionLogger"
    //self.myID = "motionlogger"
    
    //self.myCategory = objectCategoryTypes.unique
    
    //}
    
    func _initialize () -> DROPcategoryTypes? {
        
        //DispatchQueue.main.async {
        
        
        
        if (CL==nil){
            CL = CLLocationManager();
        }
        let zuu = CLLocationManager.locationServicesEnabled()
        CL?.allowsBackgroundLocationUpdates = true;
        if (zuu == false ) {
            
            _teardown()
            return DROPcategoryTypes.serviceNotAvailable
        }
        
        self.myCategory = objectCategoryTypes.uniqueServiceProvider
        
        self.name = "locationLogger"
        self.myID = "locationLogger"
        
        self.myHibernationStrategy = hibernationStrategy.persist  //dont hibernate
        self.myMemoryPressureStrategy = memoryPressureStrategy.persist //dont care
        
        //what services are authorized on this device
        let zit = CLLocationManager.authorizationStatus()
        var isAuthorized = false;
        switch (zit) {
            
            case .authorizedAlways :
            
                isAuthorized=true
            break;
            
            case .authorizedWhenInUse :
                isAuthorized=false  //significan change needs this
            
            break;
            
            default:
                isAuthorized = false
            break
            }
        
        
        
        if !isAuthorized {
            
            //dont teardown now. offer user to activate the serviise
            CL?.requestAlwaysAuthorization()
            
            return DROPcategoryTypes.serviceNotActivated
            
        }
        
       
        
        CL?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters //kCLLocationAccuracyBest
        
        //kCLLocationAccuracyHundredMeters
        
        
        //CL?.distanceFilter = 20.0  // In meters.
        
        CL?.delegate = self
        
        DispatchQueue.main.async() {

            self.CL?.startUpdatingLocation()
            
            //self.CL?.startMonitoringSignificantLocationChanges()

        }
        
        
        return nil
        /*
        
        let queue1 = Observable<CMDeviceMotion>()
        let queue2 = Observable<CMGyroData>()
        
        CM?.deviceMotionUpdateInterval = 1
        
        CM?.startDeviceMotionUpdates(to: OperationQueue.main) { motion, error in
            
            queue1.update(motion!)  //shove it down into the observable queue to be merged later
            motion?.userAcceleration
            motion?.gravity
            motion?.attitude
            
            print(motion ?? "nil" )
        }
        
        CM?.startGyroUpdates(to: OperationQueue.main) { gyro, error in
            
            queue2.update(gyro!)
            print(gyro ?? "nil" )
        }
        
 
        
        let mergedQueue = queue1.merge(queue2)
        
        mergedQueue.subscribe { t in
            
            //where to put this. maybe on appDelegate to handle meaningful concurrent events?
            //return observable to viewController?
            //logic should happen here though
            
            
        }
        
        //let t = CM.sta
        */
        
        return nil
    }
    
    func requestCurrentLocation () -> locationMessage {
        
        //this gets updated as the adapter gives more data
        return self.initialLocation;
        
        
    }
        
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        //somebody turns motionmanager off as a joke
        if (CL == nil){
            let res = _initialize()
            if res != nil {
                
                //we got a major hiccup. ask scheduler to kill us
                return res
                
            }
            //consider this as a service. if were not ready, try to kickstart us
            self._pulse(pulseBySeconds: 60 )    //keep on living
            return DROPcategoryTypes.serviceNotReady
            
        }
        
        //track if someone has disallowed the service, this means the user does not care about logs or this app
        
        
        
        self._pulse(pulseBySeconds: 60 )    //keep on living
        
        return nil
        
    }
    
    
    override func _LISTEN_extend(o: internalMessage) -> DROPcategoryTypes? {
        
        //who would logger listen to
        
        
        
        self._pulse(pulseBySeconds: 60 )
        return nil
        
    }   //end of listen extend
    
    
    func addEntry ( e : locationMessage ) -> DROPcategoryTypes? {
        
        return nil
        
        
    }
    
    override func _finalize () -> DROPcategoryTypes? {
        
        if (self.terminated) { return DROPcategoryTypes.terminating; }
        if (self.isFinalizing) { return DROPcategoryTypes.finalizing }
        
        //isFinalizing never needs to change to false again.
        self.isFinalizing = true
        
        //finalize is called if this guy has to save data or something
        //stop locationManager updates
        
        DispatchQueue.main.async() {
            
            
            //should stop also significant loc updates
            self.CL?.stopUpdatingLocation()
            
            
        }
        
        
        //finalize ends in teardown
        
        //bake my data to json, send it to dbStorage
        
        
        return _teardown()
        
    }
    
    //persisting objects need hibernate extend
    override func _hibernate_extend () -> DROPcategoryTypes? {
        
        if self.terminated { return DROPcategoryTypes.terminating }
        self._pulse(pulseBySeconds: 1000000)    //keep me going
        
        return DROPcategoryTypes.persisting
    }
    
    override func _purge ( backPressure : Int ) -> Int {
        
        //default purge. all objects obey to purge except .debugger, .uniqueServiceProvider
        /*if backPressure < uniqueServiceProviderBackPressureLimit {
            
            return backPressure
            
        }*/
        
        //uniqServiceProviders can try to stay alive and force lesser processes to die
        //by just removing one tick of backpressure
        
        //if im processing, do x
        //backpressure is 1 (warning) 99999999... (GTFO now)
        
        if (backPressure > purgeRequestEXITtreshold ) {
            
            self._finalize()
            let rema = backPressure - purgeRequestEXITtreshold
            return rema //too much back pressure, just bail out
        }
        
        isPurging = true
        
        let b = Double ( backPressure * 30 )
        let TTLdeducted = self.TTL - b //deduct by one housekeep round
        
        if (TTLdeducted < self.uxT()){
            
            self._finalize()    //some objects need finalize, timewaster does not
            return backPressure
        }
        
        TTL = TTLdeducted   //_pulse() will keep this up if something meaningful happens
        //in timewasters case it never does and we will teardown
        //some other object would do purge in a different way, block incoming data..
        
        return 1    //down by one click
        
        
        //returns a guesstimate how much pressure is relieved with my action
        
        //if not, just drop my TTL
        //the objects are somewhere else anyway
        //Scheduler just asks me to purge, i react how i react
        
        //objects die out with TTL only, nothing stays for too long anyway
        
        //default purge does absolutely nothing. you are stuck with us baby
        
        return 0
    }
    
}

extension LocationLogger: CLLocationManagerDelegate {
    
    //cclocationmaanger as extension
    //this is to decouple code from a delegate
    //baseClass had to become a NSobject for this reason
    
    func locationManager(_ manager: CLLocationManager,  didUpdateLocations locations: [CLLocation]) {
        
        let lastLocation = locations.last!
        //let ll = lastLocation.coordinate
        
        //ignore no movement
        /*if (ll.latitude == previousLat && ll.longitude == previousLon) {
            return
        }*/
        
        //this object will be purged when its not needed, dont worry about kalman filter reset
        
        if hcKalmanFilter == nil {
            
            hcKalmanFilter = HCKalmanAlgorithm(initialLocation: lastLocation)
            
            self._pulse(pulseBySeconds: 60 )
            
            return  //just ignore the first reading its probably shit anyway
            
        }
            
        //ok we are filtering spiky gps because we have an initial location
        guard let kalmanLocation = hcKalmanFilter?.processState(currentLocation: lastLocation) else {
            
            return
        }
            
        let ll = kalmanLocation.coordinate  //the tweaked loc coord
        
        
        let tS = self.uxT()
        //let mu = locationMessage (timestamp: tS, lat: ll.latitude, lon: ll.longitude)
        //let o = CommMessage.LocationMessage(type: "locationUpdate", oCAT: myCategory, oID: myID, timestamp: tS, lat: ll.latitude, lon: ll.longitude)
        self.initialLocation = locationMessage( timestamp : 0 , lat : lastLocation.coordinate.latitude, lon: lastLocation.coordinate.longitude )
        LocationLoggerMessageObserver.update(locationMessage(timestamp: tS, lat: ll.latitude, lon: ll.longitude))
        
        self._pulse(pulseBySeconds: 60 )
        
        //var o: CommMessage = [ "type" : "locationMessage", "oCAT": self.myCategory, "oID": myID , "o": mu ];
        
        //only use the observers to pass data
        
        //SAY(o: o)
        
        //print (mu)
        // Do something with the location.
    }
    
}

/*
class LocationLoggerDelegate: NSObject, CLLocationManagerDelegate {
    
    
}*/
