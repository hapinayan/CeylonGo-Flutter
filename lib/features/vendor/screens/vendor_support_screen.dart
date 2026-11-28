import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class _FaqEntry {
  final String id;
  final String question;
  final String answer;

  const _FaqEntry({
    required this.id,
    required this.question,
    required this.answer,
  });
}

/// Vendor Help & Support Screen
/// Provides searchable expandable FAQs and verified project support contact info.
class VendorSupportScreen extends StatefulWidget {
  const VendorSupportScreen({super.key});

  @override
  State<VendorSupportScreen> createState() => _VendorSupportScreenState();
}

class _VendorSupportScreenState extends State<VendorSupportScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<_FaqEntry> _faqs = [
    _FaqEntry(
      id: 'register',
      question: 'How to register as a vendor',
      answer:
          'Open Vendor Login, tap Register, enter your business name, email, phone, category, location, and password to create a local demo vendor profile.',
    ),
    _FaqEntry(
      id: 'add_listing',
      question: 'How to add a listing',
      answer:
          'Go to My Listings from the bottom navigation bar, tap Add Listing, select your category, complete the category-specific fields, and tap Create Listing.',
    ),
    _FaqEntry(
      id: 'upload_photos',
      question: 'How to upload photos',
      answer:
          'Inside Add or Edit Listing, use Gallery or Camera to add up to 5 local photos (JPG, PNG, WEBP, HEIC up to 10 MB) and choose a cover photo.',
    ),
    _FaqEntry(
      id: 'manage_bookings',
      question: 'How to manage bookings',
      answer:
          'Open Bookings from the bottom navigation bar or View all on the Dashboard to filter requests and simulate Accept, Reject, or Complete status updates.',
    ),
    _FaqEntry(
      id: 'change_availability',
      question: 'How to change availability',
      answer:
          'Open More → Availability Calendar, choose your listing, tap a valid date on the calendar, and select Mark Available or Mark Unavailable.',
    ),
    _FaqEntry(
      id: 'update_profile',
      question: 'How to update a vendor profile',
      answer:
          'Tap the top-right Profile icon on the Dashboard or More → Vendor Profile to view your business details. Full backend profile editing is not yet connected in demo mode.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FaqEntry> get _filteredFaqs {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _faqs;
    return _faqs
        .where(
          (f) =>
              f.question.toLowerCase().contains(q) ||
              f.answer.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _filteredFaqs;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            TextField(
              key: const Key('support_faq_search'),
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search vendor help topics...',
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
            const SizedBox(height: 14),
            if (faqs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No help topics match your search.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              )
            else
              ...faqs.map(
                (faq) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFDBEAFE)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                    key: Key('faq_tile_${faq.id}'),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                    title: Text(
                      faq.question,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Text(
                          faq.answer,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support Contact',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Email: support@ceylongo.com',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0A4DF5),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Phone and live-chat support channels are not configured in this demo build.',
                    style: TextStyle(
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
    );
  }
}

