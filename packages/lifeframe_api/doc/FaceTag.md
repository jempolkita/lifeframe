# lifeframe_api.model.FaceTag

## Load the model package
```dart
import 'package:lifeframe_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** | Unique face detection ID | 
**personId** | **String** | ID of identified person if assigned | [optional] 
**personName** | **String** | Recognized or labeled person name | [optional] 
**confidence** | **double** | Detection confidence score (0.0 to 1.0) | [optional] 
**isConfirmed** | **bool** | Whether verified by user or auto-detected by AI | [optional] [default to false]
**box** | [**BoundingBox**](BoundingBox.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


