//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UploadResponse {
  /// Returns a new [UploadResponse] instance.
  UploadResponse({
    required this.success,
    required this.photoId,
    required this.relativePath,
    required this.message,
  });

  bool success;

  String photoId;

  String relativePath;

  String message;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UploadResponse &&
    other.success == success &&
    other.photoId == photoId &&
    other.relativePath == relativePath &&
    other.message == message;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (success.hashCode) +
    (photoId.hashCode) +
    (relativePath.hashCode) +
    (message.hashCode);

  @override
  String toString() => 'UploadResponse[success=$success, photoId=$photoId, relativePath=$relativePath, message=$message]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'success'] = this.success;
      json[r'photo_id'] = this.photoId;
      json[r'relative_path'] = this.relativePath;
      json[r'message'] = this.message;
    return json;
  }

  /// Returns a new [UploadResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UploadResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'success'), 'Required key "UploadResponse[success]" is missing from JSON.');
        assert(json[r'success'] != null, 'Required key "UploadResponse[success]" has a null value in JSON.');
        assert(json.containsKey(r'photo_id'), 'Required key "UploadResponse[photo_id]" is missing from JSON.');
        assert(json[r'photo_id'] != null, 'Required key "UploadResponse[photo_id]" has a null value in JSON.');
        assert(json.containsKey(r'relative_path'), 'Required key "UploadResponse[relative_path]" is missing from JSON.');
        assert(json[r'relative_path'] != null, 'Required key "UploadResponse[relative_path]" has a null value in JSON.');
        assert(json.containsKey(r'message'), 'Required key "UploadResponse[message]" is missing from JSON.');
        assert(json[r'message'] != null, 'Required key "UploadResponse[message]" has a null value in JSON.');
        return true;
      }());

      return UploadResponse(
        success: mapValueOfType<bool>(json, r'success')!,
        photoId: mapValueOfType<String>(json, r'photo_id')!,
        relativePath: mapValueOfType<String>(json, r'relative_path')!,
        message: mapValueOfType<String>(json, r'message')!,
      );
    }
    return null;
  }

  static List<UploadResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UploadResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UploadResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UploadResponse> mapFromJson(dynamic json) {
    final map = <String, UploadResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UploadResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UploadResponse-objects as value to a dart map
  static Map<String, List<UploadResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UploadResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UploadResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'success',
    'photo_id',
    'relative_path',
    'message',
  };
}

