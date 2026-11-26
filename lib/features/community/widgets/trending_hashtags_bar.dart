import 'package:flutter/material.dart';

/// Horizontal Trending Hashtags Bar
/// Displays scrollable hashtag pills to filter community posts.
class TrendingHashtagsBar extends StatelessWidget {
  final List<String> hashtags;
  final String selectedHashtag;
  final ValueChanged<String> onHashtagSelected;

  const TrendingHashtagsBar({
    super.key,
    required this.hashtags,
    required this.selectedHashtag,
    required this.onHashtagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: hashtags.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tag = hashtags[index];
          final isSelected = tag.toLowerCase() == selectedHashtag.toLowerCase();

          return GestureDetector(
            key: Key('hashtag_${tag.replaceAll('#', '').toLowerCase()}'),
            onTap: () => onHashtagSelected(tag),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF073B91) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF073B91) : const Color(0xFFE2E8F0),
                  width: 1.1,
                ),
              ),
              child: Center(
                child: Text(
                  tag,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF082B5C),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
