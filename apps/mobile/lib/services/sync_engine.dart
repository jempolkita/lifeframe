import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:lifeframe_api/api.dart';

import 'discovery_service.dart';

class SyncProgress {
  final double progress; // 0.0 to 1.0
  final String status;
  final String? currentItem;
  final int completedOps;
  final int totalOps;

  SyncProgress({
    required this.progress,
    required this.status,
    this.currentItem,
    required this.completedOps,
    required this.totalOps,
  });
}

class SyncEngine {
  static const String dbName = 'lifeframe_mobile.db';
  static final SyncEngine _instance = SyncEngine._internal();
  factory SyncEngine() => _instance;
  SyncEngine._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(docsDir.path, dbName);

      return await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS local_photos (
              id TEXT PRIMARY KEY,
              filename TEXT NOT NULL,
              relative_path TEXT NOT NULL UNIQUE,
              size_bytes INTEGER NOT NULL,
              hash_sha256 TEXT NOT NULL,
              date_taken TEXT,
              date_modified TEXT NOT NULL,
              local_path TEXT NOT NULL
            )
          ''');
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('SyncEngine database initialization error: $e');
      rethrow;
    }
  }

  /// Get the root storage directory for synced photos
  Future<Directory> getPhotosDirectory() async {
    Directory? baseDir;
    try {
      baseDir = await getExternalStorageDirectory();
    } catch (_) {}
    baseDir ??= await getApplicationDocumentsDirectory();

    final photoDir = Directory(p.join(baseDir.path, 'Lifeframe'));
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    return photoDir;
  }

  /// Send device telemetry to Desktop server
  Future<void> sendDeviceTelemetry(String baseUrl, String syncState) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceName = 'Mobile Client';
      String deviceType = 'mobile_android';

      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        deviceName = '${info.manufacturer} ${info.model}';
        deviceType = 'mobile_android';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        deviceName = info.name;
        deviceType = 'mobile_ios';
      }

      final uri = Uri.parse('$baseUrl/api/device-status');
      final payload = jsonEncode({
        'device_id': deviceName.replaceAll(' ', '-').toLowerCase(),
        'device_name': deviceName,
        'device_type': deviceType,
        'client_version': '1.0.0',
        'last_sync_at': DateTime.now().toUtc().toIso8601String(),
        'sync_status': syncState,
      });

      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );
    } catch (_) {
      // Non-critical telemetry failure
    }
  }

  /// Fetches strongly-typed manifest from Desktop
  Future<SyncManifest?> fetchRemoteManifest(String baseUrl) async {
    try {
      final uri = Uri.parse('$baseUrl/api/manifest');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return SyncManifest.fromJson(json);
      }
    } catch (e) {
      // Failed to retrieve manifest
    }
    return null;
  }

  /// Query all locally indexed photos from SQLite (Legacy)
  Future<List<Map<String, dynamic>>> getLocalIndexedPhotos() async {
    final db = await database;
    return await db.query('local_photos');
  }

  /// Tab 1 (Photos): Get all photos sorted by date descending
  Future<List<Map<String, dynamic>>> getAllPhotosSorted() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM local_photos 
      ORDER BY COALESCE(date_taken, date_modified) DESC
    ''');
  }

  /// Tab 2 (Explorer): Get child folders and photos for a given parent_path
  Future<Map<String, dynamic>> getExplorerItems(String parentPath) async {
    final db = await database;
    // We fetch all and process in Dart for cross-platform consistency and simplicity.
    // For very large datasets, this might be optimized to pure SQL in the future.
    final rows = await db.query('local_photos');
    
    final Set<String> folders = {};
    final List<Map<String, dynamic>> photos = [];
    
    final prefix = parentPath.isEmpty ? '' : '$parentPath/';
    
    for (final row in rows) {
      final path = row['relative_path'] as String;
      if (path.startsWith(prefix)) {
        final remainder = path.substring(prefix.length);
        if (remainder.contains('/')) {
          // It's in a subfolder
          final folderName = remainder.split('/').first;
          folders.add(folderName);
        } else {
          // It's a photo directly in the current directory
          photos.add(row);
        }
      }
    }
    
    return {
      'folders': folders.toList()..sort(),
      'photos': photos,
    };
  }

  /// Tab 3 (Albums): Get distinct folder paths and their cover photo/item counts
  Future<List<Map<String, dynamic>>> getAlbums() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT * FROM local_photos 
      ORDER BY COALESCE(date_taken, date_modified) DESC
    ''');
    
    final Map<String, Map<String, dynamic>> albums = {};
    
    for (final row in rows) {
      final path = row['relative_path'] as String;
      
      final lastSlash = path.lastIndexOf('/');
      final folderPath = lastSlash != -1 ? path.substring(0, lastSlash) : 'Root';
      final folderName = folderPath == 'Root' ? 'Root' : folderPath.split('/').last;
      
      if (!albums.containsKey(folderPath)) {
        albums[folderPath] = {
          'path': folderPath,
          'name': folderName,
          'count': 0,
          'cover_photo': row,
        };
      }
      albums[folderPath]!['count'] = (albums[folderPath]!['count'] as int) + 1;
    }
    
    final albumList = albums.values.toList();
    albumList.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return albumList;
  }

  /// Executes Two-Way Synchronization with the Desktop Server
  Future<void> performTwoWaySync(
    DiscoveredServer server, {
    required void Function(SyncProgress) onProgress,
  }) async {
    final baseUrl = server.baseUrl;
    final photosDir = await getPhotosDirectory();

    onProgress(SyncProgress(
      progress: 0.05,
      status: 'Connecting and sending device status...',
      completedOps: 0,
      totalOps: 1,
    ));

    await sendDeviceTelemetry(baseUrl, 'syncing');

    onProgress(SyncProgress(
      progress: 0.1,
      status: 'Fetching manifest from Desktop server...',
      completedOps: 0,
      totalOps: 1,
    ));

    final remoteManifest = await fetchRemoteManifest(baseUrl);
    if (remoteManifest == null) {
      throw Exception('Failed to retrieve manifest from ${server.baseUrl}');
    }

    final localRows = await getLocalIndexedPhotos();
    final localMap = {for (final row in localRows) row['relative_path'] as String: row};

    // Calculate files to download (on server, missing or hash mismatch locally)
    final List<Photo> filesToDownload = [];
    for (final remotePhoto in remoteManifest.photos) {
      final local = localMap[remotePhoto.relativePath];
      if (local == null || local['hash_sha256'] != remotePhoto.hashSha256) {
        filesToDownload.add(remotePhoto);
      }
    }

    final totalOps = filesToDownload.length;
    int completedOps = 0;

    onProgress(SyncProgress(
      progress: totalOps == 0 ? 1.0 : 0.2,
      status: totalOps == 0 ? 'Everything is up to date!' : 'Syncing $totalOps photos...',
      completedOps: 0,
      totalOps: totalOps,
    ));

    final db = await database;

    for (final photo in filesToDownload) {
      onProgress(SyncProgress(
        progress: (completedOps / (totalOps == 0 ? 1 : totalOps)).clamp(0.0, 0.95),
        status: 'Downloading ${photo.filename} ($completedOps/$totalOps)',
        currentItem: photo.filename,
        completedOps: completedOps,
        totalOps: totalOps,
      ));

      final downloadUrl = Uri.parse('$baseUrl/image?path=${Uri.encodeComponent(photo.relativePath)}');
      final res = await http.get(downloadUrl);

      if (res.statusCode == 200) {
        final targetFile = File(p.join(photosDir.path, photo.relativePath));
        await targetFile.parent.create(recursive: true);
        await targetFile.writeAsBytes(res.bodyBytes);

        // Record in local SQLite
        await db.insert(
          'local_photos',
          {
            'id': photo.id,
            'filename': photo.filename,
            'relative_path': photo.relativePath,
            'size_bytes': photo.sizeBytes,
            'hash_sha256': photo.hashSha256,
            'date_taken': photo.dateTaken?.toIso8601String(),
            'date_modified': photo.dateModified.toIso8601String(),
            'local_path': targetFile.path,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      completedOps++;
    }

    await sendDeviceTelemetry(baseUrl, 'idle');

    onProgress(SyncProgress(
      progress: 1.0,
      status: 'Sync completed successfully! ($completedOps photos synced)',
      completedOps: completedOps,
      totalOps: totalOps,
    ));
  }

  /// Calculates SHA-256 for a local file
  Future<String> computeSha256(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }
}
