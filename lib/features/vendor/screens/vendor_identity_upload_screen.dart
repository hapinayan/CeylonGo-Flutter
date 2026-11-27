import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../auth/models/api_error.dart';
import '../models/provider_identity_models.dart';
import '../services/provider_identity_service.dart';
import '../services/vendor_identity_doc_picker.dart';

/// Provider Identity Document Upload Screen (Module 6)
/// Supports Email OTP -> Registration Authorization -> Selfie, NIC Front, and
/// NIC Back selection, magic-byte/5MB validation, preview, and multipart upload
/// to `POST /api/v1/providers/registration/identity`.
class VendorIdentityUploadScreen extends StatefulWidget {
  final String? initialAuthToken;
  final String? initialEmail;
  final bool isDemoMode;
  final ProviderIdentityService? identityService;
  final VendorIdentityDocPicker? docPicker;

  const VendorIdentityUploadScreen({
    super.key,
    this.initialAuthToken,
    this.initialEmail,
    this.isDemoMode = false,
    this.identityService,
    this.docPicker,
  });

  @override
  State<VendorIdentityUploadScreen> createState() =>
      _VendorIdentityUploadScreenState();
}

class _VendorIdentityUploadScreenState
    extends State<VendorIdentityUploadScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  late final ProviderIdentityService _identityService;
  late final VendorIdentityDocPicker _docPicker;

  String? _authToken;
  bool _otpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isPicking = false;
  bool _isUploading = false;

  IdentityDocumentFile? _selfie;
  IdentityDocumentFile? _nicFront;
  IdentityDocumentFile? _nicBack;

  ProviderDraftStatus? _serverDraft;
  String? _errorMessage;
  String? _infoMessage;

  static const Color _royalBlue = Color(0xFF0A4DF5);

  @override
  void initState() {
    super.initState();
    _identityService = widget.identityService ?? ProviderIdentityService();
    _docPicker = widget.docPicker ?? ImagePickerVendorIdentityDocPicker();
    _authToken = widget.initialAuthToken;
    if (widget.initialEmail != null) {
      _emailCtrl.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSendOtp() async {
    if (widget.isDemoMode || _isSendingOtp) return;
    final emailErr = FormValidators.validateEmail(_emailCtrl.text);
    if (emailErr != null) {
      setState(() => _errorMessage = emailErr);
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final msg = await _identityService.sendRegistrationOtp(_emailCtrl.text);
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _otpSent = true;
        _infoMessage = msg;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _onVerifyOtp() async {
    if (widget.isDemoMode || _isVerifyingOtp) return;
    final otp = _otpCtrl.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _errorMessage = 'Enter the 6-digit verification code.');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final res = await _identityService.verifyRegistrationOtp(
        email: _emailCtrl.text,
        otp: otp,
      );
      if (!mounted) return;

      final token = res.authorizationToken;
      if (!res.verified || token == null || token.trim().isEmpty) {
        setState(() {
          _isVerifyingOtp = false;
          _errorMessage = res.message ??
              'Registration authorization was not issued for this account.';
        });
        return;
      }

      setState(() {
        _isVerifyingOtp = false;
        _authToken = token;
        _infoMessage =
            'Email verified. You can now upload your identity documents.';
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifyingOtp = false;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _onPickDocument(
    IdentityDocKind kind,
    IdentityPickSource source,
  ) async {
    if (widget.isDemoMode || _isPicking || _isUploading) return;
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });

    try {
      final picked = await _docPicker.pickDocument(kind: kind, source: source);
      if (!mounted) return;
      if (picked != null) {
        setState(() {
          switch (kind) {
            case IdentityDocKind.selfie:
              _selfie = picked;
              break;
            case IdentityDocKind.nicFront:
              _nicFront = picked;
              break;
            case IdentityDocKind.nicBack:
              _nicBack = picked;
              break;
          }
        });
      }
    } on IdentityValidationException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _onRemoveDocument(IdentityDocKind kind) {
    if (_isUploading) return;
    setState(() {
      _errorMessage = null;
      switch (kind) {
        case IdentityDocKind.selfie:
          _selfie = null;
          break;
        case IdentityDocKind.nicFront:
          _nicFront = null;
          break;
        case IdentityDocKind.nicBack:
          _nicBack = null;
          break;
      }
    });
  }

  Future<void> _onUpload() async {
    if (widget.isDemoMode || _isUploading) return;
    final token = _authToken;
    if (token == null || token.trim().isEmpty) {
      setState(() {
        _errorMessage =
            'Complete email OTP verification first to obtain registration authorization.';
      });
      return;
    }

    if (_selfie == null && _nicFront == null && _nicBack == null) {
      setState(() {
        _errorMessage =
            'Select at least one document (Selfie, NIC Front, or NIC Back) to upload.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final draft = await _identityService.uploadIdentityDocuments(
        registrationAuthToken: token,
        selfie: _selfie,
        nicFront: _nicFront,
        nicBack: _nicBack,
      );
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _serverDraft = draft;
        _infoMessage = draft.identityCompleted
            ? 'Identity documents uploaded. Final provider approval requires administrative review.'
            : 'Uploaded selected documents. Upload remaining documents to complete verification.';
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = e.message;
        if (e.statusCode == 401) {
          _authToken = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAnySelected =
        _selfie != null || _nicFront != null || _nicBack != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        title: const Text(
          'Identity Verification',
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
              if (widget.isDemoMode) ...[
                Container(
                  key: const Key('identity_demo_blocked_banner'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Text(
                    'Demo Mode: Real identity document uploads are disabled during offline demo sessions.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_errorMessage != null) ...[
                Container(
                  key: const Key('identity_error_banner'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.errorRed.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: AppTheme.errorRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (hasAnySelected && _authToken != null && !_isUploading)
                        TextButton(
                          key: const Key('identity_retry_btn'),
                          onPressed: _onUpload,
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_infoMessage != null) ...[
                Container(
                  key: const Key('identity_info_banner'),
                  padding: const EdgeInsets.all(12),
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
                const SizedBox(height: 12),
              ],
              _buildAuthorizationSection(),
              const SizedBox(height: 14),
              _IdentityDocumentCard(
                kind: IdentityDocKind.selfie,
                guidance: 'Ensure your face is clearly visible and well-lit.',
                file: _selfie,
                isConfirmedOnServer: _serverDraft?.selfieUploaded ?? false,
                enabled: !widget.isDemoMode && !_isUploading && !_isPicking,
                onCamera: () =>
                    _onPickDocument(IdentityDocKind.selfie, IdentityPickSource.camera),
                onGallery: () =>
                    _onPickDocument(IdentityDocKind.selfie, IdentityPickSource.gallery),
                onRemove: () => _onRemoveDocument(IdentityDocKind.selfie),
              ),
              const SizedBox(height: 12),
              _IdentityDocumentCard(
                kind: IdentityDocKind.nicFront,
                guidance:
                    'Ensure the entire front side of your NIC is readable.',
                file: _nicFront,
                isConfirmedOnServer: _serverDraft?.nicFrontUploaded ?? false,
                enabled: !widget.isDemoMode && !_isUploading && !_isPicking,
                onCamera: () => _onPickDocument(
                  IdentityDocKind.nicFront,
                  IdentityPickSource.camera,
                ),
                onGallery: () => _onPickDocument(
                  IdentityDocKind.nicFront,
                  IdentityPickSource.gallery,
                ),
                onRemove: () => _onRemoveDocument(IdentityDocKind.nicFront),
              ),
              const SizedBox(height: 12),
              _IdentityDocumentCard(
                kind: IdentityDocKind.nicBack,
                guidance: 'Ensure all details on the back side are readable.',
                file: _nicBack,
                isConfirmedOnServer: _serverDraft?.nicBackUploaded ?? false,
                enabled: !widget.isDemoMode && !_isUploading && !_isPicking,
                onCamera: () => _onPickDocument(
                  IdentityDocKind.nicBack,
                  IdentityPickSource.camera,
                ),
                onGallery: () => _onPickDocument(
                  IdentityDocKind.nicBack,
                  IdentityPickSource.gallery,
                ),
                onRemove: () => _onRemoveDocument(IdentityDocKind.nicBack),
              ),
              if (_serverDraft != null) ...[
                const SizedBox(height: 14),
                _buildServerStatusCard(_serverDraft!),
              ],
              if (_isUploading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(
                  key: Key('identity_upload_progress'),
                  color: _royalBlue,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  key: const Key('identity_upload_submit_btn'),
                  onPressed: (widget.isDemoMode ||
                          _isUploading ||
                          _authToken == null ||
                          !hasAnySelected)
                      ? null
                      : _onUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _royalBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Upload Identity Documents'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorizationSection() {
    if (_authToken != null) {
      return Container(
        key: const Key('identity_auth_verified_badge'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: _royalBlue, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Registration authorization verified. Permitted formats: JPEG, PNG, WEBP (max 5 MB).',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Step 1: Email Verification (Required)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('identity_otp_email_field'),
            controller: _emailCtrl,
            enabled: !widget.isDemoMode && !_isSendingOtp && !_isVerifyingOtp,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Provider Email',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('identity_send_otp_btn'),
                  onPressed: widget.isDemoMode || _isSendingOtp
                      ? null
                      : _onSendOtp,
                  child: Text(_otpSent ? 'Resend Code' : 'Send Code'),
                ),
              ),
            ],
          ),
          if (_otpSent) ...[
            const SizedBox(height: 10),
            TextField(
              key: const Key('identity_otp_code_field'),
              controller: _otpCtrl,
              enabled: !widget.isDemoMode && !_isVerifyingOtp,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: '6-Digit Verification Code',
                isDense: true,
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              key: const Key('identity_verify_otp_btn'),
              onPressed: widget.isDemoMode || _isVerifyingOtp
                  ? null
                  : _onVerifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: _royalBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Verify Email & Authorize Upload'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServerStatusCard(ProviderDraftStatus draft) {
    return Container(
      key: const Key('identity_server_status_card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Server Upload Status',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text('Selfie: ${draft.selfieUploaded ? 'Uploaded' : 'Pending'}'),
          Text(
            'NIC Front: ${draft.nicFrontUploaded ? 'Uploaded' : 'Pending'}',
          ),
          Text('NIC Back: ${draft.nicBackUploaded ? 'Uploaded' : 'Pending'}'),
          const SizedBox(height: 4),
          Text(
            draft.identityCompleted
                ? 'Identity Verification: Completed (Pending Admin Review)'
                : 'Identity Verification: Incomplete',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: draft.identityCompleted
                  ? const Color(0xFF047857)
                  : const Color(0xFFEA580C),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityDocumentCard extends StatelessWidget {
  final IdentityDocKind kind;
  final String guidance;
  final IdentityDocumentFile? file;
  final bool isConfirmedOnServer;
  final bool enabled;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  const _IdentityDocumentCard({
    required this.kind,
    required this.guidance,
    required this.file,
    required this.isConfirmedOnServer,
    required this.enabled,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final String statusLabel = isConfirmedOnServer
        ? 'Uploaded'
        : (file != null ? 'Ready' : 'Not Selected');
    final Color statusColor = isConfirmedOnServer
        ? const Color(0xFF16A34A)
        : (file != null ? const Color(0xFF0A4DF5) : const Color(0xFF64748B));

    return Container(
      key: Key('identity_card_${kind.fieldName}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  kind.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            guidance,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),
          if (file != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Image.memory(
                      file!.bytes,
                      key: Key('identity_preview_${kind.fieldName}'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    key: Key('identity_remove_${kind.fieldName}'),
                    onTap: enabled ? onRemove : null,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: const Text(
                'No image selected',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: Key('identity_camera_${kind.fieldName}'),
                  onPressed: enabled ? onCamera : null,
                  icon: const Icon(Icons.photo_camera_outlined, size: 17),
                  label: Text(file == null ? 'Camera' : 'Retake'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: Key('identity_gallery_${kind.fieldName}'),
                  onPressed: enabled ? onGallery : null,
                  icon: const Icon(Icons.photo_library_outlined, size: 17),
                  label: Text(file == null ? 'Gallery' : 'Replace'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

