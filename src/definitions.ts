import type { PluginListenerHandle } from '@capacitor/core';

export interface ScanResultItem {
  name: string;
  rssi: number;
  address: string;
}

export interface WifiListResult {
  list: string[];
}

export interface WifiConnectResult {
  success: boolean;
  message: string;
}

export interface NetworkStatusResult {
  connected: boolean;
  status: string;
}

export interface BlufiPlugin {
  startScan(): Promise<void>;
  stopScan(): Promise<{ scanResult: ScanResultItem[] }>;
  connectToDevice(options: { deviceId: string }): Promise<void>;
  disconnectFromDevice(): Promise<void>;
  resetPlugin(): Promise<void>;
  getDeviceInfo(): Promise<void>;
  scanWifi(): Promise<WifiListResult>;
  setWifi(options: { ssid: string; password: string }): Promise<WifiConnectResult>;
  getNetworkStatus(): Promise<NetworkStatusResult>;

  addListener(eventName: 'onBlufiEvent', listenerFunc: (event: any) => void): Promise<PluginListenerHandle>;
}
