import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/constants/api_constants.dart';
import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/auth/models/api_error.dart';
import 'package:ceylongo/features/vendor/screens/vendor_more_screen.dart';
import 'package:ceylongo/features/weather/models/weather_models.dart';
import 'package:ceylongo/features/weather/screens/live_weather_screen.dart';
import 'package:ceylongo/features/weather/services/weather_api_service.dart';
import 'package:ceylongo/main.dart';

Map<String, dynamic> _sampleLocationsJson({bool empty = false}) => {
      'source': 'OpenWeather',
      'source_url': 'https://openweathermap.org/',
      'fetched_at': '2026-01-01T18:00:00Z',
      'stale': false,
      'locations': empty
          ? []
          : [
              {
                'name': 'Nuwara Eliya',
                'region': 'Central',
                'country': 'LK',
                'latitude': 6.97,
                'longitude': 80.78,
              },
              {
                'name': 'Kandy',
                'region': null,
                'country': 'LK',
                'latitude': 7.29,
                'longitude': 80.63,
              },
            ],
    };

Map<String, dynamic> _sampleCurrentJson({
  bool stale = false,
  int? windDirectionDegrees = 180,
}) =>
    {
      'source': 'OpenWeather',
      'source_url': 'https://openweathermap.org/',
      'fetched_at': '2026-01-01T18:00:00Z',
      'stale': stale,
      'coordinates': {'latitude': 6.97, 'longitude': 80.78},
      'temperature_c': 21.5,
      'feels_like_c': 20.8,
      'condition': {
        'code': 500,
        'name': 'Rain',
        'description': 'light rain',
        'icon': '10d',
      },
      'humidity_percent': 84,
      'wind_speed_kmh': 18.4,
      'wind_direction_degrees': windDirectionDegrees,
      'sunrise': '2026-01-01T06:22:00+05:30',
      'sunset': '2026-01-01T18:05:00+05:30',
      'observed_at': '2026-01-01T23:30:00+05:30',
    };

Map<String, dynamic> _sampleForecastJson({
  bool stale = false,
  bool omitDays = false,
}) =>
    {
      'source': 'OpenWeather',
      'source_url': 'https://openweathermap.org/',
      'fetched_at': '2026-01-01T18:00:00Z',
      'stale': stale,
      'coordinates': {'latitude': 6.97, 'longitude': 80.78},
      'timezone': 'Asia/Colombo',
      'intervals': [
        {
          'forecast_at': '2026-01-01T23:30:00+05:30',
          'temperature_c': 19.0,
          'min_temperature_c': 18.0,
          'max_temperature_c': 20.0,
          'rain_probability_percent': null,
          'wind_speed_kmh': 14.0,
          'condition': {
            'code': 800,
            'name': 'Clear',
            'description': 'clear sky',
            'icon': '01n',
          },
        },
        {
          'forecast_at': '2026-01-02T08:30:00+05:30',
          'temperature_c': 22.0,
          'min_temperature_c': 17.5,
          'max_temperature_c': 24.0,
          'rain_probability_percent': 75.0,
          'wind_speed_kmh': 22.0,
          'condition': {
            'code': 501,
            'name': 'Rain',
            'description': 'moderate rain',
            'icon': '10d',
          },
        },
        {
          'forecast_at': '2026-01-02T14:30:00+05:30',
          'temperature_c': 23.0,
          'min_temperature_c': 19.0,
          'max_temperature_c': 25.0,
          'rain_probability_percent': 80.0,
          'wind_speed_kmh': 42.0,
          'condition': {
            'code': 211,
            'name': 'Thunderstorm',
            'description': 'thunderstorm',
            'icon': '11d',
          },
        },
      ],
      if (!omitDays)
        'days': [
          {
            'date': '2026-01-01',
            'interval_count': 1,
            'partial': true,
            'min_temperature_c': 18.0,
            'max_temperature_c': 20.0,
            'rain_probability_percent': null,
            'condition': {
              'code': 800,
              'name': 'Clear',
              'description': 'clear sky',
              'icon': '01n',
            },
            'recommendations': [
              'Consider an outdoor outing during a favorable interval and recheck conditions.',
            ],
            'cautions': [],
          },
          {
            'date': '2026-01-02',
            'interval_count': 2,
            'partial': true,
            'min_temperature_c': 17.5,
            'max_temperature_c': 25.0,
            'rain_probability_percent': 80.0,
            'condition': {
              'code': 211,
              'name': 'Thunderstorm',
              'description': 'thunderstorm',
              'icon': '11d',
            },
            'recommendations': [
              'Pack rain gear and check trail conditions with your guide.',
              'Keep a museum, gallery or indoor workshop as an alternative.',
            ],
            'cautions': [
              'Thunderstorms are possible. Consider postponing exposed hikes.',
              'Rain is possible. Trails and steps may be slippery.',
            ],
          },
        ],
      'advisory_notice':
          'Travel guidance is advisory. Check official warnings and local conditions.',
    };

