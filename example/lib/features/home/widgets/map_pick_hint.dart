import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

/// Hint overlay for map point selection mode.
class MapPickHint extends StatelessWidget {
  const MapPickHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(160),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          AppLocalizations.of(context).tapMapToSelectPoint,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
