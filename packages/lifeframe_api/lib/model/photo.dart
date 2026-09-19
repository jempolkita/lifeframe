//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Photo {
  /// Returns a new [Photo] instance.
  Photo({
    required this.id,
    required this.filename,
    required this.relativePath,
    required this.sizeBytes,
    required this.hashSha256,
    required this.mimeType,
    this.width,
    this.height,
    this.rating = 0,
    this.dateTaken,
    required this.dateModified,
    this.albumId,
    this.tags = const [],
    this.faces = const [],
    this.gps,
    this.exif,
  });

  /// Unique UUID or identifier
  String id;

  /// Original filename e.g. IMG_2026.JPG
  String filename;

  /// Relative file path from root storage
  String relativePath;

  /// File size in bytes
  int sizeBytes;

  /// SHA-256 hash checksum for integrity & deduplication
  String hashSha256;

  /// MIME type e.g. image/jpeg, image/png, image/heic
  String mimeType;

  /// Image width in pixels
  int? width;

  /// Image height in pixels
  int? height;

  /// Star rating (0-5, matching digiKam rating)
  ///
  /// Minimum value: 0
  /// Maximum value: 5
  int rating;

  /// Date captured from EXIF
  DateTime? dateTaken;

  /// File modification timestamp
  DateTime dateModified;

  /// Parent album ID if assigned
  String? albumId;

  /// Keywords and general tags
  List<String> tags;

  /// Detected faces and regions
  List<FaceTag> faces;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  GeoLocation? gps;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ExifData? exif;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Photo &&
    other.id == id &&
    other.filename == filename &&
    other.relativePath == relativePath &&
    other.sizeBytes == sizeBytes &&
    other.hashSha256 == hashSha256 &&
    other.mimeType == mimeType &&
    other.width == width &&
    other.height == height &&
    other.rating == rating &&
    other.dateTaken == dateTaken &&
    other.dateModified == dateModified &&
    other.albumId == albumId &&
    _deepEquality.equals(other.tags, tags) &&
    _deepEquality.equals(other.faces, faces) &&
    other.gps == gps &&
    other.exif == exif;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (filename.hashCode) +
    (relativePath.hashCode) +
    (sizeBytes.hashCode) +
    (hashSha256.hashCode) +
    (mimeType.hashCode) +
    (width == null ? 0 : width!.hashCode) +
    (height == null ? 0 : height!.hashCode) +
    (rating.hashCode) +
    (dateTaken == null ? 0 : dateTaken!.hashCode) +
    (dateModified.hashCode) +
    (albumId == null ? 0 : albumId!.hashCode) +
    (tags.hashCode) +
    (faces.hashCode) +
    (gps == null ? 0 : gps!.hashCode) +
    (exif == null ? 0 : exif!.hashCode);

  @override
  String toString() => 'Photo[id=$id, filename=$filename, relativePath=$relativePath, sizeBytes=$sizeBytes, hashSha256=$hashSha256, mimeType=$mimeType, width=$width, height=$height, rating=$rating, dateTaken=$dateTaken, dateModified=$dateModified, albumId=$albumId, tags=$tags, faces=$faces, gps=$gps, exif=$exif]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'filename'] = this.filename;
      json[r'relative_path'] = this.relativePath;
      json[r'size_bytes'] = this.sizeBytes;
      json[r'hash_sha256'] = this.hashSha256;
      json[r'mime_type'] = this.mimeType;
    if (this.width != null) {
      json[r'width'] = this.width;
    } else {
      json[r'width'] = null;
    }
    if (this.height != null) {
      json[r'height'] = this.height;
    } else {
      json[r'height'] = null;
    }
      json[r'rating'] = this.rating;
    if (this.dateTaken != null) {
      json[r'date_taken'] = this.dateTaken!.toUtc().toIso8601String();
    } else {
      json[r'date_taken'] = null;
    }
      json[r'date_modified'] = this.dateModified.toUtc().toIso8601String();
    if (this.albumId != null) {
      json[r'album_id'] = this.albumId;
    } else {
      json[r'album_id'] = null;
    }
      json[r'tags'] = this.tags;
      json[r'faces'] = this.faces;
    if (this.gps != null) {
      json[r'gps'] = this.gps;
    } else {
      json[r'gps'] = null;
    }
    if (this.exif != null) {
      json[r'exif'] = this.exif;
    } else {
      json[r'exif'] = null;
    }
    return json;
  }

  /// Returns a new [Photo] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Photo? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Photo[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Photo[id]" has a null value in JSON.');
        assert(json.containsKey(r'filename'), 'Required key "Photo[filename]" is missing from JSON.');
        assert(json[r'filename'] != null, 'Required key "Photo[filename]" has a null value in JSON.');
        assert(json.containsKey(r'relative_path'), 'Required key "Photo[relative_path]" is missing from JSON.');
        assert(json[r'relative_path'] != null, 'Required key "Photo[relative_path]" has a null value in JSON.');
        assert(json.containsKey(r'size_bytes'), 'Required key "Photo[size_bytes]" is missing from JSON.');
        assert(json[r'size_bytes'] != null, 'Required key "Photo[size_bytes]" has a null value in JSON.');
        assert(json.containsKey(r'hash_sha256'), 'Required key "Photo[hash_sha256]" is missing from JSON.');
        assert(json[r'hash_sha256'] != null, 'Required key "Photo[hash_sha256]" has a null value in JSON.');
        assert(json.containsKey(r'mime_type'), 'Required key "Photo[mime_type]" is missing from JSON.');
        assert(json[r'mime_type'] != null, 'Required key "Photo[mime_type]" has a null value in JSON.');
        assert(json.containsKey(r'date_modified'), 'Required key "Photo[date_modified]" is missing from JSON.');
        assert(json[r'date_modified'] != null, 'Required key "Photo[date_modified]" has a null value in JSON.');
        return true;
      }());

      return Photo(
        id: mapValueOfType<String>(json, r'id')!,
        filename: mapValueOfType<String>(json, r'filename')!,
        relativePath: mapValueOfType<String>(json, r'relative_path')!,
        sizeBytes: mapValueOfType<int>(json, r'size_bytes')!,
        hashSha256: mapValueOfType<String>(json, r'hash_sha256')!,
        mimeType: mapValueOfType<String>(json, r'mime_type')!,
        width: mapValueOfType<int>(json, r'width'),
        height: mapValueOfType<int>(json, r'height'),
        rating: mapValueOfType<int>(json, r'rating') ?? 0,
        dateTaken: mapDateTime(json, r'date_taken', r''),
        dateModified: mapDateTime(json, r'date_modified', r'')!,
        albumId: mapValueOfType<String>(json, r'album_id'),
        tags: json[r'tags'] is Iterable
            ? (json[r'tags'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        faces: FaceTag.listFromJson(json[r'faces']),
        gps: GeoLocation.fromJson(json[r'gps']),
        exif: ExifData.fromJson(json[r'exif']),
      );
    }
    return null;
  }

  static List<Photo> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Photo>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Photo.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Photo> mapFromJson(dynamic json) {
    final map = <String, Photo>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Photo.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Photo-objects as value to a dart map
  static Map<String, List<Photo>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Photo>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Photo.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'filename',
    'relative_path',
    'size_bytes',
    'hash_sha256',
    'mime_type',
    'date_modified',
  };
}

