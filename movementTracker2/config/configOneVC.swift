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
        
        
        //self.view.backgroundColor = UIColor.flatGreenColorDark()
        //label1.tintColor = viewColors.labelText
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated) // No need for semicolon
       
        //myView.backgroundColor = #colorLiteral(red: 0.6029270887, green: 0.6671635509, blue: 0.8504692912, alpha: 1)
        self.view.setNeedsDisplay()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
