import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindful/services/model_service.dart';

/// A small pill-shaped widget that shows whether the backend server is live.
///
/// ● When connected:  pulsing green dot + "Live" label
/// ● When offline:    static red dot with a strike-through line + "Offline"
/// ● While checking:  animated spinner + "Checking…"
class BackendStatusIndicator extends StatefulWidget {
  /// How often to re-check (default: every 15 seconds).
  final Duration pollInterval;

  const BackendStatusIndicator({
    Key? key,
    this.pollInterval = const Duration(seconds: 15),
  }) : super(key: key);

  @override
  State<BackendStatusIndicator> createState() => _BackendStatusIndicatorState();
}

class _BackendStatusIndicatorState extends State<BackendStatusIndicator>
    with SingleTickerProviderStateMixin {
  final ModelService _modelService = ModelService();

  /// null = still checking, true = online, false = offline
  bool? _isOnline;
  Timer? _pollTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // First check immediately
    _checkHealth();

    // Then poll periodically
    _pollTimer = Timer.periodic(widget.pollInterval, (_) => _checkHealth());
  }

  Future<void> _checkHealth() async {
    final ok = await _modelService.checkHealth();
    if (mounted) {
      setState(() => _isOnline = ok);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors
    final Color dotColor;
    final Color labelColor;
    final Color bgColor;
    final String label;

    if (_isOnline == null) {
      // Checking
      dotColor = Colors.amber;
      labelColor = isDark ? Colors.amber.shade200 : Colors.amber.shade800;
      bgColor = isDark ? Colors.amber.withOpacity(0.12) : Colors.amber.withOpacity(0.08);
      label = '…';
    } else if (_isOnline!) {
      // Online
      dotColor = const Color(0xFF34D399); // emerald green
      labelColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669);
      bgColor = isDark ? const Color(0xFF059669).withOpacity(0.12) : const Color(0xFF059669).withOpacity(0.08);
      label = 'Live';
    } else {
      // Offline
      dotColor = const Color(0xFFEF4444); // red
      labelColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
      bgColor = isDark ? const Color(0xFFDC2626).withOpacity(0.12) : const Color(0xFFDC2626).withOpacity(0.08);
      label = 'Offline';
    }

    return GestureDetector(
      onTap: () {
        setState(() => _isOnline = null);
        _checkHealth();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dotColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dot / indicator
            if (_isOnline == null)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation(dotColor),
                ),
              )
            else if (_isOnline!)
              // Pulsing green dot
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withOpacity(_pulseAnimation.value * 0.6),
                          blurRadius: 6 * _pulseAnimation.value,
                          spreadRadius: 1 * _pulseAnimation.value,
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              // Offline: red dot with a strikethrough line
              SizedBox(
                width: 10,
                height: 10,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor.withOpacity(0.4),
                      ),
                    ),
                    // Diagonal strike line
                    Transform.rotate(
                      angle: -0.785, // 45 degrees
                      child: Container(
                        width: 12,
                        height: 1.5,
                        color: dotColor,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(width: 6),

            // Label
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
