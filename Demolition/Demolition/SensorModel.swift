//
//  SensorModel.swift
//  Anteater
//
//  Created by Justin Anderson on 8/1/16.
//  Copyright © 2016 MIT. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

protocol SensorModelDelegate {
    func sensorModel(_ model: SensorModel, didChangeActiveHill hill: Hill?)
    func sensorModel(_ model: SensorModel, didReceiveReadings readings: [Reading], forHill hill: Hill?)
}

extension Notification.Name {
    public static let SensorModelActiveHillChanged = Notification.Name(rawValue: "SensorModelActiveHillChangedNotification")
    public static let SensorModelReadingsChanged = Notification.Name(rawValue: "SensorModelHillReadingsChangedNotification")
}

enum ReadingType: Int {
    case Unknown = -1
    case Humidity = 2
    case Temperature = 1
    case Error = 0
}

struct Reading {
    let type: ReadingType
    let value: Double
    let date: Date = Date()
    let sensorId: String?
    
    func toJson() -> [String: Any] {
        return [
            "value": self.value,
            "type": self.type.rawValue,
            "timestamp": self.date.timeIntervalSince1970,
            "userid": UIDevice.current.identifierForVendor?.uuidString ?? "NONE",
            "sensorid": sensorId ?? "NONE"
        ]
    }
}

extension Reading: CustomStringConvertible {
    var description: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        guard let numberString = formatter.string(from: NSNumber(value: self.value)) else {
            print("Double \"\(value)\" couldn't be formatted by NumberFormatter")
            return "NaN"
        }
        switch type {
        case .Temperature:
            return "\(numberString)°F"
        case .Humidity:
            return "\(numberString)%"
        default:
            return "\(type)"
        }
    }
}

struct Hill {
    var readings: [Reading]
    var name: String
    
    init(name: String) {
        readings = []
        self.name = name
    }
}

extension Hill: CustomStringConvertible, Hashable, Equatable {
    var description: String {
        return name
    }
    
    var hashValue: Int {
        return name.hashValue
    }
}

func ==(lhs: Hill, rhs: Hill) -> Bool {
    return lhs.name == rhs.name
}

class SensorModel {

    static let kBLE_SCAN_TIMEOUT = 10000.0
    
    static let shared = SensorModel()

    var delegate: SensorModelDelegate?
    var sensorReadings: [ReadingType: [Reading]] = [.Humidity: [], .Temperature: []]
    var activeHill: Hill?
    var ble : BLE
    var isConnected = false
    
    var packetBuffer = ""
    var isValidReading = false
    
    init() {
        self.ble = BLE()
        ble.delegate = self
    }
}

extension SensorModel: BLEDelegate {
    func ble(didUpdateState state: BLEState) {
        if state == BLEState.poweredOn {
            ble.startScanning(timeout: SensorModel.kBLE_SCAN_TIMEOUT)
        }
    }
    
    func ble(didDiscoverPeripheral peripheral: CBPeripheral) {
        if !(isConnected) {
            if ble.connectToPeripheral(peripheral) {
                isConnected = true
            }
        }
    }
    
    func ble(didConnectToPeripheral peripheral: CBPeripheral) {
        let newHill = Hill(name: peripheral.name!)
        activeHill = newHill
        
        delegate?.sensorModel(SensorModel.shared, didChangeActiveHill: activeHill)
    }
    
    func ble(didDisconnectFromPeripheral peripheral: CBPeripheral) {
        if peripheral.name == activeHill?.name {
            activeHill = nil
            delegate?.sensorModel(SensorModel.shared, didChangeActiveHill: activeHill)
        }
        
        isConnected = false
//        activeHill?.readings.removeAll()
//        ble(didUpdateState: BLEState.poweredOn)
    }
    
    func ble(_ peripheral: CBPeripheral, didReceiveData data: Data?) {
        // convert a non-nil Data optional into a String
        let str = String(data: data!, encoding: String.Encoding.ascii)!
        
        // check for error
        if !(str[str.startIndex] == "E") {
            
            // String parsing, based on data format
            for ch in str {
                if ch == "H" || ch == "T" {
                    packetBuffer += String(ch)
                    isValidReading = true
                    continue
                }
                
                if ch == "D" {
                    packetBuffer += " "
                    isValidReading = false
                    continue
                }
                
                if isValidReading {
                    packetBuffer += String(ch)
                }
            }
            
            var stripped = packetBuffer.components(separatedBy: " ")
            var reconstr = ""
            var readingsArr = [Reading]()
            while stripped.count > 0 {
                var parsedStr = stripped.removeFirst().trimmingCharacters(in: .whitespaces)
                if parsedStr.count > 1 {
                    
                    // get Reading Type
                    let type = parsedStr.removeFirst()
                    var rType = ReadingType.Unknown
                    if type == "H" {
                        rType = ReadingType.Humidity
                    }
                    
                    if type == "T" {
                        rType = ReadingType.Temperature
                    }
                    
                    // convert a String to a Double, and create a Reading
                    let val = NSString(string: parsedStr).doubleValue
                    let newReading = Reading(type: rType, value: val, sensorId: peripheral.name)
                    readingsArr.append(newReading)
                } else {
                    reconstr += parsedStr
                }
            }
            
            // keep leftover / half readings.
            packetBuffer = reconstr
            
            delegate?.sensorModel(SensorModel.shared, didReceiveReadings: readingsArr, forHill: activeHill)
            activeHill?.readings.append(contentsOf: readingsArr)
        }
    }
}



