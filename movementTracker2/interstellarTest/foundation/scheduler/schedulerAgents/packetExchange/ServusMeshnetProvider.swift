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
    
    func _initialize () -> DROPcategoryTypes? {
        
        self.name = "servusMeshnetProvider"
        self.myID = "servusMeshnetProvider"
        self.myCategory = objectCategoryTypes.uniqueServiceProvider
        
        //disappears
        _pulse(pulseBySeconds: 60)
        
        explorer = Explorer()
        explorer.delegate = self
        explorer.startExploring()
        print("Started exploring nearby peers...")
        
        return nil
    }
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
        print("Lost \(peer.hostname) from sight")
    }
}

