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
   * Get platform version
   */
  getPlatformVersion(): Promise<{ version: string }>;

  /**
   * Start scanning for BLE devices
   * @param options Optional filter string to filter devices by name
   */
  scanDeviceInfo(options?: { filter?: string }): Promise<{ success: boolean }>;

  /**
   * Stop scanning for BLE devices
   */
  stopScan(): Promise<void>;

  /**
   * Connect to a BLE peripheral
   * @param options Peripheral address to connect to
   */
  connectPeripheral(options: { peripheral: string }): Promise<{ success: boolean }>;

  /**
   * Request to close the connection
   */
  requestCloseConnection(): Promise<void>;

  /**
   * Negotiate security with the device
   */
  negotiateSecurity(): Promise<void>;

  /**
   * Request device version information
   */
  requestDeviceVersion(): Promise<void>;

  /**
   * Configure WiFi provisioning
   * @param options SSID (username) and password for WiFi network
   */
  configProvision(options: { username: string; password: string }): Promise<void>;

  /**
   * Request device status
   */
  requestDeviceStatus(): Promise<void>;

  /**
   * Request device to scan for WiFi networks
   */
  requestDeviceScan(): Promise<void>;

  /**
   * Post custom data to the device
   * @param options Custom data string to send
   */
  postCustomData(options: { customData: string }): Promise<void>;

  /**
   * Add listener for BluFi events
   * @param eventName Event name to listen for
   * @param callback Callback function to handle events
   */
  addListener(eventName: 'onBlufiEvent', callback: BlufiEventCallback): Promise<{ id: string }>;

  /**
   * Remove all listeners for a specific event
   * @param eventName Event name to remove listeners for
   */
  removeAllListeners(eventName?: string): Promise<void>;
}
