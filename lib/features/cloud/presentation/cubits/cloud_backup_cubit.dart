import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/cloud_transfer.dart';
import '../../domain/repositories/cloud_repository.dart';
import 'cloud_backup_state.dart';

class CloudBackupCubit extends Cubit<CloudBackupState> {
  final CloudRepository _cloudRepository;

  final Map<String, StreamSubscription<CloudTransferEvent>> _subs = {};

  CloudBackupCubit({required CloudRepository cloudRepository})
    : _cloudRepository = cloudRepository,
      super(CloudBackupInitial()) {
    loadCloudFiles();
  }

  @override
  Future<void> close() async {
    for (final s in _subs.values) {
      await s.cancel();
    }
    _subs.clear();
    return super.close();
  }

  Future<void> loadCloudFiles() async {
    // Preserve any in-flight transfers across reloads so progress bars
    // stick even while the file list is refreshing.
    final preservedTransfers = _currentTransfers();

    emit(CloudBackupLoading());
    final isEnabledResult = await _cloudRepository.isCloudStorageEnabled();
    bool isEnabled = false;
    isEnabledResult.fold((l) => isEnabled = false, (r) => isEnabled = r);

    if (!isEnabled) {
      emit(
        const CloudBackupError(
          message: 'Cloud Storage is disabled. Enable it in Settings.',
        ),
      );
      return;
    }

    final result = await _cloudRepository.getCloudFiles();
    result.fold(
      (failure) => emit(CloudBackupError(message: failure.message)),
      (files) =>
          emit(CloudBackupLoaded(files: files, transfers: preservedTransfers)),
    );
  }

  Map<String, CloudTransferProgress> _currentTransfers() {
    final s = state;
    if (s is CloudBackupLoaded) return s.transfers;
    return const {};
  }

  List<CloudFile> _currentFiles() {
    final s = state;
    if (s is CloudBackupLoaded) return s.files;
    return const [];
  }

  void _emitTransfers(Map<String, CloudTransferProgress> transfers) {
    emit(CloudBackupLoaded(files: _currentFiles(), transfers: transfers));
  }

  Future<void> deleteFile(String fileName, {String? categoryName}) async {
    if (_subs.containsKey(fileName)) return;
    emit(CloudBackupLoading());
    final result = await _cloudRepository.deleteCloudFile(
      fileName,
      categoryName: categoryName,
    );
    result.fold(
      (failure) {
        emit(CloudBackupError(message: failure.message));
        loadCloudFiles();
      },
      (_) {
        emit(
          const CloudBackupActionSuccess(message: 'File deleted successfully.'),
        );
        loadCloudFiles();
      },
    );
  }

