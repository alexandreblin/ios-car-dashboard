//
//  BluetoothController.swift
//  CarDash
//
//  Created by Alexandre Blin on 14/01/2017.
//  Copyright © 2017 Alexandre Blin. All rights reserved.
//

import Foundation

/// A SerialParser subclass which connects to an Arduino board
/// using Bluetooth Low Energy and parses the incoming serial data.
class BluetoothSerialParser: SerialParser, BLESerialManagerDelegate, BLESerialDeviceDelegate {
    private let bleManager: BLESerialManager

    override init(delegate: SerialParserDelegate?) {
        self.bleManager = BLESerialManager()

        super.init(delegate: delegate)

        self.bleManager.delegate = self
        startScan()
    }

    func centralManagerStateUpdated(_ state: CBCentralManagerState) {
        startScan()
    }

    private func startScan() {
        if bleManager.manager.state == .poweredOn {
            bleManager.startScanning(withTimeout: 5)
        }
    }

    func deviceFound(_ serialDevice: BLESerialDevice!) {
        print("Found serial device <\(serialDevice.peripheral.name)>")

        if serialDevice.peripheral.name == "CAN207" {
            serialDevice.delegate = self
            serialDevice.connect()
        }
    }

    func scanEnded() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.startScan()
        }
    }

    func serialDeviceDidConnect(_ serialDevice: BLESerialDevice!) {
        print("Connected to serial device <\(serialDevice.peripheral.name)>")
    }

    func serialDeviceDidDisconnect(_ serialDevice: BLESerialDevice!) {
        print("Disconnected from serial device <\(serialDevice.peripheral.name)>")

        startScan()
    }

    func serialDevice(_ serialDevice: BLESerialDevice!, didReceive data: Data!, forUUID UUID: String!) {
        // Parse incoming data
        parse(serialData: data)
    }
}
