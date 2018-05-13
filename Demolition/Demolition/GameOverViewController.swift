//
//  GameOverViewController.swift
//  Demolition
//
//  Created by Omar Gonzalez on 5/12/18.
//  Copyright © 2018 6.S062 Project. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseDatabase

class GameOverViewController: UIViewController {
    var ref: DatabaseReference!
    var receivedPartyID: String = ""
    var didTimeExpire: Bool = false
    var didCaptureMostFlags: Bool = true
    var receivedAttackersList: [String] = []
    var receivedDefendersList: [String] = []
    
    @IBOutlet weak var winnerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // get winners
        if didCaptureMostFlags && !didTimeExpire {
            print(receivedAttackersList)
            winnerLabel.text = "ATTACKERS WIN!"
        } else if !didCaptureMostFlags && didTimeExpire {
            print(receivedDefendersList)
            winnerLabel.text = "DEFENDERS WIN!"
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // wipe party from database if still in databse
        ref = Database.database().reference()
        let allPartiesRef = self.ref.child("Parties")
        allPartiesRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.hasChild(self.receivedPartyID) {
                allPartiesRef.child(self.receivedPartyID).removeValue()
            }
        }
    }
}
