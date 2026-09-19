# lifeframe_api.model.Photo

## Load the model package
```dart
import 'package:lifeframe_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** | Unique UUID or identifier | 
**filename** | **String** | Original filename e.g. IMG_2026.JPG | 
**relativePath** | **String** | Relative file path from root storage | 
**sizeBytes** | **int** | File size in bytes | 
**hashSha256** | **String** | SHA-256 hash checksum for integrity & deduplication | 
**mimeType** | **String** | MIME type e.g. image/jpeg, image/png, image/heic | 
**width** | **int** | Image width in pixels | [optional] 
**height** | **int** | Image height in pixels | [optional] 
**rating** | **int** | Star rating (0-5, matching digiKam rating) | [optional] [default to 0]
**dateTaken** | [**DateTime**](DateTime.md) | Date captured from EXIF | [optional] 
**dateModified** | [**DateTime**](DateTime.md) | File modification timestamp | 
**albumId** | **String** | Parent album ID if assigned | [optional] 
**tags** | **List<String>** | Keywords and general tags | [optional] [default to const []]
**faces** | [**List<FaceTag>**](FaceTag.md) | Detected faces and regions | [optional] [default to const []]
**gps** | [**GeoLocation**](GeoLocation.md) |  | [optional] 
**exif** | [**ExifData**](ExifData.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


