import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:mindful/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mindful/services/model_service.dart';
import 'package:mindful/results_screen.dart';
import 'package:mindful/widgets/glass_container.dart';
import 'package:mindful/widgets/page_transitions.dart';
import 'package:google_fonts/google_fonts.dart';

class EmotionDetectionScreen extends StatefulWidget {
  final bool isAutismScreening;

  const EmotionDetectionScreen({
    Key? key,
    this.isAutismScreening = false,
  }) : super(key: key);

  @override
  State<EmotionDetectionScreen> createState() => _EmotionDetectionScreenState();
}

class _EmotionDetectionScreenState extends State<EmotionDetectionScreen> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final ModelService _modelService = ModelService();
  bool _isProcessing = false;
  String? _imageUrl;

  final supabase = Supabase.instance.client;

  // ─── Logic ──────────────────────────────────────────────────────────

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });

      await _uploadToSupabase();
    }
  }

  Future<void> _uploadToSupabase() async {
    if (_imageFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final fileName = 'emotion_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bucket = supabase.storage.from('emotion-images');

      final file = File(_imageFile!.path);
      await bucket.upload(fileName, file);

      final publicUrl = bucket.getPublicUrl(fileName);
      _imageUrl = publicUrl;

      if (widget.isAutismScreening) {
        await _processAutismFaceDetection(publicUrl);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image uploaded! URL: $publicUrl')),
          );
        }
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showErrorDialog(
          'Upload Error',
          'Error uploading image: $e',
        );
      }
    }
  }

  Future<void> _processAutismFaceDetection(String imageUrl) async {
    try {
      final response = await _modelService.predictASDFaceFromUrl(imageUrl);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        final predictionData = response['prediction'] ?? response;
        final predictionValue = predictionData['prediction'] ?? 0;
        final predictedClass = predictionData['class'] ?? '';
        final confidence = predictionData['confidence'] ?? 0.0;

        final isAutismDetected = (predictionValue == 1 ||
            predictedClass.toString().toLowerCase().contains('autistic'));

        Navigator.pushReplacement(
          context,
          AppPageRoute(
            page: ResultsScreen(
              screeningResult: {
                'detected_condition': isAutismDetected ? 'Autism' : null,
                'confidence': confidence,
                'message': 'Face detection analysis completed. '
                    'Based on the questionnaire and face analysis, '
                    '${isAutismDetected ? "indicators of autism were detected" : "no strong indicators of autism were detected"}. '
                    'However, this is a screening tool and not a medical diagnosis. '
                    'Please consult a healthcare professional for proper evaluation.',
                'model_type': 'ASD Text + Face Model',
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showErrorDialog(
          'Processing Error',
          'Error processing face detection: $e',
        );
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(message, style: GoogleFonts.inter())),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _takePhoto();
            },
            child: const Text('Retry'),
          ),
          if (widget.isAutismScreening)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Skip face detection; go to results with text-only data
                Navigator.pushReplacement(
                  context,
                  AppPageRoute(
                    page: ResultsScreen(
                      screeningResult: {
                        'detected_condition': null,
                        'confidence': 0.0,
                        'message':
                            'Face analysis was skipped due to an error.\n\n'
                            'Based on your questionnaire answers only, the screening is inconclusive. '
                            'Please consult a healthcare professional for proper evaluation.',
                        'model_type': 'ASD Text Model Only (AQ-10)',
                      },
                    ),
                  ),
                );
              },
              child: Text('Skip', style: GoogleFonts.inter(color: Colors.orange)),
            ),
        ],
      ),
    );
  }

  // ─── UI (Liquid Glass Design) ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0EEFF),
              Color(0xFFE8E0FF),
              Color(0xFFF5F0FF),
              Color(0xFFEDE5FF),
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.isAutismScreening ? 'Autism Screening' : 'Emotion Detection',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      Text(
                        widget.isAutismScreening ? 'Step 2 of 4' : '',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Title ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isAutismScreening
                          ? 'Photo Capture'
                          : 'Emotion Detection',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isAutismScreening
                          ? 'Take a clear photo for facial analysis'
                          : 'Point your camera to detect emotions',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Progress (autism only) ──
              if (widget.isAutismScreening)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 0.5,
                      minHeight: 8,
                      backgroundColor: Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // ── Main content ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Preview box
                      if (_imageFile != null)
                        GlassContainer(
                          borderRadius: 18,
                          padding: const EdgeInsets.all(4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(_imageFile!.path),
                              width: double.infinity,
                              height: 260,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                      if (_imageFile != null) const SizedBox(height: 20),

                      // Instructions card
                      GlassContainer(
                        borderRadius: 18,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Photo Instructions',
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            _buildInstruction('Position your face in the center of the frame'),
                            const SizedBox(height: 10),
                            _buildInstruction('Ensure good lighting on your face'),
                            const SizedBox(height: 10),
                            _buildInstruction('Look directly at the camera with a neutral expression'),
                            const SizedBox(height: 10),
                            _buildInstruction('Your photo will be analyzed for facial features'),

                            const SizedBox(height: 24),

                            // Button
                            SizedBox(
                              width: double.infinity,
                              child: _isProcessing
                                  ? Center(
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor: AlwaysStoppedAnimation(AppColors.primaryPurple),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text('Processing image...', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryPurple.withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(14),
                                          onTap: _takePhoto,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _imageFile == null ? 'Take Photo' : 'Retake Photo',
                                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info footer
                      if (widget.isAutismScreening)
                        GlassContainer(
                          borderRadius: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: AppColors.primaryPurple),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your photo is analyzed for facial features commonly associated with ASD. Combined with your questionnaire for screening.',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            color: AppColors.primaryPurple,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
          ),
        ),
      ],
    );
  }
}
