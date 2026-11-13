import 'package:flutter/material.dart';

/// Reusable YouTube-style play button icon with standard red gradient:
/// `colors: [Colors.redAccent, Colors.red]`.
class YouTubePlayButton extends StatelessWidget {
  final double width;
  final double height;
  final double iconSize;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const YouTubePlayButton({
    super.key,
    this.width = 45,
    this.height = 38,
    this.iconSize = 20,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(height * 0.25);
    final buttonShape = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.redAccent, Colors.red],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.play_arrow_rounded,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );

    if (onTap == null) return buttonShape;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: buttonShape,
      ),
    );
  }
}
