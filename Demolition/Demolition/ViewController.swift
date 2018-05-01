//
//  ViewController.swift
//  Demolition
//
//  Created by Carlos Garcia on 4/26/18.
//  Copyright © 2018 6.S062 Project. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    
    var centralManager: CBCentralManager?
    var peripheralManager = CBPeripheralManager()
    
    var cachedPeripheralNames = Dictionary<String, String>()
    var timer = Timer()
    
    var peripherals = [CBPeripheral]()
    var activePeripheral: CBPeripheral?
    
    var characteristics = [String: CBCharacteristic]()
    
    let SCAN_TIMEOUT = 1.0
    
    var nameText: String?
    
    @IBOutlet weak var playerStatus: UILabel!
    @IBOutlet weak var fireButton: UIButton!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var team: UILabel!
    var receivedName = "";
    var receivedTeam = "";

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        name.text = receivedName;
        team.text = receivedTeam;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func fireButton(_ sender: UIButton) {
        startScanning(timeout: SCAN_TIMEOUT)
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
    }
    
    func startScanning(timeout: Double) -> Bool {
        if centralManager?.state != .poweredOn {
            
            print("[ERROR] Couldn´t start scanning")
            return false
        }
        
        print("[DEBUG] Scanning started")
        
        Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(ViewController.scanTimeout), userInfo: nil, repeats: false)
        
        self.centralManager?.scanForPeripherals(withServices: [Constants.SERVICE_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        
        return true
    }
}

extension ViewController : CBPeripheralDelegate {
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
                
                let data = "you've been attacked"
                let data2 = data.data(using: .utf8)
                
                peripheral.writeValue(data2!, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                
            }
        }
        
    }
}

extension ViewController : CBPeripheralManagerDelegate {
    
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
            let messageText = String(data: request.value!, encoding: String.Encoding.utf8) as String!
            

            print(messageText!)
            playerStatus.text = "Dead"
            fireButton.isEnabled = false;
            self.peripheralManager.respond(to: request, withResult: .success)
            
            self.peripheralManager.stopAdvertising()
            self.peripheralManager.removeAllServices()
            
        }
    }
}

extension ViewController : CBCentralManagerDelegate {
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

