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
    
    @IBOutlet weak var MemoryIndicator: NSLevelIndicator!
    @IBOutlet weak var StatusIndicator: NSLevelIndicator!
    
    @IBOutlet weak var MasterPwd: NSSecureTextField!
    
    @IBOutlet weak var Secure: NSTextField!
    @IBOutlet weak var CommKey: NSTextField!
    @IBOutlet weak var WebsiteKey: NSTextField!
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var password: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            var field = "MPWD:" + MasterPwd.stringValue
            wrstkyPeripheral.writeValue(field.data(using: .ascii)!, for: writeChar, type: .withoutResponse)
        }
    }
    @IBAction func EncryptButton(_ sender: Any) {
    }
    @IBAction func RetrieveData(_ sender: Any) {
        if(connected){
            var field = "RTRV:" + WebsiteKey.stringValue
            wrstkyPeripheral.writeValue(field.data(using: .ascii)!, for: writeChar, type: .withoutResponse)
        }
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
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected!")
        StatusIndicator.criticalValue = 1
        StatusIndicator.warningValue = 2
        connected = false
        centralManager.scanForPeripherals(withServices: [wristKeyCBUUID])
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
            let val = String(bytes: byteArray, encoding: .ascii)!
            print(val)
            let indexStartOfText = val.index(val.startIndex, offsetBy: 5)
            let substring = val[indexStartOfText...]
            let string = String(substring)
            if(val.hasPrefix("ACKN:")){
                StatusIndicator.criticalValue = 2
                StatusIndicator.warningValue = 2
            }
            if(val.hasPrefix("DATA:")){
                let dataArr = string.components(separatedBy: "#")
                print(dataArr[0])
                print(dataArr[1])
                username.stringValue = dataArr[0]
                password.stringValue = dataArr[1]
                
            }
            if(val.hasPrefix("ERRO:")){
                if(string == "1"){
                    print("Data Not Found")
                    username.stringValue = "Data Not Found"
                    password.stringValue = "Data Not Found"
                }
            }
            
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
}

