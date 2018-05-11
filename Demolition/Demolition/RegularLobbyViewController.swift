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
    var playerName: String = ""
    var partyID: String = ""
    var customHash: String = ""
    var bgGreenColor = UIColor(red: CGFloat(147.0/255.0), green: CGFloat(175.0/255.0), blue: CGFloat(147.0/255.0), alpha: CGFloat(1.0))
    var oliveColor = UIColor(red: CGFloat(77.0/255.0), green: CGFloat(112.0/255.0), blue: CGFloat(77.0/255.0), alpha: CGFloat(1.0))
    
    @IBOutlet weak var attackersTable: UITableView!
    @IBOutlet weak var defendersTable: UITableView!
    @IBOutlet weak var partyLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var teamSelector: UISegmentedControl!
    
    var attackers: [String] = []
    var defenders: [String] = []
    
    var ref: DatabaseReference!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        teamSelector.layer.cornerRadius = 0.0
        teamSelector.layer.borderColor = oliveColor.cgColor
        teamSelector.layer.borderWidth = 1.0
        teamSelector.layer.masksToBounds = true

        attackersTable.backgroundColor = bgGreenColor
        attackersTable.delegate = self
        attackersTable.dataSource = self
        attackersTable.register(UITableViewCell.self, forCellReuseIdentifier: "attackerCell")
        
        defendersTable.backgroundColor = bgGreenColor
        defendersTable.delegate = self
        defendersTable.dataSource = self
        defendersTable.register(UITableViewCell.self, forCellReuseIdentifier: "defenderCell")
        
        partyLabel.text = partyID
        nameLabel.text = playerName
        
        ref = Database.database().reference()
        
        // teams listener
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
        
        // game status listener
        let gameState = self.ref.child("Parties").child(partyID).child("Global").child("gameState")
        gameState.observe(DataEventType.value) { (snapshot) in
            let status = snapshot.value as! String
            if status == "inProgress" {
                // segue into vc
                if self.teamSelector.selectedSegmentIndex == 0 {
                    self.performSegue(withIdentifier: "attackerSegue", sender: nil)
                } else if self.teamSelector.selectedSegmentIndex == 1 {
                    self.performSegue(withIdentifier: "defenderSegue", sender: nil)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is DefenderViewController {
            let vc = segue.destination as? DefenderViewController
            vc?.receivedName = playerName
            vc?.receivedPartyID = partyID
            vc?.receivedCustomHash = customHash
        } else if segue.destination is AttackerViewController {
            let vc = segue.destination as? AttackerViewController
            vc?.receivedName = playerName
            vc?.receivedPartyID = partyID
            vc?.receivedCustomHash = customHash
        }
    }
    
    @IBAction func valueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.ref.child("Parties").child(partyID).child("Teams").child(playerName).setValue("Attacker")
            
        case 1:
            self.ref.child("Parties").child(partyID).child("Teams").child(playerName).setValue("Defender")
        default:
            print("[ERROR] Team Selection Error.")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count: Int?

        if tableView == self.attackersTable {
            count = attackers.count
        }
        
        if tableView == self.defendersTable {
            count = defenders.count
        }
        
        return count!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?

        if tableView == self.attackersTable {
            cell = tableView.dequeueReusableCell(withIdentifier: "attackerCell", for: indexPath as IndexPath)
            cell?.textLabel?.text = self.attackers[indexPath.item]
        }
        
        if tableView == self.defendersTable {
            cell = tableView.dequeueReusableCell(withIdentifier: "defenderCell", for: indexPath as IndexPath)
            cell?.textLabel?.text = self.defenders[indexPath.item]
        }
        
        cell?.backgroundColor = UIColor.clear
        cell?.textLabel?.font = UIFont(name: "Futura", size: CGFloat(17.0))
        
        return cell!
    }
}

