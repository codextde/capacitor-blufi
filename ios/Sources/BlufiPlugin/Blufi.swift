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
            guard let self = self, let device = device else { return }

            if device.name == nil {
                return
            }

            if let filterContent = self.filterContent, !filterContent.isEmpty {
                if let name = device.name, !name.lowercased().contains(filterContent.lowercased()) {
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
            
            self.notifyEvent(self.makeScanDeviceJson(address: device.uuid.uuidString, name: device.name ?? "", rssi: device.rssi))
        }
    }

    func stopScan() -> [[String: Any]] {
        espFBYBleHelper?.stopScan()
        notifyEvent(makeJson(command: "stop_scan_ble", data: "1"))
        return scanResults
    }

    func connect(deviceId: String) {
        guard let peripheral = peripheralDictionary[deviceId] else {
            return
        }

        self.connected = false
        self.device = peripheral

        if blufiClient != nil {
            blufiClient?.close()
            blufiClient = nil
        }

        blufiClient = BlufiClient()
        blufiClient?.centralManagerDelete = self
        blufiClient?.peripheralDelegate = self
        blufiClient?.blufiDelegate = self
        blufiClient?.connect(peripheral.uuid.uuidString)
    }

    func disconnect() {
        if blufiClient != nil {
            blufiClient?.requestCloseConnection()
            blufiClient?.close()
            blufiClient = nil
        }
        connected = false
        
        // Reject pending calls
        scanWifiError?("Disconnected")
        scanWifiCompletion = nil
        scanWifiError = nil
        
        networkStatusError?("Disconnected")
        networkStatusCompletion = nil
        networkStatusError = nil
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
        if blufiClient != nil && connected {
            self.scanWifiCompletion = completion
            self.scanWifiError = error
            blufiClient?.requestDeviceScan()
        } else {
            error("Not connected")
        }
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
        notifyEvent(makeJson(command: "peripheral_connect", data: "1"))
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        notifyEvent(makeJson(command: "peripheral_connect", data: "0"))
        self.connected = false
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        disconnect() // Clean up
        notifyEvent(makeJson(command: "peripheral_disconnect", data: "1"))
        self.connected = false
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Handle central manager state updates
    }

    // MARK: - BlufiDelegate

    public func blufi(_ client: BlufiClient, gattPrepared status: BlufiStatusCode, service: CBService?, writeChar: CBCharacteristic?, notifyChar: CBCharacteristic?) {
        if status == StatusSuccess {
            self.connected = true
            notifyEvent(makeJson(command: "blufi_connect_prepared", data: "1"))
        } else {
            disconnect()
            if service == nil {
                notifyEvent(makeJson(command: "blufi_connect_prepared", data: "2"))
            } else if writeChar == nil {
                notifyEvent(makeJson(command: "blufi_connect_prepared", data: "3"))
            } else if notifyChar == nil {
                notifyEvent(makeJson(command: "blufi_connect_prepared", data: "4"))
            }
        }
    }

    public func blufi(_ client: BlufiClient, didNegotiateSecurity status: BlufiStatusCode) {
        print("Blufi didNegotiateSecurity \(status.rawValue)")

        if status == StatusSuccess {
            notifyEvent(makeJson(command: "negotiate_security", data: "1"))
        } else {
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
                completion(response.isStaConnect(toWiFi: ()), "Connected")
            } else {
                completion(false, "Error")
            }
            networkStatusCompletion = nil
            networkStatusError = nil
        }
        
        if status == StatusSuccess, let response = response {
            notifyEvent(makeJson(command: "device_status", data: "1"))

            if response.isStaConnect(toWiFi: ()) {
                notifyEvent(makeJson(command: "device_wifi_connect", data: "1"))
            } else {
                notifyEvent(makeJson(command: "device_wifi_connect", data: "0"))
            }
        } else {
            notifyEvent(makeJson(command: "device_status", data: "0"))
        }
    }

    public func blufi(_ client: BlufiClient, didReceiveDeviceScanResponse scanResults: [BlufiScanResponse]?, status: BlufiStatusCode) {
        if let completion = scanWifiCompletion {
            var list: [String] = []
            if status == StatusSuccess, let scanResults = scanResults {
                for response in scanResults {
                    if let ssid = response.ssid {
                        list.append(ssid)
                    }
                }
            }
            completion(list)
            scanWifiCompletion = nil
            scanWifiError = nil
        }
        
        if status == StatusSuccess, let scanResults = scanResults {
            for response in scanResults {
                notifyEvent(makeWifiInfoJson(ssid: response.ssid ?? "", rssi: Int(response.rssi)))
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
