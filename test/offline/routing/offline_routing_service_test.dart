import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/config/transport_mode.dart';
import 'package:qorvia_maps_sdk/src/models/coordinates.dart';
import 'package:qorvia_maps_sdk/src/offline/routing/offline_routing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineRoutingService', () {
    late OfflineRoutingService service;
    late List<MethodCall> log;

    setUp(() {
      log = [];
      service = OfflineRoutingService();

      // Set up mock method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        OfflineRoutingService.channel,
        (MethodCall methodCall) async {
          log.add(methodCall);

          switch (methodCall.method) {
            case 'loadGraph':
              return {'success': true};
            case 'unloadGraph':
              return null;
            case 'isGraphLoaded':
              final regionId = methodCall.arguments['regionId'] as String;
              return regionId == 'loaded-region';
            case 'getLoadedGraphs':
              return ['region1', 'region2'];
            case 'getGraphInfo':
              return {
                'regionId': 'test-region',
                'profiles': ['car', 'bike', 'foot'],
                'nodeCount': 1000,
                'edgeCount': 2000,
                'bounds': {
                  'minLat': 55.5,
                  'minLon': 37.3,
                  'maxLat': 56.0,
                  'maxLon': 38.0,
                },
              };
            case 'calculateRoute':
              return {
                'success': true,
                'distance': 5000.0,
                'time': 600000.0, // 10 minutes in ms
                'points': [
                  [55.7558, 37.6173],
                  [55.7500, 37.6000],
                  [55.7000, 37.5000],
                ],
                'instructions': [
                  {
                    'text': 'Head north on Main St',
                    'distance': 2000.0,
                    'time': 300000.0,
                    'sign': 0,
                    'streetName': 'Main St',
                  },
                  {
                    'text': 'Turn left onto Oak Ave',
                    'distance': 3000.0,
                    'time': 300000.0,
                    'sign': -2,
                    'streetName': 'Oak Ave',
                  },
                ],
              };
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(OfflineRoutingService.channel, null);
    });

    test('creates with optional logger', () {
      final logs = <String>[];
      final serviceWithLogger = OfflineRoutingService(
        logger: (msg) => logs.add(msg),
      );

      expect(serviceWithLogger, isNotNull);
    });

    group('Graph Management', () {
      test('loadGraph calls native method with correct arguments', () async {
        await service.loadGraph('test-region', '/path/to/graph.ghz');

        expect(log.length, 1);
        expect(log[0].method, 'loadGraph');
        expect(log[0].arguments['regionId'], 'test-region');
        expect(log[0].arguments['graphPath'], '/path/to/graph.ghz');
      });

      test('loadGraph marks region as loaded on success', () async {
        await service.loadGraph('test-region', '/path/to/graph.ghz');

        expect(service.isGraphLoaded('test-region'), isTrue);
      });

      test('loadGraph throws on failure', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          OfflineRoutingService.channel,
          (MethodCall methodCall) async {
            return {'success': false, 'error': 'Invalid graph file'};
          },
        );

        expect(
          () => service.loadGraph('test-region', '/invalid/path.ghz'),
          throwsA(isA<OfflineRoutingException>()),
        );
      });

      test('loadGraph throws on platform exception', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          OfflineRoutingService.channel,
          (MethodCall methodCall) async {
            throw PlatformException(code: 'ERROR', message: 'Native error');
          },
        );

        expect(
          () => service.loadGraph('test-region', '/path.ghz'),
          throwsA(isA<OfflineRoutingException>()),
        );
      });

      test('unloadGraph calls native method', () async {
        await service.loadGraph('test-region', '/path/to/graph.ghz');
        log.clear();

        await service.unloadGraph('test-region');

        expect(log.length, 1);
        expect(log[0].method, 'unloadGraph');
        expect(log[0].arguments['regionId'], 'test-region');
      });

      test('unloadGraph removes region from loaded set', () async {
        await service.loadGraph('test-region', '/path/to/graph.ghz');
        expect(service.isGraphLoaded('test-region'), isTrue);

        await service.unloadGraph('test-region');
        expect(service.isGraphLoaded('test-region'), isFalse);
      });

      test('isGraphLoaded returns false for unloaded region', () {
        expect(service.isGraphLoaded('not-loaded'), isFalse);
      });

      test('isGraphLoadedNative queries native side', () async {
        final result = await service.isGraphLoadedNative('loaded-region');
        expect(result, isTrue);

        final result2 = await service.isGraphLoadedNative('not-loaded');
        expect(result2, isFalse);
      });

      test('getLoadedGraphs returns list from native', () async {
        final graphs = await service.getLoadedGraphs();

        expect(graphs, ['region1', 'region2']);
      });

      test('getGraphInfo returns info for loaded graph', () async {
        final info = await service.getGraphInfo('test-region');

        expect(info, isNotNull);
        expect(info!.regionId, 'test-region');
        expect(info.profiles, ['car', 'bike', 'foot']);
        expect(info.nodeCount, 1000);
        expect(info.edgeCount, 2000);
        expect(info.bounds.minLat, 55.5);
        expect(info.bounds.maxLon, 38.0);
      });
    });

    group('Route Calculation', () {
      setUp(() async {
        // Load a graph first
        await service.loadGraph('test-region', '/path/to/graph.ghz');
        log.clear();
      });

      test('getRoute throws when graph not loaded', () {
        expect(
          () => service.getRoute(
            regionId: 'not-loaded',
            from: const Coordinates(lat: 55.7558, lon: 37.6173),
            to: const Coordinates(lat: 55.7000, lon: 37.5000),
          ),
          throwsA(isA<OfflineRoutingException>()),
        );
      });

      test('getRoute calls native method with correct arguments', () async {
        await service.getRoute(
          regionId: 'test-region',
          from: const Coordinates(lat: 55.7558, lon: 37.6173),
          to: const Coordinates(lat: 55.7000, lon: 37.5000),
          mode: TransportMode.car,
        );

        expect(log.length, 1);
        expect(log[0].method, 'calculateRoute');
        expect(log[0].arguments['regionId'], 'test-region');
        expect(log[0].arguments['fromLat'], 55.7558);
        expect(log[0].arguments['fromLon'], 37.6173);
        expect(log[0].arguments['toLat'], 55.7000);
        expect(log[0].arguments['toLon'], 37.5000);
        expect(log[0].arguments['profile'], 'car');
      });

      test('getRoute returns RouteResponse with correct data', () async {
        final response = await service.getRoute(
          regionId: 'test-region',
          from: const Coordinates(lat: 55.7558, lon: 37.6173),
          to: const Coordinates(lat: 55.7000, lon: 37.5000),
        );

        expect(response.distanceMeters, 5000);
        expect(response.durationSeconds, 600); // 600000ms / 1000
        expect(response.provider, 'offline');
        expect(response.units, 0);
        expect(response.decodedPolyline, hasLength(3));
        expect(response.steps, hasLength(2));
      });

      test('getRoute with waypoints passes them to native', () async {
        await service.getRoute(
          regionId: 'test-region',
          from: const Coordinates(lat: 55.7558, lon: 37.6173),
          to: const Coordinates(lat: 55.7000, lon: 37.5000),
          waypoints: [
            const Coordinates(lat: 55.7300, lon: 37.5500),
          ],
        );

        expect(log[0].arguments['waypoints'], [
          {'lat': 55.7300, 'lon': 37.5500},
        ]);
      });

      test('getRoute converts transport mode to profile correctly', () async {
        final modeToExpectedProfile = {
          TransportMode.car: 'car',
          TransportMode.truck: 'car', // Truck uses car profile in GraphHopper
          TransportMode.bike: 'bike',
          TransportMode.foot: 'foot',
        };

        for (final mode in TransportMode.values) {
          log.clear();
          await service.getRoute(
            regionId: 'test-region',
            from: const Coordinates(lat: 55.7558, lon: 37.6173),
            to: const Coordinates(lat: 55.7000, lon: 37.5000),
            mode: mode,
          );

          expect(log[0].arguments['profile'], modeToExpectedProfile[mode]);
        }
      });

      test('getRoute throws on null result', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          OfflineRoutingService.channel,
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadGraph') {
              return {'success': true};
            }
            return null;
          },
        );

        await service.loadGraph('null-result', '/path.ghz');

        expect(
          () => service.getRoute(
            regionId: 'null-result',
            from: const Coordinates(lat: 55.7558, lon: 37.6173),
            to: const Coordinates(lat: 55.7000, lon: 37.5000),
          ),
          throwsA(isA<OfflineRoutingException>()),
        );
      });

      test('getRoute throws on failure result', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          OfflineRoutingService.channel,
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadGraph') {
              return {'success': true};
            }
            return {'success': false, 'error': 'No route found'};
          },
        );

        await service.loadGraph('fail-region', '/path.ghz');

        expect(
          () => service.getRoute(
            regionId: 'fail-region',
            from: const Coordinates(lat: 55.7558, lon: 37.6173),
            to: const Coordinates(lat: 55.7000, lon: 37.5000),
          ),
          throwsA(isA<OfflineRoutingException>()),
        );
      });
    });

    test('dispose unloads all graphs', () async {
      await service.loadGraph('region1', '/path1.ghz');
      await service.loadGraph('region2', '/path2.ghz');
      log.clear();

      await service.dispose();

      // Should have called unloadGraph for each loaded region
      final unloadCalls =
          log.where((call) => call.method == 'unloadGraph').toList();
      expect(unloadCalls, hasLength(2));
    });
  });

  group('OfflineGraphInfo', () {
    test('fromMap creates instance correctly', () {
      final map = <Object?, Object?>{
        'regionId': 'test',
        'profiles': ['car', 'bike'],
        'nodeCount': 500,
        'edgeCount': 1000,
        'bounds': {
          'minLat': 55.0,
          'minLon': 37.0,
          'maxLat': 56.0,
          'maxLon': 38.0,
        },
      };

      final info = OfflineGraphInfo.fromMap(map);

      expect(info.regionId, 'test');
      expect(info.profiles, ['car', 'bike']);
      expect(info.nodeCount, 500);
      expect(info.edgeCount, 1000);
      expect(info.bounds.minLat, 55.0);
    });

    test('fromMap handles missing fields gracefully', () {
      final map = <Object?, Object?>{};

      final info = OfflineGraphInfo.fromMap(map);

      expect(info.regionId, '');
      expect(info.profiles, isEmpty);
      expect(info.nodeCount, 0);
      expect(info.edgeCount, 0);
    });

    test('toString provides useful info', () {
      final info = OfflineGraphInfo(
        regionId: 'test',
        profiles: ['car'],
        nodeCount: 100,
        edgeCount: 200,
        bounds: const OfflineGraphBounds(
          minLat: 55.0,
          minLon: 37.0,
          maxLat: 56.0,
          maxLon: 38.0,
        ),
      );

      expect(info.toString(), contains('test'));
      expect(info.toString(), contains('100'));
    });
  });

  group('OfflineGraphBounds', () {
    test('fromMap creates instance correctly', () {
      final map = <Object?, Object?>{
        'minLat': 55.0,
        'minLon': 37.0,
        'maxLat': 56.0,
        'maxLon': 38.0,
      };

      final bounds = OfflineGraphBounds.fromMap(map);

      expect(bounds.minLat, 55.0);
      expect(bounds.minLon, 37.0);
      expect(bounds.maxLat, 56.0);
      expect(bounds.maxLon, 38.0);
    });

    test('contains returns true for point inside bounds', () {
      const bounds = OfflineGraphBounds(
        minLat: 55.0,
        minLon: 37.0,
        maxLat: 56.0,
        maxLon: 38.0,
      );

      expect(
          bounds.contains(const Coordinates(lat: 55.5, lon: 37.5)), isTrue);
    });

    test('contains returns false for point outside bounds', () {
      const bounds = OfflineGraphBounds(
        minLat: 55.0,
        minLon: 37.0,
        maxLat: 56.0,
        maxLon: 38.0,
      );

      expect(
          bounds.contains(const Coordinates(lat: 54.0, lon: 37.5)), isFalse);
      expect(
          bounds.contains(const Coordinates(lat: 55.5, lon: 39.0)), isFalse);
    });

    test('toString provides useful info', () {
      const bounds = OfflineGraphBounds(
        minLat: 55.0,
        minLon: 37.0,
        maxLat: 56.0,
        maxLon: 38.0,
      );

      expect(bounds.toString(), contains('55.0'));
      expect(bounds.toString(), contains('38.0'));
    });
  });

  group('OfflineRoutingException', () {
    test('creates with message', () {
      const exception = OfflineRoutingException('Test error');

      expect(exception.message, 'Test error');
    });

    test('toString includes message', () {
      const exception = OfflineRoutingException('Test error');

      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), contains('OfflineRoutingException'));
    });
  });
}
