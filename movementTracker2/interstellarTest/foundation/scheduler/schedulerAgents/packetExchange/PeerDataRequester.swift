//
//  MapCombiner.swift
//  interStellarTest
//
//  Created by sami on 2017/11/25.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import Interstellar
//import GEOSwift


class PeerDataRequester : BaseObject  {
    
    let queue = DispatchQueue(label: "PeerDataRequesterQueue", qos: .utility)
    var host : String = "" //host where to pull the request from
    var requestParameters : String = ""
    var hashesPrimed = false;
    var myExhangedHashes = exchangedHashes()
    var hostname = "";
    
    func _initialize () -> DROPcategoryTypes? {
        
        //passing hashes of all my held data might lead to a massive packet to send over
        
        //myCategory = objectCategoryTypes.uniqueServiceProvider  //only one file accessor at a time
        self.name = "PeerDataRequester"
        self.myID = "PeerDataRequester"
        self.myCategory = objectCategoryTypes.generic
        
        //disappears
        _pulse(pulseBySeconds: 60)
        
        //if for some reason we cannot store to disk, give this
        //DROPcategoryTypes.serviceNotAvailable
        
        //if disk space is low, return
        //DROPcategoryTypes.lowDiskspace
        
        
        peerDataProviderExistingHashesObserver.subscribe{ hashes in
            
            self.peerDataProviderExistingHashesReceived( hashes : hashes )
            
        }
        
        //filter irrelevant runs by distance
        
        //pullRunsFromDisk also shouts here
        /*runReceivedObservable.subscribe{ run in
            
            self.addRun( run : run )
            
        }
        
        //hoodoRunStreamListener pages us when it reads a run from stream etc
        runStreamReaderDataArrivedObserver.subscribe
            { run in
                self.addRun( run : run )
                
        }*/
        
        
        
        return nil
        
    }
    
    func request () {
        
        //simple JSON request
        // to: host with requestParameters
        
        //PROTO
        //pass hashes of held run data, please give me anything but this
        
        //hash ecxhange -> individual requests to separate entries
        //individual requests all
        
        //keep responses sho
        
    }
    
    func peerDataProviderExistingHashesReceived ( hashes : exchangedHashes ) {
        
        //list of stuff we have got
        queue.sync {
            
            myExhangedHashes = hashes
            
        }
        
        hashesPrimed = true;
    }
    
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        
        return nil
    }
    
    
    
    
}

