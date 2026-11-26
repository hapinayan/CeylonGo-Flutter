import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/artisan_review_model.dart';
import 'star_rating_bar.dart';

/// Card displaying average score, total reviews, verified booking count, and star breakdown progress bars.
class ReviewBreakdownWidget extends StatelessWidget {
  final ArtisanReviewSummaryModel summary;

  const ReviewBreakdownWidget({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSlate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Big Average Rating
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    summary.averageRating > 0
                        ? summary.averageRating.toStringAsFixed(1)
                        : '0.0',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StarRatingBar(
                    rating: summary.averageRating,
                    size: 16,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.totalReviews} ${summary.totalReviews == 1 ? 'review' : 'reviews'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Rating Breakdown Bars
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((stars) {
                    final count = summary.ratingBreakdown[stars.toString()] ?? 0;
                    final ratio = summary.totalReviews > 0
                        ? count / summary.totalReviews
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            child: Text(
                              '$stars',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: AppTheme.borderSlate,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 22,
                            child: Text(
                              '$count',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          if (summary.verifiedReviewsCount > 0) ...[
            const Divider(height: 24, color: AppTheme.borderSlate),
            Row(
              children: [
                const Icon(Icons.verified, size: 14, color: AppTheme.successGreen),
                const SizedBox(width: 6),
                Text(
                  '${summary.verifiedReviewsCount} verified in-store pickup booking ${summary.verifiedReviewsCount == 1 ? 'review' : 'reviews'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.successGreen,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

