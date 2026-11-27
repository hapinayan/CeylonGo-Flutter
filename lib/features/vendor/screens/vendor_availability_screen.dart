import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/vendor_models.dart';
import '../services/vendor_demo_service.dart';

/// Vendor Availability Calendar Screen (Local In-Memory Demo State)
/// Allows switching between the active vendor's listings, navigating months,
/// selecting valid dates, and marking dates Available or Unavailable.
class VendorAvailabilityScreen extends StatefulWidget {
  const VendorAvailabilityScreen({super.key});

  @override
  State<VendorAvailabilityScreen> createState() =>
      _VendorAvailabilityScreenState();
}

class _VendorAvailabilityScreenState extends State<VendorAvailabilityScreen> {
  final VendorDemoService _service = VendorDemoService.instance;

  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  String? _selectedListingId;

  static const Color _royalBlue = Color(0xFF0A4DF5);
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const List<String> _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _displayedMonth = DateTime(now.year, now.month, 1);
    final listings = _service.listings;
    if (listings.isNotEmpty) {
      _selectedListingId = listings.first.id;
    }
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isPastDate(DateTime date) => date.isBefore(_today);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _previousMonth() {
    final prev = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    final currentMonthStart = DateTime(_today.year, _today.month, 1);
    if (prev.isBefore(currentMonthStart)) return;
    setState(() => _displayedMonth = prev);
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final listings = _service.listings;
    final activeListing = listings.isEmpty
        ? null
        : listings.firstWhere(
            (l) => l.id == _selectedListingId,
            orElse: () => listings.first,
          );
    final listingId = activeListing?.id;
    final canGoPrev = _displayedMonth.isAfter(
      DateTime(_today.year, _today.month, 1),
    );

    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final firstWeekdayOffset = _displayedMonth.weekday - 1; // Mon=0..Sun=6
    final totalCells = firstWeekdayOffset + daysInMonth;

    final isSelectedAvailable = listingId != null
        ? _service.isDateAvailable(listingId, _selectedDate)
        : true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        title: const Text(
          'Availability Calendar',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
      ),
      body: SafeArea(
        child: listings.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Create a listing first to manage its calendar availability.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: const Text(
                        'Demo Mode: Availability changes are stored per listing in local memory only.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const Key('availability_listing_dropdown'),
                      initialValue: listingId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Select Listing',
                        filled: true,
                        isDense: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: listings
                          .map(
                            (VendorListing l) => DropdownMenuItem<String>(
                              value: l.id,
                              child: Text(
                                l.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedListingId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                key: const Key('calendar_prev_month_btn'),
                                onPressed: canGoPrev ? _previousMonth : null,
                                icon: const Icon(Icons.chevron_left_rounded),
                              ),
                              Text(
                                '${_monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                                key: const Key('calendar_month_label'),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                              IconButton(
                                key: const Key('calendar_next_month_btn'),
                                onPressed: _nextMonth,
                                icon: const Icon(Icons.chevron_right_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: _weekdayLabels
                                .map(
                                  (day) => Expanded(
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: totalCells,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 4,
                              childAspectRatio: 1,
                            ),
                            itemBuilder: (context, index) {
                              if (index < firstWeekdayOffset) {
                                return const SizedBox.shrink();
                              }
                              final dayNumber = index - firstWeekdayOffset + 1;
                              final cellDate = DateTime(
                                _displayedMonth.year,
                                _displayedMonth.month,
                                dayNumber,
                              );
                              final isPast = _isPastDate(cellDate);
                              final isSelected =
                                  _isSameDay(cellDate, _selectedDate);
                              final isAvail = listingId != null
                                  ? _service.isDateAvailable(
                                      listingId,
                                      cellDate,
                                    )
                                  : true;

                              Color bgColor = Colors.transparent;
                              Color textColor = AppTheme.primaryNavy;
                              if (isPast) {
                                textColor = const Color(0xFFCBD5E1);
                              } else if (isSelected) {
                                bgColor = _royalBlue;
                                textColor = Colors.white;
                              } else if (!isAvail) {
                                bgColor = const Color(0xFFFEE2E2);
                                textColor = const Color(0xFFB91C1C);
                              } else {
                                bgColor = const Color(0xFFECFDF5);
                                textColor = const Color(0xFF047857);
                              }

                              return InkWell(
                                key: Key('calendar_day_$dayNumber'),
                                onTap: isPast
                                    ? null
                                    : () => setState(
                                          () => _selectedDate = cellDate,
                                        ),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: isSelected
                                        ? Border.all(
                                            color: AppTheme.primaryNavy,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$dayNumber',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          const Wrap(
                            spacing: 14,
                            runSpacing: 6,
                            children: [
                              _LegendDot(
                                color: Color(0xFFECFDF5),
                                borderColor: Color(0xFF047857),
                                label: 'Available',
                              ),
                              _LegendDot(
                                color: Color(0xFFFEE2E2),
                                borderColor: Color(0xFFB91C1C),
                                label: 'Unavailable',
                              ),
                              _LegendDot(
                                color: _royalBlue,
                                borderColor: _royalBlue,
                                label: 'Selected',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Selected Date: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSelectedAvailable
                                ? 'Status: Available'
                                : 'Status: Unavailable',
                            key: const Key('selected_date_status_text'),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelectedAvailable
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFB91C1C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  key: const Key('mark_date_available_btn'),
                                  onPressed: listingId == null
                                      ? null
                                      : () {
                                          _service.setDateAvailability(
                                            listingId,
                                            _selectedDate,
                                            available: true,
                                          );
                                          setState(() {});
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Mark Available'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  key: const Key('mark_date_unavailable_btn'),
                                  onPressed: listingId == null
                                      ? null
                                      : () {
                                          _service.setDateAvailability(
                                            listingId,
                                            _selectedDate,
                                            available: false,
                                          );
                                          setState(() {});
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFB91C1C),
                                    side: const BorderSide(
                                      color: Color(0xFFB91C1C),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Mark Unavailable'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String label;

  const _LegendDot({
    required this.color,
    required this.borderColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: borderColor),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}

