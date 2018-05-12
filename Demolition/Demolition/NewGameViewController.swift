//
//  NewGameViewController.swift
//  Demolition
//
//  Created by Omar Gonzalez on 5/8/18.
//  Copyright © 2018 6.S062 Project. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseDatabase

class NewGameViewController: UIViewController {
    var ref: DatabaseReference!
    var partyID: String = ""
    var customHash: String = ""
    
    @IBOutlet weak var playerName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
    }
    
    @IBAction func createGameButton(_ sender: UIButton) {
        partyID = generatePartyID()
        customHash = generateRandomString()
    
        if self.playerName.text != "" {
            // send name and partyID to db
            let partyRef = self.ref.child("Parties").child(partyID)
            let playerRef = partyRef.child("Players").child(customHash)
            playerRef.child("Name").setValue(playerName.text!)
            playerRef.child("Team").setValue("Attacker")
            playerRef.child("Status").setValue("Alive")
            self.performSegue(withIdentifier: "hostLobbySegue", sender: nil)
        } else {
            let alertController = UIAlertController(title: "Enter your name", message: "", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func joinGameButtonClick(_ sender: UIButton) {
        customHash = generateRandomString()
        if self.playerName.text != "" {
            self.performSegue(withIdentifier: "joinGameSegue", sender: nil)
        } else {
            let alertController = UIAlertController(title: "Enter your name", message: "", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func generatePartyID () -> String {
        var result = ""
        repeat {
            // Create a string with a random number 0...9999
            result = String(format:"%04d", arc4random_uniform(10000) )
        } while Set<Character>(result).count < 4
        
        return result
    }
    
    func generateRandomString() -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< 8 {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is HostLobbyViewController {
            let vc = segue.destination as? HostLobbyViewController
            vc?.playerName = playerName.text!
            vc?.partyID = partyID
            vc?.customHash = customHash
        } else if segue.destination is JoinGameViewController {
            let vc = segue.destination as? JoinGameViewController
            vc?.playerName = playerName.text!
            vc?.customHash = customHash
        }
    }

}
