//
//  DefenderViewController.swift
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

class DefenderViewController: UIViewController, CLLocationManagerDelegate {
    // DATABASE VARIABLES
    var ref: DatabaseReference!
    var playerLatitude: DatabaseReference = DatabaseReference();
    var playerLongitude: DatabaseReference = DatabaseReference();
    
    // BLUETOOTH VARIABLES
    var centralManager: CBCentralManager?
    var peripheralManager = CBPeripheralManager()
    var peripherals = [CBPeripheral]()
    var activePeripheral: CBPeripheral?
    var characteristics = [String: CBCharacteristic]()
    
    @IBOutlet weak var playerStatus: UILabel!
    @IBOutlet weak var fireButton: UIButton!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var ammoLeft: UILabel!
    @IBOutlet weak var timeLeft: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    
    var ammo = 5;
    var currentTime = 1000;
    var timer = Timer();
    var firstCheck = false;
    let locationManager = CLLocationManager()
    var centerLocation: CLLocationCoordinate2D?
    let annotation1 = MKPointAnnotation()
    let annotation2 = MKPointAnnotation()
    let annotation3 = MKPointAnnotation()
    let annotation4 = MKPointAnnotation()
    let annotation5 = MKPointAnnotation()
    let annotation6 = MKPointAnnotation()
    let annotation7 = MKPointAnnotation()
    
    var receivedName = "";
    let SCAN_TIMEOUT = 1.0
    var hit = false;
    var endTime = 0.0
<<<<<<< HEAD
    var firstCheck = false;

=======
    var pressType = "";
    
    
    var customHash = ""
    var nearbyDevices = Set<String>();
    
>>>>>>> a5daf0d36ecd2813ee9bb41ec3fd9886608d658c
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scheduledTimerWithTimeInterval()
        
        ref = Database.database().reference()
        
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        name.text = receivedName;
        ammoLeft.text = String(ammo);
        
