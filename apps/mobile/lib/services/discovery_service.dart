import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:udp/udp.dart';

class DiscoveredServer {
  final String ip;
  final int port;
  final String name;
  final String? serverId;
  final String baseUrl;

  DiscoveredServer({
    required this.ip,
    required this.port,
    required this.name,
    this.serverId,
    required this.baseUrl,
  });

  @override
  String toString() => '$name ($ip:$port)';
}

class DiscoveryService {
  /// Unified discovery: runs mDNS and UDP broadcast fallback concurrently
  static Future<List<DiscoveredServer>> discoverServers({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final List<DiscoveredServer> found = [];

    final results = await Future.wait([
      discoverMdns(timeout: timeout).catchError((e) {
        debugPrint('discoverMdns caught error: $e');
        return <DiscoveredServer>[];
      }),
      discoverUdp().catchError((e) {
        debugPrint('discoverUdp caught error: $e');
        return <DiscoveredServer>[];
      }),
    ]);

    for (final serverList in results) {
      for (final server in serverList) {
        if (!found.any((s) => s.ip == server.ip && s.port == server.port)) {
          found.add(server);
        }
      }
    }

    return found;
  }

  /// Discovers active Lifeframe Desktop servers broadcasting via mDNS (_http._tcp.local)
  static Future<List<DiscoveredServer>> discoverMdns({Duration timeout = const Duration(seconds: 4)}) async {
    // Custom socket factory to override reusePort on Android/Linux.
    // Dart runtime on Android throws "reusePort not supported on this platform" if reusePort is true.
    final MDnsClient client = MDnsClient(
      rawDatagramSocketFactory: (
        dynamic host,
        int port, {
        bool reuseAddress = true,
        bool reusePort = false,
        int ttl = 1,
      }) =>
          RawDatagramSocket.bind(
            host,
            port,
            reuseAddress: reuseAddress,
            reusePort: false, // Explicitly false for Android compatibility
            ttl: ttl,
          ),
    );
    final List<DiscoveredServer> found = [];

    try {
      await client.start();

      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_http._tcp.local'),
      ).timeout(timeout, onTimeout: (sink) => sink.close())) {
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        ).timeout(const Duration(seconds: 2), onTimeout: (sink) => sink.close())) {
          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          ).timeout(const Duration(seconds: 2), onTimeout: (sink) => sink.close())) {
            String name = 'Lifeframe Desktop';
            String? serverId;

            // Read TXT records for server info
            try {
              await for (final TxtResourceRecord txt in client.lookup<TxtResourceRecord>(
                ResourceRecordQuery.text(ptr.domainName),
              ).timeout(const Duration(seconds: 1), onTimeout: (sink) => sink.close())) {
                for (final line in txt.text.split('\n')) {
                  if (line.startsWith('name=')) {
                    name = line.substring(5);
                  } else if (line.startsWith('server_id=')) {
                    serverId = line.substring(10);
                  }
                }
              }
            } catch (_) {}

            final ipAddress = ip.address.address;
            final server = DiscoveredServer(
              ip: ipAddress,
              port: srv.port,
              name: name,
              serverId: serverId,
              baseUrl: 'http://$ipAddress:${srv.port}',
            );

            if (!found.any((s) => s.ip == server.ip && s.port == server.port)) {
              found.add(server);
            }
          }
        }
      }
    } catch (e, stack) {
      debugPrint('mDNS discovery error: $e\n$stack');
    } finally {
      client.stop();
    }

    return found;
  }

  /// Verifies connectivity by calling /health endpoint on the discovered server
  static Future<bool> checkServerHealth(String baseUrl, {Duration timeout = const Duration(seconds: 2)}) async {
    try {
      final client = HttpClient()..connectionTimeout = timeout;
      final uri = Uri.parse('$baseUrl/health');
      final request = await client.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// UDP broadcast discovery fallback
  static Future<List<DiscoveredServer>> discoverUdp({int port = 8081}) async {
    final List<DiscoveredServer> found = [];
    try {
      final sender = await UDP.bind(Endpoint.any(port: const Port(0)));
      await sender.send('LIFEFRAME_DISCOVERY'.codeUnits, Endpoint.broadcast(port: Port(port)));

      await for (final datagram in sender.asStream(timeout: const Duration(seconds: 2))) {
        if (datagram != null) {
          try {
            final json = jsonDecode(String.fromCharCodes(datagram.data));
            final ip = json['ip'] ?? datagram.address.address;
            final serverPort = json['port'] ?? 8080;
            final name = json['name'] ?? 'Lifeframe Desktop';
            final serverId = json['server_id'];

            final server = DiscoveredServer(
              ip: ip,
              port: serverPort,
              name: name,
              serverId: serverId,
              baseUrl: 'http://$ip:$serverPort',
            );

            if (!found.any((s) => s.ip == server.ip && s.port == server.port)) {
              found.add(server);
            }
          } catch (_) {}
        }
      }
      sender.close();
    } catch (e) {
      debugPrint('UDP broadcast discovery error: $e');
    }
    return found;
  }
}
