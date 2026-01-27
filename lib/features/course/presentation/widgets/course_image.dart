import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

class CourseImage extends StatelessWidget {
  const CourseImage({
    required this.imageUrl,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    var finalUrl = imageUrl;
    // Patch for broken image URL provided by user
    if (finalUrl == 'https://i.ibb.co/ZVRKdVm/grammar-hero.jpg') {
      finalUrl =
          'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?q=80&w=1000&auto=format&fit=crop';
    }

    if (finalUrl.startsWith('http')) {
      return Image.network(
        finalUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    } else if (finalUrl.startsWith('assets/') || finalUrl.startsWith('lib/')) {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    } else {
      // File path
      if (kIsWeb) {
        // Fallback for web if it somehow gets a file path (shouldn't happen for bundled assets)
        return _buildErrorPlaceholder();
      }
      return Image.file(
        File(imageUrl),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_rounded,
              color: Colors.grey.withValues(alpha: 0.4),
              size: 32,
            ),
            if ((width ?? 100) > 80) ...[
              const SizedBox(height: 8),
              Text(
                'Image not found',
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
