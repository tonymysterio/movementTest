//
//  locationDataRouter.swift
//  movementTracker2
//
//  Created by sami on 2017/11/06.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import Foundation

enum reachabilityStatus {
    
    case wifi
    case cellular
    case unreachable
}

struct appStatus {
    
    var mapVisible : Bool = false
    var onBackgroundMode = false    //just collect data on background mode, alert if a goal is met
                                    //going to background cancels all outgoing network traffic
    
    var reachability : reachabilityStatus
    var onTheMove = false;  //are we collecting movement data?
    var primingPersonalLocationData = true  //pulling stuff out of a disk?
                                            //if no data or failure, just start with empty data object
    
}

class locationDataRouter {
    
    //
    
    
    
    
}
