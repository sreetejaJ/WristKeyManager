//
//  ViewController.swift
//  WristKeyManager
//
//  Created by Sreeteja Jonnada on 08/08/2018.
//  Copyright © 2018 Sreeteja Jonnada. All rights reserved.
//

import Cocoa
import CoreBluetooth

let wristKeyCBUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
let rxCBUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
let txCBUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")

class ViewController: NSViewController{
    
    var centralManager: CBCentralManager!
    var wrstkyPeripheral: CBPeripheral!
    var writeChar: CBCharacteristic!
    var connected = false
    
    @IBOutlet weak var ErrorLabel: NSTextField!
    
    @IBOutlet weak var MemoryIndicator: NSLevelIndicator!
    @IBOutlet weak var StatusIndicator: NSLevelIndicator!
    
    @IBOutlet weak var MasterPwd: NSSecureTextField!
    
    @IBOutlet weak var Secure: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ErrorLabel.isHidden = true
        centralManager = CBCentralManager(delegate: self, queue: nil)
        StatusIndicator.criticalValue = 1
        StatusIndicator.warningValue = 2
        MemoryIndicator.doubleValue = 40
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func ConnectButton(_ sender: Any) {
        if(connected){
            wrstkyPeripheral.writeValue(MasterPwd.stringValue.data(using: .ascii)!, for: writeChar, type: .withoutResponse)
        }else{
            var msg = ""
            switch centralManager.state{
            case .unknown:
                msg = "central.state is .unknown"
            case .resetting:
                msg = "central.state is .resetting"
            case .unsupported:
                msg = "central.state is .unsupported"
            case .unauthorized:
                msg = "central.state is .unauthorized"
            case .poweredOff:
                msg = "central.state is .poweredOff"
            case .poweredOn:
                msg = "central.state is .poweredOn"
            }
            ErrorLabel.stringValue = msg
            ErrorLabel.textColor = NSColor.red
            ErrorLabel.isHidden = false
            print(msg)
        }
    }
    @IBAction func EncryptButton(_ sender: Any) {
    }
    @IBAction func RetrieveData(_ sender: Any) {
    }
    
    
}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state{
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: [wristKeyCBUUID])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        print(advertisementData)
        wrstkyPeripheral = peripheral
        centralManager.stopScan()
        centralManager.connect(wrstkyPeripheral)
        wrstkyPeripheral.delegate = self
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        connected = true
        StatusIndicator.warningValue = 1
        StatusIndicator.criticalValue = 2
        wrstkyPeripheral.discoverServices(nil)
    }
    
}

extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print(characteristic)
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
            }
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.properties.contains(.write) {
                print("\(characteristic.uuid): properties contains .write")
                writeChar = characteristic
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case rxCBUUID:
            let characteristicData = characteristic.value
            let byteArray = [UInt8](characteristicData!)
            print(String(bytes: byteArray, encoding: .ascii)!)
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
}

