//
//  ViewController.swift
//  movementTracker2
//
//  Created by sami on 2017/11/02.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import UIKit
import MapKit
import Interstellar

class mapScreenVC: UIViewController {
    
    var initialMapCentered = false;
    var currentFilteringMode = mapFilteringMode.world
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mapSnapshotObserver.subscribe { mapSnap in
            
            //got a snapshot from mapCombiner
            self.mapSnapshotReceived( mapSnap : mapSnap )
            
        }
        
        LocationLoggerMessageObserver.subscribe
            { locationMessage in
                
                /*if self.mapView == nil {
                 
                 return
                 
                 }*/
                let lc = CLLocation(latitude: locationMessage.lat, longitude: locationMessage.lon)
                
                let center = CLLocationCoordinate2D(latitude: lc.coordinate.latitude, longitude: lc.coordinate.longitude)
                
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                
                //self.mapView.setRegion(region, animated: true)
                //self.mapView.setCenter(center, animated: true)
                
                //self.centerMapOnLocation(location: lc)
                //self.locationMessageGotFromLocationLogger(locationMessage : locationMessage)
                // Drop a pin at user's Current Location
                let myAnnotation: MKPointAnnotation = MKPointAnnotation()
                myAnnotation.coordinate = CLLocationCoordinate2DMake(lc.coordinate.latitude, lc.coordinate.longitude);
                myAnnotation.title = "Current location"
                //self.mapView.addAnnotation(myAnnotation)
                //self.mapView?.showsUserLocation = true
                
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if let mlt = storage.getObject(oID: "mapCombiner") as! MapCombiner? {
            
            //if mapCombiner is alive ask for maps
            //mapCombiner will send a mapSnap via observable
            mlt.changeFilteringMode (filteringMode : currentFilteringMode )
            print ("view did appear, create snap")
            //check if we have a snap on the disk for this purpose
            
            
            //if not, process one
            let gump = mlt.createSnapshot()
            
        }
        
    }
    
    func mapSnapshotReceived( mapSnap : mapSnapshot ) {
        
        //MapCombiner gives us a new snap for some reason
        
        /*
         let o : [MKPolyline]
         let filteringMode : mapFilteringMode //throw everything in as default
         let lat : CLLocationDegrees
         let lon : CLLocationDegrees
         let getWithinArea : Double
         */
        
        // track if it is what we want to see now
        let center = CLLocationCoordinate2D(latitude: mapSnap.lat, longitude: mapSnap.lon)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        
        
        
        //self.mapView.setCenter(center, animated: true)
        //self.mapView.setRegion(region, animated: true)
        
        for i in mapSnap.coordinates {
            
            let myPolyline = MKPolyline(coordinates: i, count: i.count)
            //self.mapView.add(myPolyline) //polyline
            
        }
        
    }   //mapSnapshotReceived
    
    
}


