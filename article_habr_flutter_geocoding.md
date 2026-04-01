# Геокодинг во Flutter: альтернатива Яндекс.Картам и 2ГИС

Если вы делаете мобильное приложение с картами для российского рынка, выбор обычно сводится к двум вариантам: Яндекс.Карты или 2ГИС. Оба — отличные сервисы, но у каждого есть свои ограничения, которые могут стать проблемой.

В этой статье покажу альтернативный подход к геокодингу во Flutter. Разберём forward/reverse геокодинг, умный поиск и location bias — всё с примерами кода.

## Проблемы с популярными решениями

### Яндекс.Карты

- **Ценообразование** — бесплатно до 1000 запросов/сутки, дальше от 120 000 ₽/год за пакет. Для стартапа или пет-проекта — дорого
- **Лицензионные ограничения** — геокодинг можно использовать только вместе с картой Яндекса. Хотите свою карту или OpenStreetMap? Нельзя
- **Сложный SDK** — MapKit для Flutter требует нативной интеграции, отдельных ключей для iOS/Android
- **Тяжёлый пакет** — добавляет ощутимый вес к приложению

### 2ГИС

- **Только крупные города** — отличное покрытие мегаполисов, но в небольших городах данных мало
- **Фокус на организациях** — прекрасно ищет кафе и магазины, хуже работает с обычными адресами
- **Закрытая экосистема** — SDK заточен под использование именно карт 2ГИС
- **Сложная интеграция** — требует нативных зависимостей

### Когда это становится проблемой?

- Нужен только геокодинг без карты
- Используете MapLibre, Mapbox или OSM
- Бюджет ограничен, а запросов много
- Приложение работает в небольших городах
- Нужен легковесный SDK без нативных зависимостей

## Альтернатива: Qorvia MapKit

Для решения этих проблем я использую **Qorvia Maps SDK** — Flutter-пакет для работы с отечественным геосервисом. Что умеет:

- Forward-геокодинг (адрес → координаты)
- Reverse-геокодинг (координаты → адрес)
- Smart Search с NLP (понимает естественный язык)
- Location bias (приоритет результатов рядом с пользователем)
- Офлайн-кэширование
- Поддержка русского языка из коробки

Перейдём к коду.

## Установка и настройка

Добавляем в `pubspec.yaml`:

```yaml
dependencies:
  qorvia_maps_sdk: ^0.2.6
```

Инициализация:

```dart
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await QorviaMapsSDK.init(
    apiKey: 'ваш_api_key',
  );

  runApp(MyApp());
}
```

Никаких консолей, OAuth и танцев с бубном. Получили ключ — работаем.

## Forward-геокодинг: адрес → координаты

Классическая задача: пользователь вводит адрес, нужны координаты.

```dart
final client = QorviaMapsSDK.instance.client;

Future<void> searchAddress(String query) async {
  final response = await client.geocode(
    query: query,
    limit: 5,
    language: 'ru',
  );

  for (final result in response.results) {
    print('${result.displayName}');
    print('  Широта: ${result.coordinates.lat}');
    print('  Долгота: ${result.coordinates.lon}');
    print('  Город: ${result.address.city}');
    print('  Страна: ${result.address.country}');
  }
}
```

### Структура ответа

Геокодинг возвращает структурированные данные:

```dart
class GeocodeResult {
  final Coordinates coordinates;    // lat/lon
  final String displayName;         // Полное название
  final Address address;            // Структурированный адрес
  final String placeType;           // 'place', 'address', 'poi'
  final double importance;          // Релевантность (0-1)
  final List<double>? bbox;         // Bounding box
}
```

Класс `Address` даёт доступ к компонентам адреса:

```dart
final address = result.address;

print(address.road);        // Улица
print(address.houseNumber); // Номер дома
print(address.city);        // Город
print(address.state);       // Регион
print(address.country);     // Страна
print(address.postcode);    // Индекс

// Удобные геттеры
print(address.shortAddress); // "ул. Ленина, 42"
print(address.fullAddress);  // Полный форматированный адрес
```

## Reverse-геокодинг: координаты → адрес

Обратная задача — есть координаты (с GPS или тапа по карте), нужен адрес:

```dart
Future<void> getAddressFromCoordinates(double lat, double lon) async {
  final response = await client.reverseLatLon(
    lat: lat,
    lon: lon,
    language: 'ru',
  );

  print('Адрес: ${response.displayName}');
  print('Улица: ${response.address.road} ${response.address.houseNumber}');
  print('Город: ${response.address.city}');
}
```

Или через объект `Coordinates`:

```dart
final response = await client.reverse(
  coordinates: Coordinates(lat: 55.7539, lon: 37.6208),
  language: 'ru',
);
```

## Location Bias: контекстный поиск

Одна из самых полезных фич — **location bias**. Приоритизирует результаты рядом с указанной точкой.

Пример: пользователь в Магнитогорске ищет «вокзал». Без location bias получит вокзалы со всей России. С ним — ближайшие к его местоположению.

```dart
final response = await client.geocode(
  query: 'вокзал',
  limit: 5,
  language: 'ru',
  userLat: 53.404935,       // Широта пользователя
  userLon: 58.965423,       // Долгота пользователя
  radiusKm: 50,             // Радиус поиска в км
  biasLocation: true,       // Включить location bias
);

// Результаты отсортированы по близости
for (final result in response.results) {
  print('${result.displayName}');
  print('Релевантность: ${result.importance}');
}
```

