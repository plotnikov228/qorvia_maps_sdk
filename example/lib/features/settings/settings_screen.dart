import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'offline_maps_screen.dart';
import 'settings_service.dart';

/// Settings screen with search mode and offline maps configuration.
class SettingsScreen extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsScreen({
    super.key,
    required this.settingsService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SearchMode _searchMode;

  @override
  void initState() {
    super.initState();
    _searchMode = widget.settingsService.searchMode;
    _log('Initialized', {'searchMode': _searchMode.name});
  }

  Future<void> _onSearchModeChanged(SearchMode? mode) async {
    if (mode == null) return;

    _log('Changing search mode', {'to': mode.name});

    setState(() {
      _searchMode = mode;
    });

    await widget.settingsService.setSearchMode(mode);
  }

  void _log(String message, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' $data' : '';
    developer.log('[SettingsScreen] $message$dataStr');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Search section
          _buildSectionHeader('Поиск'),
          _buildSearchModeCard(),

          const SizedBox(height: 24),

          // Offline maps section
          _buildSectionHeader('Офлайн карты'),
          _buildOfflineMapsCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSearchModeCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          RadioListTile<SearchMode>(
            title: const Text('Smart Geosearch'),
            subtitle: const Text(
              'AI-улучшенный поиск с лучшими результатами',
              style: TextStyle(fontSize: 13),
            ),
            value: SearchMode.smartGeosearch,
            groupValue: _searchMode,
            onChanged: _onSearchModeChanged,
            activeColor: AppColors.primary,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          const Divider(height: 1),
          RadioListTile<SearchMode>(
            title: const Text('Обычный геокодинг'),
            subtitle: const Text(
              'Стандартный поиск адресов',
              style: TextStyle(fontSize: 13),
            ),
            value: SearchMode.regularGeocoding,
            groupValue: _searchMode,
            onChanged: _onSearchModeChanged,
            activeColor: AppColors.primary,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineMapsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.download_rounded,
            color: AppColors.primary,
          ),
        ),
        title: const Text('Управление картами'),
        subtitle: const Text('Скачайте карты для офлайн использования'),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.outline,
        ),
        onTap: () {
          _log('Navigating to offline maps');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OfflineMapsScreen(),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
