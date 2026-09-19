import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../../services/sync_engine.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => GalleryPageState();
}

class GalleryPageState extends State<GalleryPage> {
  final SyncEngine _syncEngine = SyncEngine();
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final photos = await _syncEngine.getAllPhotosSorted();
      if (mounted) {
        setState(() {
          _photos = photos;
          _errorMessage = null;
        });
      }
    } catch (e, stack) {
      debugPrint('Error loading photos: $e\n$stack');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load local photos: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lifeframe Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadPhotos,
            tooltip: 'Refresh Gallery',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState(theme)
              : _photos.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildPhotoGrid(theme),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error Loading Gallery',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: loadPhotos,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 72, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No Synced Photos',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover and sync with your Lifeframe Desktop server in the Sync tab to view photos here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        final localPath = photo['local_path'] as String? ?? '';
        final file = File(localPath);

        return GestureDetector(
          onTap: () => _openPhotoViewer(context, file, photo['filename'] ?? ''),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: file.existsSync()
                  ? Image.file(
                      file,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Icon(
                        Icons.broken_image,
                        color: theme.colorScheme.error,
                      ),
                    )
                  : Icon(
                      Icons.image_not_supported,
                      color: theme.colorScheme.outline,
                    ),
            ),
          ),
        );
      },
    );
  }

  void _openPhotoViewer(BuildContext context, File file, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          backgroundColor: Colors.black,
          body: PhotoView(
            imageProvider: FileImage(file),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.5,
          ),
        ),
      ),
    );
  }
}
