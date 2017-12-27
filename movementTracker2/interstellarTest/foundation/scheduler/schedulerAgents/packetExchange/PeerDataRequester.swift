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
                    print("peerdatarequest Error while fetching : \(response.result.error)")
                    //completion(nil)
                    self.orderedHashListRequestErrorHandler()
                    return
                }
                
                guard let value = response.result.value as? [String: Any],
                    let rows = value["rows"] as? [[String: Any]] else {
                        print("Malformed data received from fetchAllRooms service")
                        //completion(nil)
                        self.orderedHashListRequestErrorHandler()
                        
                        return
                }
                
                /*let rooms = rows.flatMap({ (roomDict) -> RemoteRoom? in
                    return RemoteRoom(jsonData: roomDict)
                })*/
                
                var resString = response.result.value as! Data;
                
                let decoder = JSONDecoder()
                guard let ordHashList = try! decoder.decode( orderedHashList?.self, from : resString ) else {
                    
                    self.orderedHashListRequestErrorHandler()
                    
                    return
                    
                }
                
                //parsed this clients hashlist
                self.orderedHashListRequestSuccess ( ordHashList : ordHashList )
            }
    
    }
    
    func orderedHashListRequestErrorHandler () {
            
            self.finishProcessing()
            
        }
    
    func orderedHashListRequestSuccess ( ordHashList : orderedHashList ) {
        
        self.finishProcessing()
        
        //see if i have received my own hashlist
        if myExhangedHashes.isEmpty() {
            return;
        }
        
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
        
        
        //pull one after another
        
        
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

