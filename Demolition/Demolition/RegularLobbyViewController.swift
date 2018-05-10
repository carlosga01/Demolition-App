//
//  RegularLobbyViewController.swift
//  Demolition
//
//  Created by Omar Gonzalez on 5/10/18.
//  Copyright © 2018 6.S062 Project. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseDatabase

class RegularLobbyViewController: UIViewController {
    var ref: DatabaseReference!
    var playerName = ""
    var partyID = ""
    var customHash = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        print(customHash)
        print(playerName)
        print(partyID)
    }
    
}




