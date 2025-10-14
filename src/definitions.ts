import type { PluginListenerHandle } from '@capacitor/core';

export interface BleScanResult {
  address: string;
  name: string;
  rssi: number;
}

export interface WifiInfo {
  ssid: string;
  rssi: number;
  address: string;
}

export interface BlufiEvent {
  key: string;
  value: string | BleScanResult | WifiInfo;
  address?: string;
}

export type BlufiEventCallback = (event: BlufiEvent) => void;

export interface BlufiPlugin {
  /**
   * Start scanning for BLE devices
   * @param options Optional filter string to filter devices by name
   */
  startScan(options?: { filter?: string }): Promise<{ success: boolean }>;

  /**
   * Stop scanning for BLE devices
   */
  stopScan(): Promise<void>;

  /**
   * Connect to a BLE device
   * @param options Device address to connect to
   */
  connectToDevice(options: { address: string }): Promise<{ success: boolean }>;

  /**
   * Configure WiFi credentials on the device
   * @param options SSID and password for WiFi network
   */
  setWifi(options: { ssid: string; password: string }): Promise<void>;

  /**
   * Request device to scan for available WiFi networks
   */
  scanWifi(): Promise<void>;

  /**
   * Add listener for BluFi events
   * @param eventName Event name to listen for
   * @param listenerFunc Callback function to handle events
   */
  addListener(
    eventName: 'onBlufiEvent',
    listenerFunc: BlufiEventCallback
  ): Promise<PluginListenerHandle>;

  /**
   * Remove all listeners for a specific event
   * @param options Event name to remove listeners for
   */
  removeAllListeners(options?: { eventName: string }): Promise<void>;
}
