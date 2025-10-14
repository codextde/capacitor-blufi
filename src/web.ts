import { WebPlugin } from '@capacitor/core';

import type { BlufiPlugin } from './definitions';

export class BlufiWeb extends WebPlugin implements BlufiPlugin {
  async startScan(_options?: { filter?: string }): Promise<{ success: boolean }> {
    throw this.unavailable('BLE scanning is not available on web');
  }

  async stopScan(): Promise<void> {
    throw this.unavailable('BLE scanning is not available on web');
  }

  async connectToDevice(_options: { address: string }): Promise<{ success: boolean }> {
    throw this.unavailable('BLE connection is not available on web');
  }

  async setWifi(_options: { ssid: string; password: string }): Promise<void> {
    throw this.unavailable('BluFi is not available on web');
  }

  async scanWifi(): Promise<void> {
    throw this.unavailable('BluFi is not available on web');
  }
}
