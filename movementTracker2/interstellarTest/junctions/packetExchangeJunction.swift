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

//peerDataRequester tries to keep servusMeshnetProvider alive when something meaningful happens
var peerExplorerKeepAliveObserver = Observable<Bool>()

var peerDataProviderExistingHashesObserver = Observable<exchangedHashes>()
var peerDataRequesterRunArrivedObserver = Observable<Run>()
var peerDataRequesterRunArrivedSavedObserver = Observable<String>()

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
            
            DispatchQueue.main.async{
                self.initiateMeshnet();
            }
            /*DispatchQueue.global(qos: .utility).async {
                self.initiateMeshnet();
            }*/
        }
        
        peerExplorerDidSpotPeerObserver.subscribe { toggle in
         
            //this might alert the users UI
            //maybe no need
            
        }
        
        peerExplorerKeepAliveObserver.subscribe { toggle in
            
            //make servus stay around for longe
            DispatchQueue.global(qos: .utility).async {
                self.peerExplorerKeepAlive()
            }
            
        }
        peerExplorerDidDeterminePeerObserver.subscribe { peer in
            
            //inform user. might end up into a big list
            //some of these peers might not be valid data providers
            
            //search for peerDataRequester for this peer
            
            //create one if not found
            
            //peerDataRequester initiates a JSON pull from this host
            DispatchQueue.global(qos: .utility).async {
                self.pollNewPeerForData(peer: peer)
            }
        }
        
        peerExplorerDidLosePeerObserver.subscribe() { peer in
            
            //var id = peer.identifier    //host cannot be seen now
            DispatchQueue.global(qos: .utility).async {
                self.peerExplorerDidLosePeer(peer: peer)
            }
            
        }
        peerDataRequesterRunArrivedObserver.subscribe { run in
            
            DispatchQueue.global(qos: .utility).async {
            //peer data requester got a run over the meshlink
                if let hrr = self.addHoodoRunStreamListener() {
                
                //its there
                hrr.addRun(run: run)
                
                
                }
            
                if let strr = self.addRunStreamRecorder(){
                
                //this will page us if the run is actually stored
                strr.storeRun(run: run)
                
                }
            
            }
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
        
        //peer data provider needs hashes. look at cache first
        
        //the dataPeerProvider needs to know about my hash situation
        //use PullRunsFromDisk to get loads and loads of hashes
        /*if let dp = self.addHashSetProvider() {
            dp.scanForRuns()
        }*/
        
        //stop any mapcombiners
        
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
    
    func peerExplorerKeepAlive (){
        
        //data is exchanged or shit, keep servus around
        //probably ask it to advertise again
        
        if let mlt = storage.getObject(oID: "servusMeshnetProvider") as! ServusMeshnetProvider? {
            
            mlt._pulse(pulseBySeconds: 30) //ample time to get a connection
            
        }
        
    }
    
    func peerExplorerDidLosePeer ( peer: Peer ) {
        
        //somebody disappeared
        let name = "PEER" + peer.identifier;
        
        if let mlt = storage.getObject(oID: name) as! PeerDataRequester? {
            
            mlt._teardown() //get rid of this guy now
            
        }
        
        
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
        
        //read hashes from cache to prime me. the code in primeMyRunHashes is copied from readFromDisk
        //do
        
        if let cache = storage.getObject(oID: "runCache") as! RunCache? {
            if let cachedHashes = cache.cachedHashes() {
                
                if let cuha = cache.cachedUserHashes() {
                    
                    for i in cuha {
                        
                        myPeerDataProvider.myExhangedHashes.insertForUser(user: i[0], hash: i[1])
                        
                    }
                    //tell peer data provider what we got
                    //peerDataProviderExistingHashesObserver.update(self.myExhangedHashes);
                }
                
            }
            
        }
        
        //myPeerDataProvider.primeMyRunHashes();
        
        if scheduler.addObject(oID: myPeerDataProvider.myID, o: myPeerDataProvider ){
            //myLocationTracker?.addListener(oCAT: myLiveRunStreamListener.myCategory, oID: myLiveRunStreamListener.myID, name: myLiveRunStreamListener.name)
            
            return myPeerDataProvider
        }
        
        return nil
        
    }
    
    
    func addHashSetProvider () -> PullRunsFromDisk? {
        //comes from mapView
        //if there is something on cache, prime
        
        
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
        pdc.identifier = peer.identifier;
        
        if (scheduler.addObject(oID: pdc.myID, o: pdc)) {
            return pdc
        }
        
        return nil
        
    }
    
    func addHoodoRunStreamListener () -> hoodoRunStreamListener? {
        
        //this will listen and act as a general storage
        
        if let mlt = storage.getObject(oID: "hoodoRunStreamListener") as! hoodoRunStreamListener? {
            
            mlt._pulse(pulseBySeconds: 120)
            return mlt
            
        }
        
        //create new, assume that old one is terminaattod
        let myhoodoRunStreamListener = hoodoRunStreamListener(messageQueue: messageQueue);
        myhoodoRunStreamListener._initialize()
        myhoodoRunStreamListener._pulse(pulseBySeconds: 120);
        
        if scheduler.addObject(oID: myhoodoRunStreamListener.myID, o: myhoodoRunStreamListener ){
            //myLocationTracker?.addListener(oCAT: myLiveRunStreamListener.myCategory, oID: myLiveRunStreamListener.myID, name: myLiveRunStreamListener.name)
            
            return myhoodoRunStreamListener
        }
        
        return nil
        
    }
    
    func addRunStreamRecorder () -> RunStreamRecorder? {
        
        //this will listen and act as a general storage
        
        if let mlt = storage.getObject(oID: "runStreamRecorder") as! RunStreamRecorder? {
            
            mlt._pulse(pulseBySeconds: 120)
            return mlt
            
        }
        
        //create new, assume that old one is terminaattod
        let myRunStreamRecorder = RunStreamRecorder(messageQueue: messageQueue);
        myRunStreamRecorder._initialize()
        myRunStreamRecorder._pulse(pulseBySeconds: 120);
        
        if scheduler.addObject(oID: myRunStreamRecorder.myID, o: myRunStreamRecorder ){
            //myLocationTracker?.addListener(oCAT: myLiveRunStreamListener.myCategory, oID: myLiveRunStreamListener.myID, name: myLiveRunStreamListener.name)
            
            return myRunStreamRecorder
        }
        
        return nil
        
    }
    
    
    func pollNewPeerForData (peer : Peer ) {
        
        //see if we have a poller for this
        let name = "PEER" + peer.identifier;
        
        
        if let pdc = self.addPeerDataRequester(peer: peer) {
            
            pdc.requestHashes();
        }
        
        //prime some hash data hopefully
        //use PullRunsFromDisk to get loads and loads of hashes
        if let dp = self.addHashSetProvider() {
            dp.scanForRuns()
        }
        
    }
    
}

