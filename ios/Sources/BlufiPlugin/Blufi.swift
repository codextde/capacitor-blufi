import Foundation
import CoreBluetooth

@objc public class BlufiImplementation: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, BlufiDelegate {

    private weak var plugin: BlufiPlugin?
    private var espFBYBleHelper: ESPFBYBLEHelper?
    private var peripheralDictionary: [String: ESPPeripheral] = [:]
    private var filterContent: String?
    private var device: ESPPeripheral?
    private var blufiClient: BlufiClient?
    private var connected: Bool = false

    init(plugin: BlufiPlugin) {
        self.plugin = plugin
        super.init()
        self.espFBYBleHelper = ESPFBYBLEHelper.share()
        self.filterContent = ESPDataConversion.loadBlufiScanFilter()
    }

    func scanDeviceInfo(filter: String?) {
        if let filter = filter {
            self.filterContent = filter
        }

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
            self.notifyEvent(self.makeScanDeviceJson(address: device.uuid.uuidString, name: device.name ?? "", rssi: device.rssi))
        }
    }

    func stopScan() {
        espFBYBleHelper?.stopScan()
        notifyEvent(makeJson(command: "stop_scan_ble", data: "1"))
    }

    func connectPeripheral(peripheralId: String) {
        guard let peripheral = peripheralDictionary[peripheralId] else {
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

    func onDisconnected() {
        if blufiClient != nil {
            blufiClient?.close()
        }
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

    func configProvision(ssid: String, password: String) {
        let params = BlufiConfigureParams()
        params.opMode = OpModeSta
        params.staSsid = ssid
        params.staPassword = password

        if blufiClient != nil && connected {
            blufiClient?.configure(params)
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

    // MARK: - CBCentralManagerDelegate

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        notifyEvent(makeJson(command: "peripheral_connect", data: "1"))
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        notifyEvent(makeJson(command: "peripheral_connect", data: "0"))
        self.connected = false
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        onDisconnected()
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
            onDisconnected()
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
        if status == StatusSuccess {
            notifyEvent(makeJson(command: "configure_params", data: "1"))
        } else {
            notifyEvent(makeJson(command: "configure_params", data: "0"))
        }
    }

    public func blufi(_ client: BlufiClient, didReceiveDeviceStatusResponse response: BlufiStatusResponse?, status: BlufiStatusCode) {
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
