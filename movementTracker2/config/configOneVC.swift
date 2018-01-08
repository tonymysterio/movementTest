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
        
        runStreamReaderObserver.update(vx)
        
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
            
            self.amountOfCachedRuns.text = String(cruns);
            
        }
        //self.view.backgroundColor = UIColor.flatGreenColorDark()
        //label1.tintColor = viewColors.labelText
        
        serviceStatusJunctionTotalUserProfiles.subscribe{ cruns in
            
            self.amountOfUserProfiles.text = String(cruns);
            
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
    
    func serviceItemDisable ( key : Int) {
        
        
        
        //📲 💽
       // 📟
        //💾 📔 📓🕸📡 📣
        self.statusIc[key].isHidden = true;
        self.statusIc[key].isSelected = false;
    }
    
    func serviceItemEnable ( key : Int) {
         self.statusIc[key].isHidden = false;
        self.statusIc[key].isSelected = false;
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
                self.serviceItemEnable(key: 2)
            } else {
                self.serviceItemDisable(key: 2)
            }
            
        case "runCache":
            
            if (s.active){
                self.serviceItemEnable(key: 0)
            } else {
                self.serviceItemDisable(key: 0)
            }
            
        case "snapshotCache":
            
            if (s.active){
                self.serviceItemEnable(key: 1)
            } else {
                self.serviceItemDisable(key: 1)
            }
            
        case "servusMeshnetProvider":
            
            if (s.active){
                self.serviceItemEnable(key: 3)
            } else {
                self.serviceItemDisable(key: 3)
            }
            
        case "PeerDataProvider":
            
            if (s.active){
                self.serviceItemEnable(key: 4)
            } else {
                self.serviceItemDisable(key: 4)
            }
            
            
        case "PeerDataRequester":
            
            if (s.active){
                self.serviceItemEnable(key: 5)
            } else {
                self.serviceItemDisable(key: 5)
            }
        
        case "hoodoRunStreamListener":
            
            if (s.active){
                self.serviceItemEnable(key: 6)
            } else {
                self.serviceItemDisable(key: 6)
            }
        case "jsonStreamReader":
            
            if (s.active){
                self.serviceItemEnable(key: 7)
            } else {
                self.serviceItemDisable(key: 7)
            }
        case "runStreamRecorder":
            
            if (s.active){
                self.serviceItemEnable(key: 8)
            } else {
                self.serviceItemDisable(key: 8)
            }
        default:
            return;
            
        }
        
        
    }   //updateServiceStatusItem
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    

}
