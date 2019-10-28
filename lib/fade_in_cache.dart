// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;
import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';
import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:http/http.dart' as http;

// Examples can assume:
// Uint8List bytes;

/// An image that shows a [placeholder] image while the target [image] is
/// loading, then fades in the new image when it loads.
///
/// Use this class to display long-loading images, such as [new NetworkImage],
/// so that the image appears on screen with a graceful animation rather than
/// abruptly popping onto the screen.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=pK738Pg9cxc}
///
/// If the [image] emits an [ImageInfo] synchronously, such as when the image
/// has been loaded and cached, the [image] is displayed immediately, and the
/// [placeholder] is never displayed.
///
/// The [fadeOutDuration] and [fadeOutCurve] properties control the fade-out
/// animation of the [placeholder].
///
/// The [fadeInDuration] and [fadeInCurve] properties control the fade-in
/// animation of the target [image].
///
/// Prefer a [placeholder] that's already cached so that it is displayed
/// immediately. This prevents it from popping onto the screen.
///
/// When [image] changes, it is resolved to a new [ImageStream]. If the new
/// [ImageStream.key] is different, this widget subscribes to the new stream and
/// replaces the displayed image with images emitted by the new stream.
///
/// When [placeholder] changes and the [image] has not yet emitted an
/// [ImageInfo], then [placeholder] is resolved to a new [ImageStream]. If the
/// new [ImageStream.key] is different, this widget subscribes to the new stream
/// and replaces the displayed image to images emitted by the new stream.
///
/// When either [placeholder] or [image] changes, this widget continues showing
/// the previously loaded image (if any) until the new image provider provides a
/// different image. This is known as "gapless playback" (see also
/// [Image.gaplessPlayback]).
///
/// {@tool sample}
///
/// ```dart
/// FadeInImage(
///   // here `bytes` is a Uint8List containing the bytes for the in-memory image
///   placeholder: MemoryImage(bytes),
///   image: NetworkImage('https://backend.example.com/image.png'),
/// )
/// ```
/// {@end-tool}
class FadeInImage extends StatelessWidget {
  /// Creates a widget that displays a [placeholder] while an [image] is loading,
  /// then fades-out the placeholder and fades-in the image.
  ///
  /// The [placeholder], [image], [fadeOutDuration], [fadeOutCurve],
  /// [fadeInDuration], [fadeInCurve], [alignment], [repeat], and
  /// [matchTextDirection] arguments must not be null.
  ///
  /// If [excludeFromSemantics] is true, then [imageSemanticLabel] will be ignored.
  const FadeInImage({
    Key key,
    @required this.placeholder,
    @required this.image,
    this.excludeFromSemantics = false,
    this.imageSemanticLabel,
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 700),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
  }) : assert(placeholder != null),
        assert(image != null),
        assert(fadeOutDuration != null),
        assert(fadeOutCurve != null),
        assert(fadeInDuration != null),
        assert(fadeInCurve != null),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        super(key: key);

  /// Creates a widget that uses a placeholder image stored in memory while
  /// loading the final image from the network.
  ///
  /// The `placeholder` argument contains the bytes of the in-memory image.
  ///
  /// The `image` argument is the URL of the final image.
  ///
  /// The `placeholderScale` and `imageScale` arguments are passed to their
  /// respective [ImageProvider]s (see also [ImageInfo.scale]).
  ///
  /// The [placeholder], [image], [placeholderScale], [imageScale],
  /// [fadeOutDuration], [fadeOutCurve], [fadeInDuration], [fadeInCurve],
  /// [alignment], [repeat], and [matchTextDirection] arguments must not be
  /// null.
  ///
  /// See also:
  ///
  ///  * [new Image.memory], which has more details about loading images from
  ///    memory.
  ///  * [new Image.network], which has more details about loading images from
  ///    the network.
  FadeInImage.memoryNetwork({
    Key key,
    @required Uint8List placeholder,
    @required String image,
    double placeholderScale = 1.0,
    double imageScale = 1.0,
    this.excludeFromSemantics = false,
    this.imageSemanticLabel,
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 700),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    bool sdcache =false
  }) : assert(placeholder != null),
        assert(image != null),
        assert(placeholderScale != null),
        assert(imageScale != null),
        assert(fadeOutDuration != null),
        assert(fadeOutCurve != null),
        assert(fadeInDuration != null),
        assert(fadeInCurve != null),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        placeholder = MemoryImage(placeholder, scale: placeholderScale),
        image = MyNetworkImage(image, scale: imageScale,sdCache: sdcache),
        super(key: key);

  /// Creates a widget that uses a placeholder image stored in an asset bundle
  /// while loading the final image from the network.
  ///
  /// The `placeholder` argument is the key of the image in the asset bundle.
  ///
  /// The `image` argument is the URL of the final image.
  ///
  /// The `placeholderScale` and `imageScale` arguments are passed to their
  /// respective [ImageProvider]s (see also [ImageInfo.scale]).
  ///
  /// If `placeholderScale` is omitted or is null, pixel-density-aware asset
  /// resolution will be attempted for the [placeholder] image. Otherwise, the
  /// exact asset specified will be used.
  ///
  /// The [placeholder], [image], [imageScale], [fadeOutDuration],
  /// [fadeOutCurve], [fadeInDuration], [fadeInCurve], [alignment], [repeat],
  /// and [matchTextDirection] arguments must not be null.
  ///
  /// See also:
  ///
  ///  * [new Image.asset], which has more details about loading images from
  ///    asset bundles.
  ///  * [new Image.network], which has more details about loading images from
  ///    the network.
  FadeInImage.assetNetwork({
    Key key,
    @required String placeholder,
    @required String image,
    AssetBundle bundle,
    double placeholderScale,
    double imageScale = 1.0,
    this.excludeFromSemantics = false,
    this.imageSemanticLabel,
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 700),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    bool sdcache =false
  }) : assert(placeholder != null),
        assert(image != null),
        placeholder = placeholderScale != null
            ? ExactAssetImage(placeholder, bundle: bundle, scale: placeholderScale)
            : AssetImage(placeholder, bundle: bundle),
        assert(imageScale != null),
        assert(fadeOutDuration != null),
        assert(fadeOutCurve != null),
        assert(fadeInDuration != null),
        assert(fadeInCurve != null),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        image = MyNetworkImage(image, scale: imageScale,sdCache: sdcache),
        super(key: key);

  /// Image displayed while the target [image] is loading.
  final ImageProvider placeholder;

  /// The target image that is displayed once it has loaded.
  final ImageProvider image;

  /// The duration of the fade-out animation for the [placeholder].
  final Duration fadeOutDuration;

  /// The curve of the fade-out animation for the [placeholder].
  final Curve fadeOutCurve;

  /// The duration of the fade-in animation for the [image].
  final Duration fadeInDuration;

  /// The curve of the fade-in animation for the [image].
  final Curve fadeInCurve;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder image does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder image does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double height;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit fit;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while an
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// images); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with images in right-to-left environments, for
  /// images that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip images with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  /// Whether to exclude this image from semantics.
  ///
  /// This is useful for images which do not contribute meaningful information
  /// to an application.
  final bool excludeFromSemantics;

  /// A semantic description of the [image].
  ///
  /// Used to provide a description of the [image] to TalkBack on Android, and
  /// VoiceOver on iOS.
  ///
  /// This description will be used both while the [placeholder] is shown and
  /// once the image has loaded.
  final String imageSemanticLabel;



  Image _image({
    @required ImageProvider image,
    ImageFrameBuilder frameBuilder,
  }) {
    assert(image != null);
    return Image(
      image: image,
      frameBuilder: frameBuilder,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget result = _image(
      image: image,
      frameBuilder: (BuildContext context, Widget child, int frame, bool wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded)
          return child;
        return _AnimatedFadeOutFadeIn(
          target: child,
          placeholder: _image(image: placeholder),
          isTargetLoaded: frame != null,
          fadeInDuration: fadeInDuration,
          fadeOutDuration: fadeOutDuration,
          fadeInCurve: fadeInCurve,
          fadeOutCurve: fadeOutCurve,
        );
      },
    );

    if (!excludeFromSemantics) {
      result = Semantics(
        container: imageSemanticLabel != null,
        image: true,
        label: imageSemanticLabel ?? '',
        child: result,
      );
    }

    return result;
  }
}

