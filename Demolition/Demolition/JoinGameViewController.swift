//
//  JoinGameViewController.swift
//  Demolition
//
//  Created by Omar Gonzalez on 5/10/18.
//  Copyright © 2018 6.S062 Project. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseDatabase

class JoinGameViewController: UIViewController {
    var ref: DatabaseReference!
    var playerName = ""
    var customHash = ""
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
    }
    
    @IBOutlet weak var partyIDInput: UITextField!
    
    @IBAction func joinGameButton(_ sender: UIButton) {
        
        if self.partyIDInput.text != "" {
            // check if party id exists in DB
            let allPartiesRef = self.ref.child("Parties")
            allPartiesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.hasChild(self.partyIDInput.text!) {
                    let value = snapshot.value as? [String:[String:Any]]
                    let partyRef = allPartiesRef.child(self.partyIDInput.text!)
                    let partyIdAsDict = value![self.partyIDInput.text!]! as Dictionary<String, AnyObject>
                    
                    // check if party is in waiting lobby
                    if partyIdAsDict["Global"]!["gameState"] as! String == "inLobby" {
                        
                        // send info to corresponding partyID in DB
                        let playerRef = partyRef.child("Players").child(self.customHash)
                        playerRef.child("Name").setValue(self.playerName)
                        playerRef.child("Team").setValue("Attacker")
                        playerRef.child("Status").setValue("Alive")
                        self.performSegue(withIdentifier: "conditionSegue", sender: nil)
                    } else {
                        let alertController = UIAlertController(title: "Game is already in progress", message: "", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                    }
                    
                } else {
                    let alertController = UIAlertController(title: "Party does not exist", message: "", preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            })     
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? RegularLobbyViewController {
            vc.playerName = playerName
            vc.partyID = partyIDInput.text!
            vc.customHash = customHash
        }
    }
    
}
