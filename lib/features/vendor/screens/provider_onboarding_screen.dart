import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../auth/models/api_error.dart';
import '../models/provider_identity_models.dart';
import '../models/provider_profile_model.dart';
import '../services/provider_identity_service.dart';
import '../services/vendor_identity_doc_picker.dart';
import 'vendor_identity_upload_screen.dart';

enum _OnboardingView { otp, overview, personal, business, submitted }

/// Real Provider Registration & Onboarding Flow (Modules: OTP, Personal,
/// Business, Identity Upload, Draft Progress, and Final Submission).
/// Strictly uses verified FastAPI contracts and server-confirmed `DraftResponse`.
class ProviderOnboardingScreen extends StatefulWidget {
  final ProviderIdentityService? identityService;
  final VendorIdentityDocPicker? docPicker;
  final String? initialAuthToken;
  final ProviderDraftStatus? initialDraft;

  const ProviderOnboardingScreen({
    super.key,
    this.identityService,
    this.docPicker,
    this.initialAuthToken,
    this.initialDraft,
  });

  @override
  State<ProviderOnboardingScreen> createState() =>
      _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends State<ProviderOnboardingScreen> {
  late final ProviderIdentityService _service;

  _OnboardingView _view = _OnboardingView.otp;
  String? _authToken;
  ProviderDraftStatus? _draft;
  ProviderRegistrationSubmitResult? _submitResult;

  bool _isBusy = false;
  bool _otpSent = false;
  bool _uncertainSubmitOutcome = false;
  String? _errorMessage;
  String? _infoMessage;

  // OTP controllers
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  // Personal form
  final _personalFormKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  String _gender = 'Male';
  final _nationalityCtrl = TextEditingController(text: 'Sri Lankan');
  String _identityDocType = 'nic';
  final _nicNumberCtrl = TextEditingController();
  final _permProvinceCtrl = TextEditingController();
  final _permDistrictCtrl = TextEditingController();
  final _permCityCtrl = TextEditingController();
  final _permLandmarkCtrl = TextEditingController();
  final _permPostalCtrl = TextEditingController();

  // Business form
  final _businessFormKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  BackendProviderType _providerType = BackendProviderType.homestay;
  bool _sameAsPermanent = false;
  final _secondaryPhoneCtrl = TextEditingController();
  final _bizProvinceCtrl = TextEditingController();
  final _bizDistrictCtrl = TextEditingController();
  final _bizCityCtrl = TextEditingController();
  final _bizLandmarkCtrl = TextEditingController();
  final _bizPostalCtrl = TextEditingController();
  final _bizRegNoCtrl = TextEditingController();
  final _bizDescCtrl = TextEditingController();

  static const Color _royalBlue = Color(0xFF0A4DF5);

  @override
  void initState() {
    super.initState();
    _service = widget.identityService ?? ProviderIdentityService();
    _authToken = widget.initialAuthToken;
    _draft = widget.initialDraft;
    if (_authToken != null) {
      _view = _OnboardingView.overview;
      if (_draft != null) {
        _hydrateFromDraft(_draft!);
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _nationalityCtrl.dispose();
    _nicNumberCtrl.dispose();
    _permProvinceCtrl.dispose();
    _permDistrictCtrl.dispose();
    _permCityCtrl.dispose();
    _permLandmarkCtrl.dispose();
    _permPostalCtrl.dispose();
    _businessNameCtrl.dispose();
    _secondaryPhoneCtrl.dispose();
    _bizProvinceCtrl.dispose();
    _bizDistrictCtrl.dispose();
    _bizCityCtrl.dispose();
    _bizLandmarkCtrl.dispose();
    _bizPostalCtrl.dispose();
    _bizRegNoCtrl.dispose();
    _bizDescCtrl.dispose();
    super.dispose();
  }

  void _hydrateFromDraft(ProviderDraftStatus d) {
    if (d.fullName != null) _fullNameCtrl.text = d.fullName!;
    if (d.phone != null) _phoneCtrl.text = d.phone!;
    if (d.dateOfBirth != null) _dobCtrl.text = d.dateOfBirth!;
    if (d.gender != null && ['Male', 'Female', 'Other'].contains(d.gender)) {
      _gender = d.gender!;
    }
    if (d.nationality != null) _nationalityCtrl.text = d.nationality!;
    _identityDocType = d.identityDocumentType;
    if (d.nicNumber != null) _nicNumberCtrl.text = d.nicNumber!;
    if (d.permanentProvince != null) {
      _permProvinceCtrl.text = d.permanentProvince!;
    }
    if (d.permanentDistrict != null) {
      _permDistrictCtrl.text = d.permanentDistrict!;
    }
    if (d.permanentCity != null) _permCityCtrl.text = d.permanentCity!;
    if (d.permanentLandmark != null) {
      _permLandmarkCtrl.text = d.permanentLandmark!;
    }
    if (d.permanentPostalCode != null) {
      _permPostalCtrl.text = d.permanentPostalCode!;
    }
    if (d.businessName != null) _businessNameCtrl.text = d.businessName!;
    if (d.providerType != null) {
      _providerType = BackendProviderType.values.firstWhere(
        (t) => t.apiValue == d.providerType,
        orElse: () => BackendProviderType.homestay,
      );
    }
    if (d.secondaryPhone != null) {
      _secondaryPhoneCtrl.text = d.secondaryPhone!;
    }
    if (d.businessProvince != null) _bizProvinceCtrl.text = d.businessProvince!;
    if (d.businessDistrict != null) _bizDistrictCtrl.text = d.businessDistrict!;
    if (d.businessCity != null) _bizCityCtrl.text = d.businessCity!;
    if (d.businessLandmark != null) _bizLandmarkCtrl.text = d.businessLandmark!;
    if (d.businessPostalCode != null) {
      _bizPostalCtrl.text = d.businessPostalCode!;
    }
    if (d.businessRegistrationNumber != null) {
      _bizRegNoCtrl.text = d.businessRegistrationNumber!;
    }
    if (d.description != null) _bizDescCtrl.text = d.description!;
  }

  void _handleApiError(ApiError e, {bool fromSubmit = false}) {
    if (e.statusCode == 401) {
      setState(() {
        _isBusy = false;
        _authToken = null;
        _view = _OnboardingView.otp;
        _errorMessage = e.message;
      });
      return;
    }
    setState(() {
      _isBusy = false;
      if (fromSubmit && (e.code == 'TIMEOUT' || e.code == 'NETWORK_ERROR')) {
        _uncertainSubmitOutcome = true;
      }
      _errorMessage = e.message;
    });
  }

  Future<void> _onSendOtp() async {
    if (_isBusy) return;
    final err = FormValidators.validateEmail(_emailCtrl.text);
    if (err != null) {
      setState(() => _errorMessage = err);
      return;
    }
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      final msg = await _service.sendRegistrationOtp(_emailCtrl.text);
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _otpSent = true;
        _infoMessage = msg;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      _handleApiError(e);
    }
  }

  Future<void> _onVerifyOtp() async {
    if (_isBusy) return;
    final otp = _otpCtrl.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _errorMessage = 'Enter the 6-digit verification code.');
      return;
    }
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      final res = await _service.verifyRegistrationOtp(
        email: _emailCtrl.text,
        otp: otp,
      );
      if (!mounted) return;
      final token = res.authorizationToken;
      if (!res.verified || token == null || token.trim().isEmpty) {
        setState(() {
          _isBusy = false;
          _errorMessage = res.message ??
              'Registration authorization was not issued for this email.';
        });
        return;
      }
      _authToken = token;
      final draft = await _service.getDraft(token);
      if (!mounted) return;
      _hydrateFromDraft(draft);
      setState(() {
        _isBusy = false;
        _draft = draft;
        _view = _OnboardingView.overview;
        _infoMessage = 'Email verified. Complete all steps below to submit.';
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      _handleApiError(e);
    }
  }

  Future<void> _refreshDraft() async {
    final token = _authToken;
    if (token == null || _isBusy) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      final draft = await _service.getDraft(token);
      if (!mounted) return;
      _hydrateFromDraft(draft);
      setState(() {
        _isBusy = false;
        _draft = draft;
        _uncertainSubmitOutcome = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      _handleApiError(e);
    }
  }

  Future<void> _onSavePersonal() async {
    if (_isBusy || _authToken == null) return;
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
    });
    if (!(_personalFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isBusy = true);
    try {
      final draft = await _service.savePersonalDetails(
        registrationAuthToken: _authToken!,
        payload: PersonalDetailsPayload(
          fullName: _fullNameCtrl.text,
          phone: _phoneCtrl.text,
          dateOfBirth: _dobCtrl.text,
          gender: _gender,
          nationality: _nationalityCtrl.text,
          identityDocumentType: _identityDocType,
          nicNumber: _nicNumberCtrl.text,
          permanentProvince: _permProvinceCtrl.text,
          permanentDistrict: _permDistrictCtrl.text,
          permanentCity: _permCityCtrl.text,
          permanentLandmark: _permLandmarkCtrl.text,
          permanentPostalCode: _permPostalCtrl.text,
        ),
      );
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _draft = draft;
        _view = _OnboardingView.overview;
        _infoMessage = 'Personal details saved to your registration draft.';
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      _handleApiError(e);
    }
  }

  Future<void> _onSaveBusiness() async {
    if (_isBusy || _authToken == null) return;
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
    });
    if (!(_businessFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isBusy = true);
    try {
      final draft = await _service.saveBusinessDetails(
        registrationAuthToken: _authToken!,
        payload: BusinessDetailsPayload(
          businessName: _businessNameCtrl.text,
          providerType: _providerType.apiValue,
          secondaryPhone: _secondaryPhoneCtrl.text,
          businessProvince: _bizProvinceCtrl.text,
          businessDistrict: _bizDistrictCtrl.text,
          businessCity: _bizCityCtrl.text,
          businessLandmark: _bizLandmarkCtrl.text,
          businessPostalCode: _bizPostalCtrl.text,
          businessRegistrationNumber: _bizRegNoCtrl.text,
          description: _bizDescCtrl.text,
          sameAsPermanent: _sameAsPermanent,
        ),
      );
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _draft = draft;
        _view = _OnboardingView.overview;
        _infoMessage = 'Business details saved to your registration draft.';
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      _handleApiError(e);
    }
  }

