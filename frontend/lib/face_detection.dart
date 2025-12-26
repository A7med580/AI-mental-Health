import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mindful/profile_screen.dart';
import 'package:mindful/resource_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mindful/services/model_service.dart';
import 'package:mindful/results_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import 'chat_screen.dart';

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
  int _selectedIndex = 1;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final ModelService _modelService = ModelService();
  bool _isProcessing = false;
  String? _imageUrl;

  final supabase = Supabase.instance.client;

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

      // New syntax: upload returns a void Future or throws on error
      await bucket.upload(fileName, file);

      print("Upload successful!");

      // Get public URL
      final publicUrl = bucket.getPublicUrl(fileName);
      _imageUrl = publicUrl;
      print("Upload successful! URL: $publicUrl");

      // If this is autism screening, send image URL to AI model
      if (widget.isAutismScreening) {
        await _processAutismFaceDetection(publicUrl);
      } else {
        // Regular emotion detection flow
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
      print("Upload failed: $e");
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

  }

  Future<void> _processAutismFaceDetection(String imageUrl) async {
    try {
      // Send image URL to ASD face model
      final response = await _modelService.predictASDFaceFromUrl(imageUrl);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Extract prediction result
        final predictionData = response['prediction'] ?? response;
        final predictionValue = predictionData['prediction'] ?? 0;
        final predictedClass = predictionData['class'] ?? '';
        final confidence = predictionData['confidence'] ?? 0.0;

        // Check if autism is detected (prediction == 1 or class contains "autistic")
        final isAutismDetected = (predictionValue == 1 ||
                                  predictedClass.toString().toLowerCase().contains('autistic'));

        // Navigate to results screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
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

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Processing Error',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Error processing face detection: $e',
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.isAutismScreening
                            ? 'Face Detection for Autism Screening'
                            : 'Emotion Detection',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      Text(
                        widget.isAutismScreening
                            ? 'Please take a photo of your face for autism screening analysis.'
                            : 'Point your camera at a face to detect emotions\nin real-time.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Camera Preview Box
                      Container(
                        width: double.infinity,
                        height: 340,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF64B5F6),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: _imageFile == null
                              ? Image.asset(
                            'assets/images/photo.jpg',
                            fit: BoxFit.cover,
                          )
                              : Image.file(
                            File(_imageFile!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Processing indicator
                      if (_isProcessing)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Processing image...'),
                            ],
                          ),
                        )
                      else
                        // Start Detection Button
                        ElevatedButton(
                          onPressed: _takePhoto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF42A5F5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            widget.isAutismScreening
                                ? 'Take Photo for Screening'
                                : 'Start Detection',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Navigation
            if (!widget.isAutismScreening)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: const Color(0xFFE0E7EE)),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.chat_bubble,
                      label: 'Chat',
                      index: 0,
                      isSelected: _selectedIndex == 0,
                    ),
                    _buildNavItem(
                      icon: Icons.emoji_emotions_outlined,
                      label: 'Emotion',
                      index: 1,
                      isSelected: _selectedIndex == 1,
                    ),
                    _buildNavItem(
                      icon: Icons.menu_book_outlined,
                      label: 'Resources',
                      index: 2,
                      isSelected: _selectedIndex == 2,
                    ),
                    _buildNavItem(
                      icon: Icons.person_outline,
                      label: 'Profile',
                      index: 3,
                      isSelected: _selectedIndex == 3,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MindfulAIScreen(),
            ),
          );
        }
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ResourcesScreen(),
            ),
          );
        }
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: isSelected ? const EdgeInsets.all(8) : null,
            decoration: isSelected
                ? BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            )
                : null,
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.lightBlue,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.black87 : const Color(0xFF90A4AE),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
