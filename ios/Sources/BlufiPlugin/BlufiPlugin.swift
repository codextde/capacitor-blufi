import Foundation
import Capacitor
import CoreBluetooth

@objc(BlufiPlugin)
public class BlufiPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "BlufiPlugin"
    public let jsName = "Blufi"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "getPlatformVersion", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "scanDeviceInfo", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopScan", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "connectPeripheral", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestCloseConnection", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "negotiateSecurity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestDeviceVersion", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "configProvision", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestDeviceStatus", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestDeviceScan", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "postCustomData", returnType: CAPPluginReturnPromise)
    ]

    private var implementation: BlufiImplementation?

    override public func load() {
        super.load()
        implementation = BlufiImplementation(plugin: self)
    }

    @objc func getPlatformVersion(_ call: CAPPluginCall) {
        let version = "iOS " + UIDevice.current.systemVersion
        call.resolve(["version": version])
    }

    @objc func scanDeviceInfo(_ call: CAPPluginCall) {
        let filter = call.getString("filter")
        implementation?.scanDeviceInfo(filter: filter)
        call.resolve(["success": true])
    }

    @objc func stopScan(_ call: CAPPluginCall) {
        implementation?.stopScan()
        call.resolve()
    }

    @objc func connectPeripheral(_ call: CAPPluginCall) {
        guard let peripheralId = call.getString("peripheral") else {
            call.resolve(["success": false])
            return
        }

        implementation?.connectPeripheral(peripheralId: peripheralId)
        call.resolve(["success": true])
    }

    @objc func requestCloseConnection(_ call: CAPPluginCall) {
        implementation?.requestCloseConnection()
        call.resolve()
    }

    @objc func negotiateSecurity(_ call: CAPPluginCall) {
        implementation?.negotiateSecurity()
        call.resolve()
    }

    @objc func requestDeviceVersion(_ call: CAPPluginCall) {
        implementation?.requestDeviceVersion()
        call.resolve()
    }

    @objc func configProvision(_ call: CAPPluginCall) {
        guard let username = call.getString("username"),
              let password = call.getString("password") else {
            call.reject("Missing username or password")
            return
        }

        implementation?.configProvision(ssid: username, password: password)
        call.resolve()
    }

    @objc func requestDeviceStatus(_ call: CAPPluginCall) {
        implementation?.requestDeviceStatus()
        call.resolve()
    }

    @objc func requestDeviceScan(_ call: CAPPluginCall) {
        implementation?.requestDeviceScan()
        call.resolve()
    }

    @objc func postCustomData(_ call: CAPPluginCall) {
        guard let customData = call.getString("customData") else {
            call.reject("Missing customData")
            return
        }

        implementation?.postCustomData(data: customData)
        call.resolve()
    }

    func notifyBlufiEvent(_ event: [String: Any]) {
        notifyListeners("onBlufiEvent", data: event)
    }
}
