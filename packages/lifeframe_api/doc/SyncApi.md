# lifeframe_api.api.SyncApi

## Load the API package
```dart
import 'package:lifeframe_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getManifest**](SyncApi.md#getmanifest) | **GET** /api/manifest | Get Sync Manifest


# **getManifest**
> SyncManifest getManifest(since)

Get Sync Manifest

Returns the current synchronization manifest including indexed photos, albums, and total sizes. Supports incremental sync via 'since' parameter.

### Example
```dart
import 'package:lifeframe_api/api.dart';

final api_instance = SyncApi();
final since = 2013-10-20T19:20:30+01:00; // DateTime | ISO-8601 timestamp to retrieve only items updated since this time

try {
    final result = api_instance.getManifest(since);
    print(result);
} catch (e) {
    print('Exception when calling SyncApi->getManifest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **since** | **DateTime**| ISO-8601 timestamp to retrieve only items updated since this time | [optional] 

### Return type

[**SyncManifest**](SyncManifest.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

