import 'package:permission_handler/permission_handler.dart';

/// Handles all permission requests for the application.
class PermissionService {
  /// Request storage/file access permissions.
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.status;
    if (status.isGranted) return true;

    final result = await Permission.storage.request();
    return result.isGranted;
  }

  /// Request camera permission.
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Request microphone permission for audio recording.
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Request notification permission (Android 13+).
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Request all necessary permissions at once.
  Future<Map<String, bool>> requestAllPermissions() async {
    return {
      'storage': await requestStoragePermission(),
      'camera': await requestCameraPermission(),
      'microphone': await requestMicrophonePermission(),
      'notification': await requestNotificationPermission(),
    };
  }

  /// Check if a specific permission is granted.
  Future<bool> isGranted(Permission permission) async {
    return permission.status.isGranted;
  }

  /// Check if notifications are enabled.
  Future<bool> areNotificationsEnabled() async {
    return Permission.notification.status.isGranted;
  }

  /// Open app settings if a permission is permanently denied.
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
