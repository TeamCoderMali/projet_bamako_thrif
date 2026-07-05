/// ─── Bamako Thrift — Logger Service ───────────────────────────────────────
import 'package:logger/logger.dart';

/// Service de logging centralisé.
/// En production, remplacer par Firebase Crashlytics ou Sentry.
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  late final Logger _logger;

  void init({bool isProduction = false}) {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: isProduction ? Level.warning : Level.trace,
    );
  }

  Logger get logger => _logger;

  void trace(dynamic message, {dynamic error, StackTrace? stackTrace}) =>
      _logger.t(message, error: error, stackTrace: stackTrace);

  void debug(dynamic message, {dynamic error, StackTrace? stackTrace}) =>
      _logger.d(message, error: error, stackTrace: stackTrace);

  void info(dynamic message, {dynamic error, StackTrace? stackTrace}) =>
      _logger.i(message, error: error, stackTrace: stackTrace);

  void warning(dynamic message, {dynamic error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  void severe(dynamic message, {dynamic error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  void fatal(dynamic message, {dynamic error, StackTrace? stackTrace}) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}

/// Accesseur global (singleton).
final logger = LoggerService();
