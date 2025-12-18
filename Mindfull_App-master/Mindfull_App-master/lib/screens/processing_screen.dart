import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/services/model_service.dart';
import 'package:mindful/screens/adhd_result_screen.dart';
import 'package:mindful/core/config/api_config.dart';

/// Screen shown while processing ADHD screening
class ProcessingScreen extends StatefulWidget {
  final File videoFile;
  final Map<String, dynamic> questionnaireData;

  const ProcessingScreen({
    Key? key,
    required this.videoFile,
    required this.questionnaireData,
  }) : super(key: key);

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _isProcessing = true;
  bool _hasError = false;
  String _errorMessage = '';
  String? _technicalError;
  final ModelService _modelService = ModelService();

  @override
  void initState() {
    super.initState();
    // Prevent back navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processScreening();
    });
  }

  Future<void> _processScreening() async {
    try {
      // Verify video file exists and has content
      if (!await widget.videoFile.exists()) {
        throw Exception('Video file not found');
      }

      final fileSize = await widget.videoFile.length();
      if (fileSize == 0) {
        throw Exception('Video file is empty');
      }

      // Call backend with timeout
      final result = await _modelService.screenADHD(
        videoFile: widget.videoFile,
        questionnaireData: widget.questionnaireData,
      ).timeout(
        const Duration(minutes: 2), // 2 minute timeout for upload + processing
        onTimeout: () {
          throw TimeoutException(
            'Request timed out. Please check your connection and try again.',
            const Duration(minutes: 2),
          );
        },
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Navigate to result screen
        // Cast modalities_used from List<dynamic> to List<String>
        final modalitiesUsedRaw = result['modalities_used'] as List<dynamic>? ?? [];
        final modalitiesUsed = modalitiesUsedRaw.map((e) => e.toString()).toList();
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ADHDResultScreen(
              screeningResult: result['fused_result'] ?? {},
              individualResults: result['individual_results'] ?? [],
              modalitiesUsed: modalitiesUsed,
            ),
          ),
        );
      } else {
        throw Exception('Screening failed: ${result['error'] ?? 'Unknown error'}');
      }
    } on SocketException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _hasError = true;
        _errorMessage = "Couldn't connect to the AI server. Please try again.";
        _technicalError = 'SocketException: ${e.message}';
      });
    } on TimeoutException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _hasError = true;
        _errorMessage = e.message ?? 'Request timed out. Please try again.';
        _technicalError = 'TimeoutException: ${e.toString()}';
      });
    } on HttpException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _hasError = true;
        _errorMessage = "Server error occurred. Please try again.";
        _technicalError = 'HttpException: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _hasError = true;
        _errorMessage = "Couldn't connect to the AI server. Please try again.";
        _technicalError = e.toString();
      });
    }
  }

  void _retry() {
    setState(() {
      _isProcessing = true;
      _hasError = false;
      _errorMessage = '';
      _technicalError = null;
    });
    _processScreening();
  }

  void _goBackToHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation while processing
        if (_isProcessing) {
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: !_isProcessing,
          title: Text(
            'Processing Screening',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isProcessing
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        strokeWidth: 4,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Processing your screening...',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This may take a few moments.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : _hasError
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _errorMessage,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_technicalError != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _technicalError!,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _retry,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Retry',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _goBackToHome,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: AppColors.primary, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Back to Home',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(),
          ),
        ),
      ),
    );
  }
}
