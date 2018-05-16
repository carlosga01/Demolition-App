//
//  HostLobbyViewController.swift
//  Demolition
//
//  Created by Carlos Garcia on 4/30/18.
//  Copyright © 2018 6.S062 Project. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseDatabase
import MapKit
import CoreLocation

class HostLobbyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var playerName: String = ""
    var partyID: String = ""
    var customHash: String = ""
    
    var lightBrownColor = UIColor(red: CGFloat(191.0/255.0), green: CGFloat(176.0/255.0), blue: CGFloat(131.0/255.0), alpha: CGFloat(1.0))
    var darkBrownColor = UIColor(red: CGFloat(48.0/255.0), green: CGFloat(39.0/255.0), blue: CGFloat(39.0/255.0), alpha: CGFloat(1.0))
    
    @IBOutlet weak var attackersTable: UITableView!
    @IBOutlet weak var defendersTable: UITableView!
    @IBOutlet weak var partyLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var teamSelector: UISegmentedControl!
    
    var attackers: [String] = []
    var defenders: [String] = []
    
    var annotation1 = CustomPointAnnotation()
    var annotation2 = CustomPointAnnotation()
    var annotation3 = CustomPointAnnotation()
    var annotation4 = CustomPointAnnotation()
    var annotation5 = CustomPointAnnotation()
    var annotation6 = CustomPointAnnotation()
    var annotation7 = CustomPointAnnotation()
    
    var flagAnnotations: Dictionary<String, CustomPointAnnotation> = [:]
    
    var ref: DatabaseReference!
    var teamsRef: DatabaseReference!
    var gameStateRef: DatabaseReference!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let selectedTextAttributes: [NSAttributedStringKey: Any] = [
            .font : UIFont(name: "Futura", size: 17.0)!,
            .foregroundColor : UIColor.white
        ]
        let normalTextAttributes: [NSAttributedStringKey: Any] = [
            .font : UIFont(name: "Futura", size: 17.0)!,
            .foregroundColor : darkBrownColor
        ]
        teamSelector.setTitleTextAttributes(normalTextAttributes, for: UIControlState.normal)
        teamSelector.setTitleTextAttributes(selectedTextAttributes, for: UIControlState.selected)
        teamSelector.superview?.clipsToBounds = true
        teamSelector.superview?.layer.cornerRadius = 0.0
        teamSelector.superview?.layer.borderWidth = 1.0
        teamSelector.superview?.layer.borderColor = darkBrownColor.cgColor
        
        attackersTable.backgroundColor = lightBrownColor
        attackersTable.rowHeight = 30.0
        attackersTable.delegate = self
        attackersTable.dataSource = self
        attackersTable.register(UITableViewCell.self, forCellReuseIdentifier: "attackerCell")
        
        defendersTable.backgroundColor = lightBrownColor
        defendersTable.rowHeight = 30.0
        defendersTable.delegate = self
        defendersTable.dataSource = self
        defendersTable.register(UITableViewCell.self, forCellReuseIdentifier: "defenderCell")
        
        partyLabel.text = partyID
        nameLabel.text = playerName
        
        annotation1.coordinate = CLLocationCoordinate2D(latitude: 42.360453, longitude: -71.092541)
        annotation1.title = "Flag1"
        
        annotation2.coordinate = CLLocationCoordinate2D(latitude: 42.358184, longitude: -71.092091)
        annotation2.title = "Flag2"

        annotation3.coordinate = CLLocationCoordinate2D(latitude: 42.358714, longitude: -71.090531)
        annotation3.title = "Flag3"

        annotation4.coordinate = CLLocationCoordinate2D(latitude: 42.359950, longitude: -71.089064)
        annotation4.title = "Flag4"

        annotation5.coordinate = CLLocationCoordinate2D(latitude: 42.361306, longitude: -71.087134)
        annotation5.title = "Flag5"

        annotation6.coordinate = CLLocationCoordinate2D(latitude: 42.361618, longitude: -71.089299)
        annotation6.title = "Flag6"

        
        ref = Database.database().reference()
        teamsRef = ref.child("Parties").child(partyID).child("Teams")
        gameStateRef = ref.child("Parties").child(partyID).child("Global").child("gameState")
        gameStateRef.setValue("inLobby")
        
        //append flags to database
        let globalFlagsRef = ref.child("Parties").child(partyID).child("Global").child("Flags")
        
        flagAnnotations = ["Flag1" : annotation1, "Flag2": annotation2, "Flag3":annotation3, "Flag4" : annotation4, "Flag5" : annotation5, "Flag6" : annotation6]
        
        var count = 1
        for location in flagAnnotations.values {
            location.imageName = "pin"
            let flag = globalFlagsRef.child("Flag" + String(count))
            flag.child("Status").setValue("Free")
            flag.child("Location").child("Longitude").setValue(location.coordinate.longitude)
            flag.child("Location").child("Latitude").setValue(location.coordinate.latitude)
            count += 1
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // teams listener
        teamsRef.child(playerName).setValue("Attacker")
        teamsRef.observe(DataEventType.value) { (snapshot) in
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
        gameStateRef.observe(DataEventType.value) { (snapshot) in
            let status = snapshot.value as! String
            if status == "inProgress" {
                // set global timer
                let currentTimestamp = NSDate().timeIntervalSince1970
//                let twentyMins = TimeInterval(20*60)
                let thirtyMins = TimeInterval(30*60)
                let gameEndTime = Int(currentTimestamp + thirtyMins)
                self.ref.child("Parties").child(self.partyID).child("Global").child("endTime").setValue(gameEndTime)
                
                // segue into vc
                if self.teamSelector.selectedSegmentIndex == 0 {
                    self.performSegue(withIdentifier: "attackerSegue", sender: nil)
                } else if self.teamSelector.selectedSegmentIndex == 1 {
                    self.performSegue(withIdentifier: "defenderSegue", sender: nil)
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        teamsRef.removeAllObservers()
    }
    
    @IBAction func startButton(_ sender: UIButton) {
        gameStateRef.setValue("inProgress")
        self.ref.child("Parties").child(partyID).child("Global").child("flagsCaptured").setValue(0)
    }
    
    @IBAction func valueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            teamsRef.child(playerName).setValue("Attacker")
            
        case 1:
            teamsRef.child(playerName).setValue("Defender")
            
        default:
            print("[ERROR] Team Selection Error.")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is DefenderViewController {
            let vc = segue.destination as? DefenderViewController
            vc?.receivedName = playerName
            vc?.receivedPartyID = partyID
            vc?.receivedCustomHash = customHash
            vc?.receivedAttackersList = self.attackers
            vc?.receivedDefendersList = self.defenders
            vc?.receivedFlags = self.flagAnnotations
        } else if segue.destination is AttackerViewController {
            let vc = segue.destination as? AttackerViewController
            vc?.receivedName = playerName
            vc?.receivedPartyID = partyID
            vc?.receivedCustomHash = customHash
            vc?.receivedAttackersList = self.attackers
            vc?.receivedDefendersList = self.defenders
            vc?.receivedFlags = self.flagAnnotations
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
        cell?.textLabel?.textColor = darkBrownColor
        cell?.textLabel?.textAlignment = NSTextAlignment.center
        
        return cell!
    }
}
