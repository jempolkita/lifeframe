//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SyncManifest {
  /// Returns a new [SyncManifest] instance.
  SyncManifest({
    required this.serverId,
    required this.serverName,
    required this.generatedAt,
    required this.totalPhotos,
    required this.totalSizeBytes,
    this.photos = const [],
    this.albums = const [],
    this.people = const [],
  });

  String serverId;

  String serverName;

  DateTime generatedAt;

  int totalPhotos;

  int totalSizeBytes;

  List<Photo> photos;

  List<Album> albums;

  List<Person> people;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SyncManifest &&
    other.serverId == serverId &&
    other.serverName == serverName &&
    other.generatedAt == generatedAt &&
    other.totalPhotos == totalPhotos &&
    other.totalSizeBytes == totalSizeBytes &&
    _deepEquality.equals(other.photos, photos) &&
    _deepEquality.equals(other.albums, albums) &&
    _deepEquality.equals(other.people, people);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (serverId.hashCode) +
    (serverName.hashCode) +
    (generatedAt.hashCode) +
    (totalPhotos.hashCode) +
    (totalSizeBytes.hashCode) +
    (photos.hashCode) +
    (albums.hashCode) +
    (people.hashCode);

  @override
  String toString() => 'SyncManifest[serverId=$serverId, serverName=$serverName, generatedAt=$generatedAt, totalPhotos=$totalPhotos, totalSizeBytes=$totalSizeBytes, photos=$photos, albums=$albums, people=$people]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'server_id'] = this.serverId;
      json[r'server_name'] = this.serverName;
      json[r'generated_at'] = this.generatedAt.toUtc().toIso8601String();
      json[r'total_photos'] = this.totalPhotos;
      json[r'total_size_bytes'] = this.totalSizeBytes;
      json[r'photos'] = this.photos;
      json[r'albums'] = this.albums;
      json[r'people'] = this.people;
    return json;
  }

  /// Returns a new [SyncManifest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SyncManifest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'server_id'), 'Required key "SyncManifest[server_id]" is missing from JSON.');
        assert(json[r'server_id'] != null, 'Required key "SyncManifest[server_id]" has a null value in JSON.');
        assert(json.containsKey(r'server_name'), 'Required key "SyncManifest[server_name]" is missing from JSON.');
        assert(json[r'server_name'] != null, 'Required key "SyncManifest[server_name]" has a null value in JSON.');
        assert(json.containsKey(r'generated_at'), 'Required key "SyncManifest[generated_at]" is missing from JSON.');
        assert(json[r'generated_at'] != null, 'Required key "SyncManifest[generated_at]" has a null value in JSON.');
        assert(json.containsKey(r'total_photos'), 'Required key "SyncManifest[total_photos]" is missing from JSON.');
        assert(json[r'total_photos'] != null, 'Required key "SyncManifest[total_photos]" has a null value in JSON.');
        assert(json.containsKey(r'total_size_bytes'), 'Required key "SyncManifest[total_size_bytes]" is missing from JSON.');
        assert(json[r'total_size_bytes'] != null, 'Required key "SyncManifest[total_size_bytes]" has a null value in JSON.');
        assert(json.containsKey(r'photos'), 'Required key "SyncManifest[photos]" is missing from JSON.');
        assert(json[r'photos'] != null, 'Required key "SyncManifest[photos]" has a null value in JSON.');
        assert(json.containsKey(r'albums'), 'Required key "SyncManifest[albums]" is missing from JSON.');
        assert(json[r'albums'] != null, 'Required key "SyncManifest[albums]" has a null value in JSON.');
        return true;
      }());

      return SyncManifest(
        serverId: mapValueOfType<String>(json, r'server_id')!,
        serverName: mapValueOfType<String>(json, r'server_name')!,
        generatedAt: mapDateTime(json, r'generated_at', r'')!,
        totalPhotos: mapValueOfType<int>(json, r'total_photos')!,
        totalSizeBytes: mapValueOfType<int>(json, r'total_size_bytes')!,
        photos: Photo.listFromJson(json[r'photos']),
        albums: Album.listFromJson(json[r'albums']),
        people: Person.listFromJson(json[r'people']),
      );
    }
    return null;
  }

  static List<SyncManifest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SyncManifest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SyncManifest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SyncManifest> mapFromJson(dynamic json) {
    final map = <String, SyncManifest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SyncManifest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SyncManifest-objects as value to a dart map
  static Map<String, List<SyncManifest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SyncManifest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SyncManifest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'server_id',
    'server_name',
    'generated_at',
    'total_photos',
    'total_size_bytes',
    'photos',
    'albums',
  };
}

