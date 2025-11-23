# @codext/capacitor-blufi

-

## Install

```bash
npm install @codext/capacitor-blufi
npx cap sync
```

## API

<docgen-index>

* [`startScan()`](#startscan)
* [`stopScan()`](#stopscan)
* [`connectToDevice(...)`](#connecttodevice)
* [`disconnectFromDevice()`](#disconnectfromdevice)
* [`resetPlugin()`](#resetplugin)
* [`getDeviceInfo()`](#getdeviceinfo)
* [`scanWifi()`](#scanwifi)
* [`setWifi(...)`](#setwifi)
* [`getNetworkStatus()`](#getnetworkstatus)
* [`addListener('onBlufiEvent', ...)`](#addlisteneronblufievent-)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### startScan()

```typescript
startScan() => Promise<void>
```

--------------------


### stopScan()

```typescript
stopScan() => Promise<{ scanResult: ScanResultItem[]; }>
```

**Returns:** <code>Promise&lt;{ scanResult: ScanResultItem[]; }&gt;</code>

--------------------


### connectToDevice(...)

```typescript
connectToDevice(options: { deviceId: string; }) => Promise<void>
```

| Param         | Type                               |
| ------------- | ---------------------------------- |
| **`options`** | <code>{ deviceId: string; }</code> |

--------------------


### disconnectFromDevice()

```typescript
disconnectFromDevice() => Promise<void>
```

--------------------


### resetPlugin()

```typescript
resetPlugin() => Promise<void>
```

--------------------


### getDeviceInfo()

```typescript
getDeviceInfo() => Promise<void>
```

--------------------


### scanWifi()

```typescript
scanWifi() => Promise<WifiListResult>
```

**Returns:** <code>Promise&lt;<a href="#wifilistresult">WifiListResult</a>&gt;</code>

--------------------


### setWifi(...)

```typescript
setWifi(options: { ssid: string; password: string; }) => Promise<WifiConnectResult>
```

| Param         | Type                                             |
| ------------- | ------------------------------------------------ |
| **`options`** | <code>{ ssid: string; password: string; }</code> |

**Returns:** <code>Promise&lt;<a href="#wificonnectresult">WifiConnectResult</a>&gt;</code>

--------------------


### getNetworkStatus()

```typescript
getNetworkStatus() => Promise<NetworkStatusResult>
```

**Returns:** <code>Promise&lt;<a href="#networkstatusresult">NetworkStatusResult</a>&gt;</code>

--------------------


### addListener('onBlufiEvent', ...)

```typescript
addListener(eventName: 'onBlufiEvent', listenerFunc: (event: any) => void) => Promise<PluginListenerHandle>
```

| Param              | Type                                 |
| ------------------ | ------------------------------------ |
| **`eventName`**    | <code>'onBlufiEvent'</code>          |
| **`listenerFunc`** | <code>(event: any) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### Interfaces


#### ScanResultItem

| Prop          | Type                |
| ------------- | ------------------- |
| **`name`**    | <code>string</code> |
| **`rssi`**    | <code>number</code> |
| **`address`** | <code>string</code> |


#### WifiListResult

| Prop       | Type                  |
| ---------- | --------------------- |
| **`list`** | <code>string[]</code> |


#### WifiConnectResult

| Prop          | Type                 |
| ------------- | -------------------- |
| **`success`** | <code>boolean</code> |
| **`message`** | <code>string</code>  |


#### NetworkStatusResult

| Prop            | Type                 |
| --------------- | -------------------- |
| **`connected`** | <code>boolean</code> |
| **`status`**    | <code>string</code>  |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |

</docgen-api>
