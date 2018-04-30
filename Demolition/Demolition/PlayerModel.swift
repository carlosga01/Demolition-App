//
//  PlayerModel.swift
//  Demolition
//
//  Created by Carlos Garcia on 4/30/18.
//  Copyright © 2018 6.S062 Project. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

protocol PlayerModelDelegate {
    func playerModel(_ model: PlayerModel, fire message: String)
    func playerModel(_ model: PlayerModel, didKillOpponent details: [String])
}

class PlayerModel {
    
    
    static let shared = PlayerModel()
    
    var delegate: PlayerModelDelegate?
    
    var ble : BLE
    var isConnected = false
    
    var kBLE_SCAN_TIMEOUT = 10000.0
    
    var packetBuffer = ""
    var isValidReading = false
    
    init() {
        self.ble = BLE()
        ble.delegate = self
    }
}

extension PlayerModel: BLEDelegate {
    func ble(didUpdateState state: BLEState) {
        if state == BLEState.poweredOn {
            print("state is on")
        }
    }
    
    func ble(didDiscoverPeripheral peripheral: CBPeripheral) {
        print("discovered peripheral")
        print(peripheral)
        ble.connectToPeripheral(peripheral)
//        if !(isConnected) {
//            if ble.connectToPeripheral(peripheral) {
//                isConnected = true
//            }
//        }
    }
    
    func ble(didConnectToPeripheral peripheral: CBPeripheral) {
        print("connected to peripheral")
        print(peripheral)
    }
    
    func ble(didDisconnectFromPeripheral peripheral: CBPeripheral) {
        print("disconnected to peripheral")

    }
    
    func ble(_ peripheral: CBPeripheral, didReceiveData data: Data?) {
        // convert a non-nil Data optional into a String
        //let str = String(data: data!, encoding: String.Encoding.ascii)!
        print("received data!")
        print(data)
    }
}
