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
    var totalRunItemsImported = 0;  //keep track of how much stuff we have pulled
    
    //var hisOrderedHashList : orderedHashList
    //ask for the hash list multiple times after exchanging data
    //this way if the recipient is recieving runs from other parties, the changes get reflected
    //or plan b: pull what you can and query again in the end?
    
    override func _initialize () -> DROPcategoryTypes? {
        if isInitialized { return nil }
        
        self.startProcessing();
        
        //passing hashes of all my held data might lead to a massive packet to send over
        schedulerAgentType = schedulerAgents.peerDataRequester
        agentIcon = "📣";
        //myCategory = objectCategoryTypes.uniqueServiceProvider  //only one file accessor at a time
        self.name = "PeerDataRequester"
        self.myID = "PeerDataRequester"
        self.myCategory = objectCategoryTypes.generic
        
        self.myHibernationStrategy = hibernationStrategy.hibernate  //dont hibernate
        self.myMemoryPressureStrategy = memoryPressureStrategy.finalize
        
        //disappears
        _pulse(pulseBySeconds: 60)
        
        //if for some reason we cannot store to disk, give this
        //DROPcategoryTypes.serviceNotAvailable
        
        //if disk space is low, return
        //DROPcategoryTypes.lowDiskspace
        
        
        peerDataProviderExistingHashesObserver.subscribe{ hashes in
            
            if self.isHibernating || self.terminated { return }
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
        
        
        isInitialized = true;
        self.finishProcessing();
        return nil
        
    }
    
    typealias rhashSuccess = ( _ hashList : orderedHashList ) -> Void
    typealias rhashError = () -> Void
    
    //func fetchOrCreateAgent( agent : String , name: String?, success : @escaping aSuccess , error : @escaping aError) {
        
    func requestHashes ( success : @escaping rhashSuccess , error : @escaping rhashError ) {
        
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
                    
                    print("peerdatarequest Error while fetching : \(response.result.error)")
                    
                    
                    //completion(nil)
                    self.orderedHashListRequestErrorHandler()
                    
                    error();
                    
                    _ = self.finishProcessing();
                    return
                }
                
                if self.terminated { return }
                
                
                
                let decoder = JSONDecoder()
                guard let ordHashList = try! decoder.decode( orderedHashList?.self, from : response.data as! Data ) else {
                    
                    self.orderedHashListRequestErrorHandler()
                    
                    error();
                    
                    _ = self.finishProcessing();
                    return
                    
                }
                
                //parsed this clients hashlist
                
                success(ordHashList)    //callback. junction should do magic
                
                self.orderedHashListRequestSuccess ( ordHashList : ordHashList )
                
                _ = self.finishProcessing();
            }
    
    }
    
    func primeMyRunHashes () {
        
        //query pullRunsFromDisk for this
        //self.server?.GET
        _ = self.startProcessing();
        //normally this should not be on cache
        if let cache = storage.getObject(oID: "runCache") as! RunCache? {
            if let cachedHashes = cache.cachedHashes() {
                
                if let cuha = cache.cachedUserHashes() {
                    
                    for i in cuha {
                        
                        self.myExhangedHashes.insertForUser(user: i[0], hash: i[1])
                        
                    }
                    //tell peer data provider what we got
                    //peerDataProviderExistingHashesObserver.update(self.myExhangedHashes);
                }
                
            }
            
        }
        
        _ = self.finishProcessing();
    }
    
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        if self.isProcessing {  return DROPcategoryTypes.busyProcessesing }
        
        //check if cache has new hashes
        
        /*if let cache = storage.getObject(oID: "runCache") as! RunCache? {
            
            if let r = cache.cachedHashes() {
                let rr = r as exchangedHashes;
                self.peerDataProviderExistingHashesReceived(hashes: rr )
            }
        }*/
        
        //peerDataProviderExistingHashesReceived
        
        
        if !self.fetchMissingHashes {
            
                //try to get dat list
            self.requestHashes(success: { hashList in
                
                }, error: {});
            
            }
        
        self.fetchMissingHash()
        
        return nil
        
    }
    
    override func _finalize() -> DROPcategoryTypes? {
        
        if self.totalRunItemsImported > 0 {
            
            let tot = String(self.totalRunItemsImported);
            
            let m = notificationMeiwaku(title: "meshnet service", subtitle: "shut down", body: "pulled \(tot) runs" ,sound : false, vibrate : false  )
            serviceStatusJunctionNotification.update(m);
            
        }
        
         
        
        
        //just stop the server
        
        return self._teardown()
    }
    
    func fetchMissingHash(){
        
        if self.terminated {
            
            return;
        }
        
        if self.missingRunHashes.isEmpty {
            
            fetchMissingHashes = false;
            return;
        }
        
        if self.isProcessing {
            
            return;
        }
        
        
        //pull a run hashu
        
        self.startProcessing();
        
        guard let hash = self.missingRunHashes.popLast() else {
            
            //nothing to pull
            self._finalize();
            return;
        }
        
        //do i have it im my cache.
        //if disk read has been slow or i got it from somewhere else maybe
        
        if let cache = storage.getObject(oID: "hashCache") as! HashCache? {
            
            if let ch = cache.getHashesToShowFor(user: "")
            {
                //reply with these
                
                self.finishProcessing();
                fetchMissingHash();
                
            }
        }
        
        
        /*if let cache = storage.getObject(oID: "runCache") as! RunCache? {
            
            if let r = cache.getRun(hash: hash) {
                
                self.finishProcessing();
                self.fetchMissingHash();
                
                return;
            }
        }*/
        
        //updates myExhangedHashes needs to update
        //maybe im downloading from multiple sources now
        //central storage for exchanged Hashes necessary!!
        
        
        let resourceUrl = "http://"+self.hostname+":8080/gethash?hash=" + (hash)
        print (resourceUrl);
        //keep responses sho
        
        self.finishProcessing();
        
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
                    self.orderedHashRequestErrorHandler();
                    //_ = self.finishProcessing();
                    return
                }
                
                if self.terminated { return }
                
                let decoder = JSONDecoder()
                guard let run = try! decoder.decode( Run?.self, from : response.data as! Data ) else {
                    
                    self.orderedHashRequestErrorHandler()
                    //_ = self.finishProcessing();
                    return
                    
                }
                //TODO add some checking if this run is valid
                //parsed this clients hashlist
                
                //some hashes maybe broken.
                var ran = run;
                ran.hash = ran.getHash();
                
                self.orderedHashRequestSuccess ( run : ran )
                //_ = self.finishProcessing();
        }
        
    }
    
    func orderedHashListRequestErrorHandler () {
        
        if self.terminated { return }
        
        self.unforgivableAmountOfConnectionErrors = unforgivableAmountOfConnectionErrors - 1;
        if (self.unforgivableAmountOfConnectionErrors == 0) {
            self._teardown()
            return;
        }
            self.finishProcessing()
            
        }
    
    func orderedHashRequestErrorHandler () {
        
        if self.terminated { return }
        
        if (self.unforgivableAmountOfConnectionErrors == 0) {
            self._teardown()
            return;
        }
        
        self.finishProcessing()
        
    }
    
    func orderedHashRequestSuccess ( run : Run ) {
        
        if self.terminated { return }
        
        self.finishProcessing()
        
        peerDataRequesterRunArrivedObserver.update(run) //tell packetExchange that we got the requested run
        
        peerExplorerKeepAliveObserver.update(true)  //ask packetEx to keep servus running a bit longer
        
        self.totalRunItemsImported = totalRunItemsImported + 1;
        
        let m = notificationMeiwaku(title: "meshnet service", subtitle: "orderedHashRequestSuccess", body: self.hostname ,sound : false, vibrate : false  )
        serviceStatusJunctionNotification.update(m);
        
        self.fetchMissingHash()
        
        
        
        //if ater ten runs, ask for his hashList in case hes downloading from at different people at the same time
        /*
        if (self.totalRunItemsImported % 5 == 0) {
            
            //put me into ask for more recent hashes mode
            self.fetchMissingHashes = false;
            
        }
        
        //this way we can get the latest blocks on the network
        myExhangedHashes.insertForUser(user: run.user, hash: run.hash)
        */
        
    }
    
    
    func orderedHashListRequestSuccess ( ordHashList : orderedHashList ) {
        
        if self.terminated { return }
        
        queue.sync {
        
            self._pulse(pulseBySeconds: 30);
            
            guard let cache = storage.getObject(oID: schedulerAgents.hashCache.rawValue) as! HashCache? else {
            
                //cache should be alive here.
                return;
            }
        
            guard let missing = cache.missingFromMe ( ohl : ordHashList ) else {
            
                //do another query with different set of stuff
                return;
            }
            
            
            //whats left after my and his overlap?
            print ("orderedHashListRequestSuccess: im missing  \(missing) from \(self.hostname)" )
                //push missing ones to request queue
            self.missingRunHashes = missing.list.shuffled();
            self.fetchMissingHashes = true;
            self._pulse(pulseBySeconds: 120)
        
            peerExplorerKeepAliveObserver.update(true)  //ask packetEx to keep servus running a bit longer
        
        }
        
        return;
        
        
        
        
        //see if i have received my own hashlist
        if myExhangedHashes.isEmpty() {
            //if no data, conjure some
            myExhangedHashes.addMockItemToGetPullingFromTarget();
        }
        
        
        
        queue.sync {
            
            //peek at the cache and insert to myExchangedHashes?
            
            
            let myHlist = myExhangedHashes.getAll();
            var missing = [String]()
            for f in ordHashList.list {
            
                if !(myHlist!.contains(f)) {
                    missing.append(f)
                }
            
            }
        
            if missing.isEmpty {
            //hes got nothing for me
                
                self._finalize()    //might not stick around for any longer, why bother
                return;
            }
            //whats left after my and his overlap?
            print ("orderedHashListRequestSuccess: im missing  \(missing)" )
            //push missing ones to request queue
            self.missingRunHashes = missing.shuffled();
            self.fetchMissingHashes = true;
            self._pulse(pulseBySeconds: 120)
            
            peerExplorerKeepAliveObserver.update(true)  //ask packetEx to keep servus running a bit longer
            
        }
        
        //pull one after another
        
        
    }
        
    func peerDataProviderExistingHashesReceived ( hashes : exchangedHashes ) {
        
        //list of stuff we have got
        queue.sync {
            
            myExhangedHashes.merge(hashes: hashes);
            
        }
        
        hashesPrimed = true;
    }
    
   
    
    
    
}

