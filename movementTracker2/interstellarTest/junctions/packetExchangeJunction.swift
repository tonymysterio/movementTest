//
//  packetExchangeJunction.swift
//  movementTracker2
//
//  Created by sami on 2017/12/25.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import Interstellar
import Servus

var packetExchangeRequestObserver = Observable<Bool>()
var peerExplorerDidSpotPeerObserver = Observable<Peer>()
var peerExplorerDidDeterminePeerObserver = Observable<Peer>()
var peerExplorerDidLosePeerObserver = Observable<Peer>()

var peerDataProviderExistingHashesObserver = Observable<exchangedHashes>()

class PacketExchangeJunction {
    
    var enabled = false;
    
    //user initiates packet exchange with packetExchangeRequestObserver
    
        //check if we have live objects
    
        //
    
    
    
    //
    func initialize () {
        
        print("PacketExchangeJunction here")
        
    }
    
    
    
    init () {
        
        packetExchangeRequestObserver.subscribe { toggle in
            
            self.initiateMeshnet();
            
        }
        
        peerExplorerDidSpotPeerObserver.subscribe { toggle in
         
            //this might alert the users UI
            //maybe no need
            
        }
        
        peerExplorerDidDeterminePeerObserver.subscribe { peer in
            
            //inform user. might end up into a big list
            //some of these peers might not be valid data providers
            
            //search for peerDataRequester for this peer
            
            //create one if not found
            
            //peerDataRequester initiates a JSON pull from this host
            self.pollNewPeerForData(peer: peer)
        }
        /* extension AppDelegate: ExplorerDelegate {
         func explorer(_ explorer: Explorer, didSpotPeer peer: Peer) {
         print("Spotted \(peer.identifier). Didn't determine its addresses yet")
         }
 
         func explorer(_ explorer: Explorer, didDeterminePeer peer: Peer) {
         print("Determined hostname for \(peer.identifier): \(peer.hostname!)")
         }
 
         func explorer(_ explorer: Explorer, didLosePeer peer: Peer) {
         print("Lost \(peer.hostname) from sight")
         }
         } */
    
    }   //init
    
    
    func initiateMeshnet() {
        
        //self.recordStatusChange( toggle : toggle)
        //user initiated exchange in local p2p network
        //possibly multiple people advertising
        
        //look for hashes first. no hashes, the user should do a run. prompt about that
        
        //give peerDataProvider a pullRunsFromDisk to query for run hashes
        //call its .scanForRunHashes  might return nil
        //no own runs gives a nil
        
        let sp = self.getServusMeshnetProvider()
        
        
        
        //see if we have a PeerDataProvider (swifter service)
        //everybody joining this will have one to be able to respond to JSON requests
        
        //if we dont have one, create one. Low TTL, expire
        
        //add a server to listen to requests
        let pp = self.getPeerDataProvider()
        
        //when data connection is lost, scheduler will page PeerDataProvider to shut down immediately
        
        //the dataPeerProvider needs to know about my hash situation
        //use PullRunsFromDisk to get loads and loads of hashes
        if let dp = self.addHashSetProvider() {
            dp.scanForRuns()
        }
        
        
    }
    
    func getServusMeshnetProvider () -> ServusMeshnetProvider? {
        
        if let mlt = storage.getObject(oID: "servusMeshnetProvider") as! ServusMeshnetProvider? {
            
            mlt._pulse(pulseBySeconds: 120) //ample time to get a connection
            return mlt
            
        }
        
        //create new, assume that old one is terminaattod
        let myServusMeshnetProvider = ServusMeshnetProvider(messageQueue: messageQueue);
        myServusMeshnetProvider._initialize()
        myServusMeshnetProvider._pulse(pulseBySeconds: 120);
        
        if scheduler.addObject(oID: myServusMeshnetProvider.myID, o: myServusMeshnetProvider ){
            //myLocationTracker?.addListener(oCAT: myLiveRunStreamListener.myCategory, oID: myLiveRunStreamListener.myID, name: myLiveRunStreamListener.name)
            
            return myServusMeshnetProvider
        }
        
        return nil
        
    }
    
    func getPeerDataProvider () -> PeerDataProvider? {
        
        if let mlt = storage.getObject(oID: "peerDataProvider") as! PeerDataProvider? {
            
            mlt._pulse(pulseBySeconds: 120) //ample time to get a connection
            return mlt
            
        }
        
        //create new, assume that old one is terminaattod
        let myPeerDataProvider = PeerDataProvider(messageQueue: messageQueue);
        myPeerDataProvider._initialize()
        myPeerDataProvider._pulse(pulseBySeconds: 120);
        
        if scheduler.addObject(oID: myPeerDataProvider.myID, o: myPeerDataProvider ){
            //myLocationTracker?.addListener(oCAT: myLiveRunStreamListener.myCategory, oID: myLiveRunStreamListener.myID, name: myLiveRunStreamListener.name)
            
            return myPeerDataProvider
        }
        
        return nil
        
    }
    
    
    func addHashSetProvider () -> PullRunsFromDisk? {
        //comes from mapView
        
        if let mlt = storage.getObject(oID: "pullRunsFromDisk") as! PullRunsFromDisk? {
            
            mlt._pulse(pulseBySeconds: 120) //ample time to get a connection
            return mlt
            
        }
        
        
        //read stored runs if any
        let mc = PullRunsFromDisk(messageQueue: messageQueue)
        //ignore runs from outside my scope
        //mc.initialLocation = locMessage;
        mc.getWithinArea = 10000000;    //get everything
        mc._initialize()
        if (scheduler.addObject(oID: mc.myID, o: mc)) {
            return mc
        }
        
        return nil;
        
        //mc.scanForRuns()
        
    }
    
    func addPeerDataRequester (peer: Peer ) -> PeerDataRequester? {
    
        let name = "PEER" + peer.identifier;
        
        if let mlt = storage.getObject(oID: name) as! PeerDataRequester? {
            
            mlt._pulse(pulseBySeconds: 120) //ample time to get a connection
            return mlt
            
        }
        
        let pdc = PeerDataRequester(messageQueue: messageQueue)
        pdc._pulse(pulseBySeconds: 120) //ample time to get a connection
        pdc._initialize()
        pdc.myID = name;
        pdc.hostname = peer.hostname!
        if (scheduler.addObject(oID: pdc.myID, o: pdc)) {
            return pdc
        }
        
        return nil
        
    }
    
    func pollNewPeerForData (peer : Peer ) {
        
        //see if we have a poller for this
        let name = "PEER" + peer.identifier;
        
        if let pdc = self.addPeerDataRequester(peer: peer) {
            
            pdc.requestHashes();
        }
        
    }
    
}

