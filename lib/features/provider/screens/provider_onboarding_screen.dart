import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../auth/models/api_error.dart';
import '../services/provider_service.dart';

/// Multi-step Service Provider OTP Onboarding & Registration Screen (`/provider/register`)
/// Matches:
/// 1. Email OTP (/providers/otp/send -> /providers/otp/verify)
/// 2. Personal Details (/providers/registration/personal)
/// 3. Business Details (/providers/registration/business)
/// 4. Password Setup & Submission (/providers/password/setup, /providers/registration/identity, /providers/registration/submit)
class ProviderOnboardingScreen extends StatefulWidget {
  final ProviderService? providerService;

  const ProviderOnboardingScreen({super.key, this.providerService});

  @override
  State<ProviderOnboardingScreen> createState() =>
      _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends State<ProviderOnboardingScreen> {
  late final ProviderService _service;

  int _step = 0; // 0: OTP, 1: Personal, 2: Business, 3: Security & Submit
  bool _busy = false;
  bool _otpSent = false;
  String? _authToken;
  String? _error;
  String? _submittedMessage;

  // Step 0: Email & OTP
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  // Step 1: Personal Details
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController(text: '1992-05-15');
  String _gender = 'male';
  final _nicCtrl = TextEditingController();
  final _permProvinceCtrl = TextEditingController(text: 'Western');
  final _permDistrictCtrl = TextEditingController(text: 'Colombo');
  final _permCityCtrl = TextEditingController();
  final _permLandmarkCtrl = TextEditingController();
  final _permPostalCtrl = TextEditingController(text: '00100');

  // Step 2: Business Details
  final _bizNameCtrl = TextEditingController();
  String _providerType = 'homestay';
  final _bizDistrictCtrl = TextEditingController(text: 'Kandy');
  final _bizCityCtrl = TextEditingController();
  final _bizDescCtrl = TextEditingController();

  // Step 3: Identity optional paths & Password
  final _selfiePathCtrl = TextEditingController();
  final _nicFrontPathCtrl = TextEditingController();
  final _nicBackPathCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  static const _providerTypes = [
    ('homestay', 'Homestay / Villa'),
    ('activity', 'Adventure Activity'),
    ('tour_guide', 'Local Tour Guide'),
    ('rental', 'Bike / Bicycle Rental'),
    ('artisan', 'Artisan Workshop'),
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.providerService ?? ProviderService();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _nicCtrl.dispose();
    _permProvinceCtrl.dispose();
    _permDistrictCtrl.dispose();
    _permCityCtrl.dispose();
    _permLandmarkCtrl.dispose();
    _permPostalCtrl.dispose();
    _bizNameCtrl.dispose();
    _bizDistrictCtrl.dispose();
    _bizCityCtrl.dispose();
    _bizDescCtrl.dispose();
    _selfiePathCtrl.dispose();
    _nicFrontPathCtrl.dispose();
    _nicBackPathCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final err = FormValidators.validateEmail(_emailCtrl.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final msg = await _service.sendOtp(_emailCtrl.text);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Failed to send verification OTP.';
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length < 4) {
      setState(() => _error = 'Enter the verification code from your email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await _service.verifyOtp(
        email: _emailCtrl.text,
        otp: _otpCtrl.text,
      );
      if (!res.verified || res.authorizationToken == null) {
        setState(() {
          _busy = false;
          _error = res.message ?? 'Invalid or expired code.';
        });
        return;
      }
      _authToken = res.authorizationToken;
      try {
        final draft = await _service.getRegistrationDraft(_authToken!);
        _fullNameCtrl.text = draft.fullName ?? _fullNameCtrl.text;
        _phoneCtrl.text = draft.phone ?? _phoneCtrl.text;
        _nicCtrl.text = draft.nicNumber ?? _nicCtrl.text;
        _bizNameCtrl.text = draft.businessName ?? _bizNameCtrl.text;
        if (draft.providerType != null) {
          _providerType = draft.providerType!;
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = 1;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Unable to verify OTP.';
      });
    }
  }

  Future<void> _savePersonal() async {
    if (_authToken == null) return;
    if (_fullNameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _nicCtrl.text.trim().isEmpty ||
        _permCityCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill all required personal fields.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.savePersonalDetails(_authToken!, {
        'full_name': _fullNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'date_of_birth': _dobCtrl.text.trim(),
        'gender': _gender,
        'nationality': 'Sri Lankan',
        'identity_document_type': 'NIC',
        'nic_number': _nicCtrl.text.trim(),
        'permanent_province': _permProvinceCtrl.text.trim(),
        'permanent_district': _permDistrictCtrl.text.trim(),
        'permanent_city': _permCityCtrl.text.trim(),
        'permanent_landmark': _permLandmarkCtrl.text.trim().isEmpty
            ? _permCityCtrl.text.trim()
            : _permLandmarkCtrl.text.trim(),
        'permanent_postal_code': _permPostalCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = 2;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Failed to save personal details.';
      });
    }
  }

  Future<void> _saveBusiness() async {
    if (_authToken == null) return;
    if (_bizNameCtrl.text.trim().isEmpty || _bizDistrictCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Business name and district are required.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.saveBusinessDetails(_authToken!, {
        'business_name': _bizNameCtrl.text.trim(),
        'provider_type': _providerType,
        'business_district': _bizDistrictCtrl.text.trim(),
        'business_city': _bizCityCtrl.text.trim().isEmpty
            ? _bizDistrictCtrl.text.trim()
            : _bizCityCtrl.text.trim(),
        'description': _bizDescCtrl.text.trim(),
        'same_as_permanent': false,
      });
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = 3;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Failed to save business details.';
      });
    }
  }

  Future<void> _completeOnboarding() async {
    if (_authToken == null) return;
    final pwdErr = FormValidators.validatePassword(_passwordCtrl.text);
    if (pwdErr != null) {
      setState(() => _error = pwdErr);
      return;
    }
    if (_passwordCtrl.text != _confirmPwdCtrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_selfiePathCtrl.text.trim().isNotEmpty ||
          _nicFrontPathCtrl.text.trim().isNotEmpty ||
          _nicBackPathCtrl.text.trim().isNotEmpty) {
        await _service.uploadIdentityDocuments(
          _authToken!,
          selfiePath: _selfiePathCtrl.text.trim(),
          nicFrontPath: _nicFrontPathCtrl.text.trim(),
          nicBackPath: _nicBackPathCtrl.text.trim(),
        );
      }

      await _service.setupPassword(
        _authToken!,
        password: _passwordCtrl.text,
        confirmPassword: _confirmPwdCtrl.text,
      );

      final submitMsg = await _service.submitRegistration(_authToken!);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _submittedMessage = submitMsg;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Submission failed. Please verify required steps and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submittedMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Application Submitted')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_outlined,
                  size: 64, color: AppTheme.successGreen),
              const SizedBox(height: 16),
              const Text(
                'Provider Registration Submitted',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _submittedMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/provider/login',
                    (r) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Go to Provider Sign In'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Service Provider Registration'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_step + 1) / 4,
            minHeight: 4,
            color: AppTheme.accentOrange,
            backgroundColor: Colors.grey.shade200,
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _step == 0
                  ? _buildStep0Otp()
                  : _step == 1
                      ? _buildStep1Personal()
                      : _step == 2
                          ? _buildStep2Business()
                          : _buildStep3PasswordSubmit(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep0Otp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Step 1: Verify Your Business Email',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryNavy,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email Address'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _busy ? null : _sendOtp,
          child: Text(_otpSent ? 'Resend OTP' : 'Send Verification OTP'),
        ),
        if (_otpSent) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Enter 6-Digit OTP'),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _busy ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
            ),
            child: Text(_busy ? 'Verifying...' : 'Verify OTP & Continue'),
          ),
        ],
      ],
    );
  }

  Widget _buildStep1Personal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Step 2: Personal & Permanent Address',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryNavy,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _fullNameCtrl,
          decoration: const InputDecoration(labelText: 'Full Name *'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone Number *'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _dobCtrl,
          decoration: const InputDecoration(
            labelText: 'Date of Birth (YYYY-MM-DD) *',
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _gender,
          decoration: const InputDecoration(labelText: 'Gender'),
          items: const ['male', 'female', 'other']
              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
              .toList(),
          onChanged: (v) => setState(() => _gender = v ?? 'male'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nicCtrl,
          decoration: const InputDecoration(labelText: 'NIC Number *'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _permProvinceCtrl,
          decoration: const InputDecoration(labelText: 'Province *'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _permDistrictCtrl,
          decoration: const InputDecoration(labelText: 'District *'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _permCityCtrl,
          decoration: const InputDecoration(labelText: 'City *'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _permLandmarkCtrl,
          decoration: const InputDecoration(labelText: 'Nearest Landmark'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _permPostalCtrl,
          decoration: const InputDecoration(labelText: 'Postal Code *'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _busy ? null : _savePersonal,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryNavy,
            foregroundColor: Colors.white,
          ),
          child: Text(_busy ? 'Saving...' : 'Save Personal Details'),
        ),
      ],
    );
  }

  Widget _buildStep2Business() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Step 3: Business Details',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryNavy,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bizNameCtrl,
          decoration: const InputDecoration(labelText: 'Business Name *'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _providerType,
          decoration: const InputDecoration(labelText: 'Service Type *'),
          items: _providerTypes
              .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
              .toList(),
          onChanged: (v) => setState(() => _providerType = v ?? 'homestay'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _bizDistrictCtrl,
          decoration: const InputDecoration(labelText: 'Business District *'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _bizCityCtrl,
          decoration: const InputDecoration(labelText: 'Business City'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _bizDescCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Business Description'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _busy ? null : _saveBusiness,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryNavy,
            foregroundColor: Colors.white,
          ),
          child: Text(_busy ? 'Saving...' : 'Save Business Details'),
        ),
      ],
    );
  }

  Widget _buildStep3PasswordSubmit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Step 4: Identity Verification & Password',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryNavy,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Set your provider portal password and submit for admin verification.',
          style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Create Password *'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _confirmPwdCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirm Password *'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _selfiePathCtrl,
          decoration: const InputDecoration(
            labelText: 'Selfie Image File Path (Optional)',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nicFrontPathCtrl,
          decoration: const InputDecoration(
            labelText: 'NIC Front File Path (Optional)',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nicBackPathCtrl,
          decoration: const InputDecoration(
            labelText: 'NIC Back File Path (Optional)',
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: _busy ? null : _completeOnboarding,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(_busy ? 'Submitting...' : 'Submit Application'),
        ),
      ],
    );
  }
}
