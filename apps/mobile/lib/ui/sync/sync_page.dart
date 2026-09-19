import 'package:flutter/material.dart';
import '../../services/discovery_service.dart';
import '../../services/sync_engine.dart';

class SyncPage extends StatefulWidget {
  final VoidCallback? onSyncFinished;
  const SyncPage({super.key, this.onSyncFinished});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final SyncEngine _syncEngine = SyncEngine();
  List<DiscoveredServer> _discoveredServers = [];
  bool _isSearching = false;
  bool _isSyncing = false;
  SyncProgress? _currentProgress;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final servers = await DiscoveryService.discoverServers();
      if (mounted) {
        setState(() {
          _discoveredServers = servers;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Discovery error: $e';
        });
      }
    }
  }

  Future<void> _showManualConnectDialog() async {
    final ipController = TextEditingController();
    final portController = TextEditingController(text: '8080');
    bool isChecking = false;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Server Manually'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter the IP address and port displayed in your Lifeframe Desktop application:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ipController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Desktop IP Address',
                    hintText: 'e.g. 192.168.1.50',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: portController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    hintText: '8080',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    dialogError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isChecking ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isChecking
                    ? null
                    : () async {
                        final ip = ipController.text.trim();
                        final port = int.tryParse(portController.text.trim()) ?? 8080;
                        if (ip.isEmpty) {
                          setDialogState(() => dialogError = 'Please enter a valid IP address.');
                          return;
                        }

                        setDialogState(() {
                          isChecking = true;
                          dialogError = null;
                        });

                        final baseUrl = 'http://$ip:$port';
                        final isHealthy = await DiscoveryService.checkServerHealth(baseUrl);

                        if (!mounted || !ctx.mounted) return;

                        if (isHealthy) {
                          final server = DiscoveredServer(
                            ip: ip,
                            port: port,
                            name: 'Lifeframe Desktop (Manual)',
                            baseUrl: baseUrl,
                          );
                          setState(() {
                            if (!_discoveredServers.any((s) => s.ip == server.ip && s.port == server.port)) {
                              _discoveredServers.insert(0, server);
                            }
                          });
                          Navigator.of(ctx).pop();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Connected to $baseUrl successfully!')),
                            );
                          }
                        } else {
                          setDialogState(() {
                            isChecking = false;
                            dialogError = 'Cannot reach server at $baseUrl/health. Check IP/port and firewall.';
                          });
                        }
                      },
                child: isChecking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Connect'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _triggerSync(DiscoveredServer server) async {
    setState(() {
      _isSyncing = true;
      _errorMessage = null;
    });

    try {
      await _syncEngine.performTwoWaySync(
        server,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _currentProgress = progress;
            });
          }
        },
      );
      widget.onSyncFinished?.call();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sync failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/lifeframe-logo.png',
                width: 26,
                height: 26,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text('LAN Synchronization'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            onPressed: _isSyncing ? null : _showManualConnectDialog,
            tooltip: 'Add Server by IP',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isSyncing || _isSearching ? null : _startDiscovery,
            tooltip: 'Rescan Servers',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Status Card
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wifi, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Local Wi-Fi Discovery',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ensure your mobile phone and Lifeframe Desktop are connected to the same Wi-Fi network.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _isSearching || _isSyncing ? null : _startDiscovery,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isSearching ? 'Searching (LAN)...' : 'Scan for Desktop Server'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isSyncing ? null : _showManualConnectDialog,
                        icon: const Icon(Icons.add_link),
                        label: const Text('Add by IP'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Error notification
          if (_errorMessage != null) ...[
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Sync Progress Card
          if (_isSyncing || _currentProgress != null) ...[
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sync Status',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_currentProgress != null)
                          Text(
                            '${(_currentProgress!.progress * 100).toInt()}%',
                            style: theme.textTheme.labelMedium?.copyWith(fontFamily: 'monospace'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _currentProgress?.progress,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentProgress?.status ?? 'Preparing...',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Discovered Servers Section
          Text(
            'Discovered Servers (${_discoveredServers.length})',
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),

          if (_discoveredServers.isEmpty && !_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.desktop_access_disabled, size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    Text(
                      'No Lifeframe Desktop servers found.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._discoveredServers.map((server) {
              return Card.outlined(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.computer),
                  ),
                  title: Text(server.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${server.ip}:${server.port}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: _isSyncing ? null : () => _triggerSync(server),
                    child: const Text('Sync Now'),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
