import 'package:flutter/material.dart';

/// Reusable star rating widget supporting read-only display or interactive rating input (1 to 5 stars).
class StarRatingBar extends StatelessWidget {
  final double rating;
  final double size;
  final bool isInteractive;
  final ValueChanged<double>? onRatingChanged;
  final Color activeColor;
  final Color inactiveColor;

  const StarRatingBar({
    super.key,
    required this.rating,
    this.size = 18.0,
    this.isInteractive = false,
    this.onRatingChanged,
    this.activeColor = const Color(0xFFF59E0B),
    this.inactiveColor = const Color(0xFFD1D5DB),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData icon;
        Color color;

        if (rating >= starValue) {
          icon = Icons.star;
          color = activeColor;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half;
          color = activeColor;
        } else {
          icon = Icons.star_border;
          color = inactiveColor;
        }

        final starWidget = Icon(icon, size: size, color: color);

        if (!isInteractive) {
          return starWidget;
        }

        return GestureDetector(
          onTap: () {
            if (onRatingChanged != null) {
              onRatingChanged!(starValue.toDouble());
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: starWidget,
          ),
        );
      }),
    );
  }
}

