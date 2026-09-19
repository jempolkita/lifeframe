# lifeframe_api.api.DeviceApi

## Load the API package
```dart
import 'package:lifeframe_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**reportDeviceStatus**](DeviceApi.md#reportdevicestatus) | **POST** /api/device-status | Report Device Status / Heartbeat


# **reportDeviceStatus**
> DeviceStatusResponse reportDeviceStatus(deviceStatus)

Report Device Status / Heartbeat

Reports device battery, storage, and synchronization state to the desktop coordinator.

### Example
```dart
import 'package:lifeframe_api/api.dart';

final api_instance = DeviceApi();
final deviceStatus = DeviceStatus(); // DeviceStatus | 

try {
    final result = api_instance.reportDeviceStatus(deviceStatus);
    print(result);
} catch (e) {
    print('Exception when calling DeviceApi->reportDeviceStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceStatus** | [**DeviceStatus**](DeviceStatus.md)|  | 

### Return type

[**DeviceStatusResponse**](DeviceStatusResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

