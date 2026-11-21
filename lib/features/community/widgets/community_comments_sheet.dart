import 'package:flutter/material.dart';

import '../models/community_comment_model.dart';
import '../services/community_demo_service.dart';

/// Community Comments Bottom Sheet
/// Displays discussion threads, supports replying, adding new comments,
/// and deleting comments authored by the demo traveler.
class CommunityCommentsSheet extends StatefulWidget {
  final String postId;
  final List<CommunityCommentModel> initialComments;
  final ValueChanged<int> onCommentsCountChanged;

  const CommunityCommentsSheet({
    super.key,
    required this.postId,
    required this.initialComments,
    required this.onCommentsCountChanged,
  });

  @override
  State<CommunityCommentsSheet> createState() => _CommunityCommentsSheetState();
}

class _CommunityCommentsSheetState extends State<CommunityCommentsSheet> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  final _demoService = CommunityDemoService();

  late List<CommunityCommentModel> _comments;
  CommunityCommentModel? _replyingTo;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.initialComments);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final newComment = _demoService.addComment(
      postId: widget.postId,
      text: text,
      replyToCommentId: _replyingTo?.id,
    );

    setState(() {
      _comments.add(newComment);
      _commentController.clear();
      _replyingTo = null;
    });

    widget.onCommentsCountChanged(_comments.length);
    _focusNode.unfocus();
  }

  void _onDeleteComment(String commentId) {
    final success = _demoService.deleteComment(widget.postId, commentId);
    if (success) {
      setState(() {
        _comments.removeWhere((c) => c.id == commentId);
      });
      widget.onCommentsCountChanged(_comments.length);
    }
  }

  void _onStartReply(CommunityCommentModel comment) {
    setState(() {
      _replyingTo = comment;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72 + bottomInset,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Comments (${_comments.length})',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF082B5C),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Comments List
          Expanded(
            child: _comments.isEmpty
                ? const Center(
                    child: Text(
                      'No comments yet. Start the conversation!',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _comments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final cmt = _comments[index];
                      final isDemoAuthor = cmt.authorId == CommunityDemoService.currentUserId;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEEF4FF),
                              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                            ),
                            child: Center(
                              child: Text(
                                cmt.authorInitials,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF073B91),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Comment body
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      cmt.authorName,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF082B5C),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cmt.timeAgo,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                                if (cmt.replyToAuthorName != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Replying to @${cmt.replyToAuthorName}',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF073B91),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 3),
                                Text(
                                  cmt.text,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Color(0xFF334155),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _onStartReply(cmt),
                                      child: const Text(
                                        'Reply',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF073B91),
                                        ),
                                      ),
                                    ),
                                    if (isDemoAuthor) ...[
                                      const SizedBox(width: 14),
                                      GestureDetector(
                                        key: Key('comment_delete_${cmt.id}'),
                                        onTap: () => _onDeleteComment(cmt.id),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFDC2626),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Replying indicator
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFFF0F7FF),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, size: 16, color: Color(0xFF073B91)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Replying to ${_replyingTo!.authorName}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF073B91),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _replyingTo = null),
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

          // Comment input bar
          Padding(
            padding: EdgeInsets.only(
              left: 14,
              right: 14,
              top: 8,
              bottom: bottomInset > 0 ? bottomInset + 8 : 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      key: const Key('comment_input_field'),
                      controller: _commentController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Add a helpful comment or question...',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('comment_send_btn'),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF073B91),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  onPressed: _onSendComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
