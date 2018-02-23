//
//  configOneVC.swift
//  movementTracker2
//
//  Created by sami on 2017/11/02.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import UIKit
//import Chameleon
import Interstellar
import UserNotifications

class configOneVC: UIViewController {

    @IBOutlet weak var myView: UIView!
    @IBOutlet weak var label1: UIView!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate //get papa
    
    @IBOutlet var maxObjectsSlider: UISlider!
    @IBOutlet var maxCatObjectsSlider: UISlider!
    @IBOutlet var pullRunStreamSwitch: UISwitch!
    @IBOutlet var mapCombinerSwitch: UISwitch!
    
    @IBOutlet var amountOfCachedRuns: UILabel!
    //status icons
    @IBAction func runCacheB(_ sender: Any) {
    }
    
    @IBOutlet var amountOfUserProfiles: UILabel!
    @IBOutlet var statusIcons: [UIButton]!
    
    @IBOutlet var statusIconCollection: [UIButton]!
    
    @IBOutlet var statusIc: [UIButton]!
    @IBAction func maxCatObjectsChanged(_ sender: UISlider!) {
        
        let vx = sender.value
        maxObjectsSliderObserver.update(vx)
    }
    
    @IBAction func maxObjectsChanged(_ sender: UISlider!) {
        
        let vx = sender.value
        maxObjectsSliderObserver.update(vx)
    }
    
    @IBAction func pullRunStreamChanged(_ sender: UISwitch!) {
        
        let vx = sender.isOn
        
        runJSONStreamReaderObserver.update(vx)
        
    }
    
    @IBAction func mapCombinerToggleChanged(_ sender: UISwitch!) {
        
        let vx = sender.isOn
        
        mapCombinerToggleObserver.update(vx)
        
    }
    @IBAction func mapSimplifySlider(_ sender: UISlider!) {
        
        //simplifying tolerance for mapCombiner
        let vx = sender.value
        mapCombinerToleranceObserver.update(vx)
    }
    var currentlyAnimating = 99;
    
    func animateProcessing ( button : UIButton ) {
        
        UIButton.animate(withDuration: 0.2,
                         animations: {
                            button.transform = CGAffineTransform(scaleX: 1.9, y: 1.9)
        },
                         completion: { finish in
                            UIButton.animate(withDuration: 0.1, animations: {
                                button.transform = CGAffineTransform.identity
                                self.currentlyAnimating = 99;
                                
                            })
        })
        
    }
    //this could be in appdelegate
    //let prefJunction = preferenceSignalJunction()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //set the screen style
        serviceStatusJunctionObserver.subscribe{ statusItem in
            
            self.updateServiceStatusItem(s: statusItem);
            
        }
        
        serviceStatusJunctionTotalCachedRuns.subscribe{ cruns in
            DispatchQueue.main.async {
            self.amountOfCachedRuns.text = String(cruns);
            }
            
        }
        //self.view.backgroundColor = UIColor.flatGreenColorDark()
        //label1.tintColor = viewColors.labelText
        
        serviceStatusJunctionTotalUserProfiles.subscribe{ cruns in
            DispatchQueue.main.async {
            self.amountOfUserProfiles.text = String(cruns);
            }
        }
        
