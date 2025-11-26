import { WebPlugin } from '@capacitor/core';
export class BlufiWeb extends WebPlugin {
    async startScan() {
        throw this.unavailable('BLE scanning is not available on web');
    }
    async stopScan() {
        throw this.unavailable('BLE scanning is not available on web');
    }
    async connectToDevice(_options) {
        throw this.unavailable('BLE connection is not available on web');
    }
    async disconnectFromDevice() {
        throw this.unavailable('BLE connection is not available on web');
    }
    async resetPlugin() {
        throw this.unavailable('BluFi is not available on web');
    }
    async getDeviceInfo() {
        throw this.unavailable('BluFi is not available on web');
    }
    async scanWifi() {
        throw this.unavailable('BluFi is not available on web');
    }
    async setWifi(_options) {
        throw this.unavailable('BluFi is not available on web');
    }
    async getNetworkStatus() {
        throw this.unavailable('BluFi is not available on web');
    }
}
//# sourceMappingURL=web.js.map