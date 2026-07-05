/// ─── Bamako Thrift — Network / Dio Client ─────────────────────────────────
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Client HTTP basé sur Dio.
/// Prêt pour une intégration REST API (backend tiers ou Firebase Extensions).
class DioClient {
  late final Dio _dio;
  final Logger _logger = Logger();

  static const String _baseUrl = 'https://api.bamako-thrift.com/v1';
  static const int _connectTimeout = 30000;
  static const int _receiveTimeout = 30000;
  static const int _sendTimeout = 30000;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(milliseconds: _connectTimeout),
        receiveTimeout: const Duration(milliseconds: _receiveTimeout),
        sendTimeout: const Duration(milliseconds: _sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );
    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _LoggingInterceptor(_logger),
      _ErrorInterceptor(),
    ]);
  }

  /// Mise à jour du token d'authentification (appelée après login).
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}

// ── Auth Interceptor ───────────────────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // TODO: Injecter le token depuis SecureStorage
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // TODO: Refresh token ou redirect vers login
    }
    super.onError(err, handler);
  }
}

// ── Logging Interceptor ────────────────────────────────────────────────────
class _LoggingInterceptor extends Interceptor {
  final Logger logger;
  _LoggingInterceptor(this.logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.d('[DIO] --> ${options.method} ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.d('[DIO] <-- ${response.statusCode} ${response.requestOptions.uri}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e('[DIO] ERROR: ${err.message}', error: err);
    super.onError(err, handler);
  }
}

// ── Error Interceptor ──────────────────────────────────────────────────────
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO: Convertir DioException en AppException
    super.onError(err, handler);
  }
}
