import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? localFilePath;
  final double radius;
  final String? name;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.localFilePath,
    this.radius = 28,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    Widget fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: (name != null && name!.trim().isNotEmpty)
            ? Text(
                name!.trim()[0].toUpperCase(),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: radius * 0.8,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Icon(
                Icons.person,
                color: AppColors.primary,
                size: radius * 1.1,
              ),
      ),
    );

    if (localFilePath != null && localFilePath!.isNotEmpty) {
      final file = File(localFilePath!);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallback,
          ),
        );
      }
    }

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: Image.network(
        imageUrl!.trim(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return fallback;
        },
      ),
    );
  }
}
