import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Password Strength Indicator and Validation Checklist
/// Matching CeylonGo specification for password creation
class PasswordChecklist extends StatelessWidget {
  final String password;

  const PasswordChecklist({super.key, required this.password});

  bool get hasMinLength => password.length >= 8;
  bool get hasUppercase => RegExp(r'[A-Z]').hasMatch(password);
  bool get hasLowercase => RegExp(r'[a-z]').hasMatch(password);
  bool get hasDigit => RegExp(r'[0-9]').hasMatch(password);

  int get metCount {
    int count = 0;
    if (hasMinLength) count++;
    if (hasUppercase) count++;
    if (hasLowercase) count++;
    if (hasDigit) count++;
    return count;
  }

  String get strengthLabel {
    if (password.isEmpty) return 'Enter a password';
    if (metCount <= 2) return 'Weak';
    if (metCount == 3) return 'Fair';
    return 'Strong';
  }

  Color get strengthColor {
    if (password.isEmpty) return AppTheme.textMuted;
    if (metCount <= 2) return AppTheme.errorRed;
    if (metCount == 3) return AppTheme.accentOrange;
    return AppTheme.successGreen;
  }

  double get strengthFraction {
    if (password.isEmpty) return 0.0;
    return metCount / 4.0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'Password strength:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Flexible(
              child: Text(
                strengthLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: strengthColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strengthFraction,
            backgroundColor: AppTheme.borderSlate,
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 10),

        // Checklist items
        _ChecklistItem(
          label: 'At least 8 characters',
          isMet: hasMinLength,
        ),
        _ChecklistItem(
          label: 'At least one uppercase letter (A-Z)',
          isMet: hasUppercase,
        ),
        _ChecklistItem(
          label: 'At least one lowercase letter (a-z)',
          isMet: hasLowercase,
        ),
        _ChecklistItem(
          label: 'At least one number (0-9)',
          isMet: hasDigit,
        ),
      ],
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String label;
  final bool isMet;

  const _ChecklistItem({required this.label, required this.isMet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: isMet ? AppTheme.successGreen : AppTheme.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: isMet ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
