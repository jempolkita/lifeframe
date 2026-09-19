//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ExifData {
  /// Returns a new [ExifData] instance.
  ExifData({
    this.make,
    this.model,
    this.lens,
    this.focalLength,
    this.fNumber,
    this.iso,
    this.exposureTime,
  });

  String? make;

  String? model;

  String? lens;

  double? focalLength;

  double? fNumber;

  int? iso;

  /// Formatted shutter speed e.g. 1/250s
  String? exposureTime;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ExifData &&
    other.make == make &&
    other.model == model &&
    other.lens == lens &&
    other.focalLength == focalLength &&
    other.fNumber == fNumber &&
    other.iso == iso &&
    other.exposureTime == exposureTime;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (make == null ? 0 : make!.hashCode) +
    (model == null ? 0 : model!.hashCode) +
    (lens == null ? 0 : lens!.hashCode) +
    (focalLength == null ? 0 : focalLength!.hashCode) +
    (fNumber == null ? 0 : fNumber!.hashCode) +
    (iso == null ? 0 : iso!.hashCode) +
    (exposureTime == null ? 0 : exposureTime!.hashCode);

  @override
  String toString() => 'ExifData[make=$make, model=$model, lens=$lens, focalLength=$focalLength, fNumber=$fNumber, iso=$iso, exposureTime=$exposureTime]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.make != null) {
      json[r'make'] = this.make;
    } else {
      json[r'make'] = null;
    }
    if (this.model != null) {
      json[r'model'] = this.model;
    } else {
      json[r'model'] = null;
    }
    if (this.lens != null) {
      json[r'lens'] = this.lens;
    } else {
      json[r'lens'] = null;
    }
    if (this.focalLength != null) {
      json[r'focal_length'] = this.focalLength;
    } else {
      json[r'focal_length'] = null;
    }
    if (this.fNumber != null) {
      json[r'f_number'] = this.fNumber;
    } else {
      json[r'f_number'] = null;
    }
    if (this.iso != null) {
      json[r'iso'] = this.iso;
    } else {
      json[r'iso'] = null;
    }
    if (this.exposureTime != null) {
      json[r'exposure_time'] = this.exposureTime;
    } else {
      json[r'exposure_time'] = null;
    }
    return json;
  }

  /// Returns a new [ExifData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ExifData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return ExifData(
        make: mapValueOfType<String>(json, r'make'),
        model: mapValueOfType<String>(json, r'model'),
        lens: mapValueOfType<String>(json, r'lens'),
        focalLength: mapValueOfType<double>(json, r'focal_length'),
        fNumber: mapValueOfType<double>(json, r'f_number'),
        iso: mapValueOfType<int>(json, r'iso'),
        exposureTime: mapValueOfType<String>(json, r'exposure_time'),
      );
    }
    return null;
  }

  static List<ExifData> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ExifData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ExifData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ExifData> mapFromJson(dynamic json) {
    final map = <String, ExifData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ExifData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ExifData-objects as value to a dart map
  static Map<String, List<ExifData>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ExifData>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ExifData.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