  Future<void> pickAndUploadFile(
    String customName, {
    String? categoryName,
    String? categoryId,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['enc'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return; // User cancelled

      final file = result.files.single;
      final path = file.path;

      if (path == null) {
        emit(const CloudBackupError(message: 'Could not resolve file path.'));
        loadCloudFiles();
        return;
      }

      final extension = p.extension(file.name).toLowerCase();
      if (extension != '.enc') {
        emit(
          const CloudBackupError(
            message: 'Please select an encrypted .enc file.',
          ),
        );
        loadCloudFiles();
        return;
      }

      await uploadFile(
        path,
        customName,
        categoryName: categoryName,
        categoryId: categoryId,
      );
    } catch (e) {
      emit(CloudBackupError(message: 'File picker error: $e'));
      loadCloudFiles();
    }
  }

  /// Upload with live progress. Normalizes the remote name and ensures the
  /// file list is loaded so progress can attach to a stable row.
  Future<void> uploadFile(
    String filePath,
    String customName, {
    String? categoryName,
    String? categoryId,
  }) async {
    String remoteName = customName.trim();
    if (!remoteName.toLowerCase().endsWith('.enc')) {
      remoteName += '.enc';
    }

    // Make sure we are in a Loaded state so the progress row can render.
    if (state is! CloudBackupLoaded) {
      final enabled = await _cloudRepository.isCloudStorageEnabled();
      bool ok = false;
      enabled.fold((_) {}, (v) => ok = v);
      if (!ok) {
        emit(
          const CloudBackupError(
            message: 'Cloud Storage is disabled. Enable it in Settings.',
          ),
        );
        return;
      }
      final files = await _cloudRepository.getCloudFiles();
      files.fold(
        (f) => emit(CloudBackupError(message: f.message)),
        (list) => emit(CloudBackupLoaded(files: list)),
      );
      if (state is! CloudBackupLoaded) return;
    }

    final handle = CloudTransferHandle();
    final stream = _cloudRepository.uploadFile(
      filePath: filePath,
      remoteFileName: remoteName,
      handle: handle,
      categoryName: categoryName,
      categoryId: categoryId,
    );
    _watchTransfer(
      key: remoteName,
      kind: CloudTransferKind.upload,
      handle: handle,
      stream: stream,
      successMessage: 'Uploaded "$remoteName".',
    );
  }

  Future<void> downloadFile(String fileName, {String? categoryName}) async {
    if (_subs.containsKey(fileName)) return;
    if (state is! CloudBackupLoaded) {
      await loadCloudFiles();
      if (state is! CloudBackupLoaded) return;
    }
    final handle = CloudTransferHandle();
    final stream = _cloudRepository.downloadFile(
      remoteFileName: fileName,
      handle: handle,
      categoryName: categoryName,
    );
    _watchTransfer(
      key: fileName,
      kind: CloudTransferKind.download,
      handle: handle,
      stream: stream,
      successMessage: null, // populated from success event with localPath
    );
  }

  void _watchTransfer({
    required String key,
    required CloudTransferKind kind,
    required CloudTransferHandle handle,
    required Stream<CloudTransferEvent> stream,
    required String? successMessage,
  }) {
    final initial = CloudTransferProgress(
      kind: kind,
      status: CloudTransferStatus.running,
      bytesTransferred: 0,
      totalBytes: 0,
      handle: handle,
    );
    final transfers = Map<String, CloudTransferProgress>.from(
      _currentTransfers(),
    );
    transfers[key] = initial;
    _emitTransfers(transfers);

    _subs[key] = stream.listen((event) {
      final current = Map<String, CloudTransferProgress>.from(
        _currentTransfers(),
      );
      final progress = current[key];

      switch (event) {
        case CloudTransferRunning():
          if (progress != null) {
            current[key] = progress.copyWith(
              status: CloudTransferStatus.running,
              bytesTransferred: event.bytesTransferred,
              totalBytes: event.totalBytes,
            );
            _emitTransfers(current);
          }
          break;
        case CloudTransferPaused():
          if (progress != null) {
            current[key] = progress.copyWith(
              status: CloudTransferStatus.paused,
              bytesTransferred: event.bytesTransferred,
              totalBytes: event.totalBytes,
            );
            _emitTransfers(current);
          }
          break;
        case CloudTransferSuccess():
          current.remove(key);
          _emitTransfers(current);
          _subs.remove(key);
          final msg = successMessage ??
              (event.localPath != null
                  ? 'Saved to ${event.localPath}'
                  : 'Transfer complete.');
          emit(CloudBackupActionSuccess(message: msg));
          loadCloudFiles();
          break;
        case CloudTransferCanceled():
          current.remove(key);
          _emitTransfers(current);
          _subs.remove(key);
          emit(const CloudBackupActionSuccess(message: 'Transfer canceled.'));
          loadCloudFiles();
          break;
        case CloudTransferFailed():
          current.remove(key);
          _emitTransfers(current);
          _subs.remove(key);
          emit(CloudBackupError(message: event.message));
          loadCloudFiles();
          break;
      }
    }, onError: (Object e) {
      final current = Map<String, CloudTransferProgress>.from(
        _currentTransfers(),
      );
      current.remove(key);
      _emitTransfers(current);
      _subs.remove(key);
      emit(CloudBackupError(message: e.toString()));
      loadCloudFiles();
    });
  }

  Future<void> pauseTransfer(String key) async {
    final transfers = _currentTransfers();
    await transfers[key]?.handle.pause();
  }

  Future<void> resumeTransfer(String key) async {
    final transfers = _currentTransfers();
    await transfers[key]?.handle.resume();
  }

  Future<void> cancelTransfer(String key) async {
    final transfers = _currentTransfers();
    await transfers[key]?.handle.cancel();
  }
}
