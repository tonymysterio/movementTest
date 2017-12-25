//
//  worrier.swift
//  interStellarTest
//
//  Created by sami on 2017/07/11.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation
//
//  timewaster.swift
//  interStellarTest
//
//  Created by sami on 2017/07/04.
//  Copyright © 2017年 pancristal. All rights reserved.
//

//worrier wont send messages

class Worrier : BaseObject {
    
    var interruptTask = false;
    
    
    override func _housekeep_extend() -> DROPcategoryTypes? {
        
        //should we do this at listener level. listen_extend DOES NOT CONTAIN anything vital
        //just ignore the request with a DROP, the request will come again if its important
        
        //ask this guy to waste time
        //return wasteTime();
        
        //if im housekeeping anybody, do that after all the other stuff is done
        
        _ = self._pulse(pulseBySeconds: 60 )    //keep on living
        
        return nil
        
    }
    
    
    override func _LISTEN_extend(o: internalMessage) -> DROPcategoryTypes? {
        
        switch o.o {
        case let .EXIT:
            
            print (" \(o.from) \(o.name) EXITed. Oh dear. ")
            
            break;
            
        case let .DROP:
            
            print (" \(o.from) \(o.name) is DROPping data. Oh dear oh dear. ")
            
            break;
            
        
            
           
            
        default:
                break
            
        }
        
        //any messages keep worryaunt interested. even location messages and shit if worryaunt is the listener of these things
        
        self._pulse(pulseBySeconds: 6000 )
        return nil
        
    }   //end of listen extend
    
    
}
