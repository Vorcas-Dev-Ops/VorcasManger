import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommonAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final bool isSquare;
  final double borderRadius;
  final VoidCallback? onTap;

  const CommonAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.isSquare = false,
    this.borderRadius = 12,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const defaultAvatar = AssetImage('assets/images/default_avatar.png');
    const String baseUrl = 'http://10.0.2.2:8081';

    DecorationImage? imageProvider;

    if (imageUrl != null && imageUrl!.startsWith('data:image')) {
      // Base64 Case
      try {
        final bytes = base64Decode(imageUrl!.split(',').last);
        imageProvider = DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover);
      } catch (e) {
        imageProvider = const DecorationImage(image: defaultAvatar, fit: BoxFit.cover);
      }
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Network Case
      final fullUrl = imageUrl!.startsWith('http') ? imageUrl! : '$baseUrl$imageUrl';
      // We wrap it in a child so we can use CachedNetworkImage's specialized builders if needed,
      // but for simplicity in decoration, we'll use a standard approach or just the widget.
    }

    Widget child;
    final size = radius * 2;

    if (imageUrl != null && imageUrl!.isNotEmpty && !imageUrl!.startsWith('data:image')) {
      final fullUrl = imageUrl!.startsWith('http') ? imageUrl! : '$baseUrl$imageUrl';
      child = CachedNetworkImage(
        imageUrl: fullUrl,
        imageBuilder: (context, provider) => _buildContainer(provider),
        placeholder: (context, url) => _buildContainer(defaultAvatar),
        errorWidget: (context, url, error) => _buildContainer(defaultAvatar),
      );
    } else {
      child = _buildContainer(imageProvider?.image ?? defaultAvatar);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: child,
      );
    }
    return child;
  }

  Widget _buildContainer(ImageProvider provider) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isSquare ? BorderRadius.circular(borderRadius) : null,
        image: DecorationImage(image: provider, fit: BoxFit.cover),
      ),
    );
  }
}
