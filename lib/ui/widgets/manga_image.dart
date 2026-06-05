import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manga_reader/core/extensions/widget_ext.dart';
import 'package:manga_reader/models/local_image.dart';
import 'package:manga_reader/ui/widgets/loading_widget.dart';
import 'package:manga_reader/ui/widgets/styled_menu.dart';

typedef LoadingWidgetBuilder = Widget Function(ExtendedImageState state);
typedef LoadFailedWidgetBuilder = Widget Function(ExtendedImageState state);
typedef LoadCompleteCallBack = void Function(ExtendedImageState state);

class MangaImage extends StatelessWidget {
  final LocalImage image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? maxBytes;
  final Color backgroundColor;
  final void Function()? onLongPress;
  final List<StyledAction>? longPressActions;
  final LoadingWidgetBuilder? loadingWidgetBuilder;
  final LoadFailedWidgetBuilder? loadFailedWidgetBuilder;
  final LoadCompleteCallBack? loadCompleteCallBack;

  const MangaImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = .fitWidth,
    this.maxBytes,
    this.backgroundColor = Colors.black,
    this.onLongPress,
    this.longPressActions,
    this.loadingWidgetBuilder,
    this.loadFailedWidgetBuilder,
    this.loadCompleteCallBack,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress:
          onLongPress ??
          () => StyledActionSheet.show(
            context: context,
            actions: longPressActions ?? [],
          ),
      child: Container(
        height: height,
        width: width,
        color: backgroundColor,
        child: image.isRemote
            ? _RemoteMangaImage(
                url: image.url!,
                headers: image.headers,
                width: width,
                height: height,
                fit: fit,
                maxBytes: maxBytes,
                loadCompleteCallBack: loadCompleteCallBack,
              )
            : ExtendedImage.file(
                File(image.path!),
                width: width,
                height: height,
                fit: fit,
                maxBytes: maxBytes,
                clearMemoryCacheWhenDispose: true,
                loadStateChanged: (state) {
                  switch (state.extendedImageLoadState) {
                    case .loading:
                      return LoadingWidget(
                        height: height ?? Get.width * 1.78,
                        width: width ?? Get.width,
                        size: 28,
                      );
                    case .completed:
                      loadCompleteCallBack?.call(state);
                      return _buildExtendedRawImage(state).fadeIn();
                    case .failed:
                      return const Icon(Icons.broken_image);
                  }
                },
              ),
      ),
    );
  }

  Widget _buildExtendedRawImage(ExtendedImageState state) {
    FittedSizes fittedSizes = applyBoxFit(
      fit,
      Size(
        state.extendedImageInfo!.image.width.toDouble(),
        state.extendedImageInfo!.image.height.toDouble(),
      ),
      Size(width ?? double.infinity, height ?? double.infinity),
    );

    return ExtendedRawImage(
      image: state.extendedImageInfo?.image,
      width: fittedSizes.destination.width == 0
          ? null
          : fittedSizes.destination.width,
      height: fittedSizes.destination.height == 0
          ? null
          : fittedSizes.destination.height,
      scale: state.extendedImageInfo?.scale ?? 1.0,
      fit: fit,
    ).fadeIn();
  }
}

/// Downloads a remote image via [HttpClient] and displays it with
/// [ExtendedImage.memory], bypassing Flutter's [NetworkImage] which
/// uses a separate connection pool and may fail on slow WiFi.
class _RemoteMangaImage extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? maxBytes;
  final LoadCompleteCallBack? loadCompleteCallBack;

  const _RemoteMangaImage({
    required this.url,
    this.headers,
    this.width,
    this.height,
    this.fit = .fitWidth,
    this.maxBytes,
    this.loadCompleteCallBack,
  });

  @override
  State<_RemoteMangaImage> createState() => _RemoteMangaImageState();
}

class _RemoteMangaImageState extends State<_RemoteMangaImage> {
  Uint8List? _bytes;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    const maxRetries = 3;
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      if (attempt > 0) {
        await Future.delayed(Duration(seconds: attempt));
      }
      try {
        final client = HttpClient();
        try {
          final request = await client.getUrl(Uri.parse(widget.url));
          request.headers.add('Accept', 'image/*');
          if (widget.headers != null) {
            widget.headers!.forEach((k, v) => request.headers.add(k, v));
          }
          final response = await request.close().timeout(
                const Duration(seconds: 60),
              );
          if (response.statusCode != 200) {
            throw HttpException(
              'HTTP ${response.statusCode}',
              uri: Uri.parse(widget.url),
            );
          }
          final bytes = await response.fold<List<int>>(
            <int>[],
            (prev, chunk) => prev..addAll(chunk),
          );
          if (mounted) {
            setState(() {
              _bytes = Uint8List.fromList(bytes);
              _loading = false;
            });
          }
          return; // success
        } finally {
          client.close();
        }
      } catch (e) {
        if (attempt == maxRetries - 1) {
          if (mounted) {
            setState(() {
              _error = e;
              _loading = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return LoadingWidget(
        height: widget.height ?? Get.width * 1.78,
        width: widget.width ?? Get.width,
        size: 28,
      );
    }
    if (_error != null) {
      return const Icon(Icons.broken_image);
    }
    return ExtendedImage.memory(
      _bytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      maxBytes: widget.maxBytes,
      clearMemoryCacheWhenDispose: true,
      loadStateChanged: (state) {
        switch (state.extendedImageLoadState) {
          case .loading:
            return LoadingWidget(
              height: widget.height ?? Get.width * 1.78,
              width: widget.width ?? Get.width,
              size: 28,
            );
          case .completed:
            widget.loadCompleteCallBack?.call(state);
            return _buildFromState(state).fadeIn();
          case .failed:
            return const Icon(Icons.broken_image);
        }
      },
    );
  }

  Widget _buildFromState(ExtendedImageState state) {
    FittedSizes fittedSizes = applyBoxFit(
      widget.fit,
      Size(
        state.extendedImageInfo!.image.width.toDouble(),
        state.extendedImageInfo!.image.height.toDouble(),
      ),
      Size(
        widget.width ?? double.infinity,
        widget.height ?? double.infinity,
      ),
    );

    return ExtendedRawImage(
      image: state.extendedImageInfo?.image,
      width: fittedSizes.destination.width == 0
          ? null
          : fittedSizes.destination.width,
      height: fittedSizes.destination.height == 0
          ? null
          : fittedSizes.destination.height,
      scale: state.extendedImageInfo?.scale ?? 1.0,
      fit: widget.fit,
    );
  }
}
