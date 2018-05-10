//
//  SigninViewController.swift
//  Demolition
//
//  Created by Carlos Garcia on 4/30/18.
//  Copyright © 2018 6.S062 Project. All rights reserved.
//

import Foundation
import UIKit

class SigninViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var nextViewIdentifier: String? = "View1"
    var newLine: String = "EUR"
    var playerName: String = ""
    var partyID: String = ""
    var customHash: String = ""
    
    @IBOutlet weak var attackersTable: UITableView!
    @IBOutlet weak var defendersTable: UITableView!
    
    var attackers: [String] = ["carlos", "omar", "james"]
    var defenders: [String] = ["carlos", "omar", "james"]
    
    //self.presentViewController(controller, animated: true, completion: nil)
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    

    @IBOutlet weak var partyLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
        
    @IBOutlet weak var teamSelector: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        attackersTable.delegate = self
        attackersTable.dataSource = self
        partyLabel.text = partyID
        nameLabel.text = playerName
    }
    
    @IBAction func startButton(_ sender: UIButton) {
        print("Game Started")
        if (nextViewIdentifier == "View1") {
            let nextView = self.storyboard!.instantiateViewController(withIdentifier: nextViewIdentifier!) as! AttackerViewController
            nextView.receivedName =  nameLabel.text!
            nextView.receivedCustomHash = customHash
            self.show(nextView, sender: self)
        } else {
            let nextView = self.storyboard!.instantiateViewController(withIdentifier: nextViewIdentifier!) as! DefenderViewController
            nextView.receivedName =  nameLabel.text!
            self.show(nextView, sender: self)
        }
    }
    
    @IBAction func valueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            nextViewIdentifier = "View1"
        case 1:
            nextViewIdentifier = "View2"
        default:
            nextViewIdentifier = nil;
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let secondVC = segue.destination as? AttackerViewController, segue.identifier == "SigninViewController" {
            // at this moment secondVC did not load its view yet, trying to access it would cause crash
            // because transferWord tries to set label.text directly, we need to make sure that label
            // is already set (for experiment you can try comment out next line)
            secondVC.loadViewIfNeeded()
            // but here secondVC exist, so lets call transferWord on it
        }
        
        // get a reference to the second view controller
        //let AttackerViewController = segue.destination as! AttackerViewController
        //let DefenderViewController = segue.destination as! DefenderViewController
        
        // set a variable in the second view controller with the String to pass
        //AttackerViewController.receivedName = nameField.text!
        //DefenderViewController.receivedName = nameField.text!

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(self.attackers.count)
        return self.attackers.count
    }
   
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print(indexPath.item)
        let cell = tableView.dequeueReusableCell(withIdentifier: "attackerCell", for: indexPath as IndexPath)
        cell.textLabel?.text = self.attackers[indexPath.item]
        return cell
    }
}
