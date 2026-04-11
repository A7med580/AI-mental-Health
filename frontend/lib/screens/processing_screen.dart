import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/screens/adhd_result_screen.dart';
import 'package:mindful/screens/depression_result_screen.dart';
import 'package:mindful/services/job_service.dart';
import 'package:mindful/widgets/page_transitions.dart';

class ProcessingScreen extends StatefulWidget {
  final File? videoFile;
  final Map<String, dynamic> questionnaireData;

  const ProcessingScreen({
    Key? key,
    required this.videoFile,
    required this.questionnaireData,
  }) : super(key: key);

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = true;
  bool _hasError = false;

  String _statusText = 'Checking your answers…';
  String _errorMessage = '';
  String? _technicalError;

  String? _jobId;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _startJobFlow());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─── ALL LOGIC BELOW IS UNCHANGED ───────────────────────────────────

  /// Detect condition from questionnaire data
  String get _condition {
    final cond = widget.questionnaireData['condition']?.toString().toLowerCase() ?? '';
    return cond == 'depression' ? 'depression' : 'adhd';
  }

  bool get _isDepression => _condition == 'depression';

  Future<void> _startJobFlow() async {
    try {
      // For depression, video is optional (text-only screening is valid)
      if (!_isDepression) {
        if (widget.videoFile == null) {
          throw Exception('No video found. Please record a video.');
        }
        if (!await widget.videoFile!.exists()) {
          throw Exception('Video file not found');
        }
        final size = await widget.videoFile!.length();
        if (size < 2000) {
          throw Exception('Video is too small');
        }
      }

      _setStatus(_isDepression ? 'Checking answers…' : 'Uploading video…');

      String jobId;
      if (_isDepression) {
        jobId = await JobService.submitDepressionJob(
          videoFile: widget.videoFile,
          questionnaireData: widget.questionnaireData,
        );
      } else {
        jobId = await JobService.submitADHDJob(
          videoFile: widget.videoFile!,
          questionnaireData: widget.questionnaireData,
        );
      }

      _jobId = jobId;
      _setStatus('Sent.\nWaiting for result…');

      final result = await JobService.pollJobUntilDone(
        jobId,
        pollInterval: const Duration(seconds: 2),
        maxAttempts: 180,
        onStatus: (status, error) {
          if (!mounted) return;
          if (status == 'queued') {
            _setStatus('Queued…\n(waiting)');
          } else if (status == 'processing') {
            _setStatus(_isDepression
                ? 'Checking…\nAI is looking at your answers'
                : 'Processing…\nAI is working');
          } else if (status == 'failed') {
            _setStatus('Failed…');
          }
          if (error != null && error.isNotEmpty) {
            _technicalError = error;
          }
        },
      );

      if (!mounted) return;

      final fused = Map<String, dynamic>.from(result['fused_result'] ?? {});
      final individual = List<dynamic>.from(result['individual_results'] ?? []);
      final modalitiesUsedRaw = List<dynamic>.from(result['modalities_used'] ?? []);
      final modalitiesUsed = modalitiesUsedRaw.map((e) => e.toString()).toList();

      if (_isDepression) {
        Navigator.pushReplacement(
          context,
          AppPageRoute(
            page: DepressionResultScreen(
              screeningResult: fused,
              individualResults: individual,
              modalitiesUsed: modalitiesUsed,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          AppPageRoute(
            page: ADHDResultScreen(
              screeningResult: fused,
              individualResults: individual,
              modalitiesUsed: modalitiesUsed,
            ),
          ),
        );
      }
    } on TimeoutException catch (e) {
      _fail(
        "It took too long.",
        "TimeoutException: $e",
      );
    } catch (e) {
      _fail("Could not finish. Please try again.", e.toString());
    }
  }

  void _setStatus(String txt) {
    if (!mounted) return;
    setState(() => _statusText = txt);
  }

  void _fail(String userMsg, String tech) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _hasError = true;
      _errorMessage = userMsg;
      _technicalError = tech;
    });
  }

  void _retry() {
    setState(() {
      _isProcessing = true;
      _hasError = false;
      _errorMessage = '';
      _technicalError = null;
      _jobId = null;
      _statusText = 'Checking your answers…';
    });
    _startJobFlow();
  }

  void _goBackToHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // ─── UI (NEW FIGMA DESIGN) ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: _isProcessing ? _buildProcessingView() : _buildErrorView(),
        ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withValues(alpha: 0.3),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.psychology, color: Colors.white, size: 44),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            Text(
              'Processing',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              _jobId == null ? _statusText : '$_statusText\n\nJob: $_jobId',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Progress bar (indeterminate)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'This may take time. Please do not close.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    if (!_hasError) return const SizedBox();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            ),

            const SizedBox(height: 24),

            Text(
              _errorMessage,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),

            if (_technicalError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _technicalError!,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _retry,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text('Retry', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
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
                  foregroundColor: AppColors.primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: AppColors.primaryPurple, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Back to Home', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
