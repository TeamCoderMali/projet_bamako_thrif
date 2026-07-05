/// ─── Bamako Thrift — Connectivity Service ─────────────────────────────────
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionStatusController.stream;

  ConnectivityService() {
    _init();
  }

  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _connectionStatusController.add(_isConnected(results));
    });
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  void dispose() {
    _subscription.cancel();
    _connectionStatusController.close();
  }
}
