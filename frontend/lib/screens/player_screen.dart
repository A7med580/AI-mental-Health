import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mindful/app_colors.dart';
import 'package:mindful/widgets/glass_container.dart';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String duration;
  final String focus;
  final String source;
  final Color color;
  final IconData icon;
  final String audioUrl;    // Direct MP3 URL (Google Drive)
  final String youtubeUrl;  // YouTube fallback
  final String spotifyUrl;  // Spotify URI (opens the app)

  const PlayerScreen({
    Key? key,
    required this.title,
    required this.duration,
    required this.focus,
    required this.source,
    required this.color,
    required this.icon,
    required this.audioUrl,
    required this.youtubeUrl,
    required this.spotifyUrl,
  }) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  late AudioPlayer _player;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _player.positionStream.listen((pos) { if (mounted) setState(() => _position = pos); });
    _player.durationStream.listen((dur) { if (mounted && dur != null) setState(() => _total = dur); });
    _player.playingStream.listen((p) { if (mounted) setState(() => _isPlaying = p); });

    _loadAudio();
  }

  Future<void> _loadAudio() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      await _player.setUrl(widget.audioUrl);
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  Future<void> _togglePlay() async {
    HapticFeedback.lightImpact();
    if (_hasError) { _loadAudio(); return; }
    _isPlaying ? await _player.pause() : await _player.play();
  }

  Future<void> _seek(Duration offset) async {
    HapticFeedback.selectionClick();
    final next = _position + offset;
    await _player.seek(next.isNegative ? Duration.zero : next);
  }

  Future<void> _open(String url) async {
    HapticFeedback.lightImpact();
    try {
      // Try app URI scheme first (spotify:), then fall back to https://
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
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
              // ── Header ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                      onPressed: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
                    ),
                    Expanded(
                      child: Text('Now Playing',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 28),

                      // ── Pulsing Orb ──────────────────────────────
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (ctx, child) => Transform.scale(scale: _isPlaying ? _pulseAnimation.value : 1.0, child: child),
                        child: Container(
                          width: 210, height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.color.withValues(alpha: 0.15),
                            boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.35), blurRadius: 60, spreadRadius: 12)],
                          ),
                          child: Center(child: Icon(widget.icon, size: 90, color: widget.color)),
                        ),
                      ),
                      const SizedBox(height: 26),

                      // ── Title ────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Text(widget.title,
                          style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(widget.duration, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                      ]),
                      const SizedBox(height: 12),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text('Focus: ${widget.focus}',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: widget.color),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 26),

                      // ── Waveform Bars ────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: SizedBox(
                          height: 52,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: List.generate(40, (i) => AnimatedContainer(
                              duration: Duration(milliseconds: 180 + i * 7),
                              width: 4,
                              height: _isPlaying ? (14.0 + (i % 5) * 7 + (i % 3) * 3) : 4.0,
                              decoration: BoxDecoration(
                                color: _isPlaying ? widget.color : widget.color.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Slider ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(children: [
                          SliderTheme(
                            data: SliderThemeData(
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                              trackHeight: 3,
                              activeTrackColor: widget.color,
                              inactiveTrackColor: widget.color.withValues(alpha: 0.18),
                              thumbColor: widget.color,
                              overlayColor: widget.color.withValues(alpha: 0.14),
                            ),
                            child: Slider(
                              value: _total.inSeconds > 0 ? _position.inSeconds.toDouble().clamp(0, _total.inSeconds.toDouble()) : 0.0,
                              max: _total.inSeconds > 0 ? _total.inSeconds.toDouble() : 1.0,
                              onChanged: (v) => _player.seek(Duration(seconds: v.toInt())),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(_fmt(_position), style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                              Text(_fmt(_total), style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                            ]),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 18),

                      // ── Controls ─────────────────────────────────
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        IconButton(
                          iconSize: 38,
                          icon: const Icon(Icons.replay_10, color: AppColors.textSecondary),
                          onPressed: () => _seek(const Duration(seconds: -10)),
                        ),
                        const SizedBox(width: 18),
                        GestureDetector(
                          onTap: _togglePlay,
                          child: Container(
                            width: 76, height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _hasError ? Colors.red.shade400 : widget.color,
                              boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.42), blurRadius: 24, offset: const Offset(0, 8))],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : _hasError
                                      ? const Icon(Icons.refresh_rounded, size: 36, color: Colors.white)
                                      : Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 42, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        IconButton(
                          iconSize: 38,
                          icon: const Icon(Icons.forward_10, color: AppColors.textSecondary),
                          onPressed: () => _seek(const Duration(seconds: 10)),
                        ),
                      ]),

                      if (_hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Could not load audio — tap refresh to try again', style: GoogleFonts.inter(fontSize: 11, color: Colors.red.shade400)),
                        ),

                      const SizedBox(height: 28),

                      // ── External Platform Links ───────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Listen on:',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(child: _buildPlatformBtn(
                              label: 'YouTube',
                              icon: Icons.play_circle_outline,
                              color: const Color(0xFFFF0000),
                              url: widget.youtubeUrl,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _buildPlatformBtn(
                              label: 'Spotify',
                              icon: Icons.music_note,
                              color: const Color(0xFF1DB954),
                              url: widget.spotifyUrl,
                            )),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 28),

                      // ── Reference Footer ──────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GlassContainer(
                          borderRadius: 20,
                          opacity: 0.55,
                          blur: 12,
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Icon(Icons.verified_rounded, size: 16, color: widget.color),
                              const SizedBox(width: 6),
                              Expanded(child: Text('Uses Global Standards',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: widget.color),
                              )),
                            ]),
                            const SizedBox(height: 8),
                            const Divider(height: 1, color: Colors.white24),
                            const SizedBox(height: 8),
                            Text(widget.source,
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.6),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 32),
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

  Widget _buildPlatformBtn({required String label, required IconData icon, required Color color, required String url}) {
    return GestureDetector(
      onTap: () => _open(url),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.32), width: 1),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}
