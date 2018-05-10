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
        
        // send name and partyID to db
        let partyRef = self.ref.child("Parties").child(partyID)
        let playerRef = partyRef.child("Players").child(customHash)
        playerRef.child("Name").setValue(playerName.text!)
        playerRef.child("Team").setValue("Attacker")
        playerRef.child("Status").setValue("Alive")
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
        if segue.destination is SigninViewController {
            let vc = segue.destination as? SigninViewController
            vc?.playerName = playerName.text!
            vc?.partyID = partyID
            vc?.customHash = customHash
        } else {
            let vc = segue.destination as? JoinGameViewController
            vc?.playerName = playerName.text!
            vc?.customHash = generateRandomString()
        }
    }

}
