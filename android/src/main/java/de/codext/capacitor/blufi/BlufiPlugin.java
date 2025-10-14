package de.codext.capacitor.blufi;

import android.Manifest;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanResult;
import android.bluetooth.le.ScanSettings;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.text.TextUtils;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import de.codext.capacitor.blufi.constants.BlufiConstants;
import de.codext.capacitor.blufi.params.BlufiConfigureParams;
import de.codext.capacitor.blufi.params.BlufiParameter;
import de.codext.capacitor.blufi.response.BlufiScanResult;
import de.codext.capacitor.blufi.response.BlufiStatusResponse;
import de.codext.capacitor.blufi.response.BlufiVersionResponse;

@CapacitorPlugin(
    name = "Blufi",
    permissions = {
        @Permission(strings = { Manifest.permission.ACCESS_FINE_LOCATION }, alias = "location"),
        @Permission(strings = { Manifest.permission.BLUETOOTH }, alias = "bluetooth"),
        @Permission(strings = { Manifest.permission.BLUETOOTH_ADMIN }, alias = "bluetoothAdmin"),
        @Permission(strings = { Manifest.permission.BLUETOOTH_SCAN }, alias = "bluetoothScan"),
        @Permission(strings = { Manifest.permission.BLUETOOTH_CONNECT }, alias = "bluetoothConnect")
    }
)
public class BlufiPlugin extends Plugin {

    private static final long TIMEOUT_SCAN = 4000L;

    private List<ScanResult> mBleList;
    private Map<String, ScanResult> mDeviceMap;
    private ScanCallback mScanCallback;
    private String mBlufiFilter;
    private volatile long mScanStartTime;

    private ExecutorService mThreadPool;
    private Future mUpdateFuture;

    private BluetoothDevice mDevice;
    private BlufiClient mBlufiClient;
    private volatile boolean mConnected;

    private Handler handler;

    private final BlufiLog mLog = new BlufiLog(getClass());

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    @Override
    public void load() {
        super.load();
        handler = new Handler(Looper.getMainLooper());
        mThreadPool = Executors.newSingleThreadExecutor();
        mBleList = new LinkedList<>();
        mDeviceMap = new HashMap<>();
        mScanCallback = new ScanCallback();
    }

    @PluginMethod
    public void getPlatformVersion(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("version", "Android " + Build.VERSION.RELEASE);
        call.resolve(ret);
    }

    @PluginMethod
    public void scanDeviceInfo(PluginCall call) {
        String filter = call.getString("filter");
        scan(filter, call);
    }

    @PluginMethod
    public void stopScan(PluginCall call) {
        stopScan();
        call.resolve();
    }

    @PluginMethod
    public void connectPeripheral(PluginCall call) {
        String deviceId = call.getString("peripheral");
        if (deviceId != null && mDeviceMap.containsKey(deviceId)) {
            connectDevice(mDeviceMap.get(deviceId).getDevice());
            JSObject ret = new JSObject();
            ret.put("success", true);
            call.resolve(ret);
        } else {
            JSObject ret = new JSObject();
            ret.put("success", false);
            call.resolve(ret);
        }
    }

    @PluginMethod
    public void requestCloseConnection(PluginCall call) {
        disconnectGatt();
        call.resolve();
    }

    @PluginMethod
    public void negotiateSecurity(PluginCall call) {
        negotiateSecurity();
        call.resolve();
    }

    @PluginMethod
    public void requestDeviceVersion(PluginCall call) {
        requestDeviceVersion();
        call.resolve();
    }

    @PluginMethod
    public void configProvision(PluginCall call) {
        String userName = call.getString("username");
        String password = call.getString("password");
        configure(userName, password);
        call.resolve();
    }

    @PluginMethod
    public void requestDeviceStatus(PluginCall call) {
        requestDeviceStatus();
        call.resolve();
    }

    @PluginMethod
    public void requestDeviceScan(PluginCall call) {
        requestDeviceWifiScan();
        call.resolve();
    }

    @PluginMethod
    public void postCustomData(PluginCall call) {
        String dataStr = call.getString("customData");
        postCustomData(dataStr);
        call.resolve();
    }

    // Simplified API methods
    @PluginMethod
    public void startScan(PluginCall call) {
        String filter = call.getString("filter");
        scan(filter, call);
    }

