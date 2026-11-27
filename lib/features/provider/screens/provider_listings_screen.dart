import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/models/api_error.dart';
import '../../categories/models/discovery_models.dart';
import '../models/provider_models.dart';
import '../services/provider_service.dart';

/// Provider Listings, Rooms/Units & Availability Management Screen
class ProviderListingsScreen extends StatefulWidget {
  final ProviderService? providerService;
  final bool focusAvailability;

  const ProviderListingsScreen({
    super.key,
    this.providerService,
    this.focusAvailability = false,
  });

  @override
  State<ProviderListingsScreen> createState() => _ProviderListingsScreenState();
}

class _ProviderListingsScreenState extends State<ProviderListingsScreen> {
  late final ProviderService _service;
  bool _loading = true;
  String? _error;
  List<ProviderListingModel> _listings = [];

  @override
  void initState() {
    super.initState();
    _service = widget.providerService ?? ProviderService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.getMyListings();
      if (!mounted) return;
      setState(() {
        _listings = list;
        _loading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load provider listings.';
      });
    }
  }

  Future<void> _openCreateListingDialog() async {
    String category = 'homestay';
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final districtCtrl = TextEditingController(text: 'Kandy');
    final localityCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '12000');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create New Listing'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'homestay', child: Text('Homestay')),
                    DropdownMenuItem(value: 'activity', child: Text('Activity')),
                    DropdownMenuItem(value: 'tour_guide', child: Text('Tour Guide')),
                    DropdownMenuItem(value: 'rental', child: Text('Rental Vehicle')),
                    DropdownMenuItem(value: 'artisan', child: Text('Artisan')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => category = v ?? 'homestay'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: districtCtrl,
                  decoration: const InputDecoration(labelText: 'District *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: localityCtrl,
                  decoration: const InputDecoration(labelText: 'City / Locality *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Base Price (LKR)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create Draft'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || titleCtrl.text.trim().isEmpty) return;

    try {
      await _service.createListing(
        category: category,
        title: titleCtrl.text,
        description: descCtrl.text.trim().isEmpty
            ? titleCtrl.text.trim()
            : descCtrl.text,
        district: districtCtrl.text,
        locality: localityCtrl.text.trim().isEmpty
            ? districtCtrl.text.trim()
            : localityCtrl.text,
        price: priceCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft listing created.')),
      );
      _load();
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _submitForReview(ProviderListingModel listing) async {
    try {
      await _service.submitListingForReview(listing.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing submitted for admin verification.')),
      );
      _load();
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _togglePublish(ProviderListingModel listing) async {
    try {
      await _service.setListingPublished(
        listing.id,
        publish: !listing.isActive,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !listing.isActive ? 'Listing published.' : 'Listing unpublished.',
          ),
        ),
      );
      _load();
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _manageAvailabilitySheet(ProviderListingModel listing) async {
    List<ProviderAvailabilitySlot> slots = [];
    try {
      slots = await _service.getAvailabilitySlots(listing.id);
    } catch (_) {}

    if (!mounted) return;
    final unitCtrl = TextEditingController(
      text: listing.category == 'homestay' ? 'Deluxe Room 1' : 'Slot Unit',
    );
    int? selectedUnitId = listing.units.isNotEmpty
        ? listing.units.first.id
        : (listing.rooms.isNotEmpty ? listing.rooms.first.id : null);
    DateTime slotDate = DateTime.now().add(const Duration(days: 2));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Inventory & Availability — ${listing.title}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: unitCtrl,
                      decoration: InputDecoration(
                        labelText: listing.category == 'homestay'
                            ? 'Add Room Label'
                            : 'Add Unit Label',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (unitCtrl.text.trim().isEmpty) return;
                      try {
                        final unit = listing.category == 'homestay'
                            ? await _service.addRoom(
                                listing.id,
                                label: unitCtrl.text,
                                nightlyPrice: listing.price,
                              )
                            : await _service.addInventoryUnit(
                                listing.id,
                                label: unitCtrl.text,
                              );
                        selectedUnitId = unit.id;
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Added ${unit.label}')),
                          );
                        }
                        _load();
                      } on ApiError catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx)
                              .showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (selectedUnitId != null)
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: slotDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked == null) return;
                    final starts = DateTime(picked.year, picked.month, picked.day, 9);
                    final ends = starts.add(const Duration(hours: 3));
                    try {
                      final created = await _service.createAvailabilitySlot(
                        listing.id,
                        unitId: selectedUnitId!,
                        startsAt: starts,
                        endsAt: ends,
                        capacity: 4,
                      );
                      setSheetState(() => slots = [...slots, created]);
                    } on ApiError catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx)
                            .showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    }
                  },
                  icon: const Icon(Icons.add_alarm_outlined, size: 18),
                  label: const Text('Open Availability Slot on Selected Date'),
                ),
              const SizedBox(height: 10),
              Text(
                'Configured Slots (${slots.length})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (slots.isEmpty)
                const Text(
                  'No availability slots created yet.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                )
              else
                ...slots.take(6).map(
                      (s) => Text(
                        'Unit #${s.unitId}: ${s.startsAt.toLocal().toString().substring(0, 16)} (Cap ${s.capacity})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.focusAvailability ? 'Manage Availability' : 'Manage Listings',
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateListingDialog,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Listing'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _listings.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.list_alt_outlined,
                                size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 10),
                            const Text(
                              'No listings yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Create your first homestay, activity, tour guide, rental, or artisan listing.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                        itemCount: _listings.length,
                        itemBuilder: (_, index) {
                          final item = _listings[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: AppTheme.borderSlate),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryNavy,
                                          ),
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          item.verificationStatus.toUpperCase(),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.category.toUpperCase()} • ${item.locality}, ${item.district} • ${formatLkrAmount(item.price)}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  if (item.decisionReason != null &&
                                      item.decisionReason!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Review note: ${item.decisionReason}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.errorRed,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            _manageAvailabilitySheet(item),
                                        icon: const Icon(
                                          Icons.event_available_outlined,
                                          size: 16,
                                        ),
                                        label: const Text('Units & Availability'),
                                      ),
                                      if (item.verificationStatus == 'draft' ||
                                          item.verificationStatus == 'rejected')
                                        ElevatedButton(
                                          onPressed: () => _submitForReview(item),
                                          child: const Text('Submit for Review'),
                                        ),
                                      if (item.verificationStatus == 'approved')
                                        ElevatedButton(
                                          onPressed: () => _togglePublish(item),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: item.isActive
                                                ? Colors.grey.shade700
                                                : AppTheme.successGreen,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: Text(
                                            item.isActive ? 'Unpublish' : 'Publish',
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
