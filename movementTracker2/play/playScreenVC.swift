//
//  playScreenVC.swift
//  movementTracker2
//
//  Created by sami on 2017/11/06.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import UIKit
//import SwiftLocation
//import Interstellar

class playScreenVC: UIViewController {

    @IBOutlet weak var totalCoordinates: UILabel!
    @IBOutlet weak var recordingStarted: UILabel!
    @IBOutlet weak var totalDistance: UILabel!
    
    var runRecordOn = false;
    @IBAction func recordSwitch(_ sender: UISwitch) {
        
        //are we recording? if not switch off
        let vx = sender.isOn
        
        runRecoderToggleObserver.update(vx)
        if !runRecordOn {
            
            recordingStarted.text = "not running"
            totalDistance.text = "0m"
            totalCoordinates.text = "0"
        }
        
    }
    
    @IBAction func commitToDisk(_ sender: UIButton) {
        
        //are we committing already?
        //any data to commit?
        requestCommitOfCurrentRunObserver.update(true)
        
    }
    
    @IBAction func readFromDisk(_ sender: UIButton) {
        
        //are we committing?
        requestReadOfCurrentRunObserver.update(true)
        
        
    }
    
    @IBAction func transferData(_ sender: UIButton) {
        
        //page packetExchangeJunction
        packetExchangeRequestObserver.update(true)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        signalListeners()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func signalListeners () {
    
    runAreaProgressObserver.subscribe { currentRun in
    
        //update screen
        let coordAm = String(currentRun.coordinates.count)
        let tt = currentRun.totalTime
        let dis = String(currentRun.totalDistance())
    
        let time = Int(tt)
        let hours = time / 3600
        let minutes = (time / 60) % 60
        let seconds = time % 60
        let guko = String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
    
    /*let hour = calendar.component(.hour, from: date as Date)
     let minutes = calendar.component(.minute, from: date as Date)
     let seconds = calendar.component(.second, from: date as Date)
     print("\(hour):\(minutes):\(seconds)")*/
    
        //self.runRecordTime.text = guko
        //self.runRecordDistance.text = dis
        //self.runRecordPoints.text = coordAm
        self.totalCoordinates.text = coordAm;
        self.totalDistance.text = dis;
        self.recordingStarted.text = guko;
        
        if currentRun.isClosed() {
            
            let das = "CL!"+dis
            self.totalDistance.text = dis;
        }
        
    }
    
    pedometerMessageObserver.subscribe { pedoMessage in
    
        //pedo meter is talking
    
        let st = String(pedoMessage.steps)
        let di = String(pedoMessage.distance)
    
        //self.pedometerSteps.text = st;
        //self.pedometerDistance.text = di
    
    }   //pedometerMessageObserver
    
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
