//
//  mapScreenVC.swift
//  movementTracker2
//
//  Created by sami on 2017/12/18.
//  Copyright © 2017年 pancristal. All rights reserved.
//

import UIKit

class mapVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        var storyboard = UIStoryboard(name: "map", bundle: nil)
        
        var controller = storyboard.instantiateInitialViewController() as! UINavigationController
        addChildViewController(controller)
        view.addSubview(controller.view)
        controller.didMove(toParentViewController: self)
        // Do any additional setup after loading the view.
        
        //we got a finished run. show this screen
        /*runRecorderSavedFinishedRun.subscribe { run in
            
            
        }*/
        
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
