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
    
    //update map locations here
    var initialLocation = locationMessage( timestamp : 0 , lat : 65.822299, lon: 24.2002689 )
    var currentFilteringMode = mapFilteringMode.world
    var recordingRun = false;
    
    
    @IBOutlet var mapView: MKMapView!
    
    let regionRadius: CLLocationDistance = 10000
    let mapRenderQueue = DispatchQueue(label: "mapRenderQueue", qos: .utility)
    var primeLocation = false;
    
    @IBAction func locatorButtonTap(_ sender: Any) {
        
        //the user wants to update his location
        primeLocation = false;
        //runRecorderJunction will grab this
        requestCurrentLocationObserver.update(true)
    }
    
    @IBOutlet var filteringModeSelector: UIBarButtonItem!
    
    @IBAction func filteringModeSelector(_ sender: Any) {
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // let gg = locationMessage( timestamp : 0 , lat : 65.822299, lon: 24.2002689 )
        
        
        self.centerMap(lat: self.initialLocation.lat, lon: self.initialLocation.lon)
        
        /*let lc = CLLocation(latitude: self.initialLocation.lat, longitude: self.initialLocation.lon)
        
        let center = CLLocationCoordinate2D(latitude: lc.coordinate.latitude, longitude: lc.coordinate.longitude)
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.mapView.setRegion(region, animated: true)*/
        
        //self.mapView.setCenter(center, animated: true)
        
        runRecoderToggleObserver.subscribe { toggle in
            if !toggle {
                
                self.recordingRun = false;
                
            } else {
                
                self.recordingRun = true;
                
            }
            
        }
        
        //when mapCombiner finds something that is going to be displayed on the screen,
        //notify user with something, data is incoming!
        mapCombinerPertinentDataFound.subscribe
            { locationMessage in
                //check that we are looking at this
                //flash info that yes we are getting map data, please wait
                return;
            }
        
        mapSnapshotObserver.subscribe { mapSnap in
            
            //got a snapshot from mapCombiner
            //quickly throw it in the queue and get out of observer handler
            self.mapRenderQueue.sync{
                self.mapSnapshotReceived( mapSnap : mapSnap )
            }
            
            
        }
        
        LocationLoggerMessageObserver.subscribe
            { locationMessage in
                
                if !self.recordingRun {
                    
                    //let the user to mess with the map and dont worry about location updates
                    //in case the user wants to scroll around to see areas of interdust
                    return;
                }
                let lc = CLLocation(latitude: locationMessage.lat, longitude: locationMessage.lon)
                let center = CLLocationCoordinate2D(latitude: lc.coordinate.latitude, longitude: lc.coordinate.longitude)
                
                
                //self.locationMessageGotFromLocationLogger(locationMessage : locationMessage)
                // Drop a pin at user's Current Location
                let myAnnotation: MKPointAnnotation = MKPointAnnotation()
                myAnnotation.coordinate = CLLocationCoordinate2DMake(lc.coordinate.latitude, lc.coordinate.longitude);
                myAnnotation.title = "Current location"
                DispatchQueue.main.async {
                    
                    self.mapView.setCenter(center,animated: true)
                    self.mapView.addAnnotation(myAnnotation)
                    self.mapView?.showsUserLocation = true
                    
                }
                
        }
        
        locationMessageObserver.subscribe
            { locationMessage in
               //runRecorderJunction is sending the last location it knows
                //if this view is freshly created or the user polls for current location
                //refresh the view accordingly
                
                if self.recordingRun {
                    
                    //let the user to mess with the map and dont worry about location updates
                    //in case the user wants to scroll around to see areas of interdust
                    return;
                }
                
                if !self.primeLocation {
                    self.initialLocation = locationMessage
                    self.centerMap(lat: locationMessage.lat, lon: locationMessage.lon)
                    self.primeLocation = true;
                    
                }
            }
        
        //we are appearing. screen moving will call this again but ignore from the mapJunction
        
        requestForMapCombiner.update(self.initialLocation)
        requestForMapDataProvider.update(self.initialLocation)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //let overlays = mapView.overlays
        //mapView.removeOverlays(overlays)
        
        /*if let mlt = storage.getObject(oID: "mapCombiner") as! MapCombiner? {
            
            //if mapCombiner is alive ask for maps
            //mapCombiner will send a mapSnap via observable
            mlt.changeFilteringMode (filteringMode : currentFilteringMode )
            print ("view did appear, create snap")
            debuMess(text: "creating snapshot")
            //check if we have a snap on the disk for this purpose
            
            
            //if not, process one
            let gump = mlt.createSnapshot()
            
        } else {
            
            //add that mapCombinator
            //locationMessage( timestamp : 0 , lat : 65.822299, lon: 24.2002689 )
            requestForMapCombiner.update(self.initialLocation)
            
            requestForMapDataProvider.update(self.initialLocation)
            
            //load for cache if all fails
        }*/
        
        //the map anim triggers movement that triggers snapshot pull automatically
        //only make sure that map gets combined somehow
        
    }
    
    func centerMap ( lat : CLLocationDegrees , lon: CLLocationDegrees ) {
        
        /*if !self.recordingRun {
            
            //let the user to mess with the map and dont worry about location updates
            //in case the user wants to scroll around to see areas of interdust
            return;
        }*/
        
        let lc = CLLocation(latitude: lat, longitude: lon)
        
        let center = CLLocationCoordinate2D(latitude: lc.coordinate.latitude, longitude: lc.coordinate.longitude)
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        DispatchQueue.main.async {
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    func browsedToLocation ( lat : CLLocationDegrees , lon: CLLocationDegrees ) {
    
        //the user wants to see surroundingusu
        //even on a run, let him check out areas of interdust
        let radiu = self.mapView.currentRadius()
        
        self.initialLocation = locationMessage(timestamp: radiu, lat: lat, lon: lon)
        //tell mapviewJunction about our desire
        //mapcombiner will ignore if the request was too close to current
        
        requestForMapCombiner.update(self.initialLocation)
        requestForMapDataProvider.update(self.initialLocation)
        
        //somebody needs to make the map compile, timeout since last entry
        
        
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
        
        //check if the snapshot applies to the current viev before purging
        DispatchQueue.main.async {
            let overlays = self.mapView.overlays
            self.mapView.removeOverlays(overlays)
        }
        
        //self.mapView.setCenter(center, animated: true)
        //self.mapView.setRegion(region, animated: true)
        var polylines = [MKPolyline]();
        mapView.delegate = self
        for i in mapSnap.coordinates {
            
            polylines.append( MKPolyline(coordinates: i, count: i.count))
            let pol : MKPolyline = MKPolyline(coordinates: i, count: i.count)
            //self.mapRenderQueue.sync{
            DispatchQueue.main.async {
                self.mapView.delegate = self
                self.mapView.add(pol) //polyline
            }
            
        }
        
    }   //mapSnapshotReceived
    
    
}

//https://stackoverflow.com/questions/5556977/determine-if-mkmapview-was-dragged-moved
var mapRegionTimer: Timer?
var isBrowsingMap = false;
var browsedCoordinate = CLLocationCoordinate2D()

extension mapScreenVC : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.1)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 5
            return renderer
            
        } else if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.orange
            renderer.lineWidth = 3
            return renderer
            
        } else if overlay is MKPolygon {
            let renderer = MKPolygonRenderer(polygon: overlay as! MKPolygon)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.orange
            renderer.lineWidth = 2
            return renderer
        }
        
        return MKOverlayRenderer()
    }
    
    /*func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
     guard let annotation = view.annotation as? Place, let title = annotation.title else { return }
     
     let alertController = UIAlertController(title: "Welcome to \(title)", message: "You've selected \(title)", preferredStyle: .alert)
     let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
     alertController.addAction(cancelAction)
     present(alertController, animated: true, completion: nil)
     }*/
    
    
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapRegionTimer?.invalidate()
        mapRegionTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true, block: { (t) in
            
            //this happens even when automatically zooming around
            
            browsedCoordinate = CLLocationCoordinate2DMake(mapView.centerCoordinate.latitude, mapView.centerCoordinate.longitude);
            isBrowsingMap = true;
            //self.myAnnotation.title = "Current location"
            //self.mapView.addAnnotation(self.myAnnotation)
            //if im dragging around, i might want to see more data about my surroundings
            
        })
    }
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapRegionTimer?.invalidate()
        if (isBrowsingMap && !recordingRun) {
            
            //the user wants to see something outside his sphere
            self.browsedToLocation(lat: browsedCoordinate.latitude, lon: browsedCoordinate.longitude)
            
        }
        isBrowsingMap = false;
    }
    
}

extension MKMapView {
    
    func topCenterCoordinate() -> CLLocationCoordinate2D {
        return self.convert(CGPoint(x: self.frame.size.width / 2.0, y: 0), toCoordinateFrom: self)
    }
    
    func currentRadius() -> Double {
        let centerLocation = CLLocation(latitude: self.centerCoordinate.latitude, longitude: self.centerCoordinate.longitude)
        let topCenterCoordinate = self.topCenterCoordinate()
        let topCenterLocation = CLLocation(latitude: topCenterCoordinate.latitude, longitude: topCenterCoordinate.longitude)
        return centerLocation.distance(from: topCenterLocation)
    }
    
}




