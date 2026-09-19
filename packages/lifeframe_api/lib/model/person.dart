//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Person {
  /// Returns a new [Person] instance.
  Person({
    required this.id,
    required this.name,
    this.thumbnailFaceId,
    this.photoCount = 0,
  });

  /// Unique person identifier
  String id;

  /// Person full name or label
  String name;

  /// Face tag ID used as avatar
  String? thumbnailFaceId;

  /// Number of photos tagged with this person
  int photoCount;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Person &&
    other.id == id &&
    other.name == name &&
    other.thumbnailFaceId == thumbnailFaceId &&
    other.photoCount == photoCount;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (thumbnailFaceId == null ? 0 : thumbnailFaceId!.hashCode) +
    (photoCount.hashCode);

  @override
  String toString() => 'Person[id=$id, name=$name, thumbnailFaceId=$thumbnailFaceId, photoCount=$photoCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
    if (this.thumbnailFaceId != null) {
      json[r'thumbnail_face_id'] = this.thumbnailFaceId;
    } else {
      json[r'thumbnail_face_id'] = null;
    }
      json[r'photo_count'] = this.photoCount;
    return json;
  }

  /// Returns a new [Person] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Person? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Person[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Person[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "Person[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "Person[name]" has a null value in JSON.');
        return true;
      }());

      return Person(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        thumbnailFaceId: mapValueOfType<String>(json, r'thumbnail_face_id'),
        photoCount: mapValueOfType<int>(json, r'photo_count') ?? 0,
      );
    }
    return null;
  }

  static List<Person> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Person>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Person.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Person> mapFromJson(dynamic json) {
    final map = <String, Person>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Person.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Person-objects as value to a dart map
  static Map<String, List<Person>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Person>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Person.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
  };
}

