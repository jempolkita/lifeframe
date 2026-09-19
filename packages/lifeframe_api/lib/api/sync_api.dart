//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class SyncApi {
  SyncApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get Sync Manifest
  ///
  /// Returns the current synchronization manifest including indexed photos, albums, and total sizes. Supports incremental sync via 'since' parameter.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DateTime] since:
  ///   ISO-8601 timestamp to retrieve only items updated since this time
  Future<Response> getManifestWithHttpInfo({ DateTime? since, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/manifest';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (since != null) {
      queryParams.addAll(_queryParams('', 'since', since));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Get Sync Manifest
  ///
  /// Returns the current synchronization manifest including indexed photos, albums, and total sizes. Supports incremental sync via 'since' parameter.
  ///
  /// Parameters:
  ///
  /// * [DateTime] since:
  ///   ISO-8601 timestamp to retrieve only items updated since this time
  Future<SyncManifest?> getManifest({ DateTime? since, Future<void>? abortTrigger, }) async {
    final response = await getManifestWithHttpInfo(since: since, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SyncManifest',) as SyncManifest;
    
    }
    return null;
  }
}
