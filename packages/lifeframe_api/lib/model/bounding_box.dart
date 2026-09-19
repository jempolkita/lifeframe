//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BoundingBox {
  /// Returns a new [BoundingBox] instance.
  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Top-left X coordinate normalized (0.0 to 1.0)
  double x;

  /// Top-left Y coordinate normalized (0.0 to 1.0)
  double y;

  /// Bounding box width normalized (0.0 to 1.0)
  double width;

  /// Bounding box height normalized (0.0 to 1.0)
  double height;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BoundingBox &&
    other.x == x &&
    other.y == y &&
    other.width == width &&
    other.height == height;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (x.hashCode) +
    (y.hashCode) +
    (width.hashCode) +
    (height.hashCode);

  @override
  String toString() => 'BoundingBox[x=$x, y=$y, width=$width, height=$height]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'x'] = this.x;
      json[r'y'] = this.y;
      json[r'width'] = this.width;
      json[r'height'] = this.height;
    return json;
  }

  /// Returns a new [BoundingBox] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BoundingBox? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'x'), 'Required key "BoundingBox[x]" is missing from JSON.');
        assert(json[r'x'] != null, 'Required key "BoundingBox[x]" has a null value in JSON.');
        assert(json.containsKey(r'y'), 'Required key "BoundingBox[y]" is missing from JSON.');
        assert(json[r'y'] != null, 'Required key "BoundingBox[y]" has a null value in JSON.');
        assert(json.containsKey(r'width'), 'Required key "BoundingBox[width]" is missing from JSON.');
        assert(json[r'width'] != null, 'Required key "BoundingBox[width]" has a null value in JSON.');
        assert(json.containsKey(r'height'), 'Required key "BoundingBox[height]" is missing from JSON.');
        assert(json[r'height'] != null, 'Required key "BoundingBox[height]" has a null value in JSON.');
        return true;
      }());

      return BoundingBox(
        x: mapValueOfType<double>(json, r'x')!,
        y: mapValueOfType<double>(json, r'y')!,
        width: mapValueOfType<double>(json, r'width')!,
        height: mapValueOfType<double>(json, r'height')!,
      );
    }
    return null;
  }

  static List<BoundingBox> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BoundingBox>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BoundingBox.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BoundingBox> mapFromJson(dynamic json) {
    final map = <String, BoundingBox>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BoundingBox.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BoundingBox-objects as value to a dart map
  static Map<String, List<BoundingBox>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BoundingBox>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BoundingBox.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'x',
    'y',
    'width',
    'height',
  };
}

