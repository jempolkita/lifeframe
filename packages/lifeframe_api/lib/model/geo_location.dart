//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GeoLocation {
  /// Returns a new [GeoLocation] instance.
  GeoLocation({
    required this.latitude,
    required this.longitude,
    this.altitude,
  });

  double latitude;

  double longitude;

  double? altitude;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GeoLocation &&
    other.latitude == latitude &&
    other.longitude == longitude &&
    other.altitude == altitude;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (latitude.hashCode) +
    (longitude.hashCode) +
    (altitude == null ? 0 : altitude!.hashCode);

  @override
  String toString() => 'GeoLocation[latitude=$latitude, longitude=$longitude, altitude=$altitude]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'latitude'] = this.latitude;
      json[r'longitude'] = this.longitude;
    if (this.altitude != null) {
      json[r'altitude'] = this.altitude;
    } else {
      json[r'altitude'] = null;
    }
    return json;
  }

  /// Returns a new [GeoLocation] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GeoLocation? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'latitude'), 'Required key "GeoLocation[latitude]" is missing from JSON.');
        assert(json[r'latitude'] != null, 'Required key "GeoLocation[latitude]" has a null value in JSON.');
        assert(json.containsKey(r'longitude'), 'Required key "GeoLocation[longitude]" is missing from JSON.');
        assert(json[r'longitude'] != null, 'Required key "GeoLocation[longitude]" has a null value in JSON.');
        return true;
      }());

      return GeoLocation(
        latitude: mapValueOfType<double>(json, r'latitude')!,
        longitude: mapValueOfType<double>(json, r'longitude')!,
        altitude: mapValueOfType<double>(json, r'altitude'),
      );
    }
    return null;
  }

  static List<GeoLocation> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GeoLocation>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GeoLocation.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GeoLocation> mapFromJson(dynamic json) {
    final map = <String, GeoLocation>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GeoLocation.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GeoLocation-objects as value to a dart map
  static Map<String, List<GeoLocation>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GeoLocation>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GeoLocation.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'latitude',
    'longitude',
  };
}

