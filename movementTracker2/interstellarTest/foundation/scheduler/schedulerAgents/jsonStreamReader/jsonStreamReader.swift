//
//  timewaster.swift
//  interStellarTest
//
//  Created by sami on 2017/07/04.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
import Alamofire


class jsonStreamReader : BaseObject {
    
    var interruptTask = false;
    var requestMade = false;
    var jsBuffScanner = jsonBufferScanner()
    var urlString = "http://192.168.11.54:5000/"
    let queue = DispatchQueue(label: "streamAnalyzerQueue", qos: .userInitiated)
    let dataFeederQueue = DispatchQueue(label: "dataFeedstreamAnalyzerQueue", qos: .userInitiated)
    
    func _initialize () -> DROPcategoryTypes? {
    
    
        myCategory = objectCategoryTypes.locationlistener
        self.name = "jsonStreamReader"
        self.myID = "jsonStreamReader"
        self.myCategory = objectCategoryTypes.locationlistener
        
        if self.isLowPowerModeEnabled() {
            //dont allow map combining on low power mode
            //
            self._teardown();
            return DROPcategoryTypes.lowBattery;
            
        }
        
        if !self.requestMade {
            //set myself as processing if the  stream request works and we get data
            self.makeAndParseArequest()
            self.requestMade = true;
        }
        
    
    
        return nil
    
    }
    
    
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
        
        //dont do this if im terminated or processing
        print("makeAndParseArequest:: talking to serverus fro stream");
        
        //let urlString = "http://192.168.11.54:5000/"
        
        self._pulse(pulseBySeconds: 60 )
        
        // let expectation = expectationWithDescription("Video image should succeed")
        var gatheredEnoughImageData = false
        
        
        let imageData: NSMutableData = NSMutableData()
        
        let request = Alamofire.request(urlString)
        request.validate(statusCode: 200..<400)
        request.stream { data in
            //guard !gatheredEnoughImageData else { return }
            
            if self.terminated {
                
                print("makeAndParseArequest:: terminated self");
                self.jsBuffScanner.terminated = true;
                request.cancel()
                return;
            }
            
            //having and active stream means we are processing data
            //if we mark this as processing for the request, it wont be housekept ever
            //self.startProcessing();
            
            //print("makeAndParseArequest:: data got");
            self.dataFeederQueue.sync {
               
                
                if let j = String(data:data, encoding:.utf8) {
                
                    //let jss = j.unescaped; //convert to string
                    //let intext = jss.replacingOccurrences(of: "\\", with: "")
                    print("$$jsb")
                    //jsonBufferScanner.
                    self.jsBuffScanner.addObject(text: j)
                    //_ = self.finishProcessing()
                
                    self._pulse(pulseBySeconds: 3500 )
                    //print("pulsed")
            
                }
            
            }
            //if we need to close the stream do it here
        
        }   ///end request stream closure
        
        
        return nil
        
    }   //end makeandparserequest
    

    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        //should we do this at listener level. listen_extend DOES NOT CONTAIN anything vital
        //just ignore the request with a DROP, the request will come again if its important
        
        if !requestMade {
            
            return DROPcategoryTypes.serviceNotReady
        }
        
        if self.isProcessing {
            
            return DROPcategoryTypes.busyProcessesing
            
        }
        
        //ask this guy to waste time
        //return wasteTime();
        
        //if im housekeeping anybody, do that after all the other stuff is done
        //if the inner class is still doing its thing, tell scheduler we are busy
        //the inner class should be something jsonStreamReader is talking to
        /*if jsBuffScanner.processing {
            
            //tell worryaunt too about my calamity
            DROP(dropCode: DROPcategoryTypes.busyProcessesing, reason: "busy parsing json objects with jsBufScanner")
            return DROPcategoryTypes.busyProcessesing;
        
        }*/
        
        if jsBuffScanner.processing {
         
            //tell worryaunt too about my calamity
            //DROP(dropCode: DROPcategoryTypes.busyProcessesing, reason: "busy parsing json objects with jsBufScanner")
            return DROPcategoryTypes.busyProcessesing;
         
         }
        
        //data contains something if theres something to process.
        if jsBuffScanner.data.count == 0 {
            return nil
            
        }
        //throw into utility queue
        
        self.startProcessing()
        
        //copy data
        
        //https://stackoverflow.com/questions/28523069/fatal-error-subscript-subrange-extends-past-string-end-xcode
        //queue.async {
        queue.sync {
            //self.jsBuffScanner.shiftInpipe();
            
            
            if let gnuk = self.jsBuffScanner.processBuffers(data: self.jsBuffScanner.data ) {
                
                for f in gnuk {
                    
                    /*let tS = self.uxT()
                    //let mu = locationMessage (timestamp: tS, lat: ll.latitude, lon: ll.longitude)
                    let o = CommMessage.RunMessage(type: "runStreamUpdate", oCAT: self.myCategory, oID: self.myID, run: f!)
                    
                    //DANGER to do this here , worryAunt gets this too
                    self.SAY(o: o)
                    */
                    
                    //pipe straigt to RunDataIO to be saved or..
                    if f.isValid && f.isClosed(){
                        
                        //patch hash
                        var ran = f;
                        ran.hash = ran.getHash();
                        
                        runStreamReaderDataArrivedObserver.update(ran)
                        
                    } else {
                        
                        print("invalid crap run. ei jatkoon" )
                    }
                    
                    
                }
                
                
                
            }
            
            //empty my buffer. json parser keeps stuff from last time around
            jsBuffScanner.data = "";
            
            _ = self.finishProcessing()
        }
        
        //processing in jsonStreamReader case is having and active stream request
        
        
        
        return nil
        
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

