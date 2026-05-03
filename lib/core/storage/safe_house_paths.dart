import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../errors/failures.dart';

/// Returns `<sharedStorageRoot>/SafeHouse/<subfolder>/<filename>`.
///
/// Uses **public shared storage** on Android so files are visible
/// in any file-manager app under "Internal storage › SafeHouse":
///   - Android  → `/storage/emulated/0/SafeHouse/...`
///   - iOS      → `<app sandbox>/Documents/SafeHouse/...`
///   - Desktop  → platform-appropriate documents dir
///
/// On Android 11+ this path requires the MANAGE_EXTERNAL_STORAGE
/// permission ("All files access"); callers are expected to have
/// gone through StoragePermission.ensure before invoking. Without
/// permission, [Directory.create] raises a [FileSystemException]
/// which this surfaces as a [StorageFailure].
Future<String> resolveSafeHousePath({
  required String subfolder,
  required String filename,
}) async {
  final Directory root;
  if (Platform.isAndroid) {
    root = Directory('/storage/emulated/0');
  } else {
    root = await getApplicationDocumentsDirectory();
  }

  final dir = Directory(p.join(root.path, 'SafeHouse', subfolder));
  try {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  } on FileSystemException catch (e) {
    throw StorageFailure(
      'Could not create output folder "${dir.path}". '
      'Make sure SafeHouse has "All files access" enabled in Settings. '
      '(${e.osError?.message ?? e.message})',
    );
  }
  return p.join(dir.path, filename);
}
