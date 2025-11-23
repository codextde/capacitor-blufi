import { WebPlugin } from '@capacitor/core';

import type {
  BlufiPlugin,
  ScanResultItem,
  WifiListResult,
  WifiConnectResult,
  NetworkStatusResult,
} from './definitions';

export class BlufiWeb extends WebPlugin implements BlufiPlugin {
  async startScan(): Promise<void> {
    throw this.unavailable('BLE scanning is not available on web');
  }

  async stopScan(): Promise<{ scanResult: ScanResultItem[] }> {
    throw this.unavailable('BLE scanning is not available on web');
  }

  async connectToDevice(_options: { deviceId: string }): Promise<void> {
    throw this.unavailable('BLE connection is not available on web');
  }

  async disconnectFromDevice(): Promise<void> {
    throw this.unavailable('BLE connection is not available on web');
  }

  async resetPlugin(): Promise<void> {
    throw this.unavailable('BluFi is not available on web');
  }

  async getDeviceInfo(): Promise<void> {
    throw this.unavailable('BluFi is not available on web');
  }

  async scanWifi(): Promise<WifiListResult> {
    throw this.unavailable('BluFi is not available on web');
  }

  async setWifi(_options: { ssid: string; password: string }): Promise<WifiConnectResult> {
    throw this.unavailable('BluFi is not available on web');
  }

  async getNetworkStatus(): Promise<NetworkStatusResult> {
    throw this.unavailable('BluFi is not available on web');
  }
}
