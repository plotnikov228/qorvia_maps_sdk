import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

class SearchResultItem {
  final String title;
  final String? subtitle;
  final String label;
  final Coordinates coordinates;

  const SearchResultItem({
    required this.title,
    required this.label,
    required this.coordinates,
    this.subtitle,
  });
}
