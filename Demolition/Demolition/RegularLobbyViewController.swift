//
//  RegularLobbyViewController.swift
//  Demolition
//
//  Created by Carlos Garcia on 4/30/18.
//  Copyright © 2018 6.S062 Project. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseDatabase

class RegularLobbyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var nextViewIdentifier: String? = "View1"
    var newLine: String = "EUR"
    var playerName: String = ""
    var partyID: String = ""
    var customHash: String = ""
    
    @IBOutlet weak var attackersTable: UITableView!
    @IBOutlet weak var defendersTable: UITableView!
    
    var attackers: [String] = ["Attackers"]
    var defenders: [String] = ["Defenders"]
    
    var ref: DatabaseReference!
    
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
        attackersTable.register(UITableViewCell.self, forCellReuseIdentifier: "attackerCell")
        
        defendersTable.delegate = self
        defendersTable.dataSource = self
        defendersTable.register(UITableViewCell.self, forCellReuseIdentifier: "defenderCell")
        
        partyLabel.text = partyID
        nameLabel.text = playerName
        
        ref = Database.database().reference()
        let teams = self.ref.child("Parties").child(partyID).child("Teams")
        teams.child(playerName).setValue("Attacker")
        teams.observe(DataEventType.value) { (snapshot) in
            let value = snapshot.value as! NSDictionary
            self.attackers.removeAll()
            self.defenders.removeAll()
            for name in value.allKeys {
                let team = value[name] as! String
                
                if team == "Attacker" {
                    self.attackers.append(name as! String)
                } else if team == "Defender" {
                    self.defenders.append(name as! String)
                }
                
            }
            self.attackersTable.reloadData()
            self.defendersTable.reloadData()
        }
    }
    

    @IBAction func valueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            nextViewIdentifier = "View1"
            self.ref.child("Parties").child(partyID).child("Teams").child(playerName).setValue("Attacker")
            
        case 1:
            nextViewIdentifier = "View2"
            
            self.ref.child("Parties").child(partyID).child("Teams").child(playerName).setValue("Defender")
            
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
        var count: Int?
        print("ok")
        if tableView == self.attackersTable {
            print("hey there")
            count = attackers.count
        }
        
        if tableView == self.defendersTable {
            count = defenders.count
        }
        return count!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        print("poopity scoop")
        if tableView == self.attackersTable {
            cell = tableView.dequeueReusableCell(withIdentifier: "attackerCell", for: indexPath as IndexPath)
            cell?.textLabel?.text = self.attackers[indexPath.item]
        }
        
        if tableView == self.defendersTable {
            cell = tableView.dequeueReusableCell(withIdentifier: "defenderCell", for: indexPath as IndexPath)
            cell?.textLabel?.text = self.defenders[indexPath.item]
        }
        
        return cell!
        
    }
}

