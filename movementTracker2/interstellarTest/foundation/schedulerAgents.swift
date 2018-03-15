//
//  schedulerAgents.swift
//  movementTracker2
//
//  Created by sami on 2018/03/13.
//  Copyright © 2018年 pancristal. All rights reserved.
//

import Foundation



//makign this into an enum means updating the base object every time a new variation is created
enum objectCategoryTypes: String {
    
    case generic = "generic" //string out of enums!
    case user = "user"
    case group = "group"
    case debugger = "debugger"
    case uniqueServiceProvider = "uniqueServiceProvider"  //can only have one of these running at any time
    //like gps logger, motion logger...  //when adding to object storage, confirm that only on is alive
    
    case motionlistener = "motionlistener"  //listens to coreMotion events
    case locationlistener = "locationlistener" //listens to coreLocation events
    case cache = "cache" //cache for something
    case mapCombiner = "mapCombiner";
    static func allValues() -> [objectCategoryTypes] {
        return [.generic, .user, .group, .debugger, .uniqueServiceProvider ,.motionlistener , .locationlistener, .cache, .mapCombiner]
    }
}

enum schedulerAgents: String {
    
    case runCache = "runCache"
    case snapshotCache = "snapshotCache"
    case hashCache = "hashCache"    //share hash cache for all participants of meshnet transfer
    
    //controlled by packet exchange junction
    case peerDataRequester = "peerDataRequester"    //meshnet, asks for missing blocks
    case peerDataProvider = "peerDataProvider"   //meshnet, server that responds to block requests
    case servusMeshnetProvider = "servusMeshnetProvider"    //meshnet peer discovery
    
    case jsonStreamReader = "jsonStreamReader"  //tries to pull a endless stream of runs, parse and send ahead
    case JSONstreamRequestor = "JSONstreamRequestor"  //opens a json stream resource for jsonstreamreader to listen to, intelligent as fuck
    
    case locationLogger = "locationLogger"  //the one to access ios location. pushes messages if active
    
    case mapCombiner = "mapCombiner";
    case pedometer = "pedometer"
    
    //subcategories persistent storage
    
    case pullRunsFromDisk = "pullRunsFromDisk"  //bad boy that just pulls shitload of data to cache now
    case runStreamRecorder = "runStreamRecorder" //run data incoming from mesh, stream, wherever, this saves it to disk
    case currentRunDataIO = "currentRunDataIO" //when run is on this saves current run in case we drop something
    
    case liveRunStreamListener = "liveRunStreamListener"    //we are on a run, this receives data from locationlogger
    
    case timewaster = "timewaster"  //TEST agent that just wastes time and dies
    case worrier = "worrier"    //TEST agent that is worried about agents who get killed. a group supervisor?
    
    case generic = "generic"    //anything generic is dubious and probably deprecated
    
    static func allValues() -> [schedulerAgents] {
        return [.runCache,.snapshotCache,.peerDataRequester,.peerDataProvider,.servusMeshnetProvider,.jsonStreamReader,.locationLogger,.mapCombiner,.pedometer,.pullRunsFromDisk,.runStreamRecorder,.currentRunDataIO,.liveRunStreamListener,.timewaster,.worrier,.generic]
    }
}

struct schedulerAgentGroup {
    
    let data = [String]();
    
}

struct schedulerAgentGroups {
    
    var list : [String:[String]]
    
    init(){
        
        list  = [:]
    }
    
    //group by function
    //name after the junction that oversees this group
    //let papa = schedulerAgentGroup([schedulerAgents.locationLogger,schedulerAgents.liveRunStreamListener]);
    mutating func add ( ek : String, e : [String] ) {
        
        self.list[ek] = e ;
        
    }
    
}

func createSchedulerAgent ( agent: String) -> BaseObject? {
    
    switch agent {
    case "peerDataRequester" :
        
        return PeerDataRequester(messageQueue: nil);
        
        
    case "peerDataProvider" :
        
        return PeerDataProvider(messageQueue: nil);
        
    case "servusMeshnetProvider" :
        
        return ServusMeshnetProvider(messageQueue: nil);
        
    case "hashCache" :
        
        return HashCache(messageQueue: nil);
        
    default:
        print("createSchedulerAgent could not create \(agent), missing case!")
        return nil;
    }
    
}

//let packetExchange = [ schedulerAgents.peerDataRequester , schedulerAgents.peerDataProvider , schedulerAgents.servusMeshnetProvider ]
//let runRecorder = [schedulerAgents.locationLogger,schedulerAgents.liveRunStreamListener]    //bare minimum co dependent components to keep run recording going