  Future<void> _openIdentityUpload() async {
    if (_authToken == null || _isBusy) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VendorIdentityUploadScreen(
          initialAuthToken: _authToken,
          initialEmail: _draft?.email ?? _emailCtrl.text.trim(),
          identityService: _service,
          docPicker: widget.docPicker,
        ),
      ),
    );
    if (mounted) {
      await _refreshDraft();
    }
  }

  Future<void> _onSubmitRegistration() async {
    if (_isBusy || _authToken == null || !(_draft?.readyToSubmit ?? false)) {
      return;
    }
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      final result = await _service.submitRegistration(_authToken!);
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _submitResult = result;
        _authToken = null; // Consumed on server submit
        _view = _OnboardingView.submitted;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      _handleApiError(e, fromSubmit: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        leading: (_view == _OnboardingView.personal ||
                _view == _OnboardingView.business)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _isBusy
                    ? null
                    : () => setState(() {
                          _errorMessage = null;
                          _view = _OnboardingView.overview;
                        }),
              )
            : null,
        title: const Text(
          'Provider Onboarding',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  key: const Key('onboarding_error_banner'),
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.errorRed.withAlpha(80)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: AppTheme.errorRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_uncertainSubmitOutcome && _authToken != null) ...[
                        const SizedBox(height: 8),
                        OutlinedButton(
                          key: const Key('onboarding_check_draft_btn'),
                          onPressed: _isBusy ? null : _refreshDraft,
                          child: const Text('Check Draft Status'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (_infoMessage != null) ...[
                Container(
                  key: const Key('onboarding_info_banner'),
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    _infoMessage!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: Color(0xFF047857),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              switch (_view) {
                _OnboardingView.otp => _buildOtpView(),
                _OnboardingView.overview => _buildOverviewView(),
                _OnboardingView.personal => _buildPersonalForm(),
                _OnboardingView.business => _buildBusinessForm(),
                _OnboardingView.submitted => _buildSubmittedView(),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Step 1: Verify Provider Email',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'We will send a 6-digit verification code to authorize your registration draft.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('onboarding_email_field'),
            controller: _emailCtrl,
            enabled: !_isBusy,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Provider Email Address',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            key: const Key('onboarding_send_otp_btn'),
            onPressed: _isBusy ? null : _onSendOtp,
            child: Text(_otpSent ? 'Resend Code' : 'Send Verification Code'),
          ),
          if (_otpSent) ...[
            const SizedBox(height: 12),
            TextField(
              key: const Key('onboarding_otp_field'),
              controller: _otpCtrl,
              enabled: !_isBusy,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: '6-Digit Verification Code',
                isDense: true,
                counterText: '',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              key: const Key('onboarding_verify_otp_btn'),
              onPressed: _isBusy ? null : _onVerifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: _royalBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Verify Email & Continue'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewView() {
    final d = _draft;
    final personalDone = d?.personalCompleted ?? false;
    final businessDone = d?.businessCompleted ?? false;
    final identityDone = d?.identityCompleted ?? false;
    final ready = d?.readyToSubmit ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('onboarding_progress_card'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Server-Confirmed Registration Progress',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 6),
              _StatusLine('Email Verified', _authToken != null),
              _StatusLine('Personal Details Completed', personalDone),
              _StatusLine('Business Details Completed', businessDone),
              _StatusLine('Selfie Uploaded', d?.selfieUploaded ?? false),
              _StatusLine('NIC Front Uploaded', d?.nicFrontUploaded ?? false),
              _StatusLine('NIC Back Uploaded', d?.nicBackUploaded ?? false),
              _StatusLine('Identity Verification Completed', identityDone),
              _StatusLine('Ready for Final Submission', ready),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _StepTile(
          key: const Key('onboarding_step_personal'),
          title: '1. Personal Details',
          subtitle: 'Full name, Sri Lankan phone, DOB (18+), NIC/Passport & address',
          completed: personalDone,
          onTap: () => setState(() {
            _errorMessage = null;
            _view = _OnboardingView.personal;
          }),
        ),
        const SizedBox(height: 10),
        _StepTile(
          key: const Key('onboarding_step_business'),
          title: '2. Business Details',
          subtitle: 'Business name, category, address & description',
          completed: businessDone,
          onTap: () => setState(() {
            _errorMessage = null;
            _view = _OnboardingView.business;
          }),
        ),
        const SizedBox(height: 10),
        _StepTile(
          key: const Key('onboarding_step_identity'),
          title: '3. Identity Documents',
          subtitle: 'Selfie, NIC Front & NIC Back (JPEG/PNG/WEBP, max 5 MB)',
          completed: identityDone,
          onTap: _openIdentityUpload,
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            key: const Key('onboarding_submit_btn'),
            onPressed: (!ready || _isBusy || _uncertainSubmitOutcome)
                ? null
                : _onSubmitRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: _royalBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit Application for Review'),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalForm() {
    return Form(
      key: _personalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Personal Details',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 10),
          _formField(
            fieldKey: const Key('personal_full_name_field'),
            controller: _fullNameCtrl,
            label: 'Full Name',
            validator: (v) => ProviderOnboardingValidators.validateRequiredLength(
              v,
              label: 'Full name',
              minLength: 2,
              maxLength: 150,
            ),
          ),
          _formField(
            fieldKey: const Key('personal_phone_field'),
            controller: _phoneCtrl,
            label: 'Primary Phone (e.g. 0771234567)',
            keyboardType: TextInputType.phone,
            validator: (v) =>
                ProviderValidators.validatePhone(v, requiredField: true),
          ),
          _formField(
            fieldKey: const Key('personal_dob_field'),
            controller: _dobCtrl,
            label: 'Date of Birth (YYYY-MM-DD, 18+)',
            validator: ProviderOnboardingValidators.validateDateOfBirth,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              key: const Key('personal_gender_dropdown'),
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender', isDense: true),
              items: const ['Male', 'Female', 'Other']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _gender = v);
              },
            ),
          ),
          _formField(
            fieldKey: const Key('personal_nationality_field'),
            controller: _nationalityCtrl,
            label: 'Nationality',
            validator: (v) => ProviderOnboardingValidators.validateRequiredLength(
              v,
              label: 'Nationality',
              minLength: 2,
              maxLength: 50,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              key: const Key('personal_doc_type_dropdown'),
              initialValue: _identityDocType,
              decoration: const InputDecoration(
                labelText: 'Identity Document Type',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'nic', child: Text('Sri Lankan NIC')),
                DropdownMenuItem(value: 'passport', child: Text('Passport')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _identityDocType = v);
              },
            ),
          ),
          _formField(
            fieldKey: const Key('personal_nic_field'),
            controller: _nicNumberCtrl,
            label: _identityDocType == 'passport'
                ? 'Passport Number'
                : 'NIC Number (9 digits + V/X or 12 digits)',
            validator: (v) => ProviderOnboardingValidators.validateIdentityNumber(
              v,
              docType: _identityDocType,
            ),
          ),
          _formField(
            fieldKey: const Key('personal_province_field'),
            controller: _permProvinceCtrl,
            label: 'Permanent Province',
            validator: (v) => ProviderOnboardingValidators.validateRequiredLength(
              v,
              label: 'Permanent province',
              minLength: 2,
              maxLength: 100,
            ),
          ),
          _formField(
            fieldKey: const Key('personal_district_field'),
            controller: _permDistrictCtrl,
            label: 'Permanent District',
            validator: (v) => ProviderOnboardingValidators.validateRequiredLength(
              v,
              label: 'Permanent district',
              minLength: 2,
              maxLength: 100,
            ),
          ),
          _formField(
            fieldKey: const Key('personal_city_field'),
            controller: _permCityCtrl,
            label: 'Permanent City',
            validator: (v) => ProviderOnboardingValidators.validateRequiredLength(
              v,
              label: 'Permanent city',
              minLength: 2,
              maxLength: 100,
            ),
          ),
          _formField(
            fieldKey: const Key('personal_landmark_field'),
            controller: _permLandmarkCtrl,
            label: 'Permanent Landmark (min 5 chars)',
            validator: (v) => ProviderOnboardingValidators.validateRequiredLength(
              v,
              label: 'Permanent landmark',
              minLength: 5,
              maxLength: 255,
            ),
          ),
          _formField(
            fieldKey: const Key('personal_postal_field'),
            controller: _permPostalCtrl,
            label: 'Permanent Postal Code',
            validator: (v) => ProviderOnboardingValidators.validateRequiredLength(
              v,
              label: 'Postal code',
              minLength: 3,
              maxLength: 20,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              key: const Key('personal_save_btn'),
              onPressed: _isBusy ? null : _onSavePersonal,
              style: ElevatedButton.styleFrom(
                backgroundColor: _royalBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Personal Details & Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessForm() {
    return Form(
      key: _businessFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Business Details',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 10),
          _formField(
            fieldKey: const Key('business_name_field'),
            controller: _businessNameCtrl,
            label: 'Business Name',
            validator: ProviderValidators.validateBusinessName,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<BackendProviderType>(
              key: const Key('business_provider_type_dropdown'),
              initialValue: _providerType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Provider Type',
                isDense: true,
              ),
              items: BackendProviderType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.displayLabel),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _providerType = v);
              },
            ),
          ),
          _formField(
            fieldKey: const Key('business_secondary_phone_field'),
            controller: _secondaryPhoneCtrl,
            label: 'Secondary Phone (optional)',
            keyboardType: TextInputType.phone,
            validator: (v) =>
                ProviderValidators.validatePhone(v, requiredField: false),
          ),
          SwitchListTile(
            key: const Key('business_same_address_switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Business address same as permanent address'),
            value: _sameAsPermanent,
            onChanged: (v) => setState(() => _sameAsPermanent = v),
          ),
          if (!_sameAsPermanent) ...[
            _formField(
              fieldKey: const Key('business_province_field'),
              controller: _bizProvinceCtrl,
              label: 'Business Province',
              validator: (v) =>
                  ProviderOnboardingValidators.validateRequiredLength(
                v,
                label: 'Business province',
                minLength: 2,
                maxLength: 100,
              ),
            ),
            _formField(
              fieldKey: const Key('business_district_field'),
              controller: _bizDistrictCtrl,
              label: 'Business District',
              validator: (v) =>
                  ProviderOnboardingValidators.validateRequiredLength(
                v,
                label: 'Business district',
                minLength: 2,
                maxLength: 100,
              ),
            ),
            _formField(
              fieldKey: const Key('business_city_field'),
              controller: _bizCityCtrl,
              label: 'Business City',
              validator: (v) =>
                  ProviderOnboardingValidators.validateRequiredLength(
                v,
                label: 'Business city',
                minLength: 2,
                maxLength: 100,
              ),
            ),
            _formField(
              fieldKey: const Key('business_landmark_field'),
              controller: _bizLandmarkCtrl,
              label: 'Business Landmark (optional)',
              validator: (v) => ProviderValidators.validateMaxLength(
                v,
                fieldLabel: 'Business landmark',
                maxLength: 255,
              ),
            ),
            _formField(
              fieldKey: const Key('business_postal_field'),
              controller: _bizPostalCtrl,
              label: 'Business Postal Code',
              validator: (v) =>
                  ProviderOnboardingValidators.validateRequiredLength(
                v,
                label: 'Business postal code',
                minLength: 3,
                maxLength: 20,
              ),
            ),
          ],
          _formField(
            fieldKey: const Key('business_reg_no_field'),
            controller: _bizRegNoCtrl,
            label: 'Business Registration Number (optional)',
            validator: (v) => ProviderValidators.validateMaxLength(
              v,
              fieldLabel: 'Registration number',
              maxLength: 50,
            ),
          ),
          _formField(
            fieldKey: const Key('business_description_field'),
            controller: _bizDescCtrl,
            label: 'Business Description',
            maxLines: 3,
            validator: (v) => ProviderOnboardingValidators.validateRequiredLength(
              v,
              label: 'Business description',
              minLength: 5,
              maxLength: 1000,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              key: const Key('business_save_btn'),
              onPressed: _isBusy ? null : _onSaveBusiness,
              style: ElevatedButton.styleFrom(
                backgroundColor: _royalBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Business Details & Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedView() {
    final res = _submitResult!;
    return Container(
      key: const Key('onboarding_submitted_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            size: 48,
            color: _royalBlue,
          ),
          const SizedBox(height: 12),
          const Text(
            'Application Submitted',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            res.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Approval Status: ${res.approvalStatus.toUpperCase()} (${res.nextAction})',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEA580C),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can sign in only after an administrator reviews and approves your application and you complete password setup.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              key: const Key('onboarding_back_to_login_btn'),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/vendor/login',
                (route) => false,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _royalBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Return to Vendor Login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formField({
    required Key fieldKey,
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        enabled: !_isBusy,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final String label;
  final bool done;

  const _StatusLine(this.label, this.done);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: done ? const Color(0xFF16A34A) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                color: AppTheme.primaryNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool completed;
  final VoidCallback onTap;

  const _StepTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: completed
              ? const Color(0xFF86EFAC)
              : const Color(0xFFDBEAFE),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          completed ? Icons.check_circle_rounded : Icons.edit_document,
          color: completed ? const Color(0xFF16A34A) : const Color(0xFF0A4DF5),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryNavy,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

