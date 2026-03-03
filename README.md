# Qorvia Maps SDK

Flutter SDK для гео-сервисов: навигация, маршрутизация, геокодирование и интерактивные карты на базе MapLibre GL.

[English version](README.en.md)

## Получение API-ключа

Для использования SDK необходим API-ключ. Перейдите на [qorviamapkit.ru](https://qorviamapkit.ru), чтобы создать ключ и управлять аккаунтом.

## Возможности

- **Инициализация SDK** — глобальная конфигурация с автоматической загрузкой URL тайлов
- **API-клиент** — маршрутизация, геокодирование, обратное геокодирование, квоты и статистика использования
- **Виджет карты** — интерактивная карта MapLibre GL с поддержкой жестов
- **Маркеры** — стандартные, SVG, asset, сетевые, виджетные, нумерованные, анимированные и кешируемые иконки
- **Кластеризация** — автоматическая кластеризация маркеров с настраиваемым стилем
- **Отображение маршрута** — настраиваемый рендеринг линии маршрута
- **Пошаговая навигация** — навигация в реальном времени с отслеживанием состояния
- **Голосовые подсказки** — голосовые инструкции через Text-to-Speech
- **Сервис геолокации** — GPS-трекинг с фильтрацией Калмана

## Установка

Добавьте зависимость в `pubspec.yaml`:

```yaml
dependencies:
  qorvia_maps_sdk: ^0.2.2
```

### Настройка платформ

**Android** — добавьте в `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

**iOS** — добавьте в `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Приложению необходим доступ к геолокации для навигации</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Приложению необходима фоновая геолокация для пошаговой навигации</string>
```

## Быстрый старт

### Инициализация SDK

```dart
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация SDK — автоматически загружает URL тайлов
  await QorviaMapsSDK.init(
    apiKey: 'your_api_key',
    enableLogging: true,  // опционально, для отладки
  );

  runApp(MyApp());
}
```

### Отображение карты

```dart
final controller = QorviaMapController();

QorviaMapView(
  controller: controller,
  options: const MapOptions(
    initialCenter: Coordinates(lat: 55.7539, lon: 37.6208),
    initialZoom: 13,
    showUserLocation: true,
  ),
  onMapTap: (coordinates) => print('Нажатие: $coordinates'),
)
```

### Добавление маркеров

```dart
QorviaMapView(
  controller: controller,
  options: MapOptions(
    initialCenter: Coordinates(lat: 55.7539, lon: 37.6208),
  ),
  markers: [
    // Стандартный маркер
    Marker(
      id: 'start',
      position: Coordinates(lat: 55.7539, lon: 37.6208),
      icon: DefaultMarkerIcon.start,
    ),
    // Нумерованный маркер
    Marker(
      id: 'waypoint1',
      position: Coordinates(lat: 55.7545, lon: 37.6220),
      icon: NumberedMarkerIcon(number: 1),
    ),
    // Анимированный маркер
    Marker(
      id: 'active',
      position: Coordinates(lat: 55.7550, lon: 37.6230),
      icon: AnimatedMarkerIcon.pulsingPrimary,
    ),
  ],
  onMarkerTap: (marker) => print('Нажат: ${marker.id}'),
)
```

### Кластеризация маркеров

```dart
QorviaMapView(
  controller: controller,
  options: MapOptions(initialCenter: center),
  markers: myMarkers,
  clusterOptions: const MarkerClusterOptions(
    enabled: true,
    radiusPx: 60,
    minClusterSize: 3,
  ),
  onClusterTap: (cluster) => print('Кластер: ${cluster.count} маркеров'),
)
```

### Построение маршрута

```dart
// Используем глобальный клиент SDK
final client = QorviaMapsSDK.instance.client;

final route = await client.route(
  from: Coordinates(lat: 55.7539, lon: 37.6208),
  to: Coordinates(lat: 55.7614, lon: 37.6500),
  mode: TransportMode.car,
  language: 'ru',
);

