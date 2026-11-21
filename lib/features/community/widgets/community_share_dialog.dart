import 'package:flutter/material.dart';

import '../models/community_post_model.dart';

/// Community Share Dialog
/// Safe offline demo share interaction that provides copy-link and demo-sharing actions.
class CommunityShareDialog extends StatelessWidget {
  final CommunityPostModel post;

  const CommunityShareDialog({
    super.key,
    required this.post,
  });

  static void show(BuildContext context, CommunityPostModel post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CommunityShareDialog(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.share_rounded, color: Color(0xFF073B91), size: 22),
              SizedBox(width: 10),
              Text(
                'Share Post',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF082B5C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Post snippet container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.article_outlined, color: Color(0xFF64748B), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF082B5C),
                        ),
                      ),
                      Text(
                        post.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Copy Link button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              key: const Key('share_copy_link_btn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF073B91),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Demo link copied: ceylongo.app/post/${post.id}'),
                    backgroundColor: const Color(0xFF073B91),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text('Copy Demo Link'),
            ),
          ),
          const SizedBox(height: 10),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

