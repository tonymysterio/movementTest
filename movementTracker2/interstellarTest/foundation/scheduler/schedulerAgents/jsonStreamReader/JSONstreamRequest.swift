//
//  JSONstreamRequest.swift
//  interStellarTest
//
//  Created by sami on 2017/11/09.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import Alamofire

/*
 
 */

class JSONstreamRequestor : BaseObject {
    
    var interruptTask = false;
    
    override func _LISTEN_extend ( o: internalMessage ) -> DROPcategoryTypes? {
        
        //if let type = o["type"]
        
        
        /*switch o.o["type"] as? String {   //filter null values
         case .some("wasteTime"):
         return wasteTime()
         default:
         return nil
         }*/
        
        return nil
    }
    
    func makeAndParseArequest () -> DROPcategoryTypes? {
        
        let urlString = "http://localhost:5000"
        
        
        
           // let expectation = expectationWithDescription("Video image should succeed")
            var gatheredEnoughImageData = false
            let imageData: NSMutableData = NSMutableData()
            
            let request = Alamofire.request(urlString)
            request.validate(statusCode: 200..<400)
            request.stream { data in
                guard !gatheredEnoughImageData else { return }
                
                //imageData.append(data)
                
                print("New data: \(data.count)")
                
                if imageData.length > 300_000 {
                    gatheredEnoughImageData = true
                    request.cancel()
                    //expectation.fulfill()
                }
            }
            
            //waitForExpectationsWithTimeout(timeout, handler: nil)
            
            print("Final Image Data Length: \(imageData.length)")
        
        
        
        return nil
        
    }
    
    func wasteTime () -> DROPcategoryTypes? {
        
        if self.terminated == true {
            return DROPcategoryTypes.terminating
        }
        
        let a = startProcessing()
        //we are already wasting time
        if (a != nil) {
            return a
        }
        _ = self._pulse(pulseBySeconds: 60 )
        
        let delay = Int(randomIntFromInterval(min: 1, max: 3))
        //new GDC syntax, do on background
        
        
        var results = [Int]()
        /*DispatchQueue.concurrentPerform(iterations: 100) {i in
         
         results.append(123)
         }   //async loop
         
         
         
         */
        
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds( delay ), execute: {
            
            if (self.terminated == true){
                //no need to care about finishProcessing or anything, we are dead dead dead
                return ;   //dont start doing anything if i was terminated
            }
            
            //what is our purge strategy? purge should not stop existing workloads
            
            //if task is interrupted, tell somebody somewhere we are DROP ping shit
            
            
            // Put your code which should be executed with a delay here
            _ = self.finishProcessing()
            
            //timewaster does not have to _finalize, no data to keep
            _ = self._teardown()
            
            //
            //self._pulse(pulseBySeconds: 60 )
            //print("finished wasting time \(self.myID) .EXIT")
            
            
        })
        
        //        let tw = Timewaster();
        
        
        //this is not sane
        
        let greatSuccess = self.scheduler?.addAfunObjectForMe {
            // TODO
            let tw = Timewaster( messageQueue : messageQueue ); //copies reference to messageQueue
            // init
            
            return tw
        }
        
        return nil
        
    }
    
    
    
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        //should we do this at listener level. listen_extend DOES NOT CONTAIN anything vital
        //just ignore the request with a DROP, the request will come again if its important
        
        //ask this guy to waste time
        return wasteTime();
        
        //if im housekeeping anybody, do that after all the other stuff is done
        
        
        
    }
    
    override func _purge ( backPressure : Int ) -> Int {
        
        //if im processing, do x
        //backpressure is 1 (warning) 99999999... (GTFO now)
        
        if (backPressure > purgeRequestEXITtreshold ) {
            
            self._teardown()
            let rema = backPressure - purgeRequestEXITtreshold
            return rema //too much back pressure, just bail out
        }
        
        isPurging = true
        
        let b = Double ( backPressure * 30 )
        let TTLdeducted = self.TTL - b //deduct by one housekeep round
        
        if (TTLdeducted < self.uxT()){
            
            self._teardown()    //some objects need finalize, timewaster does not
            return backPressure
        }
        
        TTL = TTLdeducted   //_pulse() will keep this up if something meaningful happens
        //in timewasters case it never does and we will teardown
        //some other object would do purge in a different way, block incoming data..
        
        return 1    //down by one click
        
        
        //returns a guesstimate how much pressure is relieved with my action
        
        //if not, just drop my TTL
        //the objects are somewhere else anyway
        //Scheduler just asks me to purge, i react how i react
        
        //objects die out with TTL only, nothing stays for too long anyway
        
        //default purge does absolutely nothing. you are stuck with us baby
        
        return 0
    }
    
}
