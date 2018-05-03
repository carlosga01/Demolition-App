//
//  SigninViewController.swift
//  Demolition
//
//  Created by Carlos Garcia on 4/30/18.
//  Copyright © 2018 6.S062 Project. All rights reserved.
//

import Foundation
import UIKit

class SigninViewController: UIViewController {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    

    
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var teamSelector: UISegmentedControl!
    
    @IBAction func startButton(_ sender: UIButton) {
        print("Game Started")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // get a reference to the second view controller
        let ViewController = segue.destination as! ViewController
        
        // set a variable in the second view controller with the String to pass
        ViewController.receivedName = nameField.text!
        ViewController.receivedTeam = teamSelector.titleForSegment(at: teamSelector.selectedSegmentIndex)!
    }
    
    
    
    
}
