//
//  MapCombiner.swift
//  interStellarTest
//
//  Created by sami on 2017/11/25.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import Interstellar
import Swifter
import Disk

//import GEOSwift


class PeerDataProvider : BaseObject  {
    
    let queue = DispatchQueue(label: "PeerDataProviderQueue", qos: .utility)
    var primed = false;
    //var queriedHashes : storedHashes
    //var sentHashes : storedHashes
    var myExhangedHashes = exchangedHashes()
    private var server: HttpServer?
    
    func _initialize () -> DROPcategoryTypes? {
        
        //passing hashes of all my held data might lead to a massive packet to send over
        
        //myCategory = objectCategoryTypes.uniqueServiceProvider  //only one file accessor at a time
        self.name = "PeerDataProvider"
        self.myID = "PeerDataProvider"
        self.myCategory = objectCategoryTypes.uniqueServiceProvider
        
        //disappears
        _pulse(pulseBySeconds: 600)
        
        //if for some reason we cannot store to disk, give this
        //DROPcategoryTypes.serviceNotAvailable
        
        //if disk space is low, return
        //DROPcategoryTypes.lowDiskspace
        
        
        
        //filter irrelevant runs by distance
        
        //pullRunsFromDisk also shouts here
        peerDataProviderExistingHashesObserver.subscribe{ hashes in
         
            self.peerDataProviderExistingHashesReceived( hashes : hashes )
         
         }
         
         //hoodoRunStreamListener pages us when it reads a run from stream etc
         /*runStreamReaderDataArrivedObserver.subscribe
         { run in
         self.addRun( run : run )
         
         }*/
        
        self.startServer()
        
        return nil
        
    }
    
    func startServer () {
        
        //kick swifter alive
        primed = false;
        let server = HttpServer()
        server["/hello"] = { .ok(.html("You asked for \($0)"))  }
        
        server["/stream"] = { r in
            return HttpResponse.raw(200, "OK", nil, { w in
                
                let dux = r.queryParams;
                
                for i in 0...100 {
                    try w.write([UInt8]("[chunk \(i)] \(dux)".utf8))
                }
            })
        }
        
        server["/storedhashes"] = { r in
            return HttpResponse.raw(200, "OK", nil, { w in
                
                var dux = "empty"
                if !self.myExhangedHashes.isEmpty() {
                    
                    //returns orderedHashList
                    let latestFirst = self.myExhangedHashes.orderAllLatestFirst()
                    let encoder = JSONEncoder()
                    let data = try! encoder.encode(latestFirst)
                    let naz = (String(data: data, encoding: .utf8)!)
                    try w.write([UInt8](naz.utf8))
                    
                    //print(String(data: data, encoding: .utf8)!)
                    
                    //dux = data;
                }
                
                    //try w.write([UInt8]("[chunk \(i)] \(dux)".utf8))
                
            })
        }
        
        server["/gethash"] = { r in
            return HttpResponse.raw(200, "OK", nil, { w in
                let key = r.queryParams[0]
                let path = "runData/" + key.1 + ".json"
                
                if let retrievedMessage = try Disk.retrieve(path, from: .caches, as: Run?.self) {
                    
                    let encoder = JSONEncoder()
                    let data = try! encoder.encode(retrievedMessage)
                    let naz = (String(data: data, encoding: .utf8)!)
                    try w.write([UInt8](naz.utf8))
                    
                } else {
                    
                    try w.write([UInt8]("NOT_FOUND".utf8))
                    
                }
                
                
            })
        }
        
        
        do {
            
            try server.start()
            self.server = server
            
        } catch {
            
            print("server borked")
            
        }
        
        

        /*do {
            let server = demoServer(Bundle.main.resourcePath!)
            try server.start(9080)
            self.server = server
        } catch {
            print("Server start error: \(error)")
        }*/
        
    }
    
    override func _finalize() -> DROPcategoryTypes? {
        
        //just stop the server
        self.server?.stop()
        return nil
    }
    
    func primeMyRunHashes ( hashes : [String]) {
        
        //query pullRunsFromDisk for this
        //self.server?.GET
        
    }
    
    func peerDataProviderExistingHashesReceived ( hashes : exchangedHashes ) {
        
        //list of stuff we have got
        
        //if list of hashes does not happen, TTL shortly. no data, no play
        queue.sync {
            
            //TODO: this should update not overwrite
            
            myExhangedHashes = hashes
            
            let orderAllLatestFirst = hashes.orderAllLatestFirst()
            
            //print (hashes)
        }
        
        primed = true;
    }
    
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        
        return nil
    }
    
    
    
    
}


