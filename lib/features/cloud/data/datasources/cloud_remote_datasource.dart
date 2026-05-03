import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/storage/safe_house_paths.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/cloud_transfer.dart';

abstract class CloudRemoteDataSource {
  Stream<CloudTransferEvent> uploadFile({
    required String filePath,
    required String remoteFileName,
    required CloudTransferHandle handle,
    String? categoryName,
    String? categoryId,
  });

  Stream<CloudTransferEvent> downloadFile({
    required String remoteFileName,
    required CloudTransferHandle handle,
    String? categoryName,
  });

  Future<List<CloudFile>> getCloudFiles();

  Future<void> deleteCloudFile(String fileName, {String? categoryName});

  Future<void> deleteAllCloudFiles();

  Future<bool> isCloudStorageEnabled();

  Future<void> setCloudStorageEnabled(bool enabled);
}

class CloudRemoteDataSourceImpl implements CloudRemoteDataSource {
  final FirebaseStorage firebaseStorage;
  final FirebaseAuth firebaseAuth;
  final SharedPreferences sharedPreferences;

  static const String _cloudStorageEnabledKey = 'cloud_storage_enabled';
  static const String _encryptedSubfolder = 'encrypted files';

  CloudRemoteDataSourceImpl({
    required this.firebaseStorage,
    required this.firebaseAuth,
    required this.sharedPreferences,
  });

