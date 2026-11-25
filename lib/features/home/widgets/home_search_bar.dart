import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Section B: CeylonGo Modern Rounded Search Bar
/// Features search icon, placeholder "Start your search",
/// and subtle pale-blue border/shadow styling.
class HomeSearchBar extends StatefulWidget {
  final Animation<double> animation;
  final ValueChanged<String>? onSearch;

  const HomeSearchBar({super.key, required this.animation, this.onSearch});

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  final bool _isFocused = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Search CeylonGo',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Find artisan workshops, homestays, eco tours, and attractions across Sri Lanka',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'e.g. Kandy, Masks, Homestay...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.primaryNavy,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => _controller.clear(),
                  ),
                ),
                onSubmitted: (query) {
                  Navigator.pop(ctx);
                  if (query.trim().isNotEmpty) {
                    Navigator.pushNamed(context, '/artisan');
                  }
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Artisans in Galle'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, '/artisan');
                    },
                  ),
                  ActionChip(
                    label: const Text('Ella Homestays'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Showing Ella Homestays')),
                      );
                    },
                  ),
                  ActionChip(
                    label: const Text('Kandy Crafts'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, '/artisan');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
          CurvedAnimation(
            parent: widget.animation,
            curve: const Interval(0.1, 0.75, curve: Curves.easeOutCubic),
          ),
        );

    final fadeAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.1, 0.65, curve: Curves.easeIn),
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
          child: InkWell(
            key: const Key('home_search_bar'),
            onTap: () => _showSearchDialog(context),
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isFocused
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFDBEAFE),
                  width: _isFocused ? 1.5 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isFocused
                        ? const Color(0xFF2563EB).withAlpha(20)
                        : Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryNavy,
                    size: 21,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Start your search',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