class _AnimatedFadeOutFadeIn extends ImplicitlyAnimatedWidget {
  const _AnimatedFadeOutFadeIn({
    Key key,
    @required this.target,
    @required this.placeholder,
    @required this.isTargetLoaded,
    @required this.fadeOutDuration,
    @required this.fadeOutCurve,
    @required this.fadeInDuration,
    @required this.fadeInCurve,
  }) : assert(target != null),
        assert(placeholder != null),
        assert(isTargetLoaded != null),
        assert(fadeOutDuration != null),
        assert(fadeOutCurve != null),
        assert(fadeInDuration != null),
        assert(fadeInCurve != null),
        super(key: key, duration: fadeInDuration + fadeOutDuration);

  final Widget target;
  final Widget placeholder;
  final bool isTargetLoaded;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final Curve fadeInCurve;
  final Curve fadeOutCurve;

  @override
  _AnimatedFadeOutFadeInState createState() => _AnimatedFadeOutFadeInState();
}

class _AnimatedFadeOutFadeInState extends ImplicitlyAnimatedWidgetState<_AnimatedFadeOutFadeIn> {
  Tween<double> _targetOpacity;
  Tween<double> _placeholderOpacity;
  Animation<double> _targetOpacityAnimation;
  Animation<double> _placeholderOpacityAnimation;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _targetOpacity = visitor(
      _targetOpacity,
      widget.isTargetLoaded ? 1.0 : 0.0,
          (dynamic value) => Tween<double>(begin: value),
    );
    _placeholderOpacity = visitor(
      _placeholderOpacity,
      widget.isTargetLoaded ? 0.0 : 1.0,
          (dynamic value) => Tween<double>(begin: value),
    );
  }

  @override
  void didUpdateTweens() {
    _placeholderOpacityAnimation = animation.drive(TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: _placeholderOpacity.chain(CurveTween(curve: widget.fadeOutCurve)),
        weight: widget.fadeOutDuration.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0),
        weight: widget.fadeInDuration.inMilliseconds.toDouble(),
      ),
    ]));
    _targetOpacityAnimation = animation.drive(TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0),
        weight: widget.fadeOutDuration.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: _targetOpacity.chain(CurveTween(curve: widget.fadeInCurve)),
        weight: widget.fadeInDuration.inMilliseconds.toDouble(),
      ),
    ]));
    if (!widget.isTargetLoaded && _isValid(_placeholderOpacity) && _isValid(_targetOpacity)) {
      // Jump (don't fade) back to the placeholder image, so as to be ready
      // for the full animation when the new target image becomes ready.
      controller.value = controller.upperBound;
    }
  }

  bool _isValid(Tween<double> tween) {
    return tween.begin != null && tween.end != null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      alignment: AlignmentDirectional.center,
      // Text direction is irrelevant here since we're using center alignment,
      // but it allows the Stack to avoid a call to Directionality.of()
      textDirection: TextDirection.ltr,
      children: <Widget>[
        FadeTransition(
          opacity: _targetOpacityAnimation,
          child: widget.target,
        ),
        FadeTransition(
          opacity: _placeholderOpacityAnimation,
          child: widget.placeholder,
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Animation<double>>('targetOpacity', _targetOpacityAnimation));
    properties.add(DiagnosticsProperty<Animation<double>>('placeholderOpacity', _placeholderOpacityAnimation));
  }
}


