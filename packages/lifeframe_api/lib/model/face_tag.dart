//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FaceTag {
  /// Returns a new [FaceTag] instance.
  FaceTag({
    required this.id,
    this.personId,
    this.personName,
    this.confidence,
    this.isConfirmed = false,
    required this.box,
  });

  /// Unique face detection ID
  String id;

  /// ID of identified person if assigned
  String? personId;

  /// Recognized or labeled person name
  String? personName;

  /// Detection confidence score (0.0 to 1.0)
  double? confidence;

  /// Whether verified by user or auto-detected by AI
  bool isConfirmed;

  BoundingBox box;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FaceTag &&
    other.id == id &&
    other.personId == personId &&
    other.personName == personName &&
    other.confidence == confidence &&
    other.isConfirmed == isConfirmed &&
    other.box == box;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (personId == null ? 0 : personId!.hashCode) +
    (personName == null ? 0 : personName!.hashCode) +
    (confidence == null ? 0 : confidence!.hashCode) +
    (isConfirmed.hashCode) +
    (box.hashCode);

  @override
  String toString() => 'FaceTag[id=$id, personId=$personId, personName=$personName, confidence=$confidence, isConfirmed=$isConfirmed, box=$box]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
    if (this.personId != null) {
      json[r'person_id'] = this.personId;
    } else {
      json[r'person_id'] = null;
    }
    if (this.personName != null) {
      json[r'person_name'] = this.personName;
    } else {
      json[r'person_name'] = null;
    }
    if (this.confidence != null) {
      json[r'confidence'] = this.confidence;
    } else {
      json[r'confidence'] = null;
    }
      json[r'is_confirmed'] = this.isConfirmed;
      json[r'box'] = this.box;
    return json;
  }

  /// Returns a new [FaceTag] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FaceTag? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "FaceTag[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "FaceTag[id]" has a null value in JSON.');
        assert(json.containsKey(r'box'), 'Required key "FaceTag[box]" is missing from JSON.');
        assert(json[r'box'] != null, 'Required key "FaceTag[box]" has a null value in JSON.');
        return true;
      }());

      return FaceTag(
        id: mapValueOfType<String>(json, r'id')!,
        personId: mapValueOfType<String>(json, r'person_id'),
        personName: mapValueOfType<String>(json, r'person_name'),
        confidence: mapValueOfType<double>(json, r'confidence'),
        isConfirmed: mapValueOfType<bool>(json, r'is_confirmed') ?? false,
        box: BoundingBox.fromJson(json[r'box'])!,
      );
    }
    return null;
  }

  static List<FaceTag> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FaceTag>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FaceTag.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FaceTag> mapFromJson(dynamic json) {
    final map = <String, FaceTag>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FaceTag.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FaceTag-objects as value to a dart map
  static Map<String, List<FaceTag>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FaceTag>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FaceTag.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'box',
  };
}

