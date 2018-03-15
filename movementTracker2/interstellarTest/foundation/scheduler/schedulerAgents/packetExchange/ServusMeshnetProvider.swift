//
//  ServusMeshnetProvider.swift
//  movementTracker2
//
//  Created by sami on 2017/12/25.
//  Copyright © 2017年 pancristal. All rights reserved.
//


import Foundation
import Interstellar
import Servus

class ServusMeshnetProvider : BaseObject  {

    var explorer: Explorer!
    
    //keep track of connections and stuff
    //let
    
    override func _initialize () -> DROPcategoryTypes? {
        
        schedulerAgentType = schedulerAgents.servusMeshnetProvider
        agentIcon = "🕸";
        self.name = "servusMeshnetProvider"
        self.myID = "servusMeshnetProvider"
        self.myCategory = objectCategoryTypes.uniqueServiceProvider
        
        self.myHibernationStrategy = hibernationStrategy.finalize  //dont hibernate
        self.myMemoryPressureStrategy = memoryPressureStrategy.finalize
        schedulerAgentType = schedulerAgents.servusMeshnetProvider
        //disappears
        
        _pulse(pulseBySeconds: 60)
        
        explorer = Explorer()
        explorer.delegate = self
        explorer.startExploring()
        print("Started exploring nearby peers...")
        
        peerExplorerKeepAliveObserver.subscribe { toggle in
         
            //some data came in thru active connection
            self._pulse(pulseBySeconds: 60)
            
        }
        
        peerExplorerDidLosePeerObserver.subscribe { peer in
            
            let m = notificationMeiwaku(title: "meshnet service", subtitle: "peer lost", body: "" ,sound : false, vibrate : false )//peer.hostname?)
            serviceStatusJunctionNotification.update(m)
            _ = self.startProcessing();
            _ = self._pulse(pulseBySeconds: 60)
            _ = self.finishProcessing()
        }
        
        peerExplorerDidDeterminePeerObserver.subscribe { peer in
            
            let m = notificationMeiwaku(title: "meshnet service", subtitle: "peer found", body: peer.hostname! ,sound : false, vibrate : false )
            serviceStatusJunctionNotification.update(m);
            
            _ = self.startProcessing();
            _ = self._pulse(pulseBySeconds: 60)
            _ = self.finishProcessing()
        }
        
        /*peerExplorerDidLosePeerObserver.subscribe{ peer in
            
            _ = self.startProcessing();
            _ = self._pulse(pulseBySeconds: 60)
            _ = self.finishProcessing()
        }*/
        
        isInitialized = true;
        
        return nil
    }
    
    override func _finalize() -> DROPcategoryTypes? {
        
        explorer.stopExploring()
        
        return self._teardown()
        
    }
    //peerDataRequesterRunArrivedObserver
    
    
}



extension ServusMeshnetProvider: ExplorerDelegate {
    func explorer(_ explorer: Explorer, didSpotPeer peer: Peer) {
        
        peerExplorerDidSpotPeerObserver.update(peer)
        
        print("Spotted \(peer.identifier). Didn't determine its addresses yet")
    }
    
    func explorer(_ explorer: Explorer, didDeterminePeer peer: Peer) {
        peerExplorerDidDeterminePeerObserver.update(peer);
        print("Determined hostname for \(peer.identifier): \(peer.hostname!)")
    }
    
    func explorer(_ explorer: Explorer, didLosePeer peer: Peer) {
        peerExplorerDidLosePeerObserver.update(peer)
        //hostname is not available
        print("Lost \(peer.identifier) from sight")
    }
}

