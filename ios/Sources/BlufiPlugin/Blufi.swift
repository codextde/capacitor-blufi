import Foundation
import CoreBluetooth

@objc public class BlufiImplementation: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, BlufiDelegate {

    private weak var plugin: BlufiPlugin?
    private var espFBYBleHelper: ESPFBYBLEHelper?
    private var peripheralDictionary: [String: ESPPeripheral] = [:]
    private var scanResults: [[String: Any]] = []
    private var filterContent: String?
    private var device: ESPPeripheral?
    private var blufiClient: BlufiClient?
    private var connected: Bool = false
    private var securityNegotiated: Bool = false

    // Completion handlers
    private var scanWifiCompletion: (([String]) -> Void)?
    private var scanWifiError: ((String) -> Void)?
    private var setWifiCompletion: ((Bool, String) -> Void)?
    private var networkStatusCompletion: ((Bool, String) -> Void)?
    private var networkStatusError: ((String) -> Void)?

    init(plugin: BlufiPlugin) {
        self.plugin = plugin
        super.init()
        self.espFBYBleHelper = ESPFBYBLEHelper.share()
        self.filterContent = ESPDataConversion.loadBlufiScanFilter()
    }

    func startScan() {
        scanResults.removeAll()
        peripheralDictionary.removeAll()
        
        espFBYBleHelper?.startScan { [weak self] device in
            guard let self = self else { return }

            if device.name.isEmpty {
                return
            }

            if let filterContent = self.filterContent, !filterContent.isEmpty {
                if !device.name.lowercased().contains(filterContent.lowercased()) {
                    return
                }
            }

            self.peripheralDictionary[device.uuid.uuidString] = device
            
            let result: [String: Any] = [
                "name": device.name ?? "Unknown",
                "address": device.uuid.uuidString,
                "rssi": device.rssi
            ]
            
            // Add or update in scanResults
            if let index = self.scanResults.firstIndex(where: { ($0["address"] as? String) == device.uuid.uuidString }) {
                self.scanResults[index] = result
            } else {
                self.scanResults.append(result)
            }
            
            self.notifyEvent(self.makeScanDeviceJson(address: device.uuid.uuidString, name: device.name ?? "", rssi: Int(device.rssi)))
        }
    }

    func stopScan() -> [[String: Any]] {
        espFBYBleHelper?.stopScan()
        notifyEvent(makeJson(command: "stop_scan_ble", data: "1"))
        return scanResults
    }

    func connect(deviceId: String) {
        print("BlufiImplementation: connect called with deviceId: \(deviceId)")
        self.connected = false
        self.securityNegotiated = false

        if let peripheral = peripheralDictionary[deviceId] {
            print("BlufiImplementation: Found peripheral in dictionary")
            self.device = peripheral
        } else {
            print("BlufiImplementation: Peripheral NOT in dictionary, will connect directly by UUID")
        }

        if blufiClient != nil {
            print("BlufiImplementation: Closing existing blufiClient")
            blufiClient?.close()
            blufiClient = nil
        }

        print("BlufiImplementation: Creating new BlufiClient")
        blufiClient = BlufiClient()
        blufiClient?.centralManagerDelete = self
        blufiClient?.peripheralDelegate = self
        blufiClient?.blufiDelegate = self

        print("BlufiImplementation: Calling blufiClient.connect(\(deviceId))")
        blufiClient?.connect(deviceId)
    }

    func disconnect() {
        print("BlufiImplementation: disconnect called")
        if blufiClient != nil {
            blufiClient?.requestCloseConnection()
            blufiClient?.close()
            blufiClient = nil
        }
        connected = false
        securityNegotiated = false

        // Reject pending calls
        scanWifiError?("Disconnected")
        scanWifiCompletion = nil
        scanWifiError = nil

        networkStatusError?("Disconnected")
        networkStatusCompletion = nil
        networkStatusError = nil
        print("BlufiImplementation: disconnect complete")
    }
    
    func reset() {
        disconnect()
        peripheralDictionary.removeAll()
        scanResults.removeAll()
    }

    func requestCloseConnection() {
        if blufiClient != nil {
            blufiClient?.requestCloseConnection()
        }
    }

    func negotiateSecurity() {
        if blufiClient != nil {
            blufiClient?.negotiateSecurity()
        }
    }

    func requestDeviceVersion() {
        if blufiClient != nil {
            blufiClient?.requestDeviceVersion()
        }
    }

    func setWifi(ssid: String, password: String, completion: @escaping (Bool, String) -> Void) {
        let params = BlufiConfigureParams()
        params.opMode = OpModeSta
        params.staSsid = ssid
        params.staPassword = password
        
        self.setWifiCompletion = completion

        if blufiClient != nil && connected {
            blufiClient?.configure(params)
        } else {
            completion(false, "Not connected")
            self.setWifiCompletion = nil
        }
    }
    