        serviceStatusJunctionNotification.subscribe{ meiwakuMessage in
            DispatchQueue.main.async {
                self.scheduleNotification(notif: meiwakuMessage, inSeconds: 2, completion: { com in
                    
                })
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated) // No need for semicolon
       
        serviceStatus.getServiceStatuses();
        
        //myView.backgroundColor = #colorLiteral(red: 0.6029270887, green: 0.6671635509, blue: 0.8504692912, alpha: 1)
        self.view.setNeedsDisplay()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var serviceItemStatuses = [ Int : serviceStatusItem ]();
    
    func serviceItemDisable ( key : Int , sitem : serviceStatusItem ) {
        
        var blinkOnActivity = false;
        if serviceItemStatuses[key] == nil {
            serviceItemStatuses[key] = sitem;
        } else {
            
            if (serviceItemStatuses[key]?.isProcessing == false) && ( sitem.isProcessing == true ) {
                blinkOnActivity = true;
            }
            
            serviceItemStatuses[key] = sitem;
        }
        
        
        
        //animateProcessing
        
        //📲 💽
       // 📟
        //💾 📔 📓🕸📡 📣
        
        DispatchQueue.main.async {
            
            self.statusIc[key].isHidden = true;
            self.statusIc[key].isSelected = false;
        
        }
        
    }
    
    func serviceItemEnable ( key : Int , sitem : serviceStatusItem ) {
        
        var blinkOnActivity = false;
        if serviceItemStatuses[key] == nil {
            serviceItemStatuses[key] = sitem;
        } else {
            
            //if (serviceItemStatuses[key]?.isProcessing == false) && ( sitem.isProcessing == true ) {
            if ( serviceItemStatuses[key]?.isProcessing !=  sitem.isProcessing ) {
                    
                blinkOnActivity = true;
            }
            
            serviceItemStatuses[key] = sitem;
        }
        
        DispatchQueue.main.async {
        
            self.statusIc[key].isHidden = false;
            self.statusIc[key].isSelected = false;
        
            if blinkOnActivity {
                if self.currentlyAnimating != key {
                    self.animateProcessing(button: self.statusIc[key])
                    self.currentlyAnimating == key;
                }
                
            }
        
        }
    }
    
    
    func updateServiceStatusItem ( s : serviceStatusItem) {
        
        //[,"","runCache",,"servusMeshnetProvider","PeerDataProvider","PeerDataRequester"];
        
        switch (s.name ){
            
        /*case "mapCombiner" :
            if (s.active){
                self.serviceItemEnable(key: <#T##Int#>)
            } else {
                self.serviceItemDisable(key: <#T##Int#>)
            }*/
            
        case "PullRunsFromDisk":
            
            if (s.active){
                self.serviceItemEnable(key: 2 , sitem : s )
            } else {
                self.serviceItemDisable(key: 2 ,sitem : s )
            }
            
        case "runCache":
            
            if (s.active){
                self.serviceItemEnable(key: 0 ,sitem : s)
                DispatchQueue.main.async {
                self.amountOfCachedRuns.text = String(s.data);
                }
            } else {
                self.serviceItemDisable(key: 0 ,sitem : s)
            }
            
        case "snapshotCache":
            
            if (s.active){
                self.serviceItemEnable(key: 1 ,sitem : s)
            } else {
                self.serviceItemDisable(key: 1 ,sitem : s)
            }
            
        case "servusMeshnetProvider":
            
            if (s.active){
                self.serviceItemEnable(key: 3 ,sitem : s)
            } else {
                self.serviceItemDisable(key: 3 ,sitem : s)
            }
            
        case "PeerDataProvider":
            
            if (s.active){
                self.serviceItemEnable(key: 4 ,sitem : s)
            } else {
                self.serviceItemDisable(key: 4 ,sitem : s)
            }
            
            
        case "PeerDataRequester":
            
            if (s.active){
                self.serviceItemEnable(key: 5,sitem : s)
            } else {
                self.serviceItemDisable(key: 5,sitem : s)
            }
        
        case "hoodoRunStreamListener":
            
            if (s.active){
                self.serviceItemEnable(key: 6,sitem : s)
            } else {
                self.serviceItemDisable(key: 6,sitem : s)
            }
        case "jsonStreamReader":
            
            if (s.active){
                self.serviceItemEnable(key: 7,sitem : s)
            } else {
                self.serviceItemDisable(key: 7,sitem : s)
            }
        case "runStreamRecorder":
            
            if (s.active){
                self.serviceItemEnable(key: 8,sitem : s)
            } else {
                self.serviceItemDisable(key: 8,sitem : s)
            }
        
        case "locationLogger":
            
            if (s.active){
                self.serviceItemEnable(key: 9,sitem : s)
            } else {
                self.serviceItemDisable(key: 9,sitem : s)
            }
            
        case "liveRunStreamListener":
            
            if (s.active){
                self.serviceItemEnable(key: 10,sitem : s)
            } else {
                self.serviceItemDisable(key: 10,sitem : s)
            }
        default:
            return;
            
        }
        //"locationLogger","liveRunStreamListener","runStreamRecorder"
        
        
        
    }   //updateServiceStatusItem
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
   
    
    let notificationIdentifier = "testNotification"
    
    func scheduleNotification(notif : notificationMeiwaku , inSeconds: TimeInterval, completion: @escaping (Bool) -> ()) {
        
        // Create Notification content
        let notificationContent = UNMutableNotificationContent()
        
        notificationContent.title = notif.title; //"Check this out"
        notificationContent.subtitle = notif.subtitle //"It's a notification"
        notificationContent.body = notif.body   //"WHOA COOL"
        
        // Create Notification trigger
        // Note that 60 seconds is the smallest repeating interval.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: inSeconds, repeats: false)
        
        // Create a notification request with the above components
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: notificationContent, trigger: trigger)
        
        // Add this notification to the UserNotificationCenter
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
            if error != nil {
                print("\(error)")
                completion(false)
            } else {
                completion(true)
            }
        })
    }
    
    

}
