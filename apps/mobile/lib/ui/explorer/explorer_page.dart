import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../../services/sync_engine.dart';

class ExplorerPage extends StatefulWidget {
  final String initialPath;
  
  const ExplorerPage({super.key, this.initialPath = ''});

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  final SyncEngine _syncEngine = SyncEngine();
  List<String> _folders = [];
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _syncEngine.getExplorerItems(widget.initialPath);
      if (mounted) {
        setState(() {
          _folders = List<String>.from(items['folders']);
          _photos = List<Map<String, dynamic>>.from(items['photos']);
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load directory: $e';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRoot = widget.initialPath.isEmpty;
    final title = isRoot ? 'Explorer' : widget.initialPath.split('/').last;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error)))
              : (_folders.isEmpty && _photos.isEmpty)
                  ? const Center(child: Text('Empty folder'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _folders.length + _photos.length,
                      itemBuilder: (context, index) {
                        if (index < _folders.length) {
                          // Render Folder Card
                          final folderName = _folders[index];
                          final nextPath = isRoot ? folderName : '${widget.initialPath}/$folderName';
                          
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ExplorerPage(initialPath: nextPath),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 0,
                              color: theme.colorScheme.surfaceContainerHighest,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.folder, size: 48, color: theme.colorScheme.primary),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      folderName,
                                      style: theme.textTheme.labelMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          // Render Photo Card
                          final photo = _photos[index - _folders.length];
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
                                        errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, color: theme.colorScheme.error),
                                      )
                                    : Icon(Icons.image_not_supported, color: theme.colorScheme.outline),
                              ),
                            ),
                          );
                        }
                      },
                    ),
    );
  }
}
