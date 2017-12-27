//
//  MapCombiner.swift
//  interStellarTest
//
//  Created by sami on 2017/11/25.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import Interstellar
import Alamofire

//import GEOSwift


class PeerDataRequester : BaseObject  {
    
    let queue = DispatchQueue(label: "PeerDataRequesterQueue", qos: .utility)
    var host : String = "" //host where to pull the request from
    var requestParameters : String = ""
    var hashesPrimed = false;
    var myExhangedHashes = exchangedHashes()
    var hostname = "";
    var identifier = "";
    
    var missingRunHashes = [String]()
    var fetchMissingHashes = false
    var unforgivableAmountOfConnectionErrors = 5;
    
    //var hisOrderedHashList : orderedHashList
    //ask for the hash list multiple times after exchanging data
    //this way if the recipient is recieving runs from other parties, the changes get reflected
    //or plan b: pull what you can and query again in the end?
    
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
    
    func requestHashes (  ) {
        
        //simple JSON request
        // to: host with requestParameters
        if self.isProcessing { return } //drop
        if self.terminated { return }
        //PROTO
        //pass hashes of held run data, please give me anything but this
        
        //hash ecxhange -> individual requests to separate entries
        //individual requests all
        let resourceUrl = "http://"+self.hostname+":8080/storedhashes"
        self.startProcessing()
        
        //keep responses sho
        Alamofire.request(
            URL(string: resourceUrl)!,
            method: .get,
            parameters: ["include_docs": "true"])
            .validate()
            .responseJSON { (response) -> Void in
                guard response.result.isSuccess else {
                    print("peerdatarequest Error while fetching : \(resourceUrl)")
                    
                    //print("peerdatarequest Error while fetching : \(response.result.error)")
                    //completion(nil)
                    self.orderedHashListRequestErrorHandler()
                    return
                }
                
                if self.terminated { return }
                
                let decoder = JSONDecoder()
                guard let ordHashList = try! decoder.decode( orderedHashList?.self, from : response.data as! Data ) else {
                    
                    self.orderedHashListRequestErrorHandler()
                    
                    return
                    
                }
                
                //parsed this clients hashlist
                self.orderedHashListRequestSuccess ( ordHashList : ordHashList )
            }
    
    }
    
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        if self.isProcessing {  return DROPcategoryTypes.busyProcessesing }
        
        if !self.fetchMissingHashes {
            
                //try to get dat list
                self.requestHashes()
            }
        
        self.fetchMissingHash()
        
        return nil
        
    }
    
    func fetchMissingHash(){
        
        if self.missingRunHashes.isEmpty {
            
            fetchMissingHashes = false;
            return;
        }
        
        if self.isProcessing {
            
            return;
        }
        
        //pull a run hashu
        
        self.startProcessing()
        let hash = self.missingRunHashes.popLast()
        let resourceUrl = "http://"+self.hostname+":8080/gethash?hash=" + (hash)!
        //keep responses sho
        
        
        Alamofire.request(
            URL(string: resourceUrl)!,
            method: .get,
            parameters: ["hash": hash])
            .validate()
            .responseJSON { (response) -> Void in
                guard response.result.isSuccess else {
                    //print("peerdatarequest Error while fetching : \(resourceUrl)")
                    
                    print("peerdatarequest Error while fetching : \(response.result.error)")
                    //completion(nil)
                    self.orderedHashRequestErrorHandler()
                    return
                }
                
                if self.terminated { return }
                
                let decoder = JSONDecoder()
                guard let run = try! decoder.decode( Run?.self, from : response.data as! Data ) else {
                    
                    self.orderedHashRequestErrorHandler()
                    
                    return
                    
                }
                
                //parsed this clients hashlist
                self.orderedHashRequestSuccess ( run : run )
        }
        
        
        
    }
    
    func orderedHashListRequestErrorHandler () {
        
        self.unforgivableAmountOfConnectionErrors = unforgivableAmountOfConnectionErrors - 1;
        if (self.unforgivableAmountOfConnectionErrors == 0) {
            self._teardown()
            return;
        }
            self.finishProcessing()
            
        }
    
    func orderedHashRequestErrorHandler () {
        
        if (self.unforgivableAmountOfConnectionErrors == 0) {
            self._teardown()
            return;
        }
        
        self.finishProcessing()
        
    }
    
    func orderedHashRequestSuccess ( run : Run ) {
        
        self.finishProcessing()
        peerDataRequesterRunArrivedObserver.update(run) //tell packetExchange that we got the requested run
        peerExplorerKeepAliveObserver.update(true)  //ask packetEx to keep servus running a bit longer
    }
    
    
    func orderedHashListRequestSuccess ( ordHashList : orderedHashList ) {
        
        if self.terminated { return }
        self.finishProcessing()
        
        //see if i have received my own hashlist
        if myExhangedHashes.isEmpty() {
            return;
        }
        queue.sync {
            let myHlist = myExhangedHashes.getAll();
            var missing = [String]()
            for f in ordHashList.list {
            
            if !(myHlist!.contains(f)) {
                missing.append(f)
            }
            
            }
        
            if missing.isEmpty {
            //hes got nothing for me
            return;
            }
            //whats left after my and his overlap?
            print ("orderedHashListRequestSuccess: im missing  \(missing)" )
            //push missing ones to request queue
            self.missingRunHashes = missing;
            self.fetchMissingHashes = true;
            self._pulse(pulseBySeconds: 120)
            
            peerExplorerKeepAliveObserver.update(true)  //ask packetEx to keep servus running a bit longer
            
        }
        
        //pull one after another
        
        
    }
        
    func peerDataProviderExistingHashesReceived ( hashes : exchangedHashes ) {
        
        //list of stuff we have got
        queue.sync {
            
            myExhangedHashes = hashes
            
        }
        
        hashesPrimed = true;
    }
    
   
    
    
    
}

