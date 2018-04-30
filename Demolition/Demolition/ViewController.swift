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
    
    let mainCellReuseIdentifier = "MainCell"
    let columnCount = 2
    let margin : CGFloat = 10
    var visibleDevices = Array<Device>()
    var cachedDevices = Array<Device>()
    var cachedPeripheralNames = Dictionary<String, String>()
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func fireButton(_ sender: UIButton) {
        
        self.centralManager?.scanForPeripherals(withServices: [Constants.SERVICE_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        print("im scanning")
    }
    
}

extension ViewController: CBPeripheralDelegate{
    
}

extension ViewController : CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        if (peripheral.state == .poweredOn){
            
            let adData = "hello"
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [Constants.SERVICE_UUID], CBAdvertisementDataLocalNameKey: adData])
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        
        for request in requests {
            print("hit")
            self.peripheralManager.respond(to: request, withResult: .success)
        }
    }
    
    func peripheral( _ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        for service in peripheral.services! {
            
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?) {
        
        for characteristic in service.characteristics! {
            
            let characteristic = characteristic as CBCharacteristic
            if (characteristic.uuid.isEqual(Constants.RX_UUID)) {
                print("recieved message")
                
                let data = "you've been attacked"
                let data2 = data.data(using: .utf8)
                
                peripheral.writeValue(data2!, for: characteristic, type: CBCharacteristicWriteType.withResponse)
            }
            
        }
    }
}

extension ViewController:CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            print("state is on")
            
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // check if the discovered perif is on opposing team
        print("trying to connect")
        centralManager?.connect(peripheral, options: nil)
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        peripheral.delegate = self
        print("connected")
        peripheral.discoverServices(nil)
        
    }
}

