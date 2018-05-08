//
//  DefenderViewController.swift
//  Demolition
//
//  Created by Carlos Garcia on 5/2/18.
//  Copyright © 2018 6.S062 Project. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import MapKit
import CoreLocation
import Firebase
import FirebaseDatabase

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
    
    @IBOutlet weak var fireButton: UIButton!
    @IBOutlet weak var playerStatus: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var ammoLeft: UILabel!
    @IBOutlet weak var timeLeft: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    // LOCATION VARIABLES
    let locationManager = CLLocationManager()
    var centerLocation: CLLocationCoordinate2D?
    
    // APPLICATION VARIABLES
    var receivedName = "";
    let SCAN_TIMEOUT = 1.0
    var ammo = 5;
    var timer = Timer();
    var hit = false;
    var endTime = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scheduledTimerWithTimeInterval()

        ref = Database.database().reference()
        
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        name.text = receivedName;
        ammoLeft.text = String(ammo);

        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()

        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            print("location services on!")
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        playerLatitude = self.ref.child("locations").child("defenders").child(name.text!).child("latitude")
        playerLongitude = self.ref.child("locations").child("defenders").child(name.text!).child("longitude")
        
        // listen to endTime value from database
        self.ref.child("global").child("endTime").observe(DataEventType.value, with: { (snapshot) in
            let value = snapshot.value as! TimeInterval
            self.endTime = value
        }) { (error) in
            print(error.localizedDescription)
        }
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
        
        //add center to db
        self.playerLatitude.setValue(location.coordinate.latitude)
        self.playerLongitude.setValue(location.coordinate.longitude)
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.mapView.setRegion(region, animated: true)
        self.mapView.showsUserLocation = true;
    }
    
    
    @IBAction func fireButton(_ sender: UIButton) {
        if ammo > 0 {
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
    
    @objc private func scanTimeout() {
        print("[DEBUG] Scanning stopped")
        self.centralManager?.stopScan()
        
        if hit {
            let alertController = UIAlertController(title: "Hit!", message: "", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            hit = false;
        } else {
            let alertController = UIAlertController(title: "Miss!", message: "", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
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
}

extension DefenderViewController : CBPeripheralDelegate {
    func peripheral( _ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("did discover services")
        for service in peripheral.services! {
            print("iterating thru services")
            peripheral.discoverCharacteristics(nil, for: service)
        }
        
        //        centralManager?.stopScan()
        //        centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?) {
        
        print("did discover characteristics")
        for characteristic in service.characteristics! {
            print("iterating thru chars")
            let characteristic = characteristic as CBCharacteristic
            if (characteristic.uuid.isEqual(Constants.RX_UUID)) {
                print("sending message")
                
                let data = "fire defender " + name.text!
                let data2 = data.data(using: .utf8)
                
                hit = true;
                peripheral.writeValue(data2!, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                
                
            }
        }
        
    }
}

extension DefenderViewController : CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        if (peripheral.state == .poweredOn){
            print("peripheral state: on")
            
            initService()
            
            let advertisementData = "hello"
            
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[Constants.SERVICE_UUID], CBAdvertisementDataLocalNameKey: advertisementData])
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        
        print("didReceiveWrite")
        for request in requests {
            //            if let value = request.value {
            //                print("request value: ", value)
            //            }
            let messageText = String(data: request.value!, encoding: String.Encoding.utf8) as String?
            
            let split = messageText?.components(separatedBy: " ")
            
            let messageType = split![0]
            let fromTeam = split![1]
            let fromName = split![2]
            
            if messageType == "fire" {
                if fromTeam != "defender" {
                    playerStatus.text = "Dead"
                    fireButton.isEnabled = false;
                    self.peripheralManager.respond(to: request, withResult: .success)
                    
                    print("You were killed by: " + fromName)
                    self.peripheralManager.stopAdvertising()
                    self.peripheralManager.removeAllServices()
                }
            }
            
        }
    }
}

extension DefenderViewController : CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            print("central state: on")
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // check if the discovered perif is on opposing team
        print("trying to connect")
        
        peripherals.append(peripheral)
        
        centralManager?.connect(peripheral, options: nil)
        
        central.stopScan()
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        activePeripheral = peripheral
        
        activePeripheral?.delegate = self
        activePeripheral?.discoverServices([Constants.SERVICE_UUID])
        central.stopScan();
        print("connected");
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        var text = "[DEBUG] Disconnected from peripheral: \(peripheral.identifier.uuidString)"
        
        if error != nil {
            text += ". Error: \(error!.localizedDescription)"
        }
        
        print(text)
        
        activePeripheral?.delegate = nil
        activePeripheral = nil
        characteristics.removeAll(keepingCapacity: false)
        
    }
    
    
}
