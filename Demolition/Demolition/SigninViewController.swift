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
        
        if teamSelector.selectedSegmentIndex == 0 {
//            let avc = AttackerViewController()
//            self.navigationController?.pushViewController(avc, animated: true)
//            print(teamSelector.selectedSegmentIndex)
            
            let storyBoard: UIStoryboard = UIStoryboard(name: "SigninViewController", bundle: nil)
            let avc = storyBoard.instantiateViewController(withIdentifier: "avc")
            
            self.present(avc, animated: true, completion: nil)
            
            
        } else if teamSelector.selectedSegmentIndex == 1 {
            let dvc = DefenderViewController()
            self.navigationController?.pushViewController(dvc, animated: true)
            print(teamSelector.selectedSegmentIndex)
        }
        
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        // get a reference to the second view controller
        let AttackerViewController = segue.destination as! AttackerViewController
        let DefenderViewController = segue.destination as! DefenderViewController
        
        // set a variable in the second view controller with the String to pass
        AttackerViewController.receivedName = nameField.text!
        DefenderViewController.receivedName = nameField.text!

    }
    
    
    
    
}
