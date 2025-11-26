'use strict';

var core = require('@capacitor/core');

const Blufi = core.registerPlugin('Blufi', {
    web: () => Promise.resolve().then(function () { return web; }).then((m) => new m.BlufiWeb()),
});

class BlufiWeb extends core.WebPlugin {
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

var web = /*#__PURE__*/Object.freeze({
    __proto__: null,
    BlufiWeb: BlufiWeb
});

exports.Blufi = Blufi;
//# sourceMappingURL=plugin.cjs.js.map
