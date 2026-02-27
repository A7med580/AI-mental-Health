import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/widgets/glass_container.dart';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String duration;
  final String focus;
  final String source;
  final Color color;
  final IconData icon;

  const PlayerScreen({
    Key? key,
    required this.title,
    required this.duration,
    required this.focus,
    required this.source,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late PlayerController _controller;
  bool _isPlaying = false;
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PlayerController();
    
    // Parse duration string into seconds (e.g. "5 min")
    final parts = widget.duration.split(' ');
    if (parts.isNotEmpty) {
      final mins = int.tryParse(parts[0]) ?? 5;
      _secondsRemaining = mins * 60;
    }
  }

  void _togglePlay() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        // Start simulated timer
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_secondsRemaining > 0) {
            setState(() => _secondsRemaining--);
          } else {
            _stopTimer();
          }
        });
      } else {
        // Pause simulated timer
        _timer?.cancel();
      }
    });
  }

  void _stopTimer() {
    setState(() {
      _isPlaying = false;
      _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String get _timeString {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.meshBackground),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Now Playing',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance for back button
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Artwork / Icon
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color.withOpacity(0.15),
                          boxShadow: [
                            BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 40, spreadRadius: 10)
                          ],
                        ),
                        child: Center(
                          child: Icon(widget.icon, size: 100, color: widget.color),
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Metadata
                      Text(widget.title, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Text('Duration: ${widget.duration}', style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Clinical Focus: ${widget.focus}',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: widget.color),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Source: ${widget.source}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                      
                      const SizedBox(height: 48),
                      
                      // Waveform placeholder (using real audio_waveforms widget but static since no file)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: SizedBox(
                          height: 60,
                          // Without a real file path and extracted waveform data, it might be blank.
                          // We overlay a decorative visual approximation just in case.
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(40, (index) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 4,
                                    height: _isPlaying ? (20.0 + (index % 5) * 10 + (index % 3) * 5) : 4.0,
                                    decoration: BoxDecoration(
                                      color: _isPlaying ? widget.color : widget.color.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  );
                                }),
                              ),
                              // The actual widget underneath doing nothing since there's no path
                              AudioFileWaveforms(
                                size: Size(MediaQuery.of(context).size.width, 60),
                                playerController: _controller,
                                waveformType: WaveformType.fitWidth,
                                playerWaveStyle: const PlayerWaveStyle(
                                  fixedWaveColor: Colors.black12,
                                  liveWaveColor: Colors.black26,
                                  spacing: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      Text(_timeString, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w300, color: AppColors.textPrimary)),
                      
                      const SizedBox(height: 32),
                      
                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 42,
                            icon: const Icon(Icons.replay_10, color: AppColors.textSecondary),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                            },
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: _togglePlay,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.color,
                                boxShadow: [
                                  BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))
                                ],
                              ),
                              child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 40, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            iconSize: 42,
                            icon: const Icon(Icons.forward_10, color: AppColors.textSecondary),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
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
}
