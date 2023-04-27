//
//  PinecilManager.swift
//  PineTool
//
//  Created by Lachlan Bell on 22/4/2023.
//  Copyright © 2023 Lachlan Bell. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation
import Combine
import CoreBluetooth

@MainActor
class PinecilManager: NSObject, ObservableObject {

    enum ConnectionState: Equatable {
        case connected(CBPeripheral)
        case connecting(CBPeripheral)
        case disconnected
        case scanning
    }

    @Published private(set) var bulkData: PinecilBulkData?
    @Published private(set) var discoveredPeripherals: [CBPeripheral] = []
    @Published private(set) var peripheralNames: [CBPeripheral: String] = [:]
    @Published private(set) var powerSamples: [Double] = []
    @Published private(set) var state: ConnectionState = .disconnected
    @Published private(set) var temperatureSamples: [Double] = []

    private let bulkDataCharacteristicUUID = CBUUID(string: "9eae1001-9d0d-48c5-AA55-33e27f9bc533")
    private var bulkDataCharacteristic: CBCharacteristic?
    private let bulkDataServiceUUID = CBUUID(string: "9eae1000-9d0d-48c5-aa55-33e27f9bc533")
    private let settingsServiceUUID = CBUUID(string: "f6d80000-5a10-4eba-aa55-33e27f9bc533")
    private var setpointCharacteristic: CBCharacteristic?
    private var setpointCharacteristicUUID = CBUUID(string: "f6d70000-5a10-4eba-aa55-33e27f9bc533")

    private let centralManager: CBCentralManager
    private var pollTimer: Timer?

    override init() {
        self.centralManager = CBCentralManager()
        super.init()

        centralManager.delegate = self
    }

    func scan() {
        guard !centralManager.isScanning else { return }

        self.state = .scanning
        discoveredPeripherals = []
        peripheralNames = [:]
        
        centralManager.scanForPeripherals(withServices: nil)
    }

    func stopScan() {
        centralManager.stopScan()

        if self.state == .scanning {
            self.state = .disconnected
        }
    }

    func connect(to peripheral: CBPeripheral) {
        guard self.state == .scanning else { return }

        self.state = .connecting(peripheral)
        centralManager.connect(peripheral)
    }

    func disconnect() {
        if case .connected(let peripheral) = state {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    func writeSetpoint(_ setpoint: UInt32) {
        guard let setpointCharacteristic else { return }

        if case .connected(let peripheral) = state {
            var setpointLE = UInt16(setpoint).littleEndian

            peripheral.writeValue(
                Data(bytes: &setpointLE, count: 2),
                for: setpointCharacteristic,
                type: .withoutResponse
            )
        }
    }

    private func clear() {
        self.bulkData = nil
        self.powerSamples = []
        self.temperatureSamples = []
    }

    @objc private func pollBulkData() {
        guard let bulkDataCharacteristic else { return }

        // Polling like this is suboptimal --- update me when BLE characteristic
        // value notifications are supported in IronOS.
        if case .connected(let peripheral) = state {
            peripheral.readValue(for: bulkDataCharacteristic)
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension PinecilManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            self.state = .disconnected
            clear()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        guard let services = advertisementData["kCBAdvDataServiceUUIDs"] as? [CBUUID] else { return }

        if services.contains(bulkDataServiceUUID) {
            discoveredPeripherals.append(peripheral)
            peripheral.delegate = self

            // Advertised local names can be disambiguated
            // (e.g. `Pinecil-00ABCFF` vs `Pinecil`), and so we'll prefer to use
            // them over the peripheral's name property.
            if let localName = advertisementData["kCBAdvDataLocalName"] as? String {
                peripheralNames[peripheral] = localName
            } else {
                peripheralNames[peripheral] = peripheral.name
            }
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        clear()
        self.state = .connected(peripheral)

        // Search for services
        peripheral.discoverServices([
            bulkDataServiceUUID,
            settingsServiceUUID
        ])

        // Start polling
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(
            timeInterval: 0.2,
            target: self,
            selector: #selector(pollBulkData),
            userInfo: nil,
            repeats: true
        )
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        self.state = .disconnected
        clear()
        pollTimer?.invalidate()
        pollTimer = nil
    }
}

// MARK: - CBPeripheralDelegate
extension PinecilManager: CBPeripheralDelegate {

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        peripheral.services?.forEach {
            peripheral.discoverCharacteristics(nil, for: $0)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard let rawData = characteristic.value else { return }

        if let bulkData = PinecilBulkData(data: rawData) {
            self.bulkData = bulkData

            self.powerSamples.append(Double(bulkData.estimatedWattage) / 10.0)
            self.temperatureSamples.append(Double(bulkData.tipTemperature))
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        service.characteristics?.forEach { characteristic in
            if characteristic.uuid == bulkDataCharacteristicUUID {
                self.bulkDataCharacteristic = characteristic
            }

            if characteristic.uuid == setpointCharacteristicUUID {
                self.setpointCharacteristic = characteristic
            }
        }
    }
}