  String get _userId {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to access cloud storage.');
    }
    return user.uid;
  }

  @override
  Stream<CloudTransferEvent> uploadFile({
    required String filePath,
    required String remoteFileName,
    required CloudTransferHandle handle,
    String? categoryName,
    String? categoryId,
  }) {
    final controller = StreamController<CloudTransferEvent>();
    _startUpload(
      controller,
      filePath,
      remoteFileName,
      handle,
      categoryName,
      categoryId,
    );
    return controller.stream;
  }

  Future<void> _startUpload(
    StreamController<CloudTransferEvent> controller,
    String filePath,
    String remoteFileName,
    CloudTransferHandle handle,
    String? categoryName,
    String? categoryId,
  ) async {
    try {
      final enabled = await isCloudStorageEnabled();
      if (!enabled) {
        controller.add(const CloudTransferFailed(
          'Cloud storage is currently disabled in settings.',
        ));
        await controller.close();
        return;
      }
      final file = File(filePath);
      if (!await file.exists()) {
        controller.add(const CloudTransferFailed('File does not exist.'));
        await controller.close();
        return;
      }

      final folder = categoryName ?? 'Others';
      final ref = firebaseStorage
          .ref()
          .child('users/$_userId/$folder/$remoteFileName');

      final metadata = SettableMetadata(
        customMetadata: {
          if (categoryId != null) 'categoryId': categoryId,
          'categoryName': folder,
        },
      );

      final task = ref.putFile(file, metadata);
      handle.attach(task);
      _forward(task.snapshotEvents, controller, successLocalPath: null);
    } catch (e) {
      controller.add(CloudTransferFailed(e.toString()));
      await controller.close();
    }
  }

  @override
  Stream<CloudTransferEvent> downloadFile({
    required String remoteFileName,
    required CloudTransferHandle handle,
    String? categoryName,
  }) {
    final controller = StreamController<CloudTransferEvent>();
    _startDownload(controller, remoteFileName, handle, categoryName);
    return controller.stream;
  }

  Future<void> _startDownload(
    StreamController<CloudTransferEvent> controller,
    String remoteFileName,
    CloudTransferHandle handle,
    String? categoryName,
  ) async {
    try {
      final enabled = await isCloudStorageEnabled();
      if (!enabled) {
        controller.add(const CloudTransferFailed(
          'Cloud storage is currently disabled in settings.',
        ));
        await controller.close();
        return;
      }
      final localPath = await resolveSafeHousePath(
        subfolder: _encryptedSubfolder,
        filename: remoteFileName,
      );
      final folder = categoryName ?? 'Others';
      final ref = firebaseStorage
          .ref()
          .child('users/$_userId/$folder/$remoteFileName');
      final task = ref.writeToFile(File(localPath));
      handle.attach(task);
      _forward(task.snapshotEvents, controller, successLocalPath: localPath);
    } catch (e) {
      controller.add(CloudTransferFailed(e.toString()));
      await controller.close();
    }
  }

  void _forward(
    Stream<TaskSnapshot> snapshots,
    StreamController<CloudTransferEvent> out, {
    required String? successLocalPath,
  }) {
    late StreamSubscription<TaskSnapshot> sub;
    sub = snapshots.listen(
      (snap) {
        switch (snap.state) {
          case TaskState.running:
            out.add(CloudTransferRunning(
              bytesTransferred: snap.bytesTransferred,
              totalBytes: snap.totalBytes,
            ));
            break;
          case TaskState.paused:
            out.add(CloudTransferPaused(
              bytesTransferred: snap.bytesTransferred,
              totalBytes: snap.totalBytes,
            ));
            break;
          case TaskState.success:
            out.add(CloudTransferSuccess(localPath: successLocalPath));
            sub.cancel();
            out.close();
            break;
          case TaskState.canceled:
            out.add(const CloudTransferCanceled());
            sub.cancel();
            out.close();
            break;
          case TaskState.error:
            out.add(const CloudTransferFailed('Transfer failed. Please check your internet connection or Firebase Storage rules.'));
            sub.cancel();
            out.close();
            break;
        }
      },
      onError: (Object e) {
        String message = 'An unexpected error occurred.';
        if (e is FirebaseException) {
          message = e.message ?? e.toString();
        } else {
          message = e.toString();
        }
        out.add(CloudTransferFailed(message));
        sub.cancel();
        out.close();
      },
    );
  }

  @override
  Future<List<CloudFile>> getCloudFiles() async {
    try {
      final rootRef = firebaseStorage.ref().child('users/$_userId');
      final rootList = await rootRef.listAll();

      final files = <CloudFile>[];

      // Handle legacy files in the root (legacy 'Others')
      for (var item in rootList.items) {
        final metadata = await item.getMetadata();
        files.add(
          CloudFile(
            name: item.name,
            fullPath: item.fullPath,
            sizeBytes: metadata.size ?? 0,
            timeCreated: metadata.timeCreated,
            categoryName: 'Others',
          ),
        );
      }

      // Handle files in category folders
      for (var prefix in rootList.prefixes) {
        final folderName = prefix.name;
        final folderList = await prefix.listAll();
        for (var item in folderList.items) {
          final metadata = await item.getMetadata();
          files.add(
            CloudFile(
              name: item.name,
              fullPath: item.fullPath,
              sizeBytes: metadata.size ?? 0,
              timeCreated: metadata.timeCreated,
              categoryName: folderName,
              categoryId: metadata.customMetadata?['categoryId'],
            ),
          );
        }
      }

      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      files.sort(
        (a, b) => (b.timeCreated ?? epoch).compareTo(a.timeCreated ?? epoch),
      );
      return files;
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch cloud files: ${e.code}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> deleteCloudFile(String fileName, {String? categoryName}) async {
    final folder = categoryName ?? 'Others';
    final ref = firebaseStorage.ref().child('users/$_userId/$folder/$fileName');
    try {
      await ref.delete();
    } catch (e) {
      // If folder-based delete fails, try root for legacy support
      if (categoryName == null || categoryName == 'Others') {
        try {
          final rootRef =
              firebaseStorage.ref().child('users/$_userId/$fileName');
          await rootRef.delete();
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> deleteAllCloudFiles() async {
    final ref = firebaseStorage.ref().child('users/$_userId');
    final listResult = await ref.listAll();
    await Future.wait(listResult.items.map((item) => item.delete()));
  }

  @override
  Future<bool> isCloudStorageEnabled() async {
    return sharedPreferences.getBool(_cloudStorageEnabledKey) ?? false;
  }

  @override
  Future<void> setCloudStorageEnabled(bool enabled) async {
    await sharedPreferences.setBool(_cloudStorageEnabledKey, enabled);
  }
}