    func scanWifi(completion: @escaping ([String]) -> Void, error: @escaping (String) -> Void) {
        print("BlufiImplementation: scanWifi called, blufiClient=\(blufiClient != nil), connected=\(connected), securityNegotiated=\(securityNegotiated)")

        if blufiClient == nil {
            print("BlufiImplementation: scanWifi failed - blufiClient is nil")
            error("Not connected (blufiClient is nil)")
            return
        }

        if !connected {
            print("BlufiImplementation: scanWifi failed - not connected")
            error("Not connected")
            return
        }

        if !securityNegotiated {
            print("BlufiImplementation: scanWifi warning - security not yet negotiated, proceeding anyway...")
        }

        print("BlufiImplementation: scanWifi requesting device scan...")
        self.scanWifiCompletion = completion
        self.scanWifiError = error
        blufiClient?.requestDeviceScan()
    }
    
    func getNetworkStatus(completion: @escaping (Bool, String) -> Void, error: @escaping (String) -> Void) {
        if blufiClient != nil && connected {
            self.networkStatusCompletion = completion
            self.networkStatusError = error
            blufiClient?.requestDeviceStatus()
        } else {
            error("Not connected")
        }
    }

    func requestDeviceStatus() {
        if blufiClient != nil {
            blufiClient?.requestDeviceStatus()
        }
    }

    func requestDeviceScan() {
        if blufiClient != nil {
            blufiClient?.requestDeviceScan()
        }
    }

    func postCustomData(data: String) {
        if blufiClient != nil, let dataValue = data.data(using: .utf8) {
            blufiClient?.postCustomData(dataValue)
        }
    }
    
    // Legacy method support
    func scanDeviceInfo(filter: String?) {
        if let filter = filter {
            self.filterContent = filter
        }
        startScan()
    }
    
    func connectPeripheral(peripheralId: String) {
        connect(deviceId: peripheralId)
    }
    
    func configProvision(ssid: String, password: String) {
        let params = BlufiConfigureParams()
        params.opMode = OpModeSta
        params.staSsid = ssid
        params.staPassword = password
        if blufiClient != nil && connected {
            blufiClient?.configure(params)
        }
    }

