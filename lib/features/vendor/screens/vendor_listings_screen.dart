import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/vendor_models.dart';
import '../services/vendor_demo_service.dart';
import '../services/vendor_photo_picker.dart';
import '../widgets/vendor_bottom_nav_bar.dart';
import '../widgets/vendor_listing_image.dart';
import '../widgets/vendor_listing_photo_section.dart';

/// Vendor Listing Management Screen (In-Memory Demo State)
/// Supports search, status & category filtering, Add, Edit, Details,
/// Active/Inactive toggle, and Delete with confirmation.
class VendorListingsScreen extends StatefulWidget {
  final VendorPhotoPicker? photoPicker;

  const VendorListingsScreen({super.key, this.photoPicker});

  @override
  State<VendorListingsScreen> createState() => _VendorListingsScreenState();
}

class _VendorListingsScreenState extends State<VendorListingsScreen> {
  final VendorDemoService _service = VendorDemoService.instance;
  final TextEditingController _searchController = TextEditingController();

  VendorCategory? _categoryFilter;

  static const List<({VendorCategory category, String label})> _filterTabs = [
    (category: VendorCategory.homestay, label: 'Homestay'),
    (category: VendorCategory.ecoTourism, label: 'Eco Tourism'),
    (category: VendorCategory.activity, label: 'Activity'),
    (category: VendorCategory.localGuide, label: 'Guide'),
    (category: VendorCategory.rental, label: 'Rental'),
    (category: VendorCategory.artisan, label: 'Artisan'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VendorListing> get _filteredListings {
    final q = _searchController.text.trim().toLowerCase();
    return _service.listings.where((item) {
      if (_categoryFilter != null && item.category != _categoryFilter) {
        return false;
      }
      if (q.isNotEmpty &&
          !item.title.toLowerCase().contains(q) &&
          !item.location.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openForm({VendorListing? existing}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VendorListingFormScreen(
          existing: existing,
          photoPicker: widget.photoPicker,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _confirmDelete(VendorListing item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing?'),
        content: Text(
          'Remove "${item.title}" from your local demo listings?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_listing_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _service.deleteListing(item.id);
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDetails(VendorListing item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: VendorListingImage(
                    photo: item.coverPhoto,
                    fallbackImageUrl: item.imageUrl,
                    fallbackIcon: Icons.storefront_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.category.label} • ${item.location} • LKR ${item.priceLkr} ${item.category.priceUnitSuffix}'
                    .trim(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A4DF5),
                ),
              ),
              if (item.categoryDetails.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...VendorCategoryFormConfig.fieldsFor(item.category).map((spec) {
                  final val = item.categoryDetails[spec.key];
                  if (val == null || val.trim().isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '${spec.label}: $val',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Color(0xFF334155),
                      ),
                    ),
                  );
                }),
              ] else if (item.categorySpecificValue.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '${item.category.specificFieldLabel}: ${item.categorySpecificValue}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                item.description,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A4DF5),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
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
    final items = _filteredListings;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        title: const Text(
          'My Listings',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('vendor_add_listing_fab'),
        backgroundColor: const Color(0xFF0A4DF5),
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Listing'),
      ),
      bottomNavigationBar: const VendorBottomNavigationBar(currentIndex: 1),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              key: const Key('vendor_listings_search'),
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search my listings...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.primaryNavy,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFDBEAFE)),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: const Key('category_filter_all'),
                    label: const Text('All'),
                    selected: _categoryFilter == null,
                    selectedColor: const Color(0xFF0A4DF5),
                    backgroundColor: const Color(0xFFF8FAFC),
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: _categoryFilter == null
                          ? const Color(0xFF0A4DF5)
                          : const Color(0xFFDBEAFE),
                    ),
                    labelStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _categoryFilter == null
                          ? Colors.white
                          : AppTheme.primaryNavy,
                    ),
                    onSelected: (_) {
                      setState(() => _categoryFilter = null);
                    },
                  ),
                ),
                ..._filterTabs.map((tab) {
                  final isSelected = _categoryFilter == tab.category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: Key('category_filter_${tab.category.name}'),
                      label: Text(tab.label),
                      selected: isSelected,
                      selectedColor: const Color(0xFF0A4DF5),
                      backgroundColor: const Color(0xFFF8FAFC),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF0A4DF5)
                            : const Color(0xFFDBEAFE),
                      ),
                      labelStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.primaryNavy,
                      ),
                      onSelected: (sel) {
                        setState(() {
                          _categoryFilter = sel ? tab.category : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'No listings match your filter.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 88,
                                  height: 82,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: VendorListingImage(
                                          photo: item.coverPhoto,
                                          fallbackImageUrl: item.imageUrl,
                                          fallbackIcon:
                                              Icons.storefront_outlined,
                                        ),
                                      ),
                                      if (item.photos.length > 1)
                                        Positioned(
                                          right: 4,
                                          bottom: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black87,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${item.photos.length} photos',
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryNavy,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.category.label} • ${item.location}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'LKR ${item.priceLkr} ${item.category.priceUnitSuffix}'
                                            .trim(),
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0A4DF5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: item.isActive,
                                  onChanged: (_) {
                                    _service.toggleListingStatus(item.id);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              children: [
                                TextButton(
                                  onPressed: () => _showDetails(item),
                                  child: const Text('Details'),
                                ),
                                TextButton(
                                  key: Key('edit_listing_${item.id}'),
                                  onPressed: () => _openForm(existing: item),
                                  child: const Text('Edit'),
                                ),
                                TextButton(
                                  key: Key('delete_listing_${item.id}'),
                                  onPressed: () => _confirmDelete(item),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.errorRed,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Add / Edit Vendor Listing Form Screen
class VendorListingFormScreen extends StatefulWidget {
  final VendorListing? existing;
  final VendorPhotoPicker? photoPicker;

  const VendorListingFormScreen({
    super.key,
    this.existing,
    this.photoPicker,
  });

  @override
  State<VendorListingFormScreen> createState() =>
      _VendorListingFormScreenState();
}

class _VendorListingFormScreenState extends State<VendorListingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final VendorPhotoPicker _photoPicker;

  final Map<String, TextEditingController> _categoryFieldControllers = {};
  final List<VendorListingPhoto> _photos = [];

  late VendorCategory _category;
  late bool _isActive;
  int _coverPhotoIndex = 0;
  bool _isPickingPhoto = false;
  bool _isSaving = false;
  String? _photoError;

  @override
  void initState() {
    super.initState();
    _photoPicker = widget.photoPicker ?? ImagePickerVendorPhotoPicker();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _priceController = TextEditingController(
      text: e != null ? e.priceLkr.toString() : '',
    );
    _descriptionController = TextEditingController(
      text: e?.description ?? '',
    );
    _category = e?.category ?? VendorCategory.homestay;
    _isActive = e?.isActive ?? true;

    if (e != null) {
      if (e.photos.isNotEmpty) {
        _photos.addAll(e.photos);
        _coverPhotoIndex =
            (e.coverPhotoIndex >= 0 && e.coverPhotoIndex < _photos.length)
                ? e.coverPhotoIndex
                : 0;
      } else if (e.imageUrl.trim().isNotEmpty) {
        _photos.add(
          VendorListingPhoto(
            id: 'existing_${e.id}',
            path: e.imageUrl.trim(),
            isLocalFile: !e.imageUrl.trim().startsWith('http'),
          ),
        );
      }

      for (final entry in e.categoryDetails.entries) {
        _categoryFieldControllers[entry.key] =
            TextEditingController(text: entry.value);
      }
      if (e.categoryDetails.isEmpty &&
          e.categorySpecificValue.trim().isNotEmpty) {
        final specs = VendorCategoryFormConfig.fieldsFor(_category);
        if (specs.isNotEmpty) {
          _categoryFieldControllers[specs.first.key] =
              TextEditingController(text: e.categorySpecificValue);
        }
      }
    }
    _ensureCategoryControllers(_category);
  }

  void _ensureCategoryControllers(VendorCategory category) {
    for (final spec in VendorCategoryFormConfig.fieldsFor(category)) {
      _categoryFieldControllers.putIfAbsent(
        spec.key,
        () => TextEditingController(),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    for (final c in _categoryFieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _onPickGallery() async {
    final remaining = VendorPhotoPicker.maxPhotos - _photos.length;
    if (remaining <= 0) {
      setState(() {
        _photoError = 'Maximum ${VendorPhotoPicker.maxPhotos} photos reached.';
      });
      return;
    }

    setState(() {
      _isPickingPhoto = true;
      _photoError = null;
    });

    try {
      final picked = await _photoPicker.pickFromGallery(maxCount: remaining);
      if (!mounted) return;
      if (picked.isNotEmpty) {
        setState(() {
          _photos.addAll(picked.take(remaining));
        });
      }
    } on VendorPhotoException catch (e) {
      if (mounted) setState(() => _photoError = e.message);
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _onCaptureCamera() async {
    if (_photos.length >= VendorPhotoPicker.maxPhotos) {
      setState(() {
        _photoError = 'Maximum ${VendorPhotoPicker.maxPhotos} photos reached.';
      });
      return;
    }

    setState(() {
      _isPickingPhoto = true;
      _photoError = null;
    });

    try {
      final photo = await _photoPicker.captureFromCamera();
      if (!mounted) return;
      if (photo != null) {
        setState(() {
          _photos.add(photo);
        });
      }
    } on VendorPhotoException catch (e) {
      if (mounted) setState(() => _photoError = e.message);
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  void _onRemovePhoto(int index) {
    if (index < 0 || index >= _photos.length) return;
    setState(() {
      _photoError = null;
      _photos.removeAt(index);
      if (_photos.isEmpty) {
        _coverPhotoIndex = 0;
      } else if (_coverPhotoIndex >= _photos.length) {
        _coverPhotoIndex = 0;
      } else if (index < _coverPhotoIndex) {
        _coverPhotoIndex -= 1;
      }
    });
  }

  void _onSelectCover(int index) {
    if (index < 0 || index >= _photos.length) return;
    setState(() => _coverPhotoIndex = index);
  }

  InputDecoration _roundedDecoration({
    required String label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      isDense: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderSlate),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderSlate),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0A4DF5), width: 1.5),
      ),
    );
  }

  void _onSave() {
    if (_isSaving || _isPickingPhoto) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final service = VendorDemoService.instance;
    final specs = VendorCategoryFormConfig.fieldsFor(_category);

    final detailsMap = <String, String>{};
    final summaryParts = <String>[];
    for (final spec in specs) {
      final val = _categoryFieldControllers[spec.key]?.text.trim() ?? '';
      if (val.isNotEmpty) {
        detailsMap[spec.key] = val;
        summaryParts.add(val);
      }
    }
    final summaryText = summaryParts.join(' • ');
    final safeCoverIdx =
        (_photos.isNotEmpty && _coverPhotoIndex < _photos.length)
            ? _coverPhotoIndex
            : 0;
    final coverPath =
        _photos.isNotEmpty ? _photos[safeCoverIdx].path : '';

    if (widget.existing != null) {
      service.updateListing(
        widget.existing!.copyWith(
          ownerVendorId: service.currentVendor.id,
          title: _titleController.text.trim(),
          category: _category,
          location: _locationController.text.trim(),
          priceLkr: price,
          description: _descriptionController.text.trim(),
          categorySpecificValue: summaryText,
          categoryDetails: detailsMap,
          imageUrl: coverPath,
          photos: List.unmodifiable(_photos),
          coverPhotoIndex: safeCoverIdx,
          isActive: _isActive,
        ),
      );
    } else {
      service.addListing(
        VendorListing(
          id: 'vl_${DateTime.now().millisecondsSinceEpoch}',
          ownerVendorId: service.currentVendor.id,
          title: _titleController.text.trim(),
          category: _category,
          location: _locationController.text.trim(),
          priceLkr: price,
          description: _descriptionController.text.trim(),
          categorySpecificValue: summaryText,
          categoryDetails: detailsMap,
          imageUrl: coverPath,
          photos: List.unmodifiable(_photos),
          coverPhotoIndex: safeCoverIdx,
          isActive: _isActive,
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final categoryFields = VendorCategoryFormConfig.fieldsFor(_category);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Listing' : 'Add Listing',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<VendorCategory>(
                  key: const Key('listing_form_category'),
                  initialValue: _category,
                  isExpanded: true,
                  decoration: _roundedDecoration(label: 'Category'),
                  items: VendorCategory.values
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _category = val;
                        _ensureCategoryControllers(val);
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('listing_form_title'),
                  controller: _titleController,
                  decoration: _roundedDecoration(
                    label: _category.titleFieldLabel,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? '${_category.titleFieldLabel} is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('listing_form_location'),
                  controller: _locationController,
                  decoration: _roundedDecoration(label: 'Location'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Location is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('listing_form_price'),
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: _roundedDecoration(
                    label: _category.priceFieldLabel,
                  ),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    return (n == null || n <= 0)
                        ? 'Valid price required'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                ...categoryFields.map((spec) {
                  final controller = _categoryFieldControllers[spec.key]!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      key: Key('listing_form_field_${spec.key}'),
                      controller: controller,
                      keyboardType: spec.isNumeric
                          ? TextInputType.number
                          : TextInputType.text,
                      decoration: _roundedDecoration(
                        label: spec.label,
                        hint: spec.hint,
                      ),
                      validator: (v) {
                        final text = v?.trim() ?? '';
                        if (spec.isRequired && text.isEmpty) {
                          return '${spec.label} is required';
                        }
                        if (spec.isNumeric && text.isNotEmpty) {
                          final n = int.tryParse(text);
                          if (n == null || n <= 0) {
                            return 'Enter a valid ${spec.label.toLowerCase()}';
                          }
                        }
                        return null;
                      },
                    ),
                  );
                }),
                TextFormField(
                  key: const Key('listing_form_description'),
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _roundedDecoration(label: 'Description'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 14),
                VendorListingPhotoSection(
                  photos: _photos,
                  coverPhotoIndex: _coverPhotoIndex,
                  isBusy: _isPickingPhoto,
                  errorMessage: _photoError,
                  onPickGallery: _onPickGallery,
                  onCaptureCamera: _onCaptureCamera,
                  onSelectCover: _onSelectCover,
                  onRemovePhoto: _onRemovePhoto,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Listing Active',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    key: const Key('listing_form_save_btn'),
                    onPressed: (_isSaving || _isPickingPhoto) ? null : _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A4DF5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isEdit ? 'Save Changes' : 'Create Listing'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