print('Расстояние: ${route.formattedDistance}');
print('Время: ${route.formattedDuration}');

// Отобразить на карте
controller.displayRoute(route, options: RouteLineOptions.primary());
```

### Геокодирование

```dart
// Адрес в координаты
final response = await client.geocode(
  query: 'Красная площадь, Москва',
  limit: 5,
  language: 'ru',
);

for (final result in response.results) {
  print('${result.displayName}: ${result.coordinates}');
}

// Координаты в адрес
final address = await client.reverse(
  coordinates: Coordinates(lat: 55.7539, lon: 37.6208),
  language: 'ru',
);
print('Адрес: ${address.displayName}');
```

### Пошаговая навигация

```dart
NavigationView(
  route: route,
  options: NavigationOptions(
    enableVoiceInstructions: true,
    voiceGuidanceOptions: const VoiceGuidanceOptions(
      language: 'ru-RU',
      speechRate: 0.5,
    ),
    trackingMode: CameraTrackingMode.followWithBearing,
    autoReroute: true,
  ),
  onStateChanged: (state) {
    print('Оставшееся расстояние: ${state.distanceRemaining}м');
    print('Прибытие: ${state.estimatedArrival}');
  },
  onStepChanged: (step) => print('Далее: ${step.instruction}'),
  onOffRoute: () => print('Отклонение от маршрута'),
  onArrival: () => print('Вы прибыли!'),
  onReroute: (from, to) async {
    // Возврат нового маршрута при отклонении
    return await client.route(from: from, to: to);
  },
)
```

## Справочник API

### QorviaMapsSDK

Глобальный инициализатор и точка входа SDK.

```dart
// Инициализация
await QorviaMapsSDK.init(apiKey: 'key');

// Проверка инициализации
if (QorviaMapsSDK.isInitialized) {
  final client = QorviaMapsSDK.instance.client;
}

// Получить URL тайлов
final tileUrl = await QorviaMapsSDK.instance.getTileUrl();

// Освободить ресурсы
QorviaMapsSDK.dispose();
```

### QorviaMapsClient

API-клиент для всех гео-сервисов.

| Метод | Описание |
|-------|----------|
| `route()` | Построить маршрут между точками |
| `geocode()` | Преобразовать адрес в координаты |
| `search()` | Лучшее совпадение по запросу |
| `reverse()` | Преобразовать координаты в адрес |
| `quota()` | Получить информацию о квоте API |
| `usage()` | Получить статистику использования |
| `tileUrl()` | Получить URL стиля тайлов карты |

### QorviaMapView

Основной виджет карты.

| Параметр | Тип | Описание |
|----------|-----|----------|
| `controller` | `QorviaMapController?` | Контроллер карты |
| `options` | `MapOptions` | Конфигурация карты |
| `markers` | `List<Marker>` | Маркеры для отображения |
| `clusterOptions` | `MarkerClusterOptions?` | Настройки кластеризации |
| `routeLines` | `List<RouteLine>` | Маршруты для отображения |
| `onMapCreated` | `Function(QorviaMapController)` | Callback готовности карты |
| `onMarkerTap` | `Function(Marker)` | Callback нажатия на маркер |
| `onClusterTap` | `Function(MarkerCluster)` | Callback нажатия на кластер |
| `onMapTap` | `Function(Coordinates)` | Callback нажатия на карту |

### QorviaMapController

Интерфейс управления картой.

```dart
// Управление камерой
await controller.animateCamera(
  CameraUpdate.newPosition(CameraPosition(
    center: Coordinates(lat: 55.75, lon: 37.62),
    zoom: 15,
    tilt: 45,
    bearing: 90,
  )),
  duration: Duration(milliseconds: 800),
);

// Вписать в границы
await controller.animateCamera(
  CameraUpdate.newLatLngBounds(coordinates, padding: 50),
);

// Маркеры
await controller.addMarker(marker);
await controller.removeMarker('marker_id');
await controller.clearMarkers();
await controller.updateMarkerPosition('id', newCoordinates);

