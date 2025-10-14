# @codext/capacitor-blufi

-

## Install

```bash
npm install @codext/capacitor-blufi
npx cap sync
```

## API

<docgen-index>

* [`startScan(...)`](#startscan)
* [`stopScan()`](#stopscan)
* [`connectToDevice(...)`](#connecttodevice)
* [`setWifi(...)`](#setwifi)
* [`scanWifi()`](#scanwifi)
* [`getDeviceInfo()`](#getdeviceinfo)
* [`addListener('onBlufiEvent', ...)`](#addlisteneronblufievent-)
* [`removeAllListeners(...)`](#removealllisteners)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### startScan(...)

```typescript
startScan(options?: { filter?: string | undefined; } | undefined) => Promise<{ success: boolean; }>
```

Start scanning for BLE devices

| Param         | Type                              | Description                                      |
| ------------- | --------------------------------- | ------------------------------------------------ |
| **`options`** | <code>{ filter?: string; }</code> | Optional filter string to filter devices by name |

**Returns:** <code>Promise&lt;{ success: boolean; }&gt;</code>

--------------------


### stopScan()

```typescript
stopScan() => Promise<void>
```

Stop scanning for BLE devices

--------------------


### connectToDevice(...)

```typescript
connectToDevice(options: { address: string; }) => Promise<{ success: boolean; }>
```

Connect to a BLE device

| Param         | Type                              | Description                  |
| ------------- | --------------------------------- | ---------------------------- |
| **`options`** | <code>{ address: string; }</code> | Device address to connect to |

**Returns:** <code>Promise&lt;{ success: boolean; }&gt;</code>

--------------------


### setWifi(...)

```typescript
setWifi(options: { ssid: string; password: string; }) => Promise<void>
```

Configure WiFi credentials on the device

| Param         | Type                                             | Description                        |
| ------------- | ------------------------------------------------ | ---------------------------------- |
| **`options`** | <code>{ ssid: string; password: string; }</code> | SSID and password for WiFi network |

--------------------


### scanWifi()

```typescript
scanWifi() => Promise<void>
```

Request device to scan for available WiFi networks

--------------------


### getDeviceInfo()

```typescript
getDeviceInfo() => Promise<void>
```

Get device information (version and status)
Status includes whether device is connected to WiFi
Results are sent through the event listener (device_version, device_status, device_wifi_connect)

--------------------


### addListener('onBlufiEvent', ...)

```typescript
addListener(eventName: 'onBlufiEvent', listenerFunc: BlufiEventCallback) => Promise<PluginListenerHandle>
```

Add listener for BluFi events

| Param              | Type                                                              | Description                        |
| ------------------ | ----------------------------------------------------------------- | ---------------------------------- |
| **`eventName`**    | <code>'onBlufiEvent'</code>                                       | Event name to listen for           |
| **`listenerFunc`** | <code><a href="#blufieventcallback">BlufiEventCallback</a></code> | Callback function to handle events |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### removeAllListeners(...)

```typescript
removeAllListeners(options?: { eventName: string; } | undefined) => Promise<void>
```

Remove all listeners for a specific event

| Param         | Type                                | Description                        |
| ------------- | ----------------------------------- | ---------------------------------- |
| **`options`** | <code>{ eventName: string; }</code> | Event name to remove listeners for |

--------------------


### Interfaces


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


#### BlufiEvent

| Prop          | Type                                                                                                  |
| ------------- | ----------------------------------------------------------------------------------------------------- |
| **`key`**     | <code>string</code>                                                                                   |
| **`value`**   | <code>string \| <a href="#blescanresult">BleScanResult</a> \| <a href="#wifiinfo">WifiInfo</a></code> |
| **`address`** | <code>string</code>                                                                                   |


#### BleScanResult

| Prop          | Type                |
| ------------- | ------------------- |
| **`address`** | <code>string</code> |
| **`name`**    | <code>string</code> |
| **`rssi`**    | <code>number</code> |


#### WifiInfo

| Prop          | Type                |
| ------------- | ------------------- |
| **`ssid`**    | <code>string</code> |
| **`rssi`**    | <code>number</code> |
| **`address`** | <code>string</code> |


### Type Aliases


#### BlufiEventCallback

<code>(event: <a href="#blufievent">BlufiEvent</a>): void</code>

</docgen-api>
