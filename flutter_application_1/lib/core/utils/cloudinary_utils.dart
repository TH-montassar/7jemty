import 'package:flutter/foundation.dart';

class CloudinaryUtils {
  /// Injects Cloudinary transformations into the URL.
  /// Example: w_500,f_auto,q_auto
  static String? getOptimizedUrl(String? url, {int? width}) {
    if (url == null || url.isEmpty) return url;
    if (!url.contains('cloudinary.com')) return url;

    try {
      // Cloudinary URL structure: .../upload/v12345/abc.jpg
      final String transform = width != null
          ? 'w_$width,f_auto,q_auto'
          : 'f_auto,q_auto';

      if (url.contains('/upload/')) {
        return url.replaceFirst('/upload/', '/upload/$transform/');
      }
    } catch (e) {
      debugPrint("Error optimizing Cloudinary URL: $e");
    }
    return url;
  }
}
