import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import 'session_service.dart';

class PermissionService {
  static Future<void> requestOnboardingPermissions() async {
    final alreadyRequested = await SessionService.isPermissionsRequested();
    if (alreadyRequested) return;

    final permissions = <Permission>[
      Permission.camera,
      Permission.microphone,
      Permission.notification,
      if (Platform.isAndroid) Permission.photos,
      if (Platform.isAndroid) Permission.storage,
    ];

    for (final permission in permissions) {
      await permission.request();
    }

    await SessionService.setPermissionsRequested(true);
  }
}
