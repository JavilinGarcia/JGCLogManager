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
            constraints.addObjects(from: NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[consoleButton]", options: NSLayoutConstraint.FormatOptions(rawValue:0), metrics: nil, views:["consoleButton":consoleButton]))
            constraints.addObjects(from: NSLayoutConstraint.constraints(withVisualFormat: "V:[consoleButton]-10-|" , options: NSLayoutConstraint.FormatOptions(rawValue:0), metrics: nil, views: ["consoleButton":consoleButton]))
            constraints.add(NSLayoutConstraint.init(item: consoleButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50.0))
            constraints.add(NSLayoutConstraint.init(item: consoleButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 100.0))

            consoleButton.superview?.addConstraints(constraints as! [NSLayoutConstraint])

            view.bringSubviewToFront(consoleButton)
            
            label.isHidden = true
        } else {
            label.isHidden = false
        }
        
        print("viewDidLoad()")
        print("adsfjalfdsñ ñalsdkfjña sldfjkañ sl\nafldsjasdflzxkja")
        print("adsfjalfdsñ ñalsdkfjña sldfjkañ sl\nafldsjasdflzxkja")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear()")
        print("adsfjalfdsñ ñalsdkfjña sldfjkañ sl\nafldsjasdflzxkja")
        print("adsfjalfdsñ ñalsdkfjña sldfjkañ sl\nafldsjasdflzxkja")
    }
    
    // MARK: - JGCLogConsoleDelegate
    func navigate(toLogConsoleViewController logConsoleViewController: UIViewController!) {
        self.present(logConsoleViewController, animated: true, completion: nil)
    }

}

