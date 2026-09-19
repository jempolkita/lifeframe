//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class MediaApi {
  MediaApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get Photo or Thumbnail Image Stream
  ///
  /// Retrieves binary image data for a photo, either full-resolution or resized thumbnail.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id:
  ///   Unique photo ID
  ///
  /// * [String] path:
  ///   Relative file path of the image
  ///
  /// * [bool] thumbnail:
  ///   Whether to return an optimized thumbnail instead of original image
  ///
  /// * [int] maxWidth:
  ///   Optional max width constraint for resizing
  ///
  /// * [int] maxHeight:
  ///   Optional max height constraint for resizing
  Future<Response> getImageWithHttpInfo({ String? id, String? path, bool? thumbnail, int? maxWidth, int? maxHeight, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/image';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (id != null) {
      queryParams.addAll(_queryParams('', 'id', id));
    }
    if (path != null) {
      queryParams.addAll(_queryParams('', 'path', path));
    }
    if (thumbnail != null) {
      queryParams.addAll(_queryParams('', 'thumbnail', thumbnail));
    }
    if (maxWidth != null) {
      queryParams.addAll(_queryParams('', 'max_width', maxWidth));
    }
    if (maxHeight != null) {
      queryParams.addAll(_queryParams('', 'max_height', maxHeight));
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

  /// Get Photo or Thumbnail Image Stream
  ///
  /// Retrieves binary image data for a photo, either full-resolution or resized thumbnail.
  ///
  /// Parameters:
  ///
  /// * [String] id:
  ///   Unique photo ID
  ///
  /// * [String] path:
  ///   Relative file path of the image
  ///
  /// * [bool] thumbnail:
  ///   Whether to return an optimized thumbnail instead of original image
  ///
  /// * [int] maxWidth:
  ///   Optional max width constraint for resizing
  ///
  /// * [int] maxHeight:
  ///   Optional max height constraint for resizing
  Future<MultipartFile?> getImage({ String? id, String? path, bool? thumbnail, int? maxWidth, int? maxHeight, Future<void>? abortTrigger, }) async {
    final response = await getImageWithHttpInfo(id: id, path: path, thumbnail: thumbnail, maxWidth: maxWidth, maxHeight: maxHeight, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MultipartFile',) as MultipartFile;
    
    }
    return null;
  }

  /// Upload Photo
  ///
  /// Uploads a photo file from mobile client to desktop server storage.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] file (required):
  ///   The raw image binary file
  ///
  /// * [String] relativePath:
  ///   Relative destination path (e.g., 'Camera/2026-09/IMG_1024.jpg')
  ///
  /// * [String] albumId:
  ///   Target album ID
  ///
  /// * [DateTime] dateTaken:
  ///   Capture timestamp if known
  ///
  /// * [String] hashSha256:
  ///   Client-calculated SHA256 checksum for validation
  Future<Response> uploadPhotoWithHttpInfo(MultipartFile file, { String? relativePath, String? albumId, DateTime? dateTaken, String? hashSha256, Future<void>? abortTrigger, }) async {
    // ignore: prefer_const_declarations
    final path = r'/upload';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (file != null) {
      hasFields = true;
      mp.fields[r'file'] = file.field;
      mp.files.add(file);
    }
    if (relativePath != null) {
      hasFields = true;
      mp.fields[r'relative_path'] = parameterToString(relativePath);
    }
    if (albumId != null) {
      hasFields = true;
      mp.fields[r'album_id'] = parameterToString(albumId);
    }
    if (dateTaken != null) {
      hasFields = true;
      mp.fields[r'date_taken'] = parameterToString(dateTaken);
    }
    if (hashSha256 != null) {
      hasFields = true;
      mp.fields[r'hash_sha256'] = parameterToString(hashSha256);
    }
    if (hasFields) {
      postBody = mp;
    }

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

  /// Upload Photo
  ///
  /// Uploads a photo file from mobile client to desktop server storage.
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] file (required):
  ///   The raw image binary file
  ///
  /// * [String] relativePath:
  ///   Relative destination path (e.g., 'Camera/2026-09/IMG_1024.jpg')
  ///
  /// * [String] albumId:
  ///   Target album ID
  ///
  /// * [DateTime] dateTaken:
  ///   Capture timestamp if known
  ///
  /// * [String] hashSha256:
  ///   Client-calculated SHA256 checksum for validation
  Future<UploadResponse?> uploadPhoto(MultipartFile file, { String? relativePath, String? albumId, DateTime? dateTaken, String? hashSha256, Future<void>? abortTrigger, }) async {
    final response = await uploadPhotoWithHttpInfo(file, relativePath: relativePath, albumId: albumId, dateTaken: dateTaken, hashSha256: hashSha256, abortTrigger: abortTrigger,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'UploadResponse',) as UploadResponse;
    
    }
    return null;
  }
}
