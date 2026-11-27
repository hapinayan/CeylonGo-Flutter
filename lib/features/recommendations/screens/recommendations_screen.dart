import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/models/api_error.dart';
import '../../map/models/map_models.dart';
import '../models/recommendation_models.dart';
import '../services/recommendation_api_service.dart';
import '../services/recommendation_preferences_service.dart';

/// Reusable "Recommended for You" screen powered by real public backend
/// listings and deterministic client-side interest/district ranking.
class RecommendationsScreen extends StatefulWidget {
  final RecommendationApiService? recommendationService;
  final RecommendationPreferencesStore? preferencesStore;

  const RecommendationsScreen({
    super.key,
    this.recommendationService,
    this.preferencesStore,
  });

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  late final RecommendationApiService _service;
  late final RecommendationPreferencesStore _prefsStore;

  TravelerPreferences _preferences = const TravelerPreferences();
  bool _showInterestEditor = true;
  bool _isLoading = true;
  String? _errorMessage;
  RecommendationResultSet? _resultSet;

  @override
  void initState() {
    super.initState();
    _service = widget.recommendationService ?? RecommendationApiService();
    _prefsStore =
        widget.preferencesStore ?? SecureRecommendationPreferencesStore();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final loaded = await _prefsStore.load();
    if (!mounted) return;
    setState(() {
      _preferences = loaded;
    });
    await _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.fetchRecommendations(
        preferences: _preferences,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _resultSet = result;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
        _resultSet = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load recommendations right now.';
        _resultSet = null;
      });
    }
  }

  Future<void> _toggleInterest(TravelerInterest interest) async {
    final next = Set<TravelerInterest>.from(_preferences.selectedInterests);
    if (next.contains(interest)) {
      next.remove(interest);
    } else {
      next.add(interest);
    }
    final updated = _preferences.copyWith(selectedInterests: next);
    setState(() {
      _preferences = updated;
    });
    await _prefsStore.save(updated);
    await _fetchRecommendations();
  }

  Future<void> _selectDistrict(String? district) async {
    final updated = district == null || district == '__all__'
        ? _preferences.copyWith(clearDistrict: true)
        : _preferences.copyWith(preferredDistrict: district);
    setState(() {
      _preferences = updated;
    });
    await _prefsStore.save(updated);
    await _fetchRecommendations();
  }

  Future<void> _clearPreferences() async {
    setState(() {
      _preferences = const TravelerPreferences();
    });
    await _prefsStore.clear();
    await _fetchRecommendations();
  }

  void _openDetails(MapLocationItem item) {
    final route = item.supportedFlutterDetailRoute;
    if (route != null) {
      Navigator.pushNamed(context, route);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        key: const Key('rec_detail_sheet'),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.category.replaceAll('_', ' ')}'
              '${item.locationSubtitle.isNotEmpty ? ' • ${item.locationSubtitle}' : ''}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            if (item.address != null) ...[
              const SizedBox(height: 8),
              Text(
                item.address!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children: [
                if (item.price != null)
                  Text(
                    '${item.currency ?? 'LKR'} ${item.price!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                if (item.rating != null)
                  Text(
                    '★ ${item.rating!.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD97706),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final districts = _resultSet?.availableDistricts ?? const <String>[];
    final recs = _resultSet?.recommendations ?? const <RankedRecommendation>[];

    return Scaffold(
      key: const Key('recommendations_screen'),
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        title: const Text(
          'Recommended for You',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppTheme.primaryNavy,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            key: const Key('rec_edit_interests_btn'),
            tooltip: _showInterestEditor ? 'Hide Interests' : 'Edit Interests',
            onPressed: () =>
                setState(() => _showInterestEditor = !_showInterestEditor),
            icon: Icon(
              _showInterestEditor ? Icons.tune_rounded : Icons.tune_outlined,
              color: AppTheme.primaryNavy,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Container(
              key: const Key('rec_client_side_notice'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primarySubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: const Text(
                'Recommended for You — Based on Your Selected Interests. Ranked locally from your saved preferences using approved public CeylonGo listings.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ),
            if (_showInterestEditor) ...[
              const SizedBox(height: 12),
              _buildInterestEditor(districts),
            ],
            if (_preferences.selectedInterests.isEmpty) ...[
              const SizedBox(height: 10),
              Container(
                key: const Key('rec_no_interests_banner'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSlate),
                ),
                child: const Text(
                  'No specific interests selected — showing all available public listings. Tap interests above to personalize.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
            if (_resultSet != null && _resultSet!.hasMore) ...[
              const SizedBox(height: 10),
              Container(
                key: const Key('rec_partial_notice'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Text(
                  'Showing partial results from the first page of public listings.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (_isLoading)
              const Padding(
                key: Key('rec_loading'),
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryNavy),
                ),
              )
            else if (_errorMessage != null)
              Container(
                key: const Key('rec_error_banner'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      key: const Key('rec_retry_btn'),
                      onPressed: _fetchRecommendations,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (recs.isEmpty)
              Container(
                key: const Key('rec_empty_state'),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderSlate),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.explore_off_outlined,
                      size: 36,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No public listings match your current interests or district.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (!_preferences.isEmpty) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _clearPreferences,
                        child: const Text('Clear Preferences'),
                      ),
                    ],
                  ],
                ),
              )
            else
              ...recs.map(_buildRecommendationCard),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestEditor(List<String> districts) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Your Travel Interests',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
              if (!_preferences.isEmpty)
                TextButton(
                  key: const Key('rec_clear_prefs_btn'),
                  onPressed: _clearPreferences,
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: TravelerInterest.values.map((interest) {
              final selected =
                  _preferences.selectedInterests.contains(interest);
              return FilterChip(
                key: Key('rec_interest_${interest.id}'),
                label: Text(interest.label),
                selected: selected,
                selectedColor: AppTheme.primaryNavy,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.primaryNavy,
                ),
                onSelected: (_) => _toggleInterest(interest),
              );
            }).toList(),
          ),
          if (districts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                const Text(
                  'District:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                PopupMenuButton<String>(
                  key: const Key('rec_district_filter'),
                  onSelected: _selectDistrict,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: '__all__',
                      child: Text('All Districts'),
                    ),
                    ...districts.map(
                      (d) => PopupMenuItem(value: d, child: Text(d)),
                    ),
                  ],
                  child: Chip(
                    label: Text(
                      _preferences.preferredDistrict ?? 'All Districts',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(RankedRecommendation rec) {
    final item = rec.item;
    return Container(
      key: Key('rec_card_${item.uniqueKey}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl != null && item.imageUrl!.startsWith('http')) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.imageUrl!,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.category.replaceAll('_', ' ')}'
                      '${item.locationSubtitle.isNotEmpty ? ' • ${item.locationSubtitle}' : ''}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.rating != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '★ ${item.rating!.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rec.explanationText,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.price != null)
                  Text(
                    '${item.currency ?? 'LKR'} ${item.price!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryNavy,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                OutlinedButton(
                  key: Key('rec_details_btn_${item.uniqueKey}'),
                  onPressed: () => _openDetails(item),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
