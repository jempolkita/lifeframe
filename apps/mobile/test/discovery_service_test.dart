import 'package:flutter_test/flutter_test.dart';
import 'package:digikam_sync_mobile_app/services/discovery_service.dart';

void main() {
  group('DiscoveredServer tests', () {
    test('DiscoveredServer properties and toString', () {
      final server = DiscoveredServer(
        ip: '192.168.1.100',
        port: 8080,
        name: 'Lifeframe Desktop (Studio)',
        serverId: 'srv-123',
        baseUrl: 'http://192.168.1.100:8080',
      );

      expect(server.ip, '192.168.1.100');
      expect(server.port, 8080);
      expect(server.name, 'Lifeframe Desktop (Studio)');
      expect(server.serverId, 'srv-123');
      expect(server.baseUrl, 'http://192.168.1.100:8080');
      expect(server.toString(), 'Lifeframe Desktop (Studio) (192.168.1.100:8080)');
    });
  });
}