        customHash = generateRandomString();
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            print("location services on!")
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            annotation1.coordinate = CLLocationCoordinate2D(latitude: 42.360453, longitude: -71.092541)
            annotation2.coordinate = CLLocationCoordinate2D(latitude: 42.358184, longitude: -71.092091)
            annotation3.coordinate = CLLocationCoordinate2D(latitude: 42.358714, longitude: -71.090531)
            annotation4.coordinate = CLLocationCoordinate2D(latitude: 42.359950, longitude: -71.089064)
            annotation5.coordinate = CLLocationCoordinate2D(latitude: 42.361306, longitude: -71.087134)
            annotation6.coordinate = CLLocationCoordinate2D(latitude: 42.361618, longitude: -71.089299)
            annotation7.coordinate = CLLocationCoordinate2D(latitude: 42.361098, longitude: -71.090898)
            self.mapView.addAnnotations([annotation1, annotation2, annotation3, annotation4, annotation5, annotation6, annotation7])
            
        }
        
        
        
        let player = self.ref.child("Players").child(customHash)
        player.child("Name").setValue(name.text!)
        player.child("Team").setValue("Defender")
        player.child("Status").setValue("Alive")
        
        playerLatitude = player.child("Location").child("Longitude")
        playerLongitude = player.child("Location").child("Latitiude")
        
        // listen to endTime value from database
        self.ref.child("global").child("endTime").observe(DataEventType.value, with: { (snapshot) in
            let value = snapshot.value as! TimeInterval
            self.endTime = value
        }) { (error) in
            print(error.localizedDescription)
        }
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
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }
    
    @objc func updateCounting(){
        let currentTimestamp = NSDate().timeIntervalSince1970
        let gameTimeRemaining = self.endTime - currentTimestamp
        let interval = Int(gameTimeRemaining)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        timeLeft.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        
        if gameTimeRemaining < 0 {
            let alertController = UIAlertController(title: "The game is over!", message: "", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last! as CLLocation
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
<<<<<<< HEAD
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.007))
=======
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
>>>>>>> a5daf0d36ecd2813ee9bb41ec3fd9886608d658c
        
        if !firstCheck{
            self.mapView.setRegion(region, animated: true)
            firstCheck = true;
        }
        
        //add center to db
        self.playerLatitude.setValue(location.coordinate.latitude)
        self.playerLongitude.setValue(location.coordinate.longitude)
        
        self.mapView.showsUserLocation = true;
        
    }
    
    
    @IBAction func fireButton(_ sender: UIButton) {
        if ammo > 0 {
            pressType = "fire"
            ammo -= 1;
            ammoLeft.text = String(ammo);
            startScanning(timeout: SCAN_TIMEOUT)
        } else {
            let alertController = UIAlertController(title: "You are out of ammo!", message: "", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func initService() {
        let serialService = CBMutableService(type: Constants.SERVICE_UUID, primary: true)
        let rx = CBMutableCharacteristic(type: Constants.RX_UUID, properties: Constants.RX_PROPERTIES, value: nil, permissions: Constants.RX_PERMISSIONS)
        
        serialService.characteristics = [rx]
        peripheralManager.add(serialService)
    }
    
    
    func startScanning(timeout: Double) -> Bool {
        if centralManager?.state != .poweredOn {
            
            print("[ERROR] Couldn´t start scanning")
            return false
        }
        
        print("[DEBUG] Scanning started")
        
        Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(DefenderViewController.scanTimeout), userInfo: nil, repeats: false)
        
        self.centralManager?.scanForPeripherals(withServices: [Constants.SERVICE_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        
        return true
    }
    
    @objc private func scanTimeout() {
        print("[DEBUG] Scanning stopped")
        self.centralManager?.stopScan()
        
        postScanProtocol()
    }
    
    func postScanProtocol() {
        
        //delete this shit later
        nearbyDevices.insert("gccqzlp6")
        
        if nearbyDevices.count > 0 {
            let playersRef = self.ref.child("Players")
            
            if pressType == "fire" {
                var inRangeNames = [String : String]()
                
                for hash in self.nearbyDevices {
                    let foundRef = playersRef.child(hash)
                    
                    var name: String?
                    var team: String?
                    var status: String?
                    
                    foundRef.observe(DataEventType.value, with: { (snapshot) in
                        let value = snapshot.value as? [String : AnyObject] ?? [:]
                        name = value["Name"] as? String
                        team = value["Team"] as? String
                        status = value["Status"] as? String
                        print(name, team, status)
                    })
                    
                    if team == "Attacker" {
                        if status == "Alive" {
                            //TODO: check if person is being aimed at
                            inRangeNames[name!] = hash
                        }
                    }
                }

                if inRangeNames.count > 0 {
                    self.generateSelectionPopup(title: "Hit!", message: "Select an enemy to kill:", names: Array(inRangeNames.keys))
                } else {
                    self.generateSelectionPopup(title: "Miss!", message: "There was no one in range.", names: [])
                }
                
            }
            else if pressType == "revive" {}
            else if pressType == "capture" {}
        } else {
            if pressType == "fire" {}
            else if pressType == "revive" {}
            else if pressType == "capture" {}
        }
        
        nearbyDevices.removeAll()
    }
    
    func  generateSelectionPopup(title: String, message: String, names: [String]) {
        // Prepare the popup assets
        
        // Create the dialog
        let popup = PopupDialog(title: title, message: message, image: nil)
        
        var buttons = [PopupDialogButton]()
        for name in names {
            let button = DefaultButton(title: name, action: nil)
            buttons.append(button)
        }
        
        popup.addButtons(buttons)
        
        // Present dialog
        self.present(popup, animated: true, completion: nil)
    }
}

extension DefenderViewController : CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        if (peripheral.state == .poweredOn){
            print("[DEBUG] peripheral state: on")
            
            initService()
            
            let advertisementData = customHash;
            
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[Constants.SERVICE_UUID], CBAdvertisementDataLocalNameKey: advertisementData])
        }
    }
}

extension DefenderViewController : CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            print("[DEBUG] central state: on")
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        peripherals.append(peripheral)
        
        if advertisementData["kCBAdvDataLocalName"] != nil {
            nearbyDevices.insert(advertisementData["kCBAdvDataLocalName"] as! String)
        }
        
        
    }
    
    
}