// Маршруты
await controller.displayRoute(route, options: RouteLineOptions.primary());
await controller.displayRouteLine(routeLine);
await controller.fitRoute(route, padding: EdgeInsets.all(50));
await controller.clearRoutes();

// Масштаб
await controller.zoomIn();
await controller.zoomOut();
```

### NavigationView

Виджет пошаговой навигации.

| Параметр | Тип | Описание |
|----------|-----|----------|
| `route` | `RouteResponse` | Маршрут для навигации |
| `options` | `NavigationOptions` | Настройки навигации |
| `styleUrl` | `String?` | URL стиля карты |
| `onStateChanged` | `Function(NavigationState)` | Обновления состояния |
| `onStepChanged` | `Function(RouteStep)` | Callback смены шага |
| `onArrival` | `VoidCallback` | Callback прибытия |
| `onOffRoute` | `VoidCallback` | Callback отклонения от маршрута |
| `onReroute` | `Function(Coordinates, Coordinates)` | Построитель нового маршрута |

### NavigationOptions

| Опция | По умолч. | Описание |
|-------|-----------|----------|
| `trackingMode` | `followWithBearing` | Режим отслеживания камеры |
| `zoom` | `17` | Уровень масштаба навигации |
| `tilt` | `55` | Угол наклона камеры |
| `enableVoiceInstructions` | `false` | Включить голосовые подсказки |
| `offRouteThreshold` | `30` | Метры для срабатывания отклонения |
| `arrivalThreshold` | `35` | Метры для срабатывания прибытия |
| `autoReroute` | `true` | Автоматический перестрой маршрута |
| `showNextTurnPanel` | `true` | Показать панель следующего поворота |
| `showEtaPanel` | `true` | Показать панель ETA/расстояния |
| `showSpeedIndicator` | `true` | Показать текущую скорость |
| `snapToRouteEnabled` | `true` | Привязка курсора к маршруту |

### NavigationController

Программное управление навигацией.

```dart
final controller = NavigationController(
  options: NavigationOptions.driving(),
  onStateChanged: (state) => print(state),
  onArrival: () => print('Прибыли!'),
);

// Запустить навигацию
await controller.startNavigation(route);

// Обновить маршрут (перестроение)
await controller.updateRoute(newRoute);

// Управление камерой
controller.setTrackingMode(CameraTrackingMode.follow);
controller.pauseTracking();  // Пользователь сдвинул карту
controller.recenter();       // Вернуться к отслеживанию

// Остановить
controller.stopNavigation();

// Очистка
controller.dispose();
```

### LocationService

Управление геолокацией устройства.

```dart
final locationService = LocationService();

// Проверка разрешений
final enabled = await locationService.isLocationServiceEnabled();
final permission = await locationService.checkPermission();

if (permission == LocationPermissionStatus.denied) {
  await locationService.requestPermission();
}

// Получить текущее местоположение
final location = await locationService.getCurrentLocation(
  accuracy: LocationAccuracy.high,
);

// Начать отслеживание с фильтрацией
await locationService.startTracking(
  LocationSettings.navigation(),
  LocationFilterSettings.navigation(),
);

locationService.locationStream.listen((location) {
  print('${location.coordinates}, скорость: ${location.speed}');
});

// Проверка состояния
final health = locationService.checkHealth();
print('Исправен: ${health.isHealthy}');

// Остановить отслеживание
locationService.stopTracking();
locationService.dispose();
```

### Иконки маркеров

```dart
// Стандартные пресеты
DefaultMarkerIcon.primary    // Индиго
DefaultMarkerIcon.red        // Красный
DefaultMarkerIcon.green      // Зелёный
DefaultMarkerIcon.start      // Зелёный с флагом
DefaultMarkerIcon.end        // Красный с булавкой

// Пользовательский стандартный
DefaultMarkerIcon(
  color: MarkerColors.purple,
  size: 56,
  style: MarkerStyle.modern,
  innerIcon: Icons.star,
)

