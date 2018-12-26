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
            
            JGCLogManager.sharedInstance().logConsoleDelegate = self
            
            let consoleButton:UIButton = JGCLogManager.sharedInstance().createConsoleButton()

            view.addSubview(consoleButton)

            let constraints = NSMutableArray()
            constraints.addObjects(from: NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[consoleButton]", options: NSLayoutConstraint.FormatOptions(rawValue:0), metrics: nil, views:["consoleButton":consoleButton]))
            constraints.addObjects(from: NSLayoutConstraint.constraints(withVisualFormat: "V:[consoleButton]-20-|" , options: NSLayoutConstraint.FormatOptions(rawValue:0), metrics: nil, views: ["consoleButton":consoleButton]))
            constraints.add(NSLayoutConstraint.init(item: consoleButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 35.0))
            constraints.add(NSLayoutConstraint.init(item: consoleButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 35.0))

            consoleButton.superview?.addConstraints(constraints as! [NSLayoutConstraint])

            view.bringSubviewToFront(consoleButton)
            
            label.isHidden = true
        } else {
            label.isHidden = false
        }
        
        print("viewDidLoad()")
        print("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear()")
        print("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
    }
    
    // MARK: - JGCLogConsoleDelegate
    func navigate(toLogConsoleViewController logConsoleViewController: UIViewController!) {
        self.present(logConsoleViewController, animated: true, completion: nil)
    }
}
