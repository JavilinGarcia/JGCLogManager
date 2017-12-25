//
//  ViewController.swift
//  JGCLogConsoleDemo
//
//  Created by Javier Garcia Castro on 24/12/17.
//  Copyright © 2017 Javier Garcia Castro. All rights reserved.
//

import UIKit

class ViewController: UIViewController, JGCLogConsoleDelegate {

    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !JGCLogManager.sharedInstance().isRunFromXcode() {
            let consoleButton:UIButton = JGCLogManager.sharedInstance().createConsoleButton()
            
            JGCLogManager.sharedInstance().logConsoleDelegate = self
            
            view.addSubview(consoleButton)
            
            let constraints = NSMutableArray()
            constraints.addObjects(from: NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[consoleButton]", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views:["consoleButton":consoleButton]))
            constraints.addObjects(from: NSLayoutConstraint.constraints(withVisualFormat: "V:[consoleButton]-10-|" , options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["consoleButton":consoleButton]))
            constraints.add(NSLayoutConstraint.init(item: consoleButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50.0))
            constraints.add(NSLayoutConstraint.init(item: consoleButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 100.0))
            
            consoleButton.superview?.addConstraints(constraints as! [NSLayoutConstraint])
            
            view.bringSubview(toFront: consoleButton)
            
            label.isHidden = true
        }
        else{
            label.isHidden = false
        }
        
        print("viewDidLoad()")
    }
    
    // MARK: - JGCLogConsoleDelegate
    func navigate(toLogConsoleViewController logConsoleViewController: UIViewController!) {
        self.present(logConsoleViewController, animated: true, completion: nil)
    }

}

