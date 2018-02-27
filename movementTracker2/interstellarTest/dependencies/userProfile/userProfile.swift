//
//  userProfile.swift
//  movementTracker2
//
//  Created by sami on 2018/01/08.
//  Copyright © 2018年 pancristal. All rights reserved.
//

import Foundation

struct Player  {
    var playerID : String = ""
    var name : String = ""
    var clan : String = ""
    var email : String = ""
    var hash : String = ""
    var created : Double = 0
    var updated : Double = 0
    var runHashes : [String]
    var latestRunTimestamp : Double = 0
    var latestRunHash : String = ""
    var latestLocationGeoHash : String = ""
    
    init(playerID : String,name:String,clan:String,email:String,hash:String,created :Double,updated:Double,runHashes:[String],latestRunTimestamp:Double,latestRunHash:String, latestLocationGeoHash:String) {
        self.playerID = playerID
        self.name = name
        self.clan = clan
        self.email = email
        self.hash = hash
        self.created = created
        self.updated = updated
        self.runHashes = runHashes
        self.latestRunTimestamp = latestRunTimestamp
        self.latestRunHash = latestRunHash;
        self.latestLocationGeoHash = latestLocationGeoHash;
        
        
    }
/*var myID = String(Date().timeIntervalSince1970)
 var name = "defaultName"
 var created = Date().timeIntervalSince1970*/
    mutating func addRunHash (hash: String) {
        
        runHashes.append(hash);
        self.updated = Date().timeIntervalSince1970;
    }
    
    mutating func updateLatestLocation (time : Double, geoHash : String ) {
        if self.latestRunTimestamp > time {
            self.latestLocationGeoHash = geoHash;
            self.updated = Date().timeIntervalSince1970;
        }
       
        
    }
    
    
    
    mutating func updateLatestRun ( latestRunHash : String , latestRunTimestamp : Double ) {
        
        if self.latestRunTimestamp > latestRunTimestamp { return; }
        self.latestRunHash = latestRunHash;
        self.latestRunTimestamp = latestRunTimestamp;
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
    
    func getLocalPlayer () -> Player? {
        
        //its always the first one
        if self.list.count == 0 { return nil; }
        return self.list.first?.value;
        
    }
    
    func addPlayerWithCompute(name:String,email:String,clan: String) -> Player? {
        
        let hash = name+"_"+email;
        let created : Double = Date().timeIntervalSince1970;
        let updated : Double = Date().timeIntervalSince1970;
        let id = String(self.list.count);
        
        let p = Player(playerID:id,name:name,clan:clan,email:email,hash:hash,created:created,updated:updated,runHashes: [], latestRunTimestamp : 0 , latestRunHash : "",latestLocationGeoHash:"" )
        
        addPlayer(playa: p);
        
        return p;
    }
    
    
}
