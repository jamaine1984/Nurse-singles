import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      imageRenderMethodForWeb: kIsWeb
          ? ImageRenderMethodForWeb.HttpGet
          : ImageRenderMethodForWeb.HtmlImage,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
