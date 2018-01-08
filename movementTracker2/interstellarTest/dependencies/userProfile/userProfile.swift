//
//  userProfile.swift
//  movementTracker2
//
//  Created by sami on 2018/01/08.
//  Copyright © 2018年 pancristal. All rights reserved.
//

import Foundation

struct Player  {
    let playerID : String
    let name : String
    let clan : String
    let email : String
    let hash : String
    let created : Double
    var updated : Double
    var runHashes : [String]
    var latestRun : Double
    var latestLocationGeoHash : String
    
/*var myID = String(Date().timeIntervalSince1970)
 var name = "defaultName"
 var created = Date().timeIntervalSince1970*/
    mutating func addRunHash (hash: String) {
        
        runHashes.append(hash);
        self.updated = Date().timeIntervalSince1970;
    }
    
    mutating func updateLatestLocation (time : Double, geoHash : String ) {
        if self.latestRun > time {
            self.latestLocationGeoHash = geoHash;
            self.updated = Date().timeIntervalSince1970;
        }
       
        
    }
    
    
}  //targetID, senderID, Dictionary that is the message

class PlayerRoster {
    
    var list = [ String : Player]()
    let created : Double = Date().timeIntervalSince1970;
    var updated : Double = Date().timeIntervalSince1970;
    
    func initialize () {
        
        print("player roster here");
        
        runReceivedObservable.subscribe{ run in
            
            //disk reader vibes with this
            if var p = self.getPlayer(name: run.user) {
                
                p.addRunHash(hash: run.hash)
                p.updateLatestLocation(time: run.closeTime, geoHash: run.geoHash);
                return
            }
            if var uz = self.addPlayerWithCompute(name: run.user, email: run.user,clan: run.clan) as Player? {
                
                uz.addRunHash(hash: run.hash)
                return
            }
            
        }
        
    }
    
    func addPlayer (playa : Player) {
        
        if let p = self.list[playa.playerID] {
            
            
            return;
        }
        self.list[playa.playerID] = playa;
        self.updated = Date().timeIntervalSince1970;
        
        //notify somebody
        serviceStatusJunctionTotalUserProfiles.update(self.list.count);
        
        
    }
    
    func getPlayer ( name : String ) -> Player? {
        
        if self.list.count == 0 { return nil; }
        for i in self.list {
            
            if i.value.name == name { return i.value }
        }
        
        return nil
        
    }
    
    func addPlayerWithCompute(name:String,email:String,clan: String) -> Player? {
        
        let hash = name+"_"+email;
        let created : Double = Date().timeIntervalSince1970;
        let updated : Double = Date().timeIntervalSince1970;
        let id = String(self.list.count);
        
        let p = Player(playerID:id,name:name,clan:clan,email:email,hash:hash,created:created,updated:updated,runHashes: [], latestRun : 0,latestLocationGeoHash:"" )
        
        addPlayer(playa: p);
        
        return p;
    }
    
    
}