// Нумерованные
NumberedMarkerIcon(number: 1)
NumberedMarkerIcon.letter('A')
NumberedMarkerIcon.sequence(5)  // [1, 2, 3, 4, 5]
NumberedMarkerIcon.letters(3)   // [A, B, C]

// Анимированные
AnimatedMarkerIcon.pulsingPrimary
AnimatedMarkerIcon.dropInStart
AnimatedMarkerIcon.rippleLocation
AnimatedMarkerIcon(
  color: MarkerColors.info,
  animationType: MarkerAnimationType.pulse,
)

// На основе ассетов
AssetMarkerIcon('assets/pin.png', width: 32, height: 32)
SvgMarkerIcon('assets/icon.svg', size: 24, color: Colors.blue)
NetworkMarkerIcon('https://example.com/icon.png')

// Виджетный
WidgetMarkerIcon(
  MyCustomWidget(),
  width: 48,
  height: 48,
)

// Кешируемый (для множества одинаковых маркеров)
CachedMarkerIcon.primary()
```

### Режимы транспорта

```dart
TransportMode.car    // Автомобиль
TransportMode.bike   // Велосипед
TransportMode.foot   // Пешком
TransportMode.truck  // Грузовик с ограничениями
```

### Стили карт

```dart
MapStyles.osm                 // OpenStreetMap
MapStyles.openFreeMapLiberty  // OpenFreeMap Liberty (без ключа)
MapStyles.cartoPositron       // CARTO Positron (без ключа)
MapStyles.custom('https://tiles.example.com')
```

## Архитектура

```
qorvia_maps_sdk/
├── lib/
│   ├── qorvia_maps_sdk.dart          # Публичные экспорты
│   └── src/
│       ├── sdk_initializer.dart      # QorviaMapsSDK синглтон
│       ├── client/                   # API-клиент
│       │   ├── qorvia_maps_client.dart
│       │   └── http_client.dart
│       ├── config/                   # Конфигурация
│       │   ├── sdk_config.dart
│       │   └── transport_mode.dart
│       ├── map/                      # Виджеты карты
│       │   ├── qorvia_map_view.dart
│       │   ├── qorvia_map_controller.dart
│       │   ├── map_options.dart
│       │   └── camera/
│       ├── markers/                  # Система маркеров
│       │   ├── marker.dart
│       │   ├── marker_icon.dart
│       │   ├── marker_widget.dart
│       │   └── cluster/
│       ├── navigation/               # Навигация
│       │   ├── navigation_view.dart
│       │   ├── navigation_controller.dart
│       │   ├── navigation_options.dart
│       │   ├── navigation_state.dart
│       │   ├── ui/                   # UI-компоненты
│       │   └── voice/                # Голосовые подсказки
│       ├── location/                 # Сервисы геолокации
│       │   ├── location_service.dart
│       │   ├── location_data.dart
│       │   ├── location_filter.dart
│       │   └── location_settings.dart
│       ├── models/                   # Модели данных
│       │   ├── coordinates.dart
│       │   ├── route/
│       │   ├── geocode/
│       │   └── reverse/
│       ├── services/                 # API-сервисы
│       │   ├── routing_service.dart
│       │   ├── geocoding_service.dart
│       │   └── reverse_service.dart
│       ├── route_display/            # Рендеринг маршрута
│       └── utils/                    # Утилиты
```

## Зависимости

| Пакет | Назначение |
|-------|------------|
| `maplibre_gl` | Рендеринг карты |
| `dio` | HTTP-клиент |
| `geolocator` | GPS-геолокация |
| `permission_handler` | Управление разрешениями |
| `flutter_compass` | Компас |
| `flutter_tts` | Голосовые подсказки |
| `flutter_svg` | SVG-иконки маркеров |
| `equatable` | Сравнение по значению |
| `freezed_annotation` | Иммутабельные модели |

## Пример

Смотрите директорию `example/` с демо-приложением.

```bash
cd example
flutter run
```

## Лицензия

MIT License. Подробнее в [LICENSE](LICENSE).
