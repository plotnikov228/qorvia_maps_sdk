import 'package:equatable/equatable.dart';

import '../coordinates.dart';
import 'opening_hours_entry.dart';

/// A single smart search result.
///
/// Contains place or address information returned by the smart search API.
class SmartSearchResult extends Equatable {
  /// Place or address name.
  final String name;

  /// Full address string.
  final String address;

  /// Latitude of the location.
  final double lat;

  /// Longitude of the location.
  final double lon;

  /// Distance from user location in meters.
  final int distanceM;

  /// Rating of the place (0-5 scale), null if not available.
  final double? rating;

  /// Type of place (e.g., "pharmacy", "cafe"), null for addresses.
  final String? placeType;

  /// Phone number, null if not available.
  final String? phone;

  /// Website URL, null if not available.
  final String? website;

  /// Opening hours entries, null if not available.
  final List<OpeningHoursEntry>? openingHours;

  /// Photo URL, null if not available.
  final String? photoUrl;

  /// Place ID from provider (e.g., Google Places ID), null if not available.
  final String? placeId;

  const SmartSearchResult({
    required this.name,
    required this.address,
    required this.lat,
    required this.lon,
    required this.distanceM,
    this.rating,
    this.placeType,
    this.phone,
    this.website,
    this.openingHours,
    this.photoUrl,
    this.placeId,
  });

  /// Returns coordinates as a [Coordinates] object.
  Coordinates get coordinates => Coordinates(lat: lat, lon: lon);

  factory SmartSearchResult.fromJson(Map<String, dynamic> json) {
    return SmartSearchResult(
      name: json['name'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      distanceM: json['distance_m'] as int,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      placeType: json['place_type'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      openingHours: json['opening_hours'] != null
          ? (json['opening_hours'] as List)
              .map((e) => OpeningHoursEntry.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      photoUrl: json['photo_url'] as String?,
      placeId: json['place_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'lat': lat,
        'lon': lon,
        'distance_m': distanceM,
        if (rating != null) 'rating': rating,
        if (placeType != null) 'place_type': placeType,
        if (phone != null) 'phone': phone,
        if (website != null) 'website': website,
        if (openingHours != null)
          'opening_hours': openingHours!.map((e) => e.toJson()).toList(),
        if (photoUrl != null) 'photo_url': photoUrl,
        if (placeId != null) 'place_id': placeId,
      };

  @override
  List<Object?> get props => [
        name,
        address,
        lat,
        lon,
        distanceM,
        rating,
        placeType,
        phone,
        website,
        openingHours,
        photoUrl,
        placeId,
      ];
}
