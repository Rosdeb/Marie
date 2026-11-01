import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'floating_success_bar.dart';

class FloatingErrorBar extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback? onDismiss;

  const FloatingErrorBar({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 4),
    this.onDismiss,
  });

  static OverlayEntry? _currentEntry;

  static void dismiss() {
    try {
      if (_currentEntry != null) {
        final entry = _currentEntry!;
        _currentEntry = null;
        if (entry.mounted) {
          entry.remove();
        }
      }
    } catch (_) {
      _currentEntry = null;
    }
  }

  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
  }) {
    FloatingSuccessBar.dismiss();
    dismiss();

    void insert() {
      try {
        final overlayState = Overlay.maybeOf(context, rootOverlay: true);
        if (overlayState == null || !overlayState.mounted) {
          return;
        }

        final entry = OverlayEntry(
          builder: (_) => FloatingErrorBar(
            message: message,
            duration: duration,
            onDismiss: onDismiss,
          ),
        );

        _currentEntry = entry;
        overlayState.insert(entry);
      } catch (_) {
        _currentEntry = null;
      }
    }

    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => insert());
    } else {
      insert();
    }
  }

  @override
  State<FloatingErrorBar> createState() => _FloatingErrorBarState();
}

class _FloatingErrorBarState extends State<FloatingErrorBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    _timer = Timer(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (!mounted) return;
      FloatingErrorBar.dismiss();
      widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEAE9E9),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismiss,
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
