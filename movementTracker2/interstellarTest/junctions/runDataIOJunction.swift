//
//  runDataIOJunction.swift
//  interStellarTest
//
//  Created by sami on 2017/11/25.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import Interstellar

var runStreamReaderObserver = Observable<Bool>()
var runJSONStreamReaderObserver = Observable<Bool>()
var runStreamReaderDataArrivedObserver = Observable<Run>()
var runStreamReaderRawDataArrivedObserver = Observable<Run>()



class runDataIOJunction {
    
    var recording = false;
    //for all our listview, stream reading fun
    weak var myJsonStreamReader : jsonStreamReader?
    weak var myHoodoRunStreamListener : hoodoRunStreamListener?
    weak var myRunStreamRecorder : RunStreamRecorder?
    func initialize () {
        
        print("runDataIOJunction - listening to UI actions about pulling or sending JSON DAATTA")
        
        //after getting some lovely run objos, save them to disk! Brilliant!
        
    }
    
    func streamPullStatusChange ( toggle : Bool ) {
        
        //first handle off situazione
        if !toggle {
            reset();
            return
        }
        
        if let mlt = storage.getObject(oID: "jsonStreamReader") as! jsonStreamReader? {
            
            
        } else {
            
            let myJsonStreamReader = jsonStreamReader( messageQueue : messageQueue );
            myJsonStreamReader.houseKeepingRole = houseKeepingRoles.slave;
            myJsonStreamReader._pulse(pulseBySeconds: 60);
            myJsonStreamReader._initialize() //let initializer to give initial pulse?
            
            //autoadd worryaunt for all objexts in
            //worryaunt knows about my big exit, scheduler does not care
            //myJsonStreamReader.addListener(oCAT: worryAunt.myCategory, oID: worryAunt.myID, name: worryAunt.name)
            _ = scheduler.addObject(oID: myJsonStreamReader.myID , o: myJsonStreamReader )
            
        }
        
        /*if myRunStreamRecorder == nil {
            
            let myRunStreamRecorder = RunStreamRecorder(messageQueue : messageQueue );
            myRunStreamRecorder._initialize()
            myRunStreamRecorder._pulse(pulseBySeconds: 60)
            _ = scheduler.addObject(oID: myRunStreamRecorder.myID , o: myRunStreamRecorder )
            
        }*/
        
        //force record to disk
        
        if myHoodoRunStreamListener == nil {
            
            let myHoodoRunStreamListener = hoodoRunStreamListener(messageQueue : messageQueue );
            myHoodoRunStreamListener._initialize()
            myHoodoRunStreamListener._pulse(pulseBySeconds: 60)
            _ = scheduler.addObject(oID: myHoodoRunStreamListener.myID , o: myHoodoRunStreamListener )
            
        }
        
    }
    
    func runStreamReaderDataArrived ( run : Run ) {
        
        //reading a html string of runs
        
        //we need our guy myRunStreamRecorder for da job
        //myRunStreamRecorder?.storeRun(run: run)
        if let mlt = addRunStreamRecorder() as! RunStreamRecorder? {
            mlt.storeRun(run: run)
            
            print("storing captured run")
        }
        
        //throw this into cache too
        if let runcache = storage.getObject(oID: "runCache") as! RunCache?  {
            
            runcache.addRun(run: run);
            //
        }
        
    }
    
    //copied from packetExchange
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
    
    
    func reset () {
        
        //finalize jsonStreamReader
        if let mlt = storage.getObject(oID: "jsonStreamReader") as! jsonStreamReader? {
            mlt._finalize()
        }
        //persistent storage storing incoming runs
        if let mlt = storage.getObject(oID: "runStreamRecorder") as! RunStreamRecorder? {
            mlt._finalize()
        }
        
        if let mlt = storage.getObject(oID: "hoodoRunStreamListener") as! hoodoRunStreamListener? {
            mlt._finalize()
        }
        
        /*if myJsonStreamReader != nil {
            
            myJsonStreamReader?._finalize()
        }
        //finalize hoodoRunStreamListener
        if myHoodoRunStreamListener != nil {
            
            myHoodoRunStreamListener?._finalize()
            
        }*/
        
        
    }
    
    func peerDataRequesterRunArrivedSaved() {
        
        //current run was closed and saved
        
        
        
    }
    
    
    init () {
        
        runJSONStreamReaderObserver.subscribe { toggle in
            //DispatchQueue.global(qos: .utility).async {
            DispatchQueue.main.async {
                self.streamPullStatusChange( toggle : toggle)
            }
            //}
        }
        
        runStreamReaderObserver.subscribe { toggle in
            //DispatchQueue.global(qos: .utility).async {
                self.streamPullStatusChange( toggle : toggle)
            //}
        }
        
        runStreamReaderDataArrivedObserver.subscribe { run in
            //run data picked from json stream. save it
            //DispatchQueue.global(qos: .utility).async {
            DispatchQueue.main.async {
                
                //creates disk writers and shit maybe
                self.runStreamReaderDataArrived(run : run)
            }
        }
        
        peerDataRequesterRunArrivedSavedObserver.subscribe { run in
            //runstream recorder has saved the run
           // DispatchQueue.global(qos: .utility).async {
                self.peerDataRequesterRunArrivedSaved()
            //}
        }
    }
    
}