/// The dart:io implemenation of [image_provider.NetworkImage].
class MyNetworkImage extends ImageProvider<MyNetworkImage>{
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments [url] and [scale] must not be null.
  const MyNetworkImage(this.url, { this.scale = 1.0, this.headers,this.sdCache })
      : assert(url != null),
        assert(scale != null);

  @override
  final String url;

  @override
  final double scale;

  @override
  final Map<String, String> headers;

  final bool sdCache;

  @override
  Future<MyNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<MyNetworkImage>(this);
  }

  @override
  ImageStreamCompleter load(MyNetworkImage key) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      informationCollector: () {
        return <DiagnosticsNode>[
          DiagnosticsProperty<ImageProvider>('Image provider', this),
          DiagnosticsProperty<MyNetworkImage>('Image key', key),
        ];
      },
    );
  }

  // Do not access this field directly; use [_httpClient] instead.
  // We set `autoUncompress` to false to ensure that we can trust the value of
  // the `Content-Length` HTTP header. We automatically uncompress the content
  // in our call to [consolidateHttpClientResponseBytes].
  static final HttpClient _sharedHttpClient = HttpClient()..autoUncompress = false;

  static HttpClient get _httpClient {
    HttpClient client = _sharedHttpClient;
    assert(() {
      if (debugNetworkImageHttpClientProvider != null)
        client = debugNetworkImageHttpClientProvider();
      return true;
    }());
    return client;
  }

  Future<Codec> _loadAsync(
      MyNetworkImage key,
      StreamController<ImageChunkEvent> chunkEvents,
      ) async {
    try {
      assert(key == this);

      if(sdCache==null){
        final Uint8List bytes =await  _getFromSdcard(key.url);
        if (bytes!=null&&bytes.lengthInBytes!=null&&bytes.lengthInBytes!= 0) {
          print("success");
          return await PaintingBinding.instance.instantiateImageCodec(bytes);
        }
      }
      final Uri resolved = Uri.base.resolve(key.url);
      final HttpClientRequest request = await _httpClient.getUrl(resolved);
      headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok)
        throw NetworkImageLoadException(statusCode: response.statusCode, uri: resolved);

      final Uint8List bytes = await consolidateHttpClientResponseBytes(
        response,
        onBytesReceived: (int cumulative, int total) {
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: cumulative,
            expectedTotalBytes: total,
          ));
        },
      );
      if (bytes.lengthInBytes == 0)
        throw Exception('NetworkImage is an empty file: $resolved');

      if(sdCache==null&&bytes.lengthInBytes != 0){
        _saveToImage(bytes, key.url);
      }
      return PaintingBinding.instance.instantiateImageCodec(bytes);
    } finally {
      chunkEvents.close();
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final MyNetworkImage typedOther = other;
    return url == typedOther.url
        && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';


  void _saveToImage(Uint8List mUint8List,String name) async  {
    name = md5.convert(convert.utf8.encode(name)).toString();
    Directory dir = await getTemporaryDirectory();
    String path = dir.path +"/"+name;
    var file = File(path);
    bool exist =  await file.exists();
    print("path =${path}");
    if(!exist)
      File(path).writeAsBytesSync(mUint8List);
  }
  _getFromSdcard(String name) async{
    name = md5.convert(convert.utf8.encode(name)).toString();
    Directory dir = await getTemporaryDirectory();
    String path = dir.path +"/"+name;
    var file = File(path);
    bool exist =  await file.exists();
    if(exist){
      final Uint8List bytes = await file.readAsBytes();

      return bytes;
    }
    return null;
  }
}
