//
//  MessageQueue.swift
//  interStellarTest
//
//  Created by sami on 2017/07/11.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation



class MessageQueue  {

    //messageQueue passes messages between objects
    //messageQueue does its own housekeeping
    //14.11.2017 processes can dump million messages a second and freeze the messageQueue
    //TODO: filter similar messages on SAY
    
    var messages = [internalMessage]()    //array Of internal messages
    var maxMessages = 100;
    var maxRelayPerClient = 1   //limit chatty user messages
    
    var newMessages = [internalMessage]()   //new messages are added here and transformed to main queue
    var insertingMessage = false;   //flag
    var isProcessing = false;
    
    /*override init() {
       
        //give a bit of lifetime to this guy
        self.TTL = self.TTL + self.PULSEextendBySecondsDefault;
        
    }*/
    var storage: MainStorageForObjects   //weak refrence to avoid crashing
    
    
    init (storage: MainStorageForObjects) {
        
        self.storage = storage
        
        
    }
    
    
    func LISTEN (i : internalMessage ) -> Void {
        
        //no news is good news here too
        //track chattyness here
        let serialQueue = DispatchQueue(label: "messageAppendQueue")
        
            serialQueue.sync {
            messages.append(i)
                
        }
        
        return
        
        
        
        
        
    }
    
    func RELAY () -> Void {
        
        if isProcessing {
        
            return
        }
            
        isProcessing = true
        
        //guard unwraps optionals
        /*if (newMessages.count != 0 ){
            
            for a in newMessages {
                
                messages.append(a)
                
            }
            
            insertingMessage = true
            newMessages.removeAll();    //get rid of entries
            insertingMessage = false
            
        }*/
        
        /*guard !messages.isEmpty else {
            
            isProcessing = false
            initHousekeeping()
            
            return }*/
        
        if messages.isEmpty {
            
            isProcessing = false
            initHousekeeping()
            return
            
        }
        
        let serialQueue = DispatchQueue(label: "messageAppendQueue")
        //processing one message at a time clogs the queue big time
        //push out more messages at one time if possible
        
        serialQueue.sync {
            
            if messages.isEmpty {
                
                isProcessing = false
                initHousekeeping()
                return
                
            }
            var survivors = [internalMessage] ()
            
            var prevSender = ""
            //var arid = 0
            
            let meco = messages.count
            
            print("OUTGOING messages \(meco) ")
            var culledUsers = [String : Bool ]()
            var culledMessages = 0
            
            for i in messages {
                
                if (culledUsers[i.to] != nil) {
                    
                    //this object does not exist, drop messages to this obj
                    culledMessages = culledMessages + 1
                    continue
                }
                
                if let o = getObject(oID : i.to) {
                    
                    //dont do async here. the target object does async if necessary
                    //messageQueue does not want to hear your DROPs or EXITs
                    //maybe it should, to purge EXITed object messages
                    if (prevSender != i.from){
                        
                        o.LISTEN(o: i);
                        prevSender = i.from
                    
                    } else {
                        //show this next round
                        survivors.append(i)
                        
                    }
                    continue
                    
                } else {
                    
                    culledUsers[i.to] = true
                    
                    
                    prevSender = "";   //ignore prev sender
                    //survivors.append(i)
                    continue
                }
                
                //if (prevSender != i.from){
                    
                    /*if let o = getObject(oID : i.to) {
                        
                        //dont do async here. the target object does async if necessary
                        //messageQueue does not want to hear your DROPs or EXITs
                        //maybe it should, to purge EXITed object messages
                        o.LISTEN(o: i);
                        prevSender = i.from
                        
                        continue
                        
                    } else {
                        
                        culledUsers[i.to] = true
                        
                        
                        prevSender = "";   //ignore prev sender
                        //survivors.append(i)
                        continue
                    }*/
                    
                    
                //}
                
                //unsent stuff
                survivors.append(i)
                
            }   //looping all messages
            
            messages = survivors    //these were not sent
            print("REMANING messages \(messages.count) CULLED: \(culledMessages) ")
            
            isProcessing = false
            initHousekeeping()
            
        }   //end of asynco
        
        
        /*var temp : [internalMessage]
        
        for t in messages {
            
            if removed[t] != nil {
                temp.append(t)
            }
        }*/
        
        //messages.remove(at: 0)
        
        //isProcessing = false
        
        //initHousekeeping()
        
    }   //END relay. this baby just calls relay
    
    func getObject (oID : String ) -> BaseObject? {
        
        return storage.getObject(oID : oID);
        
        
    }
    
    func _housekeep ()->Void {
        
        if isProcessing == true {
            initHousekeeping()  //process sometime else
            return;
        }
        
        RELAY();    //relays one or more messages
        
        
        
    }
    
    func initHousekeeping () -> Void {
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds( 300 ), execute: {
            
            
            
            // Put your code which should be executed with a delay here
            self._housekeep()
            //print("finished wasting time \(self.myID) ")
        })
        
        
    }
    
    
    
}

