//
//  AppDelegate.swift
//  movementTracker2
//
//  Created by sami on 2017/11/02.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import UIKit
import SwiftLocation
import Interstellar


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    //public let Locator: LocatorManager = LocatorManager.shared
    
    
    var window: UIWindow?
    //var lo =
    //signals from ui to scheduler
    //hook these up at junctions
    /*var maxObjectsSliderObserver = Observable<Float>()
    var maxCatObjectsSliderObserver = Observable<Float>()
    var motionLoggerToggleObserver = Observable<Bool>()
    var locationLoggerToggleObserver = Observable<Bool>()*/
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
        // If you start monitoring significant location changes and your app is subsequently terminated,
        /// the system automatically relaunches the app into the background if a new event arrives.
        // Upon relaunch, you must still subscribe to significant location changes to continue receiving location events.
        
        
        if let _ = launchOptions?[UIApplicationLaunchOptionsKey.location] {
            Locator.subscribeSignificantLocations(onUpdate: { newLocation in
                // This block will be executed with the details of the significant location change that triggered the background app launch,
                // and will continue to execute for any future significant location change events as well (unless canceled).
            }, onFail: { (err, lastLocation) in
                // Something bad has occurred
            })
        }
        // the rest of the init...
        
        // Override point for customization after application launch.
        
        //lazy var messageQueue = MessageQueue(storage: storage)
        //let messageQueue = MessageQueue(storage: storage );
        //let scheduler = Scheduler( storage: storage ,messageQueue : messageQueue );
        
        //the next ones are intelligently inside GlobalVariables.swift. what could go worng?
        
        messageQueue.initHousekeeping()
        scheduler.initHousekeeping();
        runRecorder.initialize();
        runDataIO.initialize();
        mapJunction.initialize();
        prefSignalJunction.initialize();
        packetExchange.initialize();
        serviceStatus.initialize(); //config screen shows running services
        playerRoster.initialize();
        //add own user
        playerRoster.addPlayerWithCompute(name:"samui",email:"samui@hastur.org")
        

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        //scheduler.applicationWillResignActive()
        scheduler.applicationWillResignActive()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        scheduler.applicationDidBecomeActive()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        //good point to run scheduler housekeeping?
        scheduler.applicationDidBecomeActive()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        scheduler.applicationWillTerminate()
    }


}

