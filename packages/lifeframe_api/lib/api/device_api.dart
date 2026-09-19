//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DeviceApi {
  DeviceApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Report Device Status / Heartbeat
  ///
  /// Reports device battery, storage, and synchronization state to the desktop coordinator.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DeviceStatus] deviceStatus (required):
  Future<Response> reportDeviceStatusWithHttpInfo(DeviceStatus deviceStatus, { Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/device-status';

    // ignore: prefer_final_locals
    Object? postBody = deviceStatus;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Report Device Status / Heartbeat
  ///
  /// Reports device battery, storage, and synchronization state to the desktop coordinator.
  ///
  /// Parameters:
  ///
  /// * [DeviceStatus] deviceStatus (required):
  Future<DeviceStatusResponse?> reportDeviceStatus(DeviceStatus deviceStatus, { Future<void>? abortTrigger, }) async {
    final response = await reportDeviceStatusWithHttpInfo(deviceStatus, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'DeviceStatusResponse',) as DeviceStatusResponse;
    
    }
    return null;
  }
}
