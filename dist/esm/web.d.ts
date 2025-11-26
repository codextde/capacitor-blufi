import { WebPlugin } from '@capacitor/core';
import type { BlufiPlugin, ScanResultItem, WifiListResult, WifiConnectResult, NetworkStatusResult } from './definitions';
export declare class BlufiWeb extends WebPlugin implements BlufiPlugin {
    startScan(): Promise<void>;
    stopScan(): Promise<{
        scanResult: ScanResultItem[];
    }>;
    connectToDevice(_options: {
        deviceId: string;
    }): Promise<void>;
    disconnectFromDevice(): Promise<void>;
    resetPlugin(): Promise<void>;
    getDeviceInfo(): Promise<void>;
    scanWifi(): Promise<WifiListResult>;
    setWifi(_options: {
        ssid: string;
        password: string;
    }): Promise<WifiConnectResult>;
    getNetworkStatus(): Promise<NetworkStatusResult>;
}
