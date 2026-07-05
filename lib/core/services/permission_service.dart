/// ─── Bamako Thrift — Permission Service ────────────────────────────────────
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestPhotos() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> requestLocation() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<bool> requestStorage() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<PermissionStatus> checkCamera() => Permission.camera.status;
  Future<PermissionStatus> checkPhotos() => Permission.photos.status;
  Future<PermissionStatus> checkNotifications() =>
      Permission.notification.status;
  Future<PermissionStatus> checkLocation() =>
      Permission.locationWhenInUse.status;

  /// Ouvre les paramètres système de l'app.
  Future<bool> openSettings() => openAppSettings();
}
