import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/showcase_item_model.dart';
import '../services/artisan_demo_service.dart';
import '../services/artisan_service.dart';
import '../widgets/artisan_product_card.dart';
import 'artisan_product_detail_screen.dart';

class ArtisanProductCatalogScreen extends StatefulWidget {
  final ArtisanService? artisanService;
  final int? initialListingId;

  const ArtisanProductCatalogScreen({
    super.key,
    this.artisanService,
    this.initialListingId,
  });

  @override
  State<ArtisanProductCatalogScreen> createState() =>
      _ArtisanProductCatalogScreenState();
}

class _ArtisanProductCatalogScreenState
    extends State<ArtisanProductCatalogScreen> {
  late final ArtisanService _artisanService;

  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'all'; // 'all', 'product', 'service'
  bool _featuredOnly = false;

  List<ShowcaseItemSummary> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 1;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _artisanService = widget.artisanService ??
        (ArtisanDemoService.isDemoMode
            ? ArtisanDemoService.instance
            : ArtisanService());
    _scrollController.addListener(_onScroll);
    _loadProducts(1);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadMore();
    }
  }

  Future<void> _loadProducts(int page) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _artisanService.getShowcaseItems(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        itemType: _selectedType == 'all' ? null : _selectedType,
        isFeatured: _featuredOnly ? true : null,
        artisanListingId: widget.initialListingId,
        page: page,
        pageSize: 12,
      );

      if (mounted) {
        setState(() {
          _products = res.items;
          _currentPage = res.page;
          _totalPages = res.totalPages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final res = await _artisanService.getShowcaseItems(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        itemType: _selectedType == 'all' ? null : _selectedType,
        isFeatured: _featuredOnly ? true : null,
        artisanListingId: widget.initialListingId,
        page: nextPage,
        pageSize: 12,
      );

      if (mounted) {
        setState(() {
          _products.addAll(res.items);
          _currentPage = res.page;
          _totalPages = res.totalPages;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _selectedType = 'all';
      _featuredOnly = false;
    });
    _loadProducts(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Artisan Products & Crafts'),
      ),
      body: Column(
        children: [
          // Filter Toolbar
          Container(
            color: AppTheme.backgroundWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search items, materials, workshops...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _loadProducts(1);
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _loadProducts(1),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _buildTypeChip('all', 'All Items'),
                          const SizedBox(width: 6),
                          _buildTypeChip('product', 'Products'),
                          const SizedBox(width: 6),
                          _buildTypeChip('service', 'Workshops'),
                        ],
                      ),
                    ),
                    FilterChip(
                      label: const Text('Featured'),
                      selected: _featuredOnly,
                      selectedColor: const Color(0xFFFEF3C7),
                      checkmarkColor: const Color(0xFF92400E),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: _featuredOnly ? FontWeight.bold : FontWeight.normal,
                        color: _featuredOnly ? const Color(0xFF92400E) : AppTheme.textSecondary,
                      ),
                      side: BorderSide(
                        color: _featuredOnly ? const Color(0xFFFDE68A) : AppTheme.borderSlate,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _featuredOnly = val;
                        });
                        _loadProducts(1);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Catalog Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accentOrange),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                              const SizedBox(height: 12),
                              const Text(
                                'Unable to Load Products',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: () => _loadProducts(1),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _products.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shopping_bag_outlined,
                                      size: 48, color: AppTheme.textMuted),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No Items Found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'No products match your current search and filter settings.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 14),
                                  OutlinedButton(
                                    onPressed: _resetFilters,
                                    child: const Text('Reset Filters'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _products.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _products.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.accentOrange,
                                    ),
                                  ),
                                );
                              }
                              final item = _products[index];
                              return ArtisanProductCard(
                                product: item,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ArtisanProductDetailScreen(
                                        productId: item.id,
                                        artisanService: _artisanService,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryNavy,
      backgroundColor: AppTheme.backgroundLight,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryNavy : AppTheme.borderSlate,
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedType = type;
          });
          _loadProducts(1);
        }
      },
    );
  }
}

