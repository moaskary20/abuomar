import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../data/api_client.dart';

/// عرض صور المتجر من الأصول المضمّنة أو من الشبكة.
class StoreNetworkImage extends StatelessWidget {
  const StoreNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  bool get _isAsset => imageUrl.startsWith('asset:');

  String get _assetPath => imageUrl.substring('asset:'.length);

  String get _resolvedUrl =>
      AppConfig.rewriteMediaUrl(imageUrl, ApiClient.instance.baseUrl);

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolvedUrl;
    if (imageUrl.trim().isEmpty) {
      return _placeholder();
    }

    if (_isAsset) {
      return Image.asset(
        _assetPath,
        fit: fit,
        width: width,
        height: height,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      // على الويب: عنصر HTML img لا يحتاج CORS للعرض
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      filterQuality: FilterQuality.medium,
      headers: const {
        'Accept': 'image/*',
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return const ColoredBox(
          color: Color(0xFFF3EDE8),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: const Color(0xFFF3EDE8),
      child: Center(
        child: Icon(
          Icons.cake_outlined,
          color: AppTheme.primary.withValues(alpha: 0.55),
          size: 36,
        ),
      ),
    );
  }
}
