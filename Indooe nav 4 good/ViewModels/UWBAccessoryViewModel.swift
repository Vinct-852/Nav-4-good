//
//  UWBAccessoryViewModel.swift
//  Indooe nav 4 good
//
//  Created by vincent deng on 6/11/2025.
//

import Foundation
import NearbyInteraction
import CoreBluetooth
import Combine

@Observable
class UWBAccessoryViewModel: NSObject {
    // MARK: - Published Properties
    var discoveredAccessories: [AccessoryInfo] = []
    var connectedAccessory: AccessoryInfo?
    var distance: Float?
    var direction: simd_float3?
    var connectionStatus: ConnectionStatus = .disconnected
    var errorMessage: String?
    var isScanning: Bool = false
    
    // MARK: - Private Properties
    private var niSession: NISession?
    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var accessoryConfigCharacteristic: CBCharacteristic?
    private var accessoryDataCharacteristic: CBCharacteristic?
    
    // Service and Characteristic UUIDs (standard for Nearby Interaction)
    private let niServiceUUID = CBUUID(string: "48FE3E40-0817-4BB2-8633-3073689C2DBA")
    private let configurationCharacteristicUUID = CBUUID(string: "48FE3E42-0817-4BB2-8633-3073689C2DBA")
    private let accessoryConfigDataCharacteristicUUID = CBUUID(string: "48FE3E43-0817-4BB2-8633-3073689C2DBA")
    
    enum ConnectionStatus: Equatable{
        case disconnected
        case scanning
        case connecting
        case exchangingConfig
        case ranging
        case error(String)
    }
    
    struct AccessoryInfo: Identifiable {
        let id: UUID
        let name: String
        let peripheral: CBPeripheral
        var rssi: NSNumber
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupNISession()
        setupBluetoothManager()
    }
    
    // MARK: - Setup Methods
    private func setupNISession() {
        // Check if Nearby Interaction is supported
        guard NISession.isSupported else {
            errorMessage = "Nearby Interaction is not supported on this device"
            return
        }
        
        niSession = NISession()
        niSession?.delegate = self
    }
    
    private func setupBluetoothManager() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    func startScanning() {
        guard let centralManager = centralManager,
              centralManager.state == .poweredOn else {
            errorMessage = "Bluetooth is not available"
            return
        }
        
        discoveredAccessories.removeAll()
        isScanning = true
        connectionStatus = .scanning
        
        // Scan for peripherals with NI service
        centralManager.scanForPeripherals(
            withServices: [niServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }
    
    func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
        if connectionStatus == .scanning {
            connectionStatus = .disconnected
        }
    }
    
    func connect(to accessory: AccessoryInfo) {
        stopScanning()
        connectionStatus = .connecting
        connectedAccessory = accessory
        centralManager?.connect(accessory.peripheral, options: nil)
    }
    
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        niSession?.invalidate()
        resetConnection()
    }
    
    private func resetConnection() {
        connectedPeripheral = nil
        connectedAccessory = nil
        accessoryConfigCharacteristic = nil
        accessoryDataCharacteristic = nil
        distance = nil
        direction = nil
        connectionStatus = .disconnected
    }
    
