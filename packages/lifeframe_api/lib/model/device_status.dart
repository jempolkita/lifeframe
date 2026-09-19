//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DeviceStatus {
  /// Returns a new [DeviceStatus] instance.
  DeviceStatus({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    this.batteryPercentage,
    this.isCharging,
    this.storageFreeBytes,
    this.storageTotalBytes,
    required this.clientVersion,
    this.lastSyncAt,
    this.syncStatus,
  });

  String deviceId;

  String deviceName;

  DeviceStatusDeviceTypeEnum deviceType;

  /// Minimum value: 0
  /// Maximum value: 100
  int? batteryPercentage;

  bool? isCharging;

  int? storageFreeBytes;

  int? storageTotalBytes;

  String clientVersion;

  DateTime? lastSyncAt;

  /// Current sync state (e.g. idle, syncing, paused, error)
  String? syncStatus;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DeviceStatus &&
    other.deviceId == deviceId &&
    other.deviceName == deviceName &&
    other.deviceType == deviceType &&
    other.batteryPercentage == batteryPercentage &&
    other.isCharging == isCharging &&
    other.storageFreeBytes == storageFreeBytes &&
    other.storageTotalBytes == storageTotalBytes &&
    other.clientVersion == clientVersion &&
    other.lastSyncAt == lastSyncAt &&
    other.syncStatus == syncStatus;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (deviceId.hashCode) +
    (deviceName.hashCode) +
    (deviceType.hashCode) +
    (batteryPercentage == null ? 0 : batteryPercentage!.hashCode) +
    (isCharging == null ? 0 : isCharging!.hashCode) +
    (storageFreeBytes == null ? 0 : storageFreeBytes!.hashCode) +
    (storageTotalBytes == null ? 0 : storageTotalBytes!.hashCode) +
    (clientVersion.hashCode) +
    (lastSyncAt == null ? 0 : lastSyncAt!.hashCode) +
    (syncStatus == null ? 0 : syncStatus!.hashCode);

  @override
  String toString() => 'DeviceStatus[deviceId=$deviceId, deviceName=$deviceName, deviceType=$deviceType, batteryPercentage=$batteryPercentage, isCharging=$isCharging, storageFreeBytes=$storageFreeBytes, storageTotalBytes=$storageTotalBytes, clientVersion=$clientVersion, lastSyncAt=$lastSyncAt, syncStatus=$syncStatus]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'device_id'] = this.deviceId;
      json[r'device_name'] = this.deviceName;
      json[r'device_type'] = this.deviceType;
    if (this.batteryPercentage != null) {
      json[r'battery_percentage'] = this.batteryPercentage;
    } else {
      json[r'battery_percentage'] = null;
    }
    if (this.isCharging != null) {
      json[r'is_charging'] = this.isCharging;
    } else {
      json[r'is_charging'] = null;
    }
    if (this.storageFreeBytes != null) {
      json[r'storage_free_bytes'] = this.storageFreeBytes;
    } else {
      json[r'storage_free_bytes'] = null;
    }
    if (this.storageTotalBytes != null) {
      json[r'storage_total_bytes'] = this.storageTotalBytes;
    } else {
      json[r'storage_total_bytes'] = null;
    }
      json[r'client_version'] = this.clientVersion;
    if (this.lastSyncAt != null) {
      json[r'last_sync_at'] = this.lastSyncAt!.toUtc().toIso8601String();
    } else {
      json[r'last_sync_at'] = null;
    }
    if (this.syncStatus != null) {
      json[r'sync_status'] = this.syncStatus;
    } else {
      json[r'sync_status'] = null;
    }
    return json;
  }

  /// Returns a new [DeviceStatus] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DeviceStatus? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'device_id'), 'Required key "DeviceStatus[device_id]" is missing from JSON.');
        assert(json[r'device_id'] != null, 'Required key "DeviceStatus[device_id]" has a null value in JSON.');
        assert(json.containsKey(r'device_name'), 'Required key "DeviceStatus[device_name]" is missing from JSON.');
        assert(json[r'device_name'] != null, 'Required key "DeviceStatus[device_name]" has a null value in JSON.');
        assert(json.containsKey(r'device_type'), 'Required key "DeviceStatus[device_type]" is missing from JSON.');
        assert(json[r'device_type'] != null, 'Required key "DeviceStatus[device_type]" has a null value in JSON.');
        assert(json.containsKey(r'client_version'), 'Required key "DeviceStatus[client_version]" is missing from JSON.');
        assert(json[r'client_version'] != null, 'Required key "DeviceStatus[client_version]" has a null value in JSON.');
        return true;
      }());

      return DeviceStatus(
        deviceId: mapValueOfType<String>(json, r'device_id')!,
        deviceName: mapValueOfType<String>(json, r'device_name')!,
        deviceType: DeviceStatusDeviceTypeEnum.fromJson(json[r'device_type'])!,
        batteryPercentage: mapValueOfType<int>(json, r'battery_percentage'),
        isCharging: mapValueOfType<bool>(json, r'is_charging'),
        storageFreeBytes: mapValueOfType<int>(json, r'storage_free_bytes'),
        storageTotalBytes: mapValueOfType<int>(json, r'storage_total_bytes'),
        clientVersion: mapValueOfType<String>(json, r'client_version')!,
        lastSyncAt: mapDateTime(json, r'last_sync_at', r''),
        syncStatus: mapValueOfType<String>(json, r'sync_status'),
      );
    }
    return null;
  }

  static List<DeviceStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DeviceStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeviceStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DeviceStatus> mapFromJson(dynamic json) {
    final map = <String, DeviceStatus>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DeviceStatus.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DeviceStatus-objects as value to a dart map
  static Map<String, List<DeviceStatus>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DeviceStatus>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DeviceStatus.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'device_id',
    'device_name',
    'device_type',
    'client_version',
  };
}


enum DeviceStatusDeviceTypeEnum {
  desktop._(r'desktop'),
  mobileAndroid._(r'mobile_android'),
  mobileIos._(r'mobile_ios'),
  unknown._(r'unknown'),
  ;

  /// Instantiate a new enum with the provided value.
  const DeviceStatusDeviceTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [DeviceStatusDeviceTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static DeviceStatusDeviceTypeEnum? fromJson(dynamic value) => DeviceStatusDeviceTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [DeviceStatusDeviceTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<DeviceStatusDeviceTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DeviceStatusDeviceTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeviceStatusDeviceTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DeviceStatusDeviceTypeEnum] to String,
/// and [decode] dynamic data back to [DeviceStatusDeviceTypeEnum].
class DeviceStatusDeviceTypeEnumTypeTransformer {
  factory DeviceStatusDeviceTypeEnumTypeTransformer() => _instance ??= const DeviceStatusDeviceTypeEnumTypeTransformer._();

  const DeviceStatusDeviceTypeEnumTypeTransformer._();

  String encode(DeviceStatusDeviceTypeEnum data) => data._value;

  /// Returns the instance of [DeviceStatusDeviceTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DeviceStatusDeviceTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is DeviceStatusDeviceTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'desktop': return DeviceStatusDeviceTypeEnum.desktop;
        case r'mobile_android': return DeviceStatusDeviceTypeEnum.mobileAndroid;
        case r'mobile_ios': return DeviceStatusDeviceTypeEnum.mobileIos;
        case r'unknown': return DeviceStatusDeviceTypeEnum.unknown;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static DeviceStatusDeviceTypeEnumTypeTransformer? _instance;
}


