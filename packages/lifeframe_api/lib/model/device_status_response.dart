//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DeviceStatusResponse {
  /// Returns a new [DeviceStatusResponse] instance.
  DeviceStatusResponse({
    required this.success,
    required this.message,
    required this.serverTime,
  });

  bool success;

  String message;

  DateTime serverTime;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DeviceStatusResponse &&
    other.success == success &&
    other.message == message &&
    other.serverTime == serverTime;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (success.hashCode) +
    (message.hashCode) +
    (serverTime.hashCode);

  @override
  String toString() => 'DeviceStatusResponse[success=$success, message=$message, serverTime=$serverTime]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'success'] = this.success;
      json[r'message'] = this.message;
      json[r'server_time'] = this.serverTime.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [DeviceStatusResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DeviceStatusResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'success'), 'Required key "DeviceStatusResponse[success]" is missing from JSON.');
        assert(json[r'success'] != null, 'Required key "DeviceStatusResponse[success]" has a null value in JSON.');
        assert(json.containsKey(r'message'), 'Required key "DeviceStatusResponse[message]" is missing from JSON.');
        assert(json[r'message'] != null, 'Required key "DeviceStatusResponse[message]" has a null value in JSON.');
        assert(json.containsKey(r'server_time'), 'Required key "DeviceStatusResponse[server_time]" is missing from JSON.');
        assert(json[r'server_time'] != null, 'Required key "DeviceStatusResponse[server_time]" has a null value in JSON.');
        return true;
      }());

      return DeviceStatusResponse(
        success: mapValueOfType<bool>(json, r'success')!,
        message: mapValueOfType<String>(json, r'message')!,
        serverTime: mapDateTime(json, r'server_time', r'')!,
      );
    }
    return null;
  }

  static List<DeviceStatusResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DeviceStatusResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeviceStatusResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DeviceStatusResponse> mapFromJson(dynamic json) {
    final map = <String, DeviceStatusResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DeviceStatusResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DeviceStatusResponse-objects as value to a dart map
  static Map<String, List<DeviceStatusResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DeviceStatusResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DeviceStatusResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'success',
    'message',
    'server_time',
  };
}