void main() {
  group('Weather Models & Timestamp Grouping Tests', () {
    test('parses locations, handles null region, and builds displayLabel', () {
      final parsed = WeatherLocationsResponse.fromJson(_sampleLocationsJson());
      expect(parsed.locations, hasLength(2));
      expect(parsed.locations[0].displayLabel, 'Nuwara Eliya, Central, LK');
      expect(parsed.locations[1].region, isNull);
      expect(parsed.locations[1].displayLabel, 'Kandy, LK');
    });

    test('parses current weather with nullable wind_direction_degrees', () {
      final current = CurrentWeatherData.fromJson(
        _sampleCurrentJson(windDirectionDegrees: null),
      );
      expect(current.temperatureC, 21.5);
      expect(current.feelsLikeC, 20.8);
      expect(current.humidityPercent, 84);
      expect(current.windSpeedKmh, 18.4);
      expect(current.windDirectionDegrees, isNull);
      expect(current.condition.code, 500);
      expect(current.stale, isFalse);
    });

    test('groups 3-hour Asia/Colombo intervals by local date when days omitted',
        () {
      final forecast = ForecastResponse.fromJson(
        _sampleForecastJson(omitDays: true),
      );
      expect(forecast.timezone, 'Asia/Colombo');
      expect(forecast.days, hasLength(2));
      expect(forecast.days[0].dateKey, '2026-01-01');
      expect(forecast.days[0].partial, isTrue);
      expect(forecast.days[0].rainProbabilityPercent, isNull);

      expect(forecast.days[1].dateKey, '2026-01-02');
      expect(forecast.days[1].minTemperatureC, 17.5);
      expect(forecast.days[1].maxTemperatureC, 25.0);
      expect(forecast.days[1].rainProbabilityPercent, 80.0);
      expect(forecast.days[1].condition.code, 211);
    });

    test('derives conservative travel advisories from measured values', () {
      final forecast = ForecastResponse.fromJson(
        _sampleForecastJson(omitDays: true),
      );
      final advisory = TravelWeatherAdvisory.fromWeather(forecast: forecast);
      expect(advisory.isBackendDerived, isFalse);
      expect(advisory.hasSufficientData, isTrue);
      expect(
        advisory.cautions.any((c) => c.contains('Thunderstorms')),
        isTrue,
      );
      expect(advisory.cautions.any((c) => c.contains('Rain')), isTrue);
      expect(
        advisory.cautions.any((c) => c.contains('Strong winds')),
        isTrue,
      );
    });
  });

  group('WeatherApiService HTTP & Error Handling Tests', () {
    test('encodes destination search URL and query parameters accurately',
        () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(jsonEncode(_sampleLocationsJson()), 200);
      });
      final service = WeatherApiService(client: client);
      final res = await service.searchLocations('  Nuwara   Eliya ');

      expect(capturedUri.toString(),
          startsWith(ApiConstants.weatherLocationsEndpoint));
      expect(capturedUri?.queryParameters['q'], 'Nuwara Eliya');
      expect(res.locations, hasLength(2));
    });

    test('fetches current weather and forecast with exact lat/lon params',
        () async {
      final capturedPaths = <String>[];
      final client = MockClient((request) async {
        capturedPaths.add(request.url.toString());
        if (request.url.path.endsWith('/current')) {
          return http.Response(jsonEncode(_sampleCurrentJson()), 200);
        }
        return http.Response(jsonEncode(_sampleForecastJson()), 200);
      });

      final service = WeatherApiService(client: client);
      final current =
          await service.getCurrentWeather(latitude: 6.97, longitude: 80.78);
      final forecast =
          await service.getForecast(latitude: 6.97, longitude: 80.78);

      expect(current.temperatureC, 21.5);
      expect(forecast.days, hasLength(2));
      expect(capturedPaths[0], contains('lat=6.97&lon=80.78'));
      expect(capturedPaths[1], contains('lat=6.97&lon=80.78'));
    });

    test('handles malformed JSON cleanly', () async {
      final client = MockClient((_) async => http.Response('{invalid-json', 200));
      final service = WeatherApiService(client: client);

      expect(
        () => service.getCurrentWeather(latitude: 6.97, longitude: 80.78),
        throwsA(isA<ApiError>().having(
            (e) => e.code, 'code', 'weather_invalid_response')),
      );
    });

    test('handles TimeoutException cleanly', () async {
      final client = MockClient((_) async {
        throw TimeoutException('Timed out');
      });
      final service = WeatherApiService(client: client);

      expect(
        () => service.searchLocations('Kandy'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'TIMEOUT')),
      );
    });

    test('handles SocketException cleanly', () async {
      final client = MockClient((_) async {
        throw const SocketException('Failed host lookup');
      });
      final service = WeatherApiService(client: client);

      expect(
        () => service.getForecast(latitude: 6.97, longitude: 80.78),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'NETWORK_ERROR')),
      );
    });

    test('handles HTTP 400, 404, 429, and 503 (weather_not_configured)',
        () async {
      for (final scenario in [
        (400, {'detail': {'code': 'BAD_REQUEST'}}, 'BAD_REQUEST', null),
        (404, {'detail': {'code': 'NOT_FOUND'}}, 'NOT_FOUND', null),
        (
          429,
          {'detail': {'code': 'weather_quota_exceeded'}},
          'weather_quota_exceeded',
          {'retry-after': '12'}
        ),
        (
          503,
          {'detail': {'code': 'weather_not_configured'}},
          'weather_not_configured',
          null
        ),
      ]) {
        final client = MockClient(
          (_) async => http.Response(
            jsonEncode(scenario.$2),
            scenario.$1,
            headers: scenario.$4 ?? const {},
          ),
        );
        final service = WeatherApiService(client: client);
        try {
          await service.getCurrentWeather(latitude: 6.97, longitude: 80.78);
          fail('Expected ApiError for status ${scenario.$1}');
        } on ApiError catch (e) {
          expect(e.statusCode, scenario.$1);
          expect(e.code, scenario.$3);
          if (scenario.$1 == 429) {
            expect(e.message, contains('12 seconds'));
          }
          if (scenario.$1 == 503) {
            expect(e.message, contains('unconfigured'));
          }
        }
      }
    });
  });

  group('LiveWeatherScreen Widget & Navigation Tests', () {
    testWidgets(
      'Shows loading, no-results, search, selection, current weather, forecast, advisories, and stale banner on 360x800',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        var returnEmptySearch = true;
        final completer = Completer<http.Response>();

        final client = MockClient((request) async {
          if (request.url.path.endsWith('/locations')) {
            if (returnEmptySearch) {
              return http.Response(
                jsonEncode(_sampleLocationsJson(empty: true)),
                200,
              );
            }
            return http.Response(jsonEncode(_sampleLocationsJson()), 200);
          }
          if (request.url.path.endsWith('/current')) {
            return completer.future;
          }
          return http.Response(jsonEncode(_sampleForecastJson(stale: true)), 200);
        });

        final service = WeatherApiService(client: client);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: LiveWeatherScreen(
              weatherService: service,
              searchDebounceDuration: const Duration(milliseconds: 50),
            ),
          ),
        );

        expect(find.byKey(const Key('weather_empty_prompt')), findsOneWidget);

        // 1. No search results state
        await tester.enterText(
          find.byKey(const Key('weather_search_input')),
          'Nowhere',
        );
        await tester.tap(find.byKey(const Key('weather_search_submit_btn')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('weather_no_results')), findsOneWidget);

        // 2. Real results + selection + loading state
        returnEmptySearch = false;
        await tester.enterText(
          find.byKey(const Key('weather_search_input')),
          'Nuwara Eliya',
        );
        await tester.tap(find.byKey(const Key('weather_search_submit_btn')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('weather_search_results')), findsOneWidget);
        await tester.tap(find.byKey(const Key('weather_location_item_0')));
        await tester.pump();
        expect(find.byKey(const Key('weather_data_loading')), findsOneWidget);

        completer.complete(
          http.Response(jsonEncode(_sampleCurrentJson(stale: true)), 200),
        );
        await tester.pumpAndSettle();

        // 3. Stale banner, current weather, forecast, and advisories
        expect(find.byKey(const Key('weather_stale_banner')), findsOneWidget);
        expect(
          find.byKey(const Key('weather_selected_destination')),
          findsOneWidget,
        );
        expect(find.text('21.5°C'), findsOneWidget);
        expect(find.text('Rain — Light rain'), findsOneWidget);
        expect(find.text('84%'), findsOneWidget);
        expect(find.text('18.4 km/h'), findsOneWidget);
        expect(find.byKey(const Key('weather_forecast_day_0')), findsOneWidget);
        expect(find.byKey(const Key('weather_forecast_day_1')), findsOneWidget);
        expect(find.byKey(const Key('weather_advisory_card')), findsOneWidget);
        expect(
          find.textContaining('Thunderstorms are possible'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Handles error state and retry action cleanly', (tester) async {
      var failWeather = true;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/current')) {
          if (failWeather) {
            return http.Response(
              jsonEncode({
                'detail': {'code': 'weather_not_configured'}
              }),
              503,
            );
          }
          return http.Response(jsonEncode(_sampleCurrentJson()), 200);
        }
        return http.Response(jsonEncode(_sampleForecastJson()), 200);
      });

      final service = WeatherApiService(client: client);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: LiveWeatherScreen(
            weatherService: service,
            initialLocation: const WeatherLocation(
              name: 'Nuwara Eliya',
              region: 'Central',
              latitude: 6.97,
              longitude: 80.78,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('weather_data_error')), findsOneWidget);
      expect(find.textContaining('unconfigured'), findsOneWidget);

      failWeather = false;
      await tester.tap(find.byKey(const Key('weather_data_retry_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('weather_current_card')), findsOneWidget);
      expect(find.text('21.5°C'), findsOneWidget);
    });

    testWidgets('Navigates from Vendor More -> Live Weather cleanly on 360x800',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final client = MockClient(
        (_) async => http.Response(jsonEncode(_sampleLocationsJson()), 200),
      );
      final service = WeatherApiService(client: client);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          routes: CeylonGoApp.getRoutes(weatherService: service),
          home: const VendorMoreScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final weatherTile = find.byKey(const Key('vendor_more_weather_tile'));
      await tester.ensureVisible(weatherTile);
      await tester.pumpAndSettle();
      await tester.tap(weatherTile);
      await tester.pumpAndSettle();

      expect(find.byType(LiveWeatherScreen), findsOneWidget);
      expect(find.byKey(const Key('weather_empty_prompt')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

