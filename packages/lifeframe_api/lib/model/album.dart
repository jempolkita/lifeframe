//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Album {
  /// Returns a new [Album] instance.
  Album({
    required this.id,
    required this.name,
    required this.relativePath,
    required this.photoCount,
  });

  String id;

  String name;

  String relativePath;

  int photoCount;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Album &&
    other.id == id &&
    other.name == name &&
    other.relativePath == relativePath &&
    other.photoCount == photoCount;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (relativePath.hashCode) +
    (photoCount.hashCode);

  @override
  String toString() => 'Album[id=$id, name=$name, relativePath=$relativePath, photoCount=$photoCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'relative_path'] = this.relativePath;
      json[r'photo_count'] = this.photoCount;
    return json;
  }

  /// Returns a new [Album] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Album? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Album[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Album[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "Album[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "Album[name]" has a null value in JSON.');
        assert(json.containsKey(r'relative_path'), 'Required key "Album[relative_path]" is missing from JSON.');
        assert(json[r'relative_path'] != null, 'Required key "Album[relative_path]" has a null value in JSON.');
        assert(json.containsKey(r'photo_count'), 'Required key "Album[photo_count]" is missing from JSON.');
        assert(json[r'photo_count'] != null, 'Required key "Album[photo_count]" has a null value in JSON.');
        return true;
      }());

      return Album(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        relativePath: mapValueOfType<String>(json, r'relative_path')!,
        photoCount: mapValueOfType<int>(json, r'photo_count')!,
      );
    }
    return null;
  }

  static List<Album> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Album>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Album.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Album> mapFromJson(dynamic json) {
    final map = <String, Album>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Album.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Album-objects as value to a dart map
  static Map<String, List<Album>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Album>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Album.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'relative_path',
    'photo_count',
  };
}

