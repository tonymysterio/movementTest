//
//  LocationTracker.swift
//  interStellarTest
//
//  Created by sami on 2017/07/18.
//  Copyright © 2017年 pancristal. All rights reserved.
//
//
//  LocationTracker.swift
//  interStellarTest
//
//  Created by sami on 2017/07/14.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import CoreLocation

//listens to locationEvents from locationLogger
//lets be able to prime this with previous events
//long TTL, finalize if we run out of TTL
//trust locationLogger not to send redundant data

//you could have multiple locationTrackers with data passed over XMPP
//detect collisions with other people, proximity
//make a subclass of this that reacts to specific events

//track location

class LocationTracker : BaseObject {
    
    var isLogging = false;
    var isPaused = false;   //gps off, something that is not fatal
    var isInitialized = false //
    var loggerData : [locationMessage] = []  //my shit goes in here
    var storeLoggerDataOnFinalize = false   //all data is disposable by default
    var previousLat : CLLocationDegrees = 0.0
    var previousLon : CLLocationDegrees = 0.0
    
    
    //init(){
    
    //override say with something that talks to all locationlistener category objects
    //if nobody is listening, dont extend our TTL. nobody is listening, nobody cares, terminate
    //say is for soft messages caught with _listen_extend
    
    
    //self.name = "motionLogger"
    //self.myID = "motionlogger"
    
    //self.myCategory = objectCategoryTypes.unique
    
    //}
    
    func _initialize () -> DROPcategoryTypes? {
        
        
        myCategory = objectCategoryTypes.locationlistener
        self.name = "locationTracker"
        self.myID = "locationTracker"
        self.myCategory = objectCategoryTypes.locationlistener
        
        self.myHibernationStrategy = hibernationStrategy.finalize  //dont hibernate
        self.myMemoryPressureStrategy = memoryPressureStrategy.finalize
        
        //location logger should talk to objects like me
        //dont care for locationListeners EXITs or DROPs, just TTL out and _finalize
        
        //find locationlogger somewhere else. not all trackers are interested in current gps events
        
        
        return nil
        
        if let locationTrackers = self.scheduler?.getCategoryObjects(oCAT: objectCategoryTypes.locationlistener) {
            //if we have listeners, lets push our updates to them
            for a in locationTrackers {
                
                _ = self.addListener(oCAT: objectCategoryTypes.motionlistener, oID: a, name: "locationlistener")
                
            }
            
            
        }   //any live motionTrackers that existed before me got listening to me now
        
        
        
        return nil
    }
    
    //override purge for this one if the saved data means anything and is worth storing
    
    
    func locationManager(_ manager: CLLocationManager,  didUpdateLocations locations: [CLLocation]) {
        
        let lastLocation = locations.last!
        let ll = lastLocation.coordinate
        
        //ignore no movement
        if (ll.latitude == previousLat && ll.longitude == previousLon) {
            return
        }
        let tS = self.uxT()
        let mu = locationMessage (timestamp: tS, lat: ll.latitude, lon: ll.longitude)
        
        //EVIL global observable to update the mpa
        //myCurrentGpsLocation.update(locations.last!)
        // Do something with the location.
    }
    
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        //how long should location tracker live?
        //by default it dies if no location events arrive before TTL
        
        //_ = self._pulse(pulseBySeconds: 60 )    //keep on living
        
        return nil
        
    }
    
    
    override func _LISTEN_extend(o: internalMessage) -> DROPcategoryTypes? {
        
        switch o.o {
            //the following creates the following variables for the scope
        case let .LocationMessage(type, oCAT, oID, timestamp, lat, lon):
            
            print (" \(o.from) locationmessgae. \(type) Oh dear. ")
            
            //let mu = locationMessage (timestamp: tS, lat: ll.latitude, lon: ll.longitude)
            
            //EVIL global observable to update the mpa
            //myCurrentGpsLocation.update(locations.last!)
            let clo = CLLocation(latitude : lat, longitude : lon)
            
            //doing the following will show the map tab
            myCurrentGpsLocation.update(clo)
            
            //loc message! wait for the next one
            _ = self._pulse(pulseBySeconds: 60 )
                        
        default:
            break
            
        }
        
        
        
        
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
        if storeLoggerDataOnFinalize == false {
            
            return _teardown()
            
        }
        
        //finalize ends in teardown
        
        //bake my data to json, send it to dbStorage
        
        
        return _teardown()
        
    }
    
    
    
}
