import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
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
  late AppLanguage _language;

  @override
  void initState() {
    super.initState();
    _searchMode = widget.settingsService.searchMode;
    _language = widget.settingsService.language;
    _log('Initialized', {
      'searchMode': _searchMode.name,
      'language': _language.name,
    });
  }

  Future<void> _onSearchModeChanged(SearchMode? mode) async {
    if (mode == null) return;

    _log('Changing search mode', {'to': mode.name});

    setState(() {
      _searchMode = mode;
    });

    await widget.settingsService.setSearchMode(mode);
  }

  Future<void> _onLanguageChanged(AppLanguage? language) async {
    if (language == null) return;

    _log('Changing language', {'to': language.name});

    setState(() {
      _language = language;
    });

    await widget.settingsService.setLanguage(language);
  }

  void _log(String message, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' $data' : '';
    developer.log('[SettingsScreen] $message$dataStr');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Language section
          _buildSectionHeader(l10n.language),
          _buildLanguageCard(l10n),

          const SizedBox(height: 24),

          // Search section
          _buildSectionHeader(l10n.search),
          _buildSearchModeCard(l10n),

          const SizedBox(height: 24),

          // Offline maps section
          _buildSectionHeader(l10n.offlineMaps),
          _buildOfflineMapsCard(l10n),
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

  Widget _buildLanguageCard(AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          RadioListTile<AppLanguage>(
            title: Text(l10n.languageSystem),
            value: AppLanguage.system,
            groupValue: _language,
            onChanged: _onLanguageChanged,
            activeColor: AppColors.primary,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          const Divider(height: 1),
          RadioListTile<AppLanguage>(
            title: Text(l10n.languageEnglish),
            value: AppLanguage.english,
            groupValue: _language,
            onChanged: _onLanguageChanged,
            activeColor: AppColors.primary,
          ),
          const Divider(height: 1),
          RadioListTile<AppLanguage>(
            title: Text(l10n.languageRussian),
            value: AppLanguage.russian,
            groupValue: _language,
            onChanged: _onLanguageChanged,
            activeColor: AppColors.primary,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchModeCard(AppLocalizations l10n) {
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
            title: Text(l10n.smartGeosearch),
            subtitle: Text(
              l10n.smartGeosearchDescription,
              style: const TextStyle(fontSize: 13),
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
            title: Text(l10n.regularGeocoding),
            subtitle: Text(
              l10n.regularGeocodingDescription,
              style: const TextStyle(fontSize: 13),
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

  Widget _buildOfflineMapsCard(AppLocalizations l10n) {
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
        title: Text(l10n.manageMaps),
        subtitle: Text(l10n.downloadMapsForOffline),
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
