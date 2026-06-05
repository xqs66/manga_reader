import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/models/discovered_server.dart';

void main() {
  group('DiscoveredServer', () {
    test('baseUrl is constructed correctly', () {
      const server = DiscoveredServer(
        host: '192.168.1.100',
        port: 9090,
        token: 'abc123',
        deviceName: 'Test PC',
      );
      expect(server.baseUrl, 'http://192.168.1.100:9090');
    });

    test('displayName uses deviceName when set', () {
      const server = DiscoveredServer(
        host: '192.168.1.100',
        port: 9090,
        token: '',
        deviceName: 'My PC',
      );
      expect(server.displayName, 'My PC');
    });

    test('displayName falls back to host when deviceName is empty', () {
      const server = DiscoveredServer(
        host: '192.168.1.100',
        port: 9090,
        token: '',
        deviceName: '',
      );
      expect(server.displayName, '192.168.1.100');
    });

    test('copyWith updates fields correctly', () {
      const original = DiscoveredServer(
        host: '192.168.1.100',
        port: 9090,
        token: 'old',
        deviceName: 'Old PC',
      );

      final updated = original.copyWith(
        token: 'new',
        isConnected: true,
      );

      expect(updated.host, '192.168.1.100');
      expect(updated.port, 9090);
      expect(updated.token, 'new');
      expect(updated.deviceName, 'Old PC');
      expect(updated.isConnected, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      final now = DateTime.now();
      final original = DiscoveredServer(
        host: '192.168.1.100',
        port: 9090,
        token: 'token',
        deviceName: 'PC',
        lastConnectedAt: now,
        isConnected: true,
        version: '1.0.0',
      );

      final updated = original.copyWith(host: '10.0.0.1');

      expect(updated.host, '10.0.0.1');
      expect(updated.port, 9090);
      expect(updated.lastConnectedAt, now);
      expect(updated.isConnected, isTrue);
    });

    test('equality is based on host and port only', () {
      const a = DiscoveredServer(
        host: '192.168.1.100',
        port: 9090,
        token: 'a',
        deviceName: 'A',
      );
      const b = DiscoveredServer(
        host: '192.168.1.100',
        port: 9090,
        token: 'b',
        deviceName: 'B',
      );
      const c = DiscoveredServer(
        host: '192.168.1.101',
        port: 9090,
        token: 'a',
        deviceName: 'A',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      const a = DiscoveredServer(host: '192.168.1.100', port: 9090, token: 'a', deviceName: 'A');
      const b = DiscoveredServer(host: '192.168.1.100', port: 9090, token: 'b', deviceName: 'B');

      expect(a.hashCode, equals(b.hashCode));
    });

    group('JSON serialization', () {
      test('toJson and fromJson round-trip', () {
        final server = DiscoveredServer(
          host: '192.168.1.100',
          port: 9090,
          token: '123456',
          deviceName: 'TestPC',
          version: '1.0.0',
          lastConnectedAt: DateTime.utc(2026, 6, 1, 12, 0, 0),
        );

        final json = server.toJson();
        final restored = DiscoveredServer.fromJson(json);

        expect(restored.host, server.host);
        expect(restored.port, server.port);
        expect(restored.token, server.token);
        expect(restored.deviceName, server.deviceName);
        expect(restored.version, server.version);
        expect(restored.lastConnectedAt?.millisecondsSinceEpoch,
            server.lastConnectedAt!.millisecondsSinceEpoch);
      });

      test('fromJson handles missing optional fields', () {
        final restored = DiscoveredServer.fromJson({
          'host': '10.0.0.1',
          'port': 8080,
        });

        expect(restored.host, '10.0.0.1');
        expect(restored.port, 8080);
        expect(restored.token, '');
        expect(restored.deviceName, '');
        expect(restored.version, '1.0.0');
        expect(restored.lastConnectedAt, isNull);
      });

      test('toJson skips null lastConnectedAt', () {
        const server = DiscoveredServer(
          host: '192.168.1.100',
          port: 9090,
          token: '',
          deviceName: '',
        );

        final json = server.toJson();
        expect(json['lastConnectedAt'], isNull);
      });

      test('toJson includes isConnected false', () {
        const server = DiscoveredServer(
          host: '192.168.1.100',
          port: 9090,
          token: '',
          deviceName: '',
        );

        // isConnected is not serialized (transient state)
        final json = server.toJson();
        expect(json.containsKey('isConnected'), isFalse);
      });
    });
  });
}