    @PluginMethod
    public void connectToDevice(PluginCall call) {
        String deviceId = call.getString("address");
        if (deviceId != null && mDeviceMap.containsKey(deviceId)) {
            connectDevice(mDeviceMap.get(deviceId).getDevice());
            // Auto-negotiate security after connection
            handler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    if (mConnected && mBlufiClient != null) {
                        mBlufiClient.negotiateSecurity();
                    }
                }
            }, 1000);
            JSObject ret = new JSObject();
            ret.put("success", true);
            call.resolve(ret);
        } else {
            JSObject ret = new JSObject();
            ret.put("success", false);
            call.resolve(ret);
        }
    }

    @PluginMethod
    public void setWifi(PluginCall call) {
        String ssid = call.getString("ssid");
        String password = call.getString("password");
        configure(ssid, password);
        call.resolve();
    }

    @PluginMethod
    public void scanWifi(PluginCall call) {
        requestDeviceWifiScan();
        call.resolve();
    }

    @PluginMethod
    public void getDeviceInfo(PluginCall call) {
        // Request both version and status
        requestDeviceVersion();
        requestDeviceStatus();
        call.resolve();
    }

    private void scan(String filter, PluginCall call) {
        startScan21(filter, call);
    }

    private void startScan21(String filter, PluginCall call) {
        BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
        if (adapter == null) {
            JSObject ret = new JSObject();
            ret.put("success", false);
            call.resolve(ret);
            return;
        }

        BluetoothLeScanner scanner = adapter.getBluetoothLeScanner();
        if (!adapter.isEnabled() || scanner == null) {
            JSObject ret = new JSObject();
            ret.put("success", false);
            call.resolve(ret);
            return;
        }

        mDeviceMap.clear();
        mBleList.clear();
        mBlufiFilter = filter;
        mScanStartTime = SystemClock.elapsedRealtime();

        mLog.d("Start scan ble");
        scanner.startScan(null, new ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build(),
                mScanCallback);

        JSObject ret = new JSObject();
        ret.put("success", true);
        call.resolve(ret);
    }

    private void stopScan() {
        stopScan21();
    }

    private void stopScan21() {
        BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
        if (adapter == null) return;

        BluetoothLeScanner scanner = adapter.getBluetoothLeScanner();
        if (scanner != null) {
            scanner.stopScan(mScanCallback);
        }
        if (mUpdateFuture != null) {
            mUpdateFuture.cancel(true);
        }
        mLog.d("Stop scan ble");
        notifyListeners("onBlufiEvent", makeJson("stop_scan_ble", "1"));
    }

    void connectDevice(BluetoothDevice device) {
        mDevice = device;
        if (mBlufiClient != null) {
            mBlufiClient.close();
            mBlufiClient = null;
        }

        mBlufiClient = new BlufiClient(getContext(), mDevice);
        mBlufiClient.setGattCallback(new GattCallback());
        mBlufiClient.setBlufiCallback(new BlufiCallbackMain());
        mBlufiClient.connect();
    }

    private void disconnectGatt() {
        if (mBlufiClient != null) {
            mBlufiClient.requestCloseConnection();
        }
    }

    private void negotiateSecurity() {
        if (mBlufiClient != null) {
            mBlufiClient.negotiateSecurity();
        }
    }

    private void configure(String userName, String password) {
        if (mBlufiClient != null) {
            BlufiConfigureParams params = new BlufiConfigureParams();
            params.setOpMode(1);
            byte[] ssidBytes = userName.getBytes();
            params.setStaSSIDBytes(ssidBytes);
            params.setStaPassword(password);
            mBlufiClient.configure(params);
        }
    }

    private void requestDeviceStatus() {
        if (mBlufiClient != null) {
            mBlufiClient.requestDeviceStatus();
        }
    }

    private void requestDeviceVersion() {
        if (mBlufiClient != null) {
            mBlufiClient.requestDeviceVersion();
        }
    }

    private void requestDeviceWifiScan() {
        if (mBlufiClient != null) {
            mBlufiClient.requestDeviceWifiScan();
        }
    }

    private void postCustomData(String dataString) {
        if (mBlufiClient != null && dataString != null) {
            mBlufiClient.postCustomData(dataString.getBytes());
        }
    }

    private void onGattConnected() {
        mConnected = true;
    }

    private void onGattDisconnected() {
        mConnected = false;
    }

    private void onGattServiceCharacteristicDiscovered() {
        // Implementation if needed
    }

    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
    private class GattCallback extends BluetoothGattCallback {
        @Override
        public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
            String devAddr = gatt.getDevice().getAddress();
            mLog.d(String.format(Locale.ENGLISH, "onConnectionStateChange addr=%s, status=%d, newState=%d",
                    devAddr, status, newState));
            if (status == BluetoothGatt.GATT_SUCCESS) {
                switch (newState) {
                    case BluetoothProfile.STATE_CONNECTED:
                        onGattConnected();
                        notifyListeners("onBlufiEvent", makeJson("peripheral_connect", "1"));
                        break;
                    case BluetoothProfile.STATE_DISCONNECTED:
                        gatt.close();
                        onGattDisconnected();
                        notifyListeners("onBlufiEvent", makeJson("peripheral_connect", "0"));
                        break;
                }
            } else {
                gatt.close();
                onGattDisconnected();
                notifyListeners("onBlufiEvent", makeJson("peripheral_disconnect", "1"));
            }
        }

        @Override
        public void onMtuChanged(BluetoothGatt gatt, int mtu, int status) {
            mLog.d(String.format(Locale.ENGLISH, "onMtuChanged status=%d, mtu=%d", status, mtu));
            if (status == BluetoothGatt.GATT_SUCCESS) {
                mBlufiClient.setPostPackageLengthLimit(20);
            } else {
                mBlufiClient.setPostPackageLengthLimit(20);
            }
            onGattServiceCharacteristicDiscovered();
        }

        @Override
        public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            mLog.d(String.format(Locale.ENGLISH, "onServicesDiscovered status=%d", status));
            if (status != BluetoothGatt.GATT_SUCCESS) {
                gatt.disconnect();
                notifyListeners("onBlufiEvent", makeJson("discover_services", "1"));
            }
        }

        @Override
        public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
            mLog.d(String.format(Locale.ENGLISH, "onDescriptorWrite status=%d", status));
        }

        @Override
        public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                gatt.disconnect();
            }
        }
    }

    private class BlufiCallbackMain extends BlufiCallback {
        @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
        @Override
        public void onGattPrepared(BlufiClient client, BluetoothGatt gatt, BluetoothGattService service,
                                   BluetoothGattCharacteristic writeChar, BluetoothGattCharacteristic notifyChar) {
            if (service == null) {
                mLog.w("Discover service failed");
                gatt.disconnect();
                notifyListeners("onBlufiEvent", makeJson("discover_service", "0"));
                return;
            }
            if (writeChar == null) {
                mLog.w("Get write characteristic failed");
                gatt.disconnect();
                notifyListeners("onBlufiEvent", makeJson("get_write_characteristic", "0"));
                return;
            }
            if (notifyChar == null) {
                mLog.w("Get notification characteristic failed");
                gatt.disconnect();
                notifyListeners("onBlufiEvent", makeJson("get_notification_characteristic", "0"));
                return;
            }
            notifyListeners("onBlufiEvent", makeJson("discover_service", "1"));

            int mtu = BlufiConstants.DEFAULT_MTU_LENGTH;
            mLog.d("Request MTU " + mtu);
            boolean requestMtu = false;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                requestMtu = gatt.requestMtu(mtu);
                notifyListeners("onBlufiEvent", makeJson("request_mtu", "1"));
            }
            if (!requestMtu) {
                mLog.w("Request mtu failed");
                notifyListeners("onBlufiEvent", makeJson("request_mtu", "0"));
                onGattServiceCharacteristicDiscovered();
            }
        }

        @Override
        public void onNegotiateSecurityResult(BlufiClient client, int status) {
            if (status == STATUS_SUCCESS) {
                notifyListeners("onBlufiEvent", makeJson("negotiate_security", "1"));
            } else {
                notifyListeners("onBlufiEvent", makeJson("negotiate_security", "0"));
            }
        }

        @Override
        public void onPostConfigureParams(BlufiClient client, int status) {
            if (status == STATUS_SUCCESS) {
                notifyListeners("onBlufiEvent", makeJson("configure_params", "1"));
            } else {
                notifyListeners("onBlufiEvent", makeJson("configure_params", "0"));
            }
        }

        @Override
        public void onDeviceStatusResponse(BlufiClient client, int status, BlufiStatusResponse response) {
            if (status == STATUS_SUCCESS) {
                notifyListeners("onBlufiEvent", makeJson("device_status", "1"));
                if (response.isStaConnectWifi()) {
                    notifyListeners("onBlufiEvent", makeJson("device_wifi_connect", "1"));
                } else {
                    notifyListeners("onBlufiEvent", makeJson("device_wifi_connect", "0"));
                }
            } else {
                notifyListeners("onBlufiEvent", makeJson("device_status", "0"));
            }
        }

        @Override
        public void onDeviceScanResult(BlufiClient client, int status, List<BlufiScanResult> results) {
            if (status == STATUS_SUCCESS) {
                for (BlufiScanResult scanResult : results) {
                    notifyListeners("onBlufiEvent", makeWifiInfoJson(scanResult.getSsid(), scanResult.getRssi()));
                }
            } else {
                notifyListeners("onBlufiEvent", makeJson("wifi_info", "0"));
            }
        }

        @Override
        public void onDeviceVersionResponse(BlufiClient client, int status, BlufiVersionResponse response) {
            if (status == STATUS_SUCCESS) {
                notifyListeners("onBlufiEvent", makeJson("device_version", response.getVersionString()));
            } else {
                notifyListeners("onBlufiEvent", makeJson("device_version", "0"));
            }
        }

        @Override
        public void onPostCustomDataResult(BlufiClient client, int status, byte[] data) {
            if (status == STATUS_SUCCESS) {
                notifyListeners("onBlufiEvent", makeJson("post_custom_data", "1"));
            } else {
                notifyListeners("onBlufiEvent", makeJson("post_custom_data", "0"));
            }
        }

        @Override
        public void onReceiveCustomData(BlufiClient client, int status, byte[] data) {
            if (status == STATUS_SUCCESS) {
                String customStr = new String(data);
                customStr = customStr.replace("\"", "\\\"");
                notifyListeners("onBlufiEvent", makeJson("receive_device_custom_data", customStr));
            } else {
                notifyListeners("onBlufiEvent", makeJson("receive_device_custom_data", "0"));
            }
        }

        @Override
        public void onError(BlufiClient client, int errCode) {
            notifyListeners("onBlufiEvent", makeJson("receive_error_code", errCode + ""));
        }
    }

    private JSObject makeJson(String command, String data) {
        try {
            String address = "";
            if (mDevice != null) {
                address = mDevice.getAddress();
            }

            JSONObject json = new JSONObject();
            json.put("key", command);
            json.put("value", data);
            json.put("address", address);

            return JSObject.fromJSONObject(json);
        } catch (JSONException e) {
            mLog.e("Error creating JSON", e);
            return new JSObject();
        }
    }

    private JSObject makeScanDeviceJson(String address, String name, int rssi) {
        try {
            JSONObject json = new JSONObject();
            json.put("key", "ble_scan_result");

            JSONObject value = new JSONObject();
            value.put("address", address);
            value.put("name", name);
            value.put("rssi", rssi);

            json.put("value", value);

            return JSObject.fromJSONObject(json);
        } catch (JSONException e) {
            mLog.e("Error creating scan device JSON", e);
            return new JSObject();
        }
    }

    private JSObject makeWifiInfoJson(String ssid, int rssi) {
        try {
            String address = "";
            if (mDevice != null) {
                address = mDevice.getAddress();
            }

            JSONObject json = new JSONObject();
            json.put("key", "wifi_info");

            JSONObject value = new JSONObject();
            value.put("ssid", ssid);
            value.put("rssi", rssi);
            value.put("address", address);

            json.put("value", value);

            return JSObject.fromJSONObject(json);
        } catch (JSONException e) {
            mLog.e("Error creating wifi info JSON", e);
            return new JSObject();
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    private class ScanCallback extends android.bluetooth.le.ScanCallback {

        @Override
        public void onScanFailed(int errorCode) {
            super.onScanFailed(errorCode);
        }

        @Override
        public void onBatchScanResults(List<ScanResult> results) {
            for (ScanResult result : results) {
                onLeScan(result);
            }
        }

        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            onLeScan(result);
        }

        private void onLeScan(ScanResult scanResult) {
            String name = scanResult.getDevice().getName();

            if (!TextUtils.isEmpty(mBlufiFilter)) {
                if (name == null || !name.toLowerCase().contains(mBlufiFilter.toLowerCase())) {
                    return;
                }
            }

            mLog.d("BLE scan: " + scanResult.getDevice().getAddress());

            if (scanResult.getDevice().getName() != null) {
                mDeviceMap.put(scanResult.getDevice().getAddress(), scanResult);
                notifyListeners("onBlufiEvent", makeScanDeviceJson(
                    scanResult.getDevice().getAddress(),
                    scanResult.getDevice().getName(),
                    scanResult.getRssi()
                ));
            }
        }
    }

    @Override
    protected void handleOnDestroy() {
        super.handleOnDestroy();
        if (mBlufiClient != null) {
            mBlufiClient.close();
            mBlufiClient = null;
        }
        if (mThreadPool != null) {
            mThreadPool.shutdown();
        }
    }
}
