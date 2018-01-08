//
//  serviceStatusJunction.swift
//  movementTracker2
//
//  Created by sami on 2018/01/08.
//  Copyright © 2018年 pancristal. All rights reserved.
//

import Foundation
import Interstellar

var serviceStatusJunctionObserver = Observable<serviceStatusItem>()
var serviceStatusJunctionRefresh = Observable<Bool>()
var serviceStatusJunctionTotalCachedRuns = Observable<Int>()


struct serviceStatusItem {
    
    let name : String;
    let data : Double ; //amount of runs
    let ttl : Double;
    let active : Bool
    
    
}


class serviceStatusJunction {
    
    var recording = false;
    var myRecorderObjectID = "";
    weak var myLocationTracker : LocationLogger?
    weak var myLiveRunStreamListener : liveRunStreamListener?
    weak var myPedometer : Pedometer?
    var initialLocation = locationMessage( timestamp : 0 , lat : 65.822299, lon: 24.2002689 )
    let services = ["mapCombiner","PullRunsFromDisk","runCache","snapshotCache","servusMeshnetProvider","PeerDataProvider","PeerDataRequester","jsonStreamReader","runStreamRecorder","hoodoRunStreamListener"];
    
        
    func initialize () {
        
        print("serviceStatusJunction here")
        
        //let scheduler to ping me to keep statuses fresh
        serviceStatusJunctionRefresh.subscribe { b in
            self.getServiceStatuses()
            
        }
        
    }
    
    func getServiceStatuses () {
        
        var respo =  [ String : serviceStatusItem ]();
        for i in self.services {
            
            if let mlt = storage.getObject(oID: i)  {
                //name can be diff
                respo[i]=serviceStatusItem(name: mlt.myID, data: 0, ttl: mlt.TTL, active: true);
                
            } else {
                
                respo[i]=serviceStatusItem(name: i, data: 0, ttl: 0, active: false);
            }
            
            serviceStatusJunctionObserver.update(respo[i]!); //tell it to the rest of the world
            
        }
        
        //print(respo);
        
        let lummox=1;
        
    }
    
    
}