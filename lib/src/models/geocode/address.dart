import 'package:equatable/equatable.dart';

/// Structured address information.
class Address extends Equatable {
  final String? building;
  final String? houseNumber;
  final String? road;
  final String? suburb;
  final String? city;
  final String? state;
  final String? postcode;
  final String? country;
  final String? countryCode;

  const Address({
    this.building,
    this.houseNumber,
    this.road,
    this.suburb,
    this.city,
    this.state,
    this.postcode,
    this.country,
    this.countryCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      building: json['building'] as String?,
      houseNumber: json['house_number'] as String?,
      road: json['road'] as String?,
      suburb: json['suburb'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postcode: json['postcode'] as String?,
      country: json['country'] as String?,
      countryCode: json['country_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (building != null) 'building': building,
        if (houseNumber != null) 'house_number': houseNumber,
        if (road != null) 'road': road,
        if (suburb != null) 'suburb': suburb,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (postcode != null) 'postcode': postcode,
        if (country != null) 'country': country,
        if (countryCode != null) 'country_code': countryCode,
      };

  /// Returns a short address string (road + house number or city).
  String get shortAddress {
    if (road != null) {
      return houseNumber != null ? '$road, $houseNumber' : road!;
    }
    return city ?? country ?? '';
  }

  /// Returns a full address string.
  String get fullAddress {
    final parts = <String>[];
    if (building != null) parts.add(building!);
    if (road != null) {
      parts.add(houseNumber != null ? '$road, $houseNumber' : road!);
    }
    if (suburb != null) parts.add(suburb!);
    if (city != null) parts.add(city!);
    if (state != null && state != city) parts.add(state!);
    if (postcode != null) parts.add(postcode!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
        building,
        houseNumber,
        road,
        suburb,
        city,
        state,
        postcode,
        country,
        countryCode,
      ];
}
