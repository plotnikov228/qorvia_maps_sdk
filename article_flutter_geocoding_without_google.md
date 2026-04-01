# Flutter Geocoding Without Google API: A Complete Guide

*Break free from Google's pricing and build powerful location features with open alternatives*

---

If you've ever built a Flutter app that needs geocoding, you've probably faced the same challenge: Google Maps API pricing can quickly spiral out of control. At $5 per 1,000 requests for geocoding and $7 per 1,000 for Places API, costs add up fast — especially for apps with significant user bases.

In this article, I'll show you how to implement full-featured geocoding in Flutter without touching Google's APIs. We'll explore an alternative that offers forward geocoding, reverse geocoding, and even AI-powered smart search — all without the Google tax.

## Why Move Away from Google Maps API?

Before diving into the code, let's address the elephant in the room:

**Cost**: Google's pay-per-request model can devastate budgets. A moderately popular app making 100,000 geocoding requests per month would pay $500+ just for address lookups.

**Complexity**: Setting up Google Cloud Console, managing API keys, handling billing alerts — it's a lot of overhead for a simple feature.

**Privacy Concerns**: Some applications, especially those targeting European markets or dealing with sensitive data, prefer to minimize data sharing with big tech.

**Vendor Lock-in**: Once you're deep into Google's ecosystem, switching becomes painful.

## The Alternative: Qorvia MapKit

For this tutorial, we'll use the **Qorvia Maps SDK** — a Flutter package that wraps the Qorvia MapKit API. It provides:

- Forward Geocoding (address → coordinates)
- Reverse Geocoding (coordinates → address)
- Smart Search with natural language processing
- Location bias for contextual results
- Multi-language support (Russian, English)
- Offline caching

Let's build something real.

## Getting Started

### Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  qorvia_maps_sdk: ^0.2.6
```

### Initialize the SDK

```dart
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await QorviaMapsSDK.init(
    apiKey: 'your_api_key_here',
  );

  runApp(MyApp());
}
```

That's it. No Google Cloud Console, no OAuth setup, no billing configuration dance.

## Forward Geocoding: Address to Coordinates

The most common geocoding task: your user types an address, and you need coordinates. Here's how:

```dart
final client = QorviaMapsSDK.instance.client;

Future<void> searchAddress(String query) async {
  final response = await client.geocode(
    query: query,
    limit: 5,
    language: 'en',
  );

  for (final result in response.results) {
    print('📍 ${result.displayName}');
    print('   Lat: ${result.coordinates.lat}');
    print('   Lon: ${result.coordinates.lon}');
    print('   City: ${result.address.city}');
    print('   Country: ${result.address.country}');
  }
}
```

### Response Structure

The geocoding response provides rich, structured data:

```dart
class GeocodeResult {
  final Coordinates coordinates;    // lat/lon
  final String displayName;         // Full location name
  final Address address;            // Structured address components
  final String placeType;           // 'place', 'address', 'poi'
  final double importance;          // Relevance score (0-1)
  final List<double>? bbox;         // Bounding box for the location
}
```

The `Address` class gives you granular access to address components:

```dart
final address = result.address;

print(address.road);        // Street name
print(address.houseNumber); // Building number
print(address.city);        // City
print(address.state);       // State/Region
print(address.country);     // Country
print(address.postcode);    // Postal code

// Convenience getters
print(address.shortAddress); // "Main Street, 42"
print(address.fullAddress);  // Complete formatted address
```

## Reverse Geocoding: Coordinates to Address

When you have coordinates (from GPS or a map tap) and need the address:

```dart
Future<void> getAddressFromCoordinates(double lat, double lon) async {
  final response = await client.reverseLatLon(
    lat: lat,
    lon: lon,
    language: 'en',
  );

  print('Address: ${response.displayName}');
  print('Street: ${response.address.road} ${response.address.houseNumber}');
  print('City: ${response.address.city}');
}
```

Or using the `Coordinates` object:

```dart
final response = await client.reverse(
  coordinates: Coordinates(lat: 55.7539, lon: 37.6208),
  language: 'en',
);
```

## Location Bias: Context-Aware Results

Here's where things get interesting. Location bias prioritizes results near a specific point — perfect for "find nearby" scenarios.

```dart
final response = await client.geocode(
  query: 'coffee shop',
  limit: 5,
  language: 'en',
  userLat: 40.7128,       // User's current latitude
  userLon: -74.0060,      // User's current longitude
  radiusKm: 10,           // Search within 10km
  biasLocation: true,     // Enable location bias
);

