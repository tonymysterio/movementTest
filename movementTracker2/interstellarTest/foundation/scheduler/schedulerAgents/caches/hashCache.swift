//
//  hashCache.swift
//  movementTracker2
//
//  Created by sami on 2018/03/15.
//  Copyright © 2018年 pancristal. All rights reserved.
//

import Foundation
import Disk

class HashCache : BaseObject  {
    
    let ioQueue = DispatchQueue(label: "hashCacheIOQueue", qos: .utility)
    let dataQueue = DispatchQueue(label: "hashCacheDataQueue", qos: .userInitiated)
    let path = "hashCache" //runData"
    //dont store runs here
    var cache = exchangedHashes();
    var cacheIsDirty = false;
    var getWithinArea : Double = 0;
    
    var lastInsertTimestamp = Date().timeIntervalSince1970
    
    override func _initialize () -> DROPcategoryTypes? {
        
        schedulerAgentType = schedulerAgents.hashCache;
        self.name = schedulerAgents.hashCache.rawValue;
        self.myID = schedulerAgents.hashCache.rawValue;
        
        self.myCategory = objectCategoryTypes.cache;
        
        self.myHibernationStrategy = hibernationStrategy.persist  //dont hibernate
        self.myMemoryPressureStrategy = memoryPressureStrategy.purgeCaches  //release memory thru _purge
        
        //would be better do dirty snaps on housekeep
        
        //disappears
        _pulse(pulseBySeconds: 60);
        
        prime();
        
        
        isInitialized = true;
        return  nil
        
    }
    
    func prime () {
        
        //ghetto pull all file hashes
        //add
        if isPrimed { return }
        ioQueue.async (){
            // Get contents in directory: '.' (current one)
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0];
            let luss : String = documentsURL.path + "/runData/";
            
            if let urlEncoded = luss.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                let url = URL(string: urlEncoded);
                
                do {
                    let fileURLs = try fileManager.contentsOfDirectory(at: url! , includingPropertiesForKeys: nil)
                    for i in fileURLs {
                        
                        let last4 = i.path.suffix(5);
                        if last4 == ".json" {
                            
                            let lim = i.path.split(separator: "/")
                            if let lam  = lim.last?.split(separator: ".") {
                                //print (lam[0]);
                                let luxor = String(lam[0]);
                                
                                _ = self.cache.insertForUser(user: "everything", hash: luxor);
                                
                                /*if !self.ignoredCachedHashes.contains(luxor) {
                                    let rloader = RunLoader(filename: luxor);
                                    self.files.append(rloader) //just the filename part for Disk to read
                                }*/
                                
                                
                                
                            }
                            
                        }
                        
                    }
                    
                    self.isPrimed = true;
                    //print (fileURLs);
                    // process files
                } catch {
                    //print("Error while enumerating files \(destinationFolder.path): \(error.localizedDescription)")
                    print("diskreader no data found - bailing out")
                    
                }
                
            }
            
            //let url = URL(string: luss)
        }   //end async

        
    }
    
    func insertForUser ( user : String , hash : String) {
        
        //paranoia here about processing terminating etc
        dataQueue.sync {
            
            cache.insertForUser(user: user, hash: hash);
        
        }
    }
    
    func getHashesToShowFor ( user: String ) -> orderedHashList? {
        
        //peer data provider shows some hashes for this user
        guard let ss = cache.orderAllLatestFirst() else {
            return nil;
        }
        
        return ss;
        
    }
    
    func doIhaveHash ( hash : String ) -> Bool {
        
        return cache.doIhaveHash(hash: hash)
        //return cache.doIhaveHash ( hash: hash );
        
    }
    
    func missingFromMe ( ohl : orderedHashList ) -> orderedHashList? {
        
        if cache.isEmpty() { return ohl; }
        return cache.missingFromMe(hashes:ohl)
        
        
    }
    
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        _pulse(pulseBySeconds: 6000); //keep me alive
        return nil;
        
    }

}
