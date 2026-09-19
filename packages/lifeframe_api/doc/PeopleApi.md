# lifeframe_api.api.PeopleApi

## Load the API package
```dart
import 'package:lifeframe_api/api.dart';
```

All URIs are relative to *http://localhost:8080*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getPeople**](PeopleApi.md#getpeople) | **GET** /api/people | Get People List


# **getPeople**
> List<Person> getPeople()

Get People List

Returns list of recognized or tagged people for facial recognition clustering

### Example
```dart
import 'package:lifeframe_api/api.dart';

final api_instance = PeopleApi();

try {
    final result = api_instance.getPeople();
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->getPeople: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Person>**](Person.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

