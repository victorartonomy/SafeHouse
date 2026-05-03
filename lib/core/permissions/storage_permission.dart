import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralises the runtime-permission flow needed to read and write
/// files under `/storage/emulated/0/SafeHouse/...`.
///
/// On Android 11+ (API 30+) this means **MANAGE_EXTERNAL_STORAGE**
/// ("All files access"), which Google routes through a dedicated
/// Settings screen rather than a normal permission dialog. There is no
/// way to grant it inline — the user has to flip a toggle in Settings
/// and return to the app.
///
/// On Android 6–10 the classic **WRITE_EXTERNAL_STORAGE** prompt suffices.
///
/// On non-Android platforms this class is a no-op (always granted).
class StoragePermission {
  StoragePermission._();

  /// Returns `true` if the app currently has permission to write to
  /// public shared storage. Cheap — does not show any UI.
  static Future<bool> isGranted() async {
    if (!Platform.isAndroid) return true;

    // On Android 11+ this checks the All Files Access flag.
    // On Android 6-10, permission_handler internally falls back to
    // checking WRITE_EXTERNAL_STORAGE.
    if (await Permission.manageExternalStorage.isGranted) return true;
    if (await Permission.storage.isGranted) return true;
    return false;
  }

  /// Ensures the app has shared-storage write access, prompting the
  /// user if needed. Returns `true` once permission is held.
  ///
  /// The flow:
  ///   1. If already granted → return true.
  ///   2. Show an explanation dialog (so the user understands why
  ///      they're about to be sent to Settings).
  ///   3. On Android 11+, [Permission.manageExternalStorage.request]
  ///      opens the system "All files access" settings page. We come
  ///      back to the app via lifecycle resume; re-check the flag.
  ///   4. On Android 6-10, a normal permission dialog is shown.
  ///   5. If the user permanently denies, offer to deep-link into the
  ///      app's settings page.
  static Future<bool> ensure(BuildContext context) async {
    if (!Platform.isAndroid) return true;
    if (await isGranted()) return true;

    // Step 2 — pre-prompt rationale. Skipping this puts the user in
    // Settings with no idea what just happened.
    if (!context.mounted) return false;
    final shouldRequest = await _showRationaleDialog(context);
    if (shouldRequest != true) return false;

    // Step 3/4 — actually request. On Android 11+ this opens the
    // "Allow access to manage all files" settings page.
    PermissionStatus status = await Permission.manageExternalStorage.request();

    // Older devices: the manageExternalStorage request short-circuits
    // to "granted" on API < 30, but request the legacy permission too
    // so devices in the API 23-29 window get a real prompt.
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) return true;

    // Step 5 — permanently denied. Offer the manual path.
    if (!context.mounted) return false;
    if (status.isPermanentlyDenied) {
      final goToSettings = await _showPermanentlyDeniedDialog(context);
      if (goToSettings == true) {
        await openAppSettings();
      }
    }
    return await isGranted();
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  static Future<bool?> _showRationaleDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Storage access needed'),
        content: const Text(
          'SafeHouse saves your encrypted and decrypted files to '
          '"Internal storage › SafeHouse" so you can find them in any '
          'file manager.\n\n'
          'On Android 11 and later, this requires the "All files access" '
          'permission. The next screen will open Settings — please '
          'enable the toggle for SafeHouse and come back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  static Future<bool?> _showPermanentlyDeniedDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission denied'),
        content: const Text(
          'SafeHouse cannot save files to shared storage without the '
          '"All files access" permission. You can enable it manually from '
          "the app's settings page.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