Идеально для:
- Доставки еды
- Такси-приложений
- Поиска ближайших сервисов
- Любых локальных запросов

## Smart Search: поиск на естественном языке

Самая мощная фича — **Smart Search**. Использует NLP для понимания запросов типа «ближайшая аптека» или «кофейня рядом с метро».

```dart
final response = await client.smartSearch(
  query: 'ближайшая аптека',
  lat: 55.7558,
  lon: 37.6173,
  radiusKm: 5,
  limit: 5,
  language: 'ru',
);

print('Тип запроса: ${response.classifiedAs}'); // 'PLACE' или 'ADDRESS'

for (final result in response.results) {
  print('${result.name}');
  print('  ${result.address}');
  print('  ${result.distanceM} м от вас');

  if (result.rating != null) {
    print('  Рейтинг: ${result.rating}/5');
  }

  if (result.openingHours != null) {
    for (final hours in result.openingHours!) {
      print('  ${hours.day}: ${hours.open} - ${hours.close}');
    }
  }

  if (result.phone != null) {
    print('  Телефон: ${result.phone}');
  }
}
```

`SmartSearchResult` возвращает богатую метаинформацию:

- Название и адрес
- Расстояние от пользователя (в метрах)
- Рейтинг (0-5)
- Тип заведения (аптека, кафе, отель и т.д.)
- Контакты (телефон, сайт)
- Часы работы
- Фото

## Практический пример: виджет поиска

Соберём всё вместе в готовый виджет:

```dart
class SearchPanel extends StatefulWidget {
  final void Function(Coordinates, String) onLocationSelected;

  const SearchPanel({required this.onLocationSelected});

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  final _controller = TextEditingController();
  final _client = QorviaMapsSDK.instance.client;

  List<GeocodeResult> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }

    // Debounce 450ms — не долбим API на каждый символ
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    try {
      final response = await _client.geocode(
        query: query.trim(),
        limit: 6,
        language: 'ru',
      );

      setState(() {
        _results = response.results;
        _isLoading = false;
      });
    } on QorviaMapsException catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Ошибка API: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Поиск адреса...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final result = _results[index];
              return ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(result.address.shortAddress),
                subtitle: Text(
                  result.address.city ?? result.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  widget.onLocationSelected(
                    result.coordinates,
                    result.displayName,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
```

## Фильтрация по странам

Ограничить поиск конкретными странами:

```dart
final response = await client.geocode(
  query: 'Центральная улица',
  countryCodes: ['ru', 'kz', 'by'], // Россия, Казахстан, Беларусь
  limit: 5,
  language: 'ru',
);
```

## Офлайн-режим

Включаем кэширование для работы без интернета:

```dart
await QorviaMapsSDK.init(
  apiKey: 'ваш_api_key',
  offlineConfig: OfflineConfig(
    enabled: true,
    geocodeTtl: Duration(hours: 48), // Кэш живёт 48 часов
  ),
);

// Очистка старого кэша
await QorviaMapsSDK.cleanupCache();

// Полная очистка
await QorviaMapsSDK.clearAllCaches();
```

## Обработка ошибок

SDK выбрасывает типизированные исключения:

```dart
try {
  final response = await client.geocode(query: 'тест');
  // Обработка успеха
} on QorviaMapsException catch (e) {
  print('Ошибка API: ${e.message}');
  print('Код: ${e.statusCode}');

  // Можно показать пользователю понятное сообщение
  if (e.statusCode == 429) {
    showSnackBar('Слишком много запросов, подождите');
  }
} catch (e) {
  print('Неожиданная ошибка: $e');
}
```

## Сравнение с Яндекс и 2ГИС

| Критерий | Яндекс.Карты | 2ГИС | Qorvia MapKit                   |
|----------|--------------|------|---------------------------------|
| Бесплатный лимит | 1000 запросов/сутки | Ограничен | 10000 запросов в месяц          |
| Геокодинг без карты | ❌ Нельзя по лицензии | ❌ Только с SDK | ✅ Можно используя отдельное апи |
| Нативные зависимости | Требуются | Требуются | Нет (чистый Dart)               |
| Покрытие малых городов | ✅ Хорошее | ⚠️ Частичное | ⚠️ Частичное                     |
| Smart Search (NLP) | ❌ | ❌ | ✅                               |
| Location bias | ✅ | ✅ | ✅                               |
| Размер SDK | Тяжёлый | Тяжёлый | Легковесный                     |

## Когда выбрать что

**Яндекс.Карты** — если нужна полная экосистема Яндекса: карты, навигация, пробки. И бюджет позволяет.

**2ГИС** — если приложение работает только в крупных городах и важен поиск организаций с детальной информацией.

**Qorvia MapKit** — если:
- Полный White Label (карты можете настроить сами)
- Ограничен бюджет
- Важен лёгкий SDK без нативных зависимостей
- Приложение только в городах РФ
- Нужен умный поиск на естественном языке

## Итого

Яндекс и 2ГИС — отличные продукты, но не всегда подходят под задачу. Если вам нужна кастомизируемая карта, легковесный SDK и адекватные цены — есть альтернативы.

---

**Ссылки:**

- [Qorvia Maps SDK на pub.dev](https://pub.dev/packages/qorvia_maps_sdk)
- [Документация Qorvia MapKit](https://qorviamapkit.ru)

---

*Хабы: Flutter, Dart, Разработка мобильных приложений, Геоинформационные сервисы*

*Теги: flutter, dart, геокодинг, карты, google maps, мобильная разработка*