// Results sorted by proximity to user location
for (final result in response.results) {
  print('${result.displayName}');
  print('Relevance: ${result.importance}');
}
```

This is incredibly useful for apps where local context matters — food delivery, ride-sharing, local services, and more.

## Smart Search: Natural Language Processing

The most powerful feature is **Smart Search** — it uses AI to understand natural language queries and automatically classifies them:

```dart
final response = await client.smartSearch(
  query: 'nearest pharmacy open now',
  lat: 55.7558,
  lon: 37.6173,
  radiusKm: 5,
  limit: 5,
  language: 'en',
);

print('Query type: ${response.classifiedAs}'); // 'PLACE' or 'ADDRESS'

for (final result in response.results) {
  print('📍 ${result.name}');
  print('   ${result.address}');
  print('   ${result.distanceM} meters away');

  if (result.rating != null) {
    print('   ⭐ ${result.rating}/5');
  }

  if (result.openingHours != null) {
    for (final hours in result.openingHours!) {
      print('   ${hours.day}: ${hours.open} - ${hours.close}');
    }
  }

  if (result.phone != null) {
    print('   📞 ${result.phone}');
  }
}
```

The `SmartSearchResult` provides rich metadata:

- **Name and address**
- **Distance** from user (in meters)
- **Rating** (0-5 scale)
- **Place type** (pharmacy, cafe, hotel, etc.)
- **Contact info** (phone, website)
- **Opening hours**
- **Photo URL**

## Building a Real Search UI

Let's put it all together with a practical search panel:

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
        language: 'en',
      );

      setState(() {
        _results = response.results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
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
            hintText: 'Search for a place...',
            prefixIcon: Icon(Icons.search),
            suffixIcon: _isLoading
              ? Padding(
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
                leading: Icon(Icons.location_on),
                title: Text(result.address.shortAddress),
                subtitle: Text(result.address.city ?? result.displayName),
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

## Country Filtering

Restrict results to specific countries:

```dart
final response = await client.geocode(
  query: 'Berlin',
  countryCodes: ['de', 'at', 'ch'], // Germany, Austria, Switzerland
  limit: 5,
);
```

## Offline Support

Enable caching for offline access:

```dart
await QorviaMapsSDK.init(
  apiKey: 'your_api_key',
  offlineConfig: OfflineConfig(
    enabled: true,
    geocodeTtl: Duration(hours: 48), // Cache results for 48 hours
  ),
);

// Later, clean up old cache
await QorviaMapsSDK.cleanupCache();
```

## Error Handling

The SDK provides specific exceptions for different error scenarios:

```dart
try {
  final response = await client.geocode(query: 'test');
  // Handle success
} on QorviaMapsException catch (e) {
  print('API Error: ${e.message}');
  print('Status Code: ${e.statusCode}');
} catch (e) {
  print('Unexpected error: $e');
}
```

## Cost Comparison

Let's do some quick math for an app with 100,000 geocoding requests per month:

| Service | Cost |
|---------|------|
| Google Geocoding API | ~$500/month |
| Google Places API | ~$700/month |
| Qorvia MapKit | Varies by plan, often 50-80% less |

Beyond raw pricing, Qorvia offers a simpler billing model without the complexity of Google Cloud's SKU-based pricing.

## When to Use This Approach

This solution is ideal for:

- **Budget-conscious projects** — startups, indie developers, MVPs
- **Apps targeting Russian-speaking markets** — excellent Russian language support
- **Privacy-focused applications** — minimize data sharing
- **Offline-first apps** — built-in caching support
- **Apps needing contextual search** — location bias is powerful

Google Maps API might still be preferable for:

- Apps heavily integrated with other Google services
- Projects with existing Google Cloud infrastructure
- Use cases requiring Street View or specific Google-only features

## Conclusion

Geocoding in Flutter doesn't require Google. With alternatives like Qorvia Maps SDK, you get:

- **Forward geocoding** — address to coordinates
- **Reverse geocoding** — coordinates to address
- **Smart search** — natural language understanding
- **Location bias** — contextual, proximity-based results
- **Offline caching** — resilient offline-first apps
- **Simpler pricing** — predictable costs

The implementation is straightforward, the API is clean, and your wallet will thank you.

---

*Have questions or want to share your experience with non-Google geocoding? Drop a comment below!*

---

**Resources:**

- [Qorvia Maps SDK on pub.dev](https://pub.dev/packages/qorvia_maps_sdk)
- [Qorvia MapKit Documentation](https://qorviamapkit.ru)
- [GitHub Repository](https://github.com/qorvia/qorvia_maps_sdk)

---

*Tags: Flutter, Dart, Geocoding, Maps, Mobile Development, Google Maps Alternative, Location Services*
