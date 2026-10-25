import 'package:flutter/material.dart';

class CustomShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const CustomShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE8E8EE),
    this.highlightColor = const Color(0xFFF7F7FA),
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<CustomShimmer> createState() => _CustomShimmerState();
}

class _CustomShimmerState extends State<CustomShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Moves gradient smoothly across the bounds
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2.5 - 1.2),
      0.0,
      0.0,
    );
  }
}

/// Helper rounded rectangular shimmer placeholder
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final Color? color;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE8E8EE),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Helper circular shimmer placeholder (e.g. for avatars and circular icons)
class ShimmerCircle extends StatelessWidget {
  final double size;
  final Color? color;

  const ShimmerCircle({
    super.key,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE8E8EE),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Pre-built Notification List Shimmer Loading Skeleton
class NotificationListShimmer extends StatelessWidget {
  final int itemCount;

  const NotificationListShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return CustomShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerCircle(size: 40),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 160, height: 14, borderRadius: 6),
                    SizedBox(height: 8),
                    ShimmerBox(width: double.infinity, height: 12, borderRadius: 6),
                    SizedBox(height: 6),
                    ShimmerBox(width: 200, height: 12, borderRadius: 6),
                    SizedBox(height: 8),
                    ShimmerBox(width: 60, height: 10, borderRadius: 4),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Pre-built Profile Card Shimmer Loading Skeleton
class ProfileCardShimmer extends StatelessWidget {
  const ProfileCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomShimmer(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            ShimmerCircle(size: 60),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 140, height: 16, borderRadius: 6),
                  SizedBox(height: 8),
                  ShimmerBox(width: 190, height: 12, borderRadius: 6),
                  SizedBox(height: 8),
                  ShimmerBox(width: 80, height: 18, borderRadius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pre-built Support Contact Shimmer Loading Skeleton
class SupportContactShimmer extends StatelessWidget {
  const SupportContactShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerCircle(size: 16),
              SizedBox(width: 8),
              ShimmerBox(width: 190, height: 14, borderRadius: 4),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              ShimmerCircle(size: 16),
              SizedBox(width: 8),
              ShimmerBox(width: 130, height: 14, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

/// Helper for realistic staggered text lines
class ShimmerTextLine extends StatelessWidget {
  final double widthFactor;
  final double height;
  final double borderRadius;

  const ShimmerTextLine({
    super.key,
    this.widthFactor = 1.0,
    this.height = 13.0,
    this.borderRadius = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    if (widthFactor >= 1.0) {
      return ShimmerBox(
        width: double.infinity,
        height: height,
        borderRadius: borderRadius,
      );
    }
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: ShimmerBox(
        width: double.infinity,
        height: height,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Pre-built Document Content / Legal Notice / Privacy Policy Text Shimmer Skeleton
class ContentDocumentShimmer extends StatelessWidget {
  const ContentDocumentShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomShimmer(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Title Shimmer
            ShimmerBox(width: 200, height: 22, borderRadius: 6),
            SizedBox(height: 8),

            // Date Shimmer
            ShimmerBox(width: 120, height: 12, borderRadius: 4),
            SizedBox(height: 22),

            // Section 1 Heading
            ShimmerBox(width: 160, height: 16, borderRadius: 5),
            SizedBox(height: 12),

            // Section 1 Paragraph lines
            ShimmerTextLine(widthFactor: 1.0),
            SizedBox(height: 8),
            ShimmerTextLine(widthFactor: 0.94),
            SizedBox(height: 8),
            ShimmerTextLine(widthFactor: 0.88),
            SizedBox(height: 8),
            ShimmerTextLine(widthFactor: 0.52),
            SizedBox(height: 20),

            // Bullet Point Items
            _ShimmerBulletLine(widthFactor: 0.82),
            SizedBox(height: 10),
            _ShimmerBulletLine(widthFactor: 0.75),
            SizedBox(height: 10),
            _ShimmerBulletLine(widthFactor: 0.86),
            SizedBox(height: 22),

            // Section 2 Heading
            ShimmerBox(width: 180, height: 16, borderRadius: 5),
            SizedBox(height: 12),

            // Section 2 Paragraph lines
            ShimmerTextLine(widthFactor: 1.0),
            SizedBox(height: 8),
            ShimmerTextLine(widthFactor: 0.96),
            SizedBox(height: 8),
            ShimmerTextLine(widthFactor: 0.64),
            SizedBox(height: 22),

            // Section 3 Heading
            ShimmerBox(width: 140, height: 16, borderRadius: 5),
            SizedBox(height: 12),

            // Section 3 Paragraph lines
            ShimmerTextLine(widthFactor: 1.0),
            SizedBox(height: 8),
            ShimmerTextLine(widthFactor: 0.78),
            SizedBox(height: 8),
            ShimmerTextLine(widthFactor: 0.42),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBulletLine extends StatelessWidget {
  final double widthFactor;

  const _ShimmerBulletLine({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ShimmerCircle(size: 6),
        const SizedBox(width: 10),
        Expanded(
          child: ShimmerTextLine(widthFactor: widthFactor, height: 12),
        ),
      ],
    );
  }
}

/// Pre-built Share Preview Shimmer Loading Skeleton
class SharePreviewShimmer extends StatelessWidget {
  const SharePreviewShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomShimmer(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: double.infinity, height: 180, borderRadius: 16),
            SizedBox(height: 16),
            ShimmerBox(width: 140, height: 14, borderRadius: 4),
            SizedBox(height: 8),
            ShimmerBox(width: double.infinity, height: 18, borderRadius: 6),
            SizedBox(height: 8),
            ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
            SizedBox(height: 24),
            ShimmerBox(width: double.infinity, height: 90, borderRadius: 14),
            SizedBox(height: 24),
            ShimmerBox(width: double.infinity, height: 48, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}

/// Pre-built Office Catalogue Shimmer Loading Skeleton
class OfficeCatalogueShimmer extends StatelessWidget {
  final int count;

  const OfficeCatalogueShimmer({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return CustomShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F2)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ShimmerBox(width: 44, height: 28, borderRadius: 8),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 110, height: 16, borderRadius: 4),
                          SizedBox(height: 6),
                          ShimmerBox(width: 80, height: 12, borderRadius: 4),
                        ],
                      ),
                    ],
                  ),
                  ShimmerBox(width: 80, height: 24, borderRadius: 12),
                ],
              ),
              SizedBox(height: 14),
              Row(
                children: [
                  ShimmerBox(width: 60, height: 20, borderRadius: 6),
                  SizedBox(width: 8),
                  ShimmerBox(width: 60, height: 20, borderRadius: 6),
                  SizedBox(width: 8),
                  ShimmerBox(width: 70, height: 20, borderRadius: 6),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(width: 100, height: 14, borderRadius: 4),
                  ShimmerBox(width: 80, height: 32, borderRadius: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