    // MARK: - CBCentralManagerDelegate

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("BlufiImplementation: didConnect peripheral: \(peripheral.name ?? "Unknown") - \(peripheral.identifier.uuidString)")
        notifyEvent(makeJson(command: "peripheral_connect", data: "1"))
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("BlufiImplementation: didFailToConnect peripheral: \(peripheral.name ?? "Unknown"), error: \(error?.localizedDescription ?? "nil")")
        notifyEvent(makeJson(command: "peripheral_connect", data: "0"))
        self.connected = false
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("BlufiImplementation: didDisconnectPeripheral: \(peripheral.name ?? "Unknown"), error: \(error?.localizedDescription ?? "nil")")
        disconnect() // Clean up
        notifyEvent(makeJson(command: "peripheral_disconnect", data: "1"))
        self.connected = false
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("BlufiImplementation: centralManagerDidUpdateState: \(central.state.rawValue)")
    }

    // MARK: - BlufiDelegate

    public func blufi(_ client: BlufiClient, gattPrepared status: BlufiStatusCode, service: CBService?, writeChar: CBCharacteristic?, notifyChar: CBCharacteristic?) {
        print("BlufiImplementation: gattPrepared status: \(status.rawValue), service: \(service?.uuid.uuidString ?? "nil"), writeChar: \(writeChar?.uuid.uuidString ?? "nil"), notifyChar: \(notifyChar?.uuid.uuidString ?? "nil")")
        if status == StatusSuccess {
            self.connected = true
            print("BlufiImplementation: GATT prepared successfully, connected = true")
            notifyEvent(makeJson(command: "blufi_connect_prepared", data: "1"))
        } else {
            print("BlufiImplementation: GATT prepared FAILED")
            disconnect()
            if service == nil {
                print("BlufiImplementation: service is nil")
                notifyEvent(makeJson(command: "blufi_connect_prepared", data: "2"))
            } else if writeChar == nil {
                print("BlufiImplementation: writeChar is nil")
                notifyEvent(makeJson(command: "blufi_connect_prepared", data: "3"))
            } else if notifyChar == nil {
                print("BlufiImplementation: notifyChar is nil")
                notifyEvent(makeJson(command: "blufi_connect_prepared", data: "4"))
            }
        }
    }

    public func blufi(_ client: BlufiClient, didNegotiateSecurity status: BlufiStatusCode) {
        print("BlufiImplementation: didNegotiateSecurity status: \(status.rawValue)")

        if status == StatusSuccess {
            self.securityNegotiated = true
            print("BlufiImplementation: Security negotiation successful - device ready for operations")
            notifyEvent(makeJson(command: "negotiate_security", data: "1"))
        } else {
            self.securityNegotiated = false
            print("BlufiImplementation: Security negotiation FAILED")
            notifyEvent(makeJson(command: "negotiate_security", data: "0"))
        }
    }

    public func blufi(_ client: BlufiClient, didReceiveDeviceVersionResponse response: BlufiVersionResponse?, status: BlufiStatusCode) {
        if status == StatusSuccess, let response = response {
            notifyEvent(makeJson(command: "device_version", data: response.getVersionString()))
        } else {
            notifyEvent(makeJson(command: "device_version", data: "0"))
        }
    }

    public func blufi(_ client: BlufiClient, didPostConfigureParams status: BlufiStatusCode) {
        if let completion = setWifiCompletion {
            if status == StatusSuccess {
                completion(true, "Configuration sent")
            } else {
                completion(false, "Failed to send configuration")
            }
            setWifiCompletion = nil
        }
        
        if status == StatusSuccess {
            notifyEvent(makeJson(command: "configure_params", data: "1"))
        } else {
            notifyEvent(makeJson(command: "configure_params", data: "0"))
        }
    }

    public func blufi(_ client: BlufiClient, didReceiveDeviceStatusResponse response: BlufiStatusResponse?, status: BlufiStatusCode) {
        if let completion = networkStatusCompletion {
            if status == StatusSuccess, let response = response {
                completion(response.isStaConnectWiFi(), "Connected")
            } else {
                completion(false, "Error")
            }
            networkStatusCompletion = nil
            networkStatusError = nil
        }
        
        if status == StatusSuccess, let response = response {
            notifyEvent(makeJson(command: "device_status", data: "1"))

            if response.isStaConnectWiFi() {
                notifyEvent(makeJson(command: "device_wifi_connect", data: "1"))
            } else {
                notifyEvent(makeJson(command: "device_wifi_connect", data: "0"))
            }
        } else {
            notifyEvent(makeJson(command: "device_status", data: "0"))
        }
    }

    public func blufi(_ client: BlufiClient, didReceiveDeviceScanResponse scanResults: [BlufiScanResponse]?, status: BlufiStatusCode) {
        print("BlufiImplementation: didReceiveDeviceScanResponse status: \(status.rawValue), results count: \(scanResults?.count ?? 0)")
        if let completion = scanWifiCompletion {
            var list: [String] = []
            if status == StatusSuccess, let scanResults = scanResults {
                for response in scanResults {
                    print("BlufiImplementation: WiFi network: \(response.ssid) (RSSI: \(response.rssi))")
                    list.append(response.ssid)
                }
            }
            print("BlufiImplementation: Calling scanWifiCompletion with \(list.count) networks")
            completion(list)
            scanWifiCompletion = nil
            scanWifiError = nil
        }

        if status == StatusSuccess, let scanResults = scanResults {
            for response in scanResults {
                notifyEvent(makeWifiInfoJson(ssid: response.ssid, rssi: Int(response.rssi)))
            }
        } else {
            notifyEvent(makeJson(command: "wifi_info", data: "0"))
        }
    }

    public func blufi(_ client: BlufiClient, didPostCustomData data: Data, status: BlufiStatusCode) {
        if status == StatusSuccess {
            notifyEvent(makeJson(command: "post_custom_data", data: "1"))
        } else {
            notifyEvent(makeJson(command: "post_custom_data", data: "0"))
        }
    }

    public func blufi(_ client: BlufiClient, didReceiveCustomData data: Data, status: BlufiStatusCode) {
        if status == StatusSuccess {
            var customString = String(data: data, encoding: .utf8) ?? ""
            customString = customString.replacingOccurrences(of: "\"", with: "\\\"")
            notifyEvent(makeJson(command: "receive_device_custom_data", data: customString))
        } else {
            notifyEvent(makeJson(command: "receive_device_custom_data", data: "0"))
        }
    }

    // MARK: - Helper Methods

    private func notifyEvent(_ event: [String: Any]) {
        plugin?.notifyBlufiEvent(event)
    }

    private func makeJson(command: String, data: String) -> [String: Any] {
        var address = ""
        if let device = device {
            address = device.uuid.uuidString
        }

        return [
            "key": command,
            "value": data,
            "address": address
        ]
    }

    private func makeScanDeviceJson(address: String, name: String, rssi: Int) -> [String: Any] {
        return [
            "key": "ble_scan_result",
            "value": [
                "address": address,
                "name": name,
                "rssi": rssi
            ]
        ]
    }

    private func makeWifiInfoJson(ssid: String, rssi: Int) -> [String: Any] {
        var address = ""
        if let device = device {
            address = device.uuid.uuidString
        }

        return [
            "key": "wifi_info",
            "value": [
                "ssid": ssid,
                "rssi": rssi,
                "address": address
            ]
        ]
    }
}
