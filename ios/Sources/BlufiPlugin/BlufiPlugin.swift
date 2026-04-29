import Foundation
import Capacitor
import CoreBluetooth

@objc(BlufiPlugin)
public class BlufiPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "BlufiPlugin"
    public let jsName = "Blufi"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "startScan", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopScan", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "connectToDevice", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "disconnectFromDevice", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "resetPlugin", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getDeviceInfo", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "scanWifi", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setWifi", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "disconnectWifi", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setWifiOpMode", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getNetworkStatus", returnType: CAPPluginReturnPromise)
    ]

    private var implementation: BlufiImplementation?

    override public func load() {
        super.load()
        implementation = BlufiImplementation(plugin: self)
    }

    @objc func startScan(_ call: CAPPluginCall) {
        implementation?.startScan()
        call.resolve()
    }

    @objc func stopScan(_ call: CAPPluginCall) {
        let results = implementation?.stopScan() ?? []
        call.resolve([
            "scanResult": results
        ])
    }

    @objc func connectToDevice(_ call: CAPPluginCall) {
        guard let deviceId = call.getString("deviceId") else {
            call.reject("Missing deviceId")
            return
        }

        print("BlufiPlugin: connectToDevice called with deviceId: \(deviceId)")
        implementation?.connect(deviceId: deviceId)
        call.resolve()
    }

    @objc func disconnectFromDevice(_ call: CAPPluginCall) {
        implementation?.disconnect()
        call.resolve()
    }

    @objc func resetPlugin(_ call: CAPPluginCall) {
        implementation?.disconnect()
        implementation?.reset()
        call.resolve()
    }

    @objc func getDeviceInfo(_ call: CAPPluginCall) {
        implementation?.requestDeviceVersion()
        call.resolve()
    }

    @objc func scanWifi(_ call: CAPPluginCall) {
        implementation?.scanWifi(completion: { list in
            call.resolve(["list": list])
        }, error: { msg in
            call.reject(msg)
        })
    }

    @objc func setWifi(_ call: CAPPluginCall) {
        guard let ssid = call.getString("ssid"),
              let password = call.getString("password") else {
            call.reject("Missing ssid or password")
            return
        }

        implementation?.setWifi(ssid: ssid, password: password, completion: { success, message in
            call.resolve([
                "success": success,
                "message": message
            ])
        })
    }

    @objc func disconnectWifi(_ call: CAPPluginCall) {
        implementation?.disconnectWifi(completion: { success, message in
            call.resolve([
                "success": success,
                "message": message
            ])
        })
    }

    @objc func setWifiOpMode(_ call: CAPPluginCall) {
        guard let mode = call.getInt("mode") else {
            call.reject("Missing mode (0=NULL, 1=STA, 2=SoftAP, 3=STA+SoftAP)")
            return
        }
        implementation?.setWifiOpMode(mode: mode, completion: { success, message in
            call.resolve([
                "success": success,
                "message": message
            ])
        })
    }

    @objc func getNetworkStatus(_ call: CAPPluginCall) {
        implementation?.getNetworkStatus(completion: { connected, status in
            call.resolve([
                "connected": connected,
                "status": status
            ])
        }, error: { msg in
            call.reject(msg)
        })
    }

    func notifyBlufiEvent(_ event: [String: Any]) {
        notifyListeners("onBlufiEvent", data: event)
    }
}
