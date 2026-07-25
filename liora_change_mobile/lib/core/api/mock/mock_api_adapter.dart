import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'mock_backend.dart';

/// Serves [MockBackend] over Dio's transport layer.
///
/// Plugging in at the adapter means interceptors, error handling, and every
/// repository run exactly as they will against the real API — only the wire is
/// faked.
class MockApiAdapter implements HttpClientAdapter {
  MockApiAdapter({MockBackend? backend, this.latency = _defaultLatency})
    : backend = backend ?? MockBackend();

  /// Enough delay for skeletons and spinners to be visible on device.
  static const Duration _defaultLatency = Duration(milliseconds: 450);

  final MockBackend backend;
  final Duration latency;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(latency);

    final MockResponse response = backend.handle(
      method: options.method.toUpperCase(),
      path: options.path,
      body: _decodeBody(options.data),
      query: options.queryParameters,
      token: _bearerToken(options.headers),
    );

    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  static Map<String, dynamic> _decodeBody(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      final Object? decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{};
  }

  static String? _bearerToken(Map<String, dynamic> headers) {
    final Object? header = headers['Authorization'];
    if (header is! String || !header.startsWith('Bearer ')) return null;
    return header.substring('Bearer '.length);
  }

  @override
  void close({bool force = false}) {}
}
