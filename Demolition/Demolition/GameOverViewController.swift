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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // check who won. Either time ran out, or 4 flags were captured.
        ref = Database.database().reference()
        
        // get winners
        
        // wipe party from database
    }
}
