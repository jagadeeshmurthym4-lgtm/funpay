import 'dart:convert';
import 'dart:io';
import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/domain/entities/affiliate_project_entity.dart';
import 'package:cashspark/presentation/providers/affiliate_project_provider.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SubmitProofScreen extends StatefulWidget {
  final ProjectParticipationEntity participation;
  final AffiliateProjectEntity project;

  const SubmitProofScreen({
    super.key,
    required this.participation,
    required this.project,
  });

  @override
  State<SubmitProofScreen> createState() => _SubmitProofScreenState();
}

class _SubmitProofScreenState extends State<SubmitProofScreen> {
  final _transactionIdController = TextEditingController();
  final _textProofController = TextEditingController();
  final _remarksController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isUploading = false;
  bool _submitted = false;
  double _totalUploadProgress = 0.0;
  int _uploadedCount = 0;
  int _totalToUpload = 0;
  String? _uploadStatusText;

  @override
  void dispose() {
    _transactionIdController.dispose();
    _textProofController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  /// Returns a description of what proof is needed based on the project type.
  String get _proofTypeDescription {
    switch (widget.project.projectType) {
      case ProjectType.uploadScreenshot:
        return 'Upload screenshots showing completion of the task.';
      case ProjectType.uploadPdf:
        return 'Upload the PDF document as proof of completion.';
      case ProjectType.uploadImage:
        return 'Upload an image as proof of completion.';
      case ProjectType.submitText:
        return 'Enter the required text information below.';
      case ProjectType.customTask:
        return 'Provide text details and upload supporting screenshots.';
      case ProjectType.survey:
        return 'Enter your survey responses and optionally upload a screenshot.';
      case ProjectType.quiz:
        return 'Enter your quiz answers and optionally upload a screenshot.';
      case ProjectType.watchVideo:
        return 'Confirm you watched the video and optionally upload a screenshot.';
      default:
        return 'Upload screenshots or provide text proof as required.';
    }
  }

  /// Whether the project type primarily requires text submission.
  bool get _requiresTextFirst =>
      widget.project.projectType == ProjectType.submitText ||
      widget.project.projectType == ProjectType.customTask ||
      widget.project.projectType == ProjectType.survey ||
      widget.project.projectType == ProjectType.quiz ||
      widget.project.projectType == ProjectType.watchVideo;

  /// Whether the project type requires at least one screenshot.
  bool get _requiresScreenshot =>
      widget.project.projectType == ProjectType.uploadScreenshot ||
      widget.project.projectType == ProjectType.uploadPdf ||
      widget.project.projectType == ProjectType.uploadImage ||
      widget.project.projectType == ProjectType.customTask;

  /// Whether the transaction ID field is relevant for this project type.
  bool get _showTransactionId =>
      widget.project.projectType == ProjectType.purchase ||
      widget.project.projectType == ProjectType.installApp ||
      widget.project.projectType == ProjectType.registration;

  IconData get _proofIcon {
    switch (widget.project.projectType) {
      case ProjectType.uploadScreenshot:
        return Icons.screenshot_outlined;
      case ProjectType.uploadPdf:
        return Icons.picture_as_pdf_outlined;
      case ProjectType.uploadImage:
        return Icons.image_outlined;
      case ProjectType.submitText:
        return Icons.text_fields_outlined;
      case ProjectType.customTask:
        return Icons.task_alt_outlined;
      case ProjectType.survey:
        return Icons.quiz_outlined;
      case ProjectType.watchVideo:
        return Icons.play_circle_outlined;
      default:
        return Icons.cloud_upload_outlined;
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        for (final image in images) {
          if (_selectedImages.length < 5) {
            // Max 5 images
            _selectedImages.add(File(image.path));
          }
        }
      });
    }
  }

  Future<void> _pickSingleImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (_selectedImages.length < 5) {
          _selectedImages.add(File(image.path));
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// Uploads all selected images to Cloudinary and returns their URLs.
  /// Retries once on failure.
  Future<List<String>> _uploadAllImages() async {
    if (_selectedImages.isEmpty) return [];

    final cloudinary = CloudinaryPublic('q9recjxy', 'funny_uploads',
        cache: false);
    final urls = <String>[];
    _totalToUpload = _selectedImages.length;
    _uploadedCount = 0;

    for (int i = 0; i < _selectedImages.length; i++) {
      final file = _selectedImages[i];
      bool success = false;

      for (int attempt = 0; attempt < 2 && !success; attempt++) {
        try {
          setState(() {
            _uploadStatusText =
                'Uploading image ${i + 1} of ${_selectedImages.length}...';
          });

          final response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(file.path,
                resourceType: CloudinaryResourceType.Image),
            onProgress: (sent, total) {
              if (!mounted) return;
              final fileProgress = sent / total;
              // Overall progress: completed files + current file progress
              final overall =
                  (_uploadedCount + fileProgress) / _totalToUpload;
              setState(() {
                _totalUploadProgress = overall;
                _uploadStatusText =
                    'Uploading image ${i + 1} of ${_selectedImages.length}... ${(fileProgress * 100).toStringAsFixed(0)}%';
              });
            },
          );

          urls.add(response.secureUrl);
          _uploadedCount++;
          success = true;
          setState(() {
            _totalUploadProgress = _uploadedCount / _totalToUpload;
          });
        } catch (e) {
          if (attempt == 1) {
            // Final attempt failed
            debugPrint(
                '[SubmitProof] Failed to upload image ${i + 1}: $e');
            rethrow;
          }
          debugPrint(
              '[SubmitProof] Upload attempt $attempt failed for image ${i + 1}, retrying: $e');
        }
      }
    }

    return urls;
  }

  /// Validate that required fields are filled based on the project type.
  String? _validateFields() {
    final textProof = _textProofController.text.trim();
    final imagesCount = _selectedImages.length;

    switch (widget.project.projectType) {
      case ProjectType.submitText:
        if (textProof.isEmpty) return 'Please enter the required text information.';
        break;
      case ProjectType.customTask:
        if (textProof.isEmpty) return 'Please enter the required text details.';
        if (imagesCount == 0) return 'Please upload at least one supporting screenshot.';
        break;
      case ProjectType.uploadScreenshot:
      case ProjectType.uploadPdf:
      case ProjectType.uploadImage:
        if (imagesCount == 0) return 'Please upload at least one file as proof.';
        break;
      default:
        // For other task types, at least one form of proof is required
        if (textProof.isEmpty && imagesCount == 0) {
          return 'Please provide proof by entering text or uploading a screenshot.';
        }
        break;
    }

    return null;
  }

  Future<void> _submitProof() async {
    // Validate required fields based on project type
    final validationError = _validateFields();
    if (validationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _totalUploadProgress = 0.0;
      _uploadStatusText = 'Preparing upload...';
      _uploadedCount = 0;
      _totalToUpload = 0;
    });

    // Capture context-dependent references before async gaps
    final provider = context.read<AffiliateProjectProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // Upload images if any
    List<String> screenshotUrls = [];
    if (_selectedImages.isNotEmpty) {
      try {
        screenshotUrls = await _uploadAllImages();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        setState(() {
          _isUploading = false;
          _uploadStatusText = null;
        });
        return;
      }
    }

    setState(() => _uploadStatusText = 'Saving submission...');

    final textProof = _textProofController.text.trim();
    final remarks = _remarksController.text.trim();

    // Build the note: combine text proof and remarks
    String? note;
    if (textProof.isNotEmpty && remarks.isNotEmpty) {
      note = 'Proof: $textProof\n\nRemarks: $remarks';
    } else if (textProof.isNotEmpty) {
      note = textProof;
    } else if (remarks.isNotEmpty) {
      note = remarks;
    }

    // Store screenshot URLs as JSON array for multiple images support
    final screenshotUrlStr = screenshotUrls.isNotEmpty
        ? jsonEncode(screenshotUrls)
        : null;

    try {
      final success = await provider.submitProof(
        participationId: widget.participation.participationId,
        screenshotUrl: screenshotUrlStr,
        note: note,
        transactionId: _transactionIdController.text.isNotEmpty
            ? _transactionIdController.text.trim()
            : null,
      );

      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatusText = null;
        });
        if (success) {
          setState(() => _submitted = true);
          // Auto-navigate back after a brief delay to show success
          final navigator = Navigator.of(context);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              navigator.pop(true);
            }
          });
        } else {
          messenger.showSnackBar(
            SnackBar(
              content:
                  Text(provider.errorMessage ?? 'Failed to submit proof'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatusText = null;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to submit proof: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final project = widget.project;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Submit ${project.isTask ? project.typeLabel : 'Proof'}',
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: _submitted
          ? _buildSubmissionSuccess(isDark)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project info card
                  _buildProjectInfoCard(isDark, theme),

                  const SizedBox(height: 24),

                  // Task-type aware header
                  _buildProofTypeHeader(isDark, theme),

                  const SizedBox(height: 16),

                  // Proof Section: shown based on project type priority
                  if (_requiresTextFirst) ...[
                    _buildTextProofSection(isDark, theme),
                    const SizedBox(height: 24),
                    if (_requiresScreenshot)
                      _buildImageUploadSection(isDark, theme)
                    else
                      _buildOptionalImageSection(isDark, theme),
                  ] else ...[
                    _buildImageUploadSection(isDark, theme),
                    const SizedBox(height: 24),
                    _buildOptionalTextSection(isDark, theme),
                  ],

                  const SizedBox(height: 24),

                  // Upload progress indicators
                  if (_isUploading && _totalToUpload > 1) ...[
                    _buildUploadProgress(isDark),
                    const SizedBox(height: 16),
                  ],

                  // Additional Details Section
                  if (_showTransactionId) ...[
                    _buildTransactionIdField(isDark),
                    const SizedBox(height: 12),
                  ],

                  // Remarks (always available)
                  _buildRemarksField(isDark),
                  const SizedBox(height: 32),

                  // Submit button
                  _buildSubmitButton(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildProjectInfoCard(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2740) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E3A5F).withValues(alpha: 0.5)
              : const Color(0xFFCBD5E1).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.project.projectType.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_proofIcon,
                color: widget.project.projectType.iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                  Text(
                    widget.project.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.project.projectType.iconColor
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.project.typeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: widget.project.projectType.iconColor,
                          ),
                        ),
                      ),
                      Text(
                        'Reward: ${widget.project.rewardText}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4ADE80),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofTypeHeader(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_proofIcon,
                size: 20, color: widget.project.projectType.iconColor),
            const SizedBox(width: 8),
            Text(
              _requiresTextFirst ? 'Text Proof' : 'Screenshot Upload',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (_requiresTextFirst && _requiresScreenshot)
              const Text(' *',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))
            else if (!_requiresTextFirst && _requiresScreenshot)
              const Text(' *',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _proofTypeDescription,
          style: TextStyle(
            fontSize: 12,
            color:
                isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // ─── Text Proof Section ──────────────────────────────────

  Widget _buildTextProofSection(bool isDark, ThemeData theme) {
    final isRequired = widget.project.projectType == ProjectType.submitText ||
        widget.project.projectType == ProjectType.customTask;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    const Icon(Icons.text_fields_outlined,
                        size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    Text(
                      isRequired ? 'Your Response *' : 'Your Response',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textProofController,
                enabled: !_isUploading,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: _hintTextForType(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1A3350)
                      : Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  _textProofHint(),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.textMuted
                        : const Color(0xFF94A3B8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _hintTextForType() {
    switch (widget.project.projectType) {
      case ProjectType.submitText:
        return 'Enter the required text information here...';
      case ProjectType.customTask:
        return 'Describe what you did and provide any required details...';
      case ProjectType.survey:
        return 'Enter your survey responses...';
      case ProjectType.quiz:
        return 'Enter your quiz answers...';
      case ProjectType.watchVideo:
        return 'Enter any required information about the video...';
      default:
        return 'Type your response here...';
    }
  }

  String _textProofHint() {
    switch (widget.project.projectType) {
      case ProjectType.submitText:
        return 'Provide the text information required to complete this task.';
      case ProjectType.customTask:
        return 'Include any relevant details from the task instructions.';
      case ProjectType.survey:
        return 'Share your survey responses for verification.';
      case ProjectType.quiz:
        return 'List your answers so they can be verified.';
      case ProjectType.watchVideo:
        return 'Provide any confirmation details required.';
      default:
        return '';
    }
  }

  // ─── Image Upload Section ───────────────────────────────

  Widget _buildImageUploadSection(bool isDark, ThemeData theme) {
    final isRequired = _requiresScreenshot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined,
                size: 16, color: widget.project.projectType.iconColor),
            const SizedBox(width: 6),
            Text(
              isRequired ? 'Screenshots / Images *' : 'Screenshots / Images',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            if (_selectedImages.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_selectedImages.length}/5',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Upload screenshots as proof. You can upload up to 5 images.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 12),

        // Image grid
        if (_selectedImages.isNotEmpty)
          _buildImageGrid(isDark),
        if (_selectedImages.isNotEmpty) const SizedBox(height: 12),

        // Add more button
        if (_selectedImages.length < 5)
          GestureDetector(
            onTap: _isUploading ? null : _pickImages,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A3350)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedImages.isNotEmpty
                      ? const Color(0xFF4ADE80).withValues(alpha: 0.3)
                      : isDark
                          ? const Color(0xFF1E3A5F)
                          : const Color(0xFFCBD5E1),
                  width: _selectedImages.isNotEmpty ? 1.5 : 1,
                  style: _selectedImages.isNotEmpty
                      ? BorderStyle.solid
                      : BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedImages.isNotEmpty
                        ? Icons.add_photo_alternate_outlined
                        : Icons.camera_alt_outlined,
                    size: _selectedImages.isNotEmpty ? 28 : 36,
                    color: _selectedImages.isNotEmpty
                        ? const Color(0xFF4ADE80)
                        : widget.project.projectType.iconColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedImages.isNotEmpty
                        ? 'Add more images'
                        : 'Tap to upload screenshots',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PNG, JPG format · Select multiple · Max 5 images',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.textMuted
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle,
                    size: 16, color: Color(0xFF22C55E)),
                SizedBox(width: 8),
                Text(
                  'Maximum 5 images selected',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImageGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                _selectedImages[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: isDark
                      ? const Color(0xFF1A3350)
                      : const Color(0xFFF1F5F9),
                  child: const Icon(Icons.broken_image_outlined,
                      size: 24),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _isUploading
                      ? null
                      : () => _removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Optional Sections ──────────────────────────────────

  Widget _buildOptionalImageSection(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined,
                size: 16, color: widget.project.projectType.iconColor),
            const SizedBox(width: 6),
            Text(
              'Screenshots (Optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Add supporting screenshots if available.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 12),

        if (_selectedImages.isNotEmpty) _buildImageGrid(isDark),
        if (_selectedImages.isNotEmpty) const SizedBox(height: 12),

        if (_selectedImages.length < 5)
          GestureDetector(
            onTap: _isUploading ? null : _pickSingleImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A3350)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E3A5F)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 28,
                      color: isDark
                          ? AppTheme.textMuted
                          : const Color(0xFF94A3B8)),
                  const SizedBox(height: 4),
                  Text(
                    'Add screenshots',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.textSecondary
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionalTextSection(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.text_fields_outlined,
                size: 16, color: Color(0xFFF59E0B)),
            const SizedBox(width: 6),
            Text(
              'Text Details (Optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Provide any additional text information to help verify your submission.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _textProofController,
          enabled: !_isUploading,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add text details here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A3350) : Colors.white,
          ),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ─── Transaction ID Field ───────────────────────────────

  Widget _buildTransactionIdField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Details',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _transactionIdController,
          enabled: !_isUploading,
          decoration: InputDecoration(
            labelText: 'Transaction ID',
            hintText: 'e.g. ORD123456789',
            prefixIcon: const Icon(Icons.receipt_outlined, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF1A3350) : const Color(0xFFF1F5F9),
          ),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ─── Remarks Field ──────────────────────────────────────

  Widget _buildRemarksField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.chat_outlined,
                size: 16, color: Color(0xFF8B5CF6)),
            const SizedBox(width: 6),
            Text(
              'Remarks (Optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Add any extra remarks about your submission.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _remarksController,
          enabled: !_isUploading,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Any additional comments...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF1A3350) : const Color(0xFFF1F5F9),
          ),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ─── Upload Progress ────────────────────────────────────

  Widget _buildUploadProgress(bool isDark) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _totalUploadProgress,
            minHeight: 6,
            backgroundColor: isDark
                ? const Color(0xFF1E3A5F)
                : const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF22C55E)),
          ),
        ),
        if (_uploadStatusText != null) ...[
          const SizedBox(height: 6),
          Text(
            _uploadStatusText!,
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark ? AppTheme.textMuted : const Color(0xFF64748B),
            ),
          ),
        ],
        if (_totalToUpload > 0) ...[
          const SizedBox(height: 4),
          Text(
            '$_uploadedCount of $_totalToUpload uploaded',
            style: TextStyle(
              fontSize: 11,
              color:
                  isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Submit Button ──────────────────────────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : _submitProof,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle_outline, size: 24),
        label: Text(
          _isUploading ? 'UPLOADING...' : 'SUBMIT',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          disabledBackgroundColor:
              const Color(0xFF22C55E).withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ─── Success Screen ─────────────────────────────────────

  Widget _buildSubmissionSuccess(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 72,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Submission Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your submission has been received and is awaiting admin review. You will be notified once it is approved or if more information is needed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppTheme.textSecondary
                    : const Color(0xFF475569),
              ),
            ),
            if (_selectedImages.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_selectedImages.length} screenshots uploaded',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'BACK TO PROJECTS',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
