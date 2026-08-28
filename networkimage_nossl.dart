import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class LSNetworkImageNoSSL extends ImageProvider<LSNetworkImageNoSSL> {
  const LSNetworkImageNoSSL(this.url, {this.scale = 1.0, this.headers});

  final String url;
  final double scale;
  final Map<String, String>? headers;

  @override
  Future<LSNetworkImageNoSSL> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<LSNetworkImageNoSSL>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    LSNetworkImageNoSSL key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
    );
  }

  static final HttpClient _httpClient = HttpClient()
    ..badCertificateCallback = ((X509Certificate cert, String host, int port) =>
        true);

  Future<ui.Codec> _loadAsync(
    LSNetworkImageNoSSL key,
    ImageDecoderCallback decode,
  ) async {
    assert(key == this);

    final Uri resolved = Uri.base.resolve(key.url);
    final HttpClientRequest request = await _httpClient.getUrl(resolved);
    headers?.forEach((String name, String value) {
      request.headers.add(name, value);
    });
    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'HTTP request failed, statusCode: ${response.statusCode}, $resolved',
      );
    }

    final Uint8List bytes = await consolidateHttpClientResponseBytes(response);
    if (bytes.lengthInBytes == 0) {
      throw Exception('LSNetworkImageNoSSL is an empty file: $resolved');
    }

    final ImmutableBuffer buffer = await ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is LSNetworkImageNoSSL &&
        other.url == url &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}
