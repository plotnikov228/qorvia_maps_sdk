import 'package:flutter/material.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

import '../../../app/theme/app_colors.dart';

/// List of geocoding search results.
class SearchResultsList extends StatelessWidget {
  final List<GeocodeResult> results;
  final ValueChanged<GeocodeResult> onResultSelected;

  const SearchResultsList({
    super.key,
    required this.results,
    required this.onResultSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Результаты поиска',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: results.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final result = results[index];
              return ListTile(
                title: Text(result.displayName),
                onTap: () => onResultSelected(result),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              );
            },
          ),
        ),
      ],
    );
  }
}