    // MARK: - Data Transmission
    private func sendDataToAccessory(_ data: Data) {
        guard let peripheral = connectedPeripheral,
              let characteristic = accessoryConfigCharacteristic else {
            return
        }
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

// MARK: - CBCentralManagerDelegate
extension UWBAccessoryViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on and ready")
        case .poweredOff:
            errorMessage = "Please turn on Bluetooth"
            connectionStatus = .disconnected
        case .unauthorized:
            errorMessage = "Bluetooth permission denied"
            connectionStatus = .disconnected
        case .unsupported:
            errorMessage = "Bluetooth is not supported on this device"
            connectionStatus = .disconnected
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                       didDiscover peripheral: CBPeripheral,
                       advertisementData: [String : Any],
                       rssi RSSI: NSNumber) {
        let name = peripheral.name ?? "Unknown UWB Device"
        
        // Check if already discovered
        if !discoveredAccessories.contains(where: { $0.id == peripheral.identifier }) {
            let accessory = AccessoryInfo(
                id: peripheral.identifier,
                name: name,
                peripheral: peripheral,
                rssi: RSSI
            )
            discoveredAccessories.append(accessory)
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                       didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral.name ?? "Unknown")")
        connectedPeripheral = peripheral
        peripheral.delegate = self
        connectionStatus = .exchangingConfig
        
        // Discover services
        peripheral.discoverServices([niServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager,
                       didFailToConnect peripheral: CBPeripheral,
                       error: Error?) {
        errorMessage = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
        connectionStatus = .error(errorMessage ?? "Connection failed")
        resetConnection()
    }
    
    func centralManager(_ central: CBCentralManager,
                       didDisconnectPeripheral peripheral: CBPeripheral,
                       error: Error?) {
        if let error = error {
            errorMessage = "Disconnected with error: \(error.localizedDescription)"
        }
        resetConnection()
    }
}

// MARK: - CBPeripheralDelegate
extension UWBAccessoryViewModel: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral,
                   didDiscoverServices error: Error?) {
        guard error == nil else {
            errorMessage = "Service discovery failed: \(error!.localizedDescription)"
            return
        }
        
        // Find NI service and discover characteristics
        if let niService = peripheral.services?.first(where: { $0.uuid == niServiceUUID }) {
            peripheral.discoverCharacteristics([
                configurationCharacteristicUUID,
                accessoryConfigDataCharacteristicUUID
            ], for: niService)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                   didDiscoverCharacteristicsFor service: CBService,
                   error: Error?) {
        guard error == nil else {
            errorMessage = "Characteristic discovery failed: \(error!.localizedDescription)"
            return
        }
        
        // Store characteristic references
        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid == configurationCharacteristicUUID {
                accessoryConfigCharacteristic = characteristic
            } else if characteristic.uuid == accessoryConfigDataCharacteristicUUID {
                accessoryDataCharacteristic = characteristic
                // Read accessory configuration data
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                   didUpdateValueFor characteristic: CBCharacteristic,
                   error: Error?) {
        guard error == nil, let data = characteristic.value else {
            errorMessage = "Failed to read characteristic: \(error?.localizedDescription ?? "Unknown")"
            return
        }
        
        // Received accessory configuration data
        if characteristic.uuid == accessoryConfigDataCharacteristicUUID {
            setupNISessionWithAccessoryData(data)
        }
    }
    
    private func setupNISessionWithAccessoryData(_ data: Data) {
        do {
            // Create NI configuration with accessory data
            let configuration = try NINearbyAccessoryConfiguration(data: data)
            
            // Store the discovery token for reference
            print("Accessory discovery token: \(configuration.accessoryDiscoveryToken)")
            
            // Run the NI session
            niSession?.run(configuration)
            connectionStatus = .ranging
            
        } catch {
            errorMessage = "Failed to create NI configuration: \(error.localizedDescription)"
            connectionStatus = .error(errorMessage!)
        }
    }
}

// MARK: - NISessionDelegate
extension UWBAccessoryViewModel: NISessionDelegate {
    func session(_ session: NISession,
                didGenerateShareableConfigurationData shareableConfigurationData: Data,
                for object: NINearbyObject) {
        // Send shareable configuration data back to accessory
        print("Sending shareable config data: \(shareableConfigurationData.count) bytes")
        sendDataToAccessory(shareableConfigurationData)
    }
    
    func session(_ session: NISession,
                didUpdate nearbyObjects: [NINearbyObject]) {
        guard let accessory = nearbyObjects.first else { return }
        
        // Update distance (in meters)
        if let dist = accessory.distance {
            distance = dist
        }
        
        // Update direction (3D vector)
        if let dir = accessory.direction {
            direction = dir
        }
    }
    
    func session(_ session: NISession,
                didRemove nearbyObjects: [NINearbyObject],
                reason: NINearbyObject.RemovalReason) {
        print("Nearby object removed: \(reason)")
        distance = nil
        direction = nil
    }
    
    func sessionWasSuspended(_ session: NISession) {
        print("NI Session suspended")
        connectionStatus = .error("Session suspended")
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        print("NI Session resumed")
        connectionStatus = .ranging
    }
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
        errorMessage = "Session invalidated: \(error.localizedDescription)"
        connectionStatus = .error(errorMessage!)
        
        // Recreate session
        setupNISession()
    }
}
