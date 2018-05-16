//
//  AttackerViewController.swift
//  Demolition
//
//  Created by Carlos Garcia on 4/26/18.
//  Copyright © 2018 6.S062 Project. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import MapKit
import CoreLocation
import Firebase
import FirebaseDatabase
import PopupDialog

class AttackerViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    // DATABASE VARIABLES
    var ref: DatabaseReference!
    var partyRef: DatabaseReference!
    var playerRef: DatabaseReference!
    var playerStatusRef: DatabaseReference!
    var globalLevelRef: DatabaseReference!
    var numPlayersAliveRef: DatabaseReference!
    var flagsCapturedRef: DatabaseReference!
    var localGameStateRef: DatabaseReference!
    var endTimeRef: DatabaseReference!
    var globalFlagsRef: DatabaseReference!
    var allStatusRef: DatabaseReference!
    
    var playerLatitude: DatabaseReference = DatabaseReference()
    var playerLongitude: DatabaseReference = DatabaseReference()
    var myLat: Double?
    var myLon: Double?
    var myHeading: Double?
    
    // BLUETOOTH VARIABLES
    var centralManager: CBCentralManager?
    var peripheralManager = CBPeripheralManager()
    var peripherals = [CBPeripheral]()
    var activePeripheral: CBPeripheral?
    var characteristics = [String: CBCharacteristic]()
    
    @IBOutlet weak var reviveButton: UIButton!
    @IBOutlet weak var fireButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var ammoLeft: UILabel!
    @IBOutlet weak var timeLeft: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deathOverlay: UIView!
    
    let locationManager = CLLocationManager()
    var centerLocation: CLLocationCoordinate2D?
    
    var playerAnnotations = [CustomPointAnnotation()]
    var anView = MKAnnotationView()
    
    var ammo = 10
    var timer: Timer? = nil
    var firstCheck = false
    var receivedName = ""
    var receivedPartyID = ""
    var receivedCustomHash = ""
    var receivedFlags: Dictionary<String, CustomPointAnnotation> = [:]
    var playerStatus = "Alive"
    
    var receivedAttackersList: [String] = []
    var receivedDefendersList: [String] = []
    
    let SCAN_TIMEOUT = 1.0
    let SCAN_TIMEOUT_CAPTURE = 5.0
    var scanning = false
    var endTime = 0.0
    var pressType = ""
    
    var didTimeExpire = false
    var didCaptureMostFlags = false
    var areAllAttackersDead = false
    var areAllDefendersDead = false
    
    var nearbyDevices = Set<String>()
    var nearbyHills = Set<String>()
    var capturedHills = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        
        runGlobalCountdown()
        scheduledLocationFetcher()
        
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        name.text = receivedName
        ammoLeft.text = String(ammo)
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            //locationManager.startUpdatingHeading()
        }

        self.mapView.addAnnotations(Array(receivedFlags.values))
        
        // references at different levels
        ref = Database.database().reference()
        partyRef = ref.child("Parties").child(receivedPartyID)
        playerRef = partyRef.child("Players").child(receivedCustomHash)
        playerStatusRef = playerRef.child("Status")

        globalLevelRef = partyRef.child("Global")
        flagsCapturedRef = globalLevelRef.child("flagsCaptured")
        localGameStateRef = globalLevelRef.child("gameState")
        endTimeRef = globalLevelRef.child("endTime")
        globalFlagsRef = globalLevelRef.child("Flags")
        numPlayersAliveRef = globalLevelRef.child("numPlayersAlive")
        allStatusRef = ref.child("Parties").child(receivedPartyID).child("PlayerStatus")

        //set the values in the player hash section of the DB
        playerRef.child("Name").setValue(receivedName)
        playerRef.child("Team").setValue("Attacker")
        playerRef.child("Status").setValue("Alive")
        
        //create Location folder in DB for player
        playerLongitude = playerRef.child("Location").child("Longitude")
        playerLongitude.setValue(0)
        playerLatitude = playerRef.child("Location").child("Latitude")
        playerLatitude.setValue(0)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is GameOverViewController  {
            let vc = segue.destination as? GameOverViewController
            vc?.receivedPartyID = receivedPartyID
            vc?.didTimeExpire = didTimeExpire
            vc?.didCaptureMostFlags = didCaptureMostFlags
            vc?.receivedAttackersList = receivedAttackersList
            vc?.receivedDefendersList = receivedDefendersList
            vc?.areAllAttackersDead = areAllAttackersDead
            vc?.areAllDefendersDead = areAllDefendersDead
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // player status listener
        playerStatusRef.observe(DataEventType.value) { (snapshot) in
            let status = snapshot.value as? String
            if status == "Alive" {
                //remove red overlay and enable buttons
                self.playerStatus = "Alive"
                self.enableAllButtons()
                self.deathOverlay.alpha = 0.0;
                self.allStatusRef.child(self.name.text!).setValue("Alive")
                
            } else if status == "Dead" {
                //add red overlay and disable buttons
                self.playerStatus = "Dead"
                self.disableAllButtons()
                self.deathOverlay.alpha = 0.75
                self.allStatusRef.child(self.name.text!).setValue("Dead")
            }
        }

        // game status listener
        localGameStateRef.observe(DataEventType.value) { (snapshot) in
            let status = snapshot.value as! String
            if status == "isOver" {
                // perform segue to Game Over screen
                self.performSegue(withIdentifier: "gameOverSegue", sender: nil)
            }
        }
        
        // listen to flagsCaptured
        flagsCapturedRef.observe(DataEventType.value) { (snapshot) in
            let numFlagsCaptured = snapshot.value as! Int
            if numFlagsCaptured >= 4 {
                self.didCaptureMostFlags = true
                self.localGameStateRef.setValue("isOver")
            }
        }
        
        // listen to endTime value from database
        endTimeRef.observe(DataEventType.value) { (snapshot) in
            let value = snapshot.value as! TimeInterval
            self.endTime = value
        }
        
        //listen to all player status's
        allStatusRef.observe(DataEventType.value) { (snapshot) in
            let allStatusDict = snapshot.value as! Dictionary<String, Any>
            var deadNames = ""
            var imDead = false
            for name in allStatusDict.keys {
                let status = allStatusDict[name] as! String
                
                if status == "Dead" {
                    if name == self.name.text {
                        imDead = true
                    }
                    deadNames += name + " "
                }
            }
            if deadNames != "" && imDead == false {
                let alert = UIAlertController(title: "Dead Players:", message: deadNames, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        
        // listen for flag statuses from Database
        globalFlagsRef.observe(DataEventType.value) { (snapshot) in
            let flags = snapshot.value! as! [String:[String:Any]]
            for flag in flags {
                let flag = flag.key
                let status = flags[flag]!["Status"]! as! String
                if status == "Captured" {
                    self.capturedHills.insert(flag)
                    let annotation = self.receivedFlags[flag]!
                    if annotation.imageName == "captured"{
                        continue
                    }
                    self.mapView.removeAnnotation(annotation)
                    annotation.imageName = "captured"
                    self.mapView.addAnnotation(annotation)
                }
            }
        }
        
        //listen to numAttackersAlive and numDefendersAlive
        numPlayersAliveRef.observe(DataEventType.value) { (snapshot) in
            let numPlayerAlive = snapshot.value as! [String:Int]
            if numPlayerAlive["numAttackersAlive"]! == 0 {
                self.areAllAttackersDead = true
                self.localGameStateRef.setValue("isOver")
            }
            if numPlayerAlive["numDefendersAlive"]! == 0 {
                self.areAllDefendersDead = true
                self.localGameStateRef.setValue("isOver")
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        playerStatusRef.removeAllObservers()
        flagsCapturedRef.removeAllObservers()
        localGameStateRef.removeAllObservers()
        endTimeRef.removeAllObservers()
        globalFlagsRef.removeAllObservers()
        numPlayersAliveRef.removeAllObservers()
        allStatusRef.removeAllObservers()
        
        stopTimer()
        locationManager.stopUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    func runGlobalCountdown(){
        // Scheduling timer to Call the function "updateGlobalCountdown" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateGlobalCountdown), userInfo: nil, repeats: true)
    }
    

    func scheduledLocationFetcher() {
        //scheduled timer to fetch for locations
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.fetchLocationsFromDatabase), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    @objc func fetchLocationsFromDatabase() {
        self.mapView.removeAnnotations(self.playerAnnotations)
        getLocations(callback: { (players) -> Void in
            for player in players {
                if player[2] == "Defender"{
                    continue
                }
                let playerAnnotation = CustomPointAnnotation()
                
                if player[3] == "Dead"{
                    playerAnnotation.imageName = "death"
                }
                else{
                    playerAnnotation.imageName = "self"
                }
                playerAnnotation.title = player[4]
                playerAnnotation.coordinate = CLLocationCoordinate2D(latitude: Double(player[0])!, longitude: Double(player[1])!)
                self.playerAnnotations.append(playerAnnotation)
                self.mapView.addAnnotation(playerAnnotation)
            }
        })
    }
    
    @objc func updateGlobalCountdown() {
        let currentTimestamp = NSDate().timeIntervalSince1970
        let gameTimeRemaining = self.endTime - currentTimestamp
        let interval = Int(gameTimeRemaining)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        timeLeft.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        
        if gameTimeRemaining < 0 {
            self.didTimeExpire = true
            self.ref.child("Parties").child(receivedPartyID).child("Global").child("gameState").setValue("isOver")
        }
    }
    
//    @objc func showAnnotationDisclosure(sender: MyButton) {
//        print("Disclosure button clicked")
//        print(sender.annotation?.title as! String)
//    }
    
    func mapView(_ mapView: MKMapView!, viewFor annotation: MKAnnotation!) -> MKAnnotationView! {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        
        let annotationReuseId = "Place"
        var anView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationReuseId)
        
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationReuseId)
//            let button = UIButton(type: .detailDisclosure)
//            button.addTarget(self, action: #selector(AttackerViewController.showAnnotationDisclosure(sender:)), for: .touchUpInside)
//            anView?.rightCalloutAccessoryView = button
            
        } else {
            anView?.annotation = annotation
        }
        
        let cpa = annotation as! CustomPointAnnotation
        anView?.image = UIImage(named:cpa.imageName)
        anView?.frame.size = CGSize(width: 30, height: 30)
        anView?.backgroundColor = UIColor.clear
        anView?.canShowCallout = true;
        
//        if let button = anView!.rightCalloutAccessoryView as? MyButton {
//            button.annotation = annotation as! CustomPointAnnotation
//        }
//
        return anView
        
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        
        if control == view.rightCalloutAccessoryView {
            print("Pressed!")
            
        }
        print("Click")
    }
    
//    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//        print("Annotation selected")
//
//        if let annotation = view.annotation as? CustomPointAnnotation {
//            print(annotation.title);
//        }
//    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last! as CLLocation
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.007))
        
        if !firstCheck{
            self.mapView.setRegion(region, animated: true)
            firstCheck = true
        }
        
        //add center to db
        
        self.playerLatitude.setValue(location.coordinate.latitude)
        self.playerLongitude.setValue(location.coordinate.longitude)
        self.myLat = location.coordinate.latitude
        self.myLon = location.coordinate.longitude
        
        self.mapView.showsUserLocation = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.myHeading = newHeading.magneticHeading
    }
    
    @IBAction func reviveButton(_ sender: UIButton) {
        pressType = "revive"
        startScanning(timeout: SCAN_TIMEOUT)
    }
    
    @IBAction func captureButton(_ sender: UIButton) {
        pressType = "capture"
        startScanning(timeout: SCAN_TIMEOUT_CAPTURE)
    }
    @IBAction func fireButton(_ sender: UIButton) {
        if ammo > 0 {
            pressType = "fire"
            ammo -= 1
            ammoLeft.text = String(ammo)
            startScanning(timeout: SCAN_TIMEOUT)
        } else {
            self.generateKillPopup(title: "You're out of ammo!", message: "That sucks :(", names: [:])
        }
    }
    
    func initService() {
        let serialService = CBMutableService(type: Constants.SERVICE_UUID, primary: true)
        let rx = CBMutableCharacteristic(type: Constants.RX_UUID, properties: Constants.RX_PROPERTIES, value: nil, permissions: Constants.RX_PERMISSIONS)

        serialService.characteristics = [rx]
        peripheralManager.add(serialService)
    }
    
    func disableAllButtons() {
        fireButton.isEnabled = false;
        reviveButton.isEnabled = false;
        captureButton.isEnabled = false;
    }
    
    func enableAllButtons() {
        fireButton.isEnabled = true;
        reviveButton.isEnabled = true;
        captureButton.isEnabled = true;
    }
    
    func startScanning(timeout: Double) -> Bool {
        if centralManager?.state != .poweredOn {
            print("[ERROR] Couldn´t start scanning")
            return false
        }
        
        if self.scanning == false {
            
            disableAllButtons()
            
            self.scanning = true
            
            print("[DEBUG] Scanning started")
            
            Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(AttackerViewController.scanTimeout), userInfo: nil, repeats: false)
            
            
            let newNodeService = CBUUID(string: "713D0000-503E-4C75-BA94-3148F18D941E")
            self.centralManager?.scanForPeripherals(withServices: [CBUUID(string: "FEAA"), Constants.SERVICE_UUID, newNodeService], options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
            
            
            return true
        } else {
            return false
        }
    }
    
    @objc private func scanTimeout() {
        self.scanning = false
        enableAllButtons()
        print("[DEBUG] Scanning stopped")
        self.centralManager?.stopScan()
        
        postScanProtocol()
    }
    
    func postScanProtocol() {
        
        if pressType == "capture" {
            if nearbyHills.count > 0 {
                var unCapturedHills = Set<String>()
                for hill in nearbyHills {
                    if !self.capturedHills.contains(hill) {
                        unCapturedHills.insert(hill)
                    }
                }
                
                if unCapturedHills.count > 0 {
                    
                    //check if player is still alive

                    if self.playerStatus == "Alive" {
                        self.generateCapturePopup(title: "Capture in range!", message: "Select a hill to steal data from:", hills: unCapturedHills)
                    }
                } else {
                    self.generateCapturePopup(title: "No hills in range to capture!", message: "Go get 'em ", hills: Set<String>())
                }
            } else {
                self.generateCapturePopup(title: "No hills in range to capture!", message: "Go get 'em ", hills: Set<String>())
            }
        }
        
        // Check for nearby devices
        if nearbyDevices.count > 0 {
            if pressType == "fire" {
                var inRangeNames = [String : String]()
                
                fetchPlayersFromDatabase(hashList: self.nearbyDevices, callback: { (players) -> Void in
                    
                    for player in players {
                        let team = player[1]
                        let status = player[2]
                        let name = player[0]
                        let hash = player[3]
                        let lat2 = Double(player[4])
                        let lon2 = Double(player[5])
                        
                        if team == "Defender" && status == "Alive" {
//                            print("hit")
//                            let me = MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: CLLocationDegrees(self.myLat!), longitude: CLLocationDegrees(self.myLon!)))
//                            let enemy = MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: CLLocationDegrees(lat2!), longitude: CLLocationDegrees(lon2!)))
//
//                            let distanceToEnemy = MKMetersBetweenMapPoints(me, enemy)
//                            let headingToEnemy = atan2(sin(lon2!-self.myLon!)*cos(lat2!), cos(self.myLat!)*sin(lat2!)-sin(self.myLat!)*cos(lat2!)*cos(lon2!-self.myLon!))
//
//                            let delta = abs(headingToEnemy - self.myHeading!)
//
//                            print(delta)
//                            print(distanceToEnemy)
////                            if delta < 45 || distanceToEnemy < 5 {
                            inRangeNames[name] = hash
//                            }
                            
                        }
                    }
                    
                    if inRangeNames.count > 0 {
                        self.generateKillPopup(title: "Hit!", message: "Select an enemy to kill:", names: inRangeNames)
                    } else {
                        self.generateKillPopup(title: "Miss!", message: "There was no one in range.", names: [:])
                    }
                })
                
            }
            else if pressType == "revive" {
                var inRangeNames = [String : String]()
                
                fetchPlayersFromDatabase(hashList: self.nearbyDevices, callback: { (players) -> Void in
                    
                    for player in players {
                        let team = player[1]
                        let status = player[2]
                        let name = player[0]
                        let hash = player[3]
                        
                        if team == "Attacker" && status == "Dead" {
                            inRangeNames[name] = hash
                        }
                    }
                    
                    if inRangeNames.count > 0 {
                        self.generateRevivePopup(title: "Downed ally in range!", message: "Select an ally to revive:", names: inRangeNames)
                    } else {
                        self.generateRevivePopup(title: "No downed allys in range!", message: "I guess that's good?", names: [:])
                    }
                })
            }
        } else {
            if pressType == "fire" {
                self.generateKillPopup(title: "Miss!", message: "There was no one in range.", names: [:])
            }
            else if pressType == "revive" {
                self.generateRevivePopup(title: "No downed allys in range!", message: "I guess that's good?", names: [:])
            }
        }
        
        nearbyDevices.removeAll()
    }
    
    func  generateKillPopup(title: String, message: String, names: [String:String]) {
        // Prepare the popup assets
        
        // Create the dialog
        let popup = PopupDialog(title: title, message: message, image: nil)
        
        var buttons = [PopupDialogButton]()
        for name in names.keys {
            
            let button = DefaultButton(title: name) {
                let hash = names[name]
                self.ref.child("Parties").child(self.receivedPartyID).child("Players").child(hash!).child("Status").setValue("Dead")
                
                // dec numDefendersAlive
                self.numPlayersAliveRef.child("numDefendersAlive").observeSingleEvent(of: .value, with: { (snapshot) in
                    var value = snapshot.value as! Int
                    value = value - 1
                    self.numPlayersAliveRef.child("numDefendersAlive").setValue(value)
                })
            }
            buttons.append(button)
        }
        
        popup.addButtons(buttons)
        
        // Present dialog
        self.present(popup, animated: true, completion: nil)
    }
    
    func  generateRevivePopup(title: String, message: String, names: [String:String]) {
        // Prepare the popup assets
        
        // Create the dialog
        let popup = PopupDialog(title: title, message: message, image: nil)
        
        var buttons = [PopupDialogButton]()
        for name in names.keys {
            
            let button = DefaultButton(title: name) {
                let hash = names[name]
                self.ref.child("Parties").child(self.receivedPartyID).child("Players").child(hash!).child("Status").setValue("Alive")
                
                // inc numAttackersAlive
                self.numPlayersAliveRef.child("numAttackersAlive").observeSingleEvent(of: .value, with: { (snapshot) in
                    var value = snapshot.value as! Int
                    value = value + 1
                    self.numPlayersAliveRef.child("numAttackersAlive").setValue(value)
                })
            }
            buttons.append(button)
        }
        
        popup.addButtons(buttons)
        
        // Present dialog
        self.present(popup, animated: true, completion: nil)
    }
    
    func  generateCapturePopup(title: String, message: String, hills: Set<String>) {
        // Prepare the popup assets
        
        // Create the dialog
        let popup = PopupDialog(title: title, message: message, image: nil)
        
        let flags = self.ref.child("Parties").child(receivedPartyID).child("Global").child("Flags")
        var buttons = [PopupDialogButton]()
        for hill in hills {
            
            let button = DefaultButton(title: hill) {
                if self.playerStatus == "Alive" {
                    flags.child(hill).child("Status").setValue("Captured")
                    
                    //increment flagsCaptured in database
                    self.ref.child("Parties").child(self.receivedPartyID).child("Global").child("flagsCaptured").observeSingleEvent(of: .value, with: { (snapshot) in
                        var value = snapshot.value as! Int
                        value = value + 1
                        self.ref.child("Parties").child(self.receivedPartyID).child("Global").child("flagsCaptured").setValue(value)
                    })
                    
                    //add 5 minutes to overall time
                    let fiveMin = TimeInterval(5 * 60)
                    self.endTimeRef.setValue(self.endTime + fiveMin)
                    
                }
            }
            buttons.append(button)
        }
        
        popup.addButtons(buttons)
        
        // Present dialog
        self.present(popup, animated: true, completion: nil)
    }
    
    func getLocations(callback: @escaping (_ players: [[String]])->Void){
        let dbReference = self.ref.child("Parties").child(receivedPartyID).child("Players")
        // READ VALUE FROM DATABASE
        dbReference.observeSingleEvent(of: .value, with: { (snapshot) in
            var players = [[String]]()
            let values = snapshot.value as? [String:[String:Any]]
            for value in values!{
                if value.key == self.receivedCustomHash {

                    continue
                }
                let location = value.value["Location"]! as! Dictionary<String,AnyObject>
                let team = value.value["Team"]! as! String
                let status = value.value["Status"] as! String
                let name = value.value["Name"]! as! String
                if location["Latitude"] != nil{
                    let lat = location["Latitude"]! as! Double
                    let lon = location["Longitude"]! as! Double
                    players.append([String(lat), String(lon), team, status, name])
                }
            }

            callback(players)
        })
    
    }

    func fetchPlayersFromDatabase(hashList: Set<String>, callback: @escaping (_ players: [[String]])->Void) {
        
        let dbReference = self.ref.child("Parties").child(receivedPartyID).child("Players")
        
        // READ VALUE FROM DATABASE
        dbReference.observeSingleEvent(of: .value, with: { (snapshot) in
            var players = [[String]]()
            let values = snapshot.value as? [String:[String:Any]]
            
            for hash in hashList {
                let player = values![hash]
                
                let name = player!["Name"] as! String
                let team = player!["Team"] as! String
                let status = player!["Status"] as! String
                
                let location = player!["Location"] as! Dictionary<String, Double>
                let lat = String(format:"%f", location["Latitude"]!)
                let lon = String(format:"%f", location["Longitude"]!)
                
                players.append([name, team, status, hash, lat, lon])
            }
            callback(players)
        })
    }
}

extension AttackerViewController : CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        if (peripheral.state == .poweredOn){
            print("[DEBUG] peripheral state: on")
            
            initService()
            
            let advertisementData = receivedCustomHash
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[Constants.SERVICE_UUID], CBAdvertisementDataLocalNameKey: advertisementData])
        }
    }
}

extension AttackerViewController : CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            print("[DEBUG] central state: on")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        peripherals.append(peripheral)

        if advertisementData["kCBAdvDataLocalName"] != nil {
            let name = peripheral.name
            let hash = advertisementData["kCBAdvDataLocalName"] as? String
            
            let flags = ["Flag1", "Flag2", "Flag3", "Flag4", "Flag5", "Flag6", "Flag7"]
            
            //TODO: remove this when we get a new node
            if name == "HILL11" {
                nearbyHills.insert("Flag7")
            }
            
            else if flags.contains(name!) {
                if RSSI.decimalValue > -70 {
                    nearbyHills.insert(name!)
                }
            } else if hash!.count == 8 {
                nearbyDevices.insert(hash!)
            }
        }
    }
}

class MyButton : UIButton {
    var annotation: CustomPointAnnotation? = nil
}



