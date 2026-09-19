# lifeframe_api.api.MediaApi

## Load the API package
```dart
import 'package:lifeframe_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getImage**](MediaApi.md#getimage) | **GET** /image | Get Photo or Thumbnail Image Stream
[**uploadPhoto**](MediaApi.md#uploadphoto) | **POST** /upload | Upload Photo


# **getImage**
> MultipartFile getImage(id, path, thumbnail, maxWidth, maxHeight)

Get Photo or Thumbnail Image Stream

Retrieves binary image data for a photo, either full-resolution or resized thumbnail.

### Example
```dart
import 'package:lifeframe_api/api.dart';

final api_instance = MediaApi();
final id = id_example; // String | Unique photo ID
final path = path_example; // String | Relative file path of the image
final thumbnail = true; // bool | Whether to return an optimized thumbnail instead of original image
final maxWidth = 56; // int | Optional max width constraint for resizing
final maxHeight = 56; // int | Optional max height constraint for resizing

try {
    final result = api_instance.getImage(id, path, thumbnail, maxWidth, maxHeight);
    print(result);
} catch (e) {
    print('Exception when calling MediaApi->getImage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Unique photo ID | [optional] 
 **path** | **String**| Relative file path of the image | [optional] 
 **thumbnail** | **bool**| Whether to return an optimized thumbnail instead of original image | [optional] [default to false]
 **maxWidth** | **int**| Optional max width constraint for resizing | [optional] 
 **maxHeight** | **int**| Optional max height constraint for resizing | [optional] 

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: image/*, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadPhoto**
> UploadResponse uploadPhoto(file, relativePath, albumId, dateTaken, hashSha256)

Upload Photo

Uploads a photo file from mobile client to desktop server storage.

### Example
```dart
import 'package:lifeframe_api/api.dart';

final api_instance = MediaApi();
final file = BINARY_DATA_HERE; // MultipartFile | The raw image binary file
final relativePath = relativePath_example; // String | Relative destination path (e.g., 'Camera/2026-09/IMG_1024.jpg')
final albumId = albumId_example; // String | Target album ID
final dateTaken = 2013-10-20T19:20:30+01:00; // DateTime | Capture timestamp if known
final hashSha256 = hashSha256_example; // String | Client-calculated SHA256 checksum for validation

try {
    final result = api_instance.uploadPhoto(file, relativePath, albumId, dateTaken, hashSha256);
    print(result);
} catch (e) {
    print('Exception when calling MediaApi->uploadPhoto: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**| The raw image binary file | 
 **relativePath** | **String**| Relative destination path (e.g., 'Camera/2026-09/IMG_1024.jpg') | [optional] 
 **albumId** | **String**| Target album ID | [optional] 
 **dateTaken** | **DateTime**| Capture timestamp if known | [optional] 
 **hashSha256** | **String**| Client-calculated SHA256 checksum for validation | [optional] 

### Return type

[**UploadResponse**](UploadResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

