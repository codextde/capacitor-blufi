import { WebPlugin } from '@capacitor/core';

import type { BlufiPlugin, BlufiEventCallback } from './definitions';

export class BlufiWeb extends WebPlugin implements BlufiPlugin {
  async getPlatformVersion(): Promise<{ version: string }> {
    return { version: 'Web - not supported' };
  }

  async scanDeviceInfo(_options?: { filter?: string }): Promise<{ success: boolean }> {
    throw this.unavailable('BLE scanning is not available on web');
  }

  async stopScan(): Promise<void> {
    throw this.unavailable('BLE scanning is not available on web');
  }

  async connectPeripheral(_options: { peripheral: string }): Promise<{ success: boolean }> {
    throw this.unavailable('BLE connection is not available on web');
  }

  async requestCloseConnection(): Promise<void> {
    throw this.unavailable('BLE connection is not available on web');
  }

  async negotiateSecurity(): Promise<void> {
    throw this.unavailable('BluFi is not available on web');
  }

  async requestDeviceVersion(): Promise<void> {
    throw this.unavailable('BluFi is not available on web');
  }

  async configProvision(_options: { username: string; password: string }): Promise<void> {
    throw this.unavailable('BluFi is not available on web');
  }

  async requestDeviceStatus(): Promise<void> {
    throw this.unavailable('BluFi is not available on web');
  }

  async requestDeviceScan(): Promise<void> {
    throw this.unavailable('BluFi is not available on web');
  }

  async postCustomData(_options: { customData: string }): Promise<void> {
    throw this.unavailable('BluFi is not available on web');
  }

  async addListener(_eventName: 'onBlufiEvent', _callback: BlufiEventCallback): Promise<{ id: string }> {
    throw this.unavailable('BluFi events are not available on web');
  }

  async removeAllListeners(_eventName?: string): Promise<void> {
    // No-op on web
  }
}
