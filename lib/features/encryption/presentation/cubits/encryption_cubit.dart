import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import '../../../../core/errors/failures.dart';
import '../../domain/entities/encrypted_file.dart';
import '../../domain/repositories/encryption_repository.dart';

part 'encryption_state.dart';

/// Manages the lifecycle of a single encrypt-or-decrypt operation.
///
/// Registered as a **factory** in GetIt so each screen receives a fresh
/// instance with a clean [EncryptionInitial] state.
///
/// ### Typical encrypt flow
/// ```
/// pickFileForEncryption()  →  EncryptionFileSelected
/// encryptSelectedFile(key) →  EncryptionLoading → EncryptionSuccess
/// ```
///
/// ### Typical decrypt flow
/// ```
/// pickFileForDecryption()  →  EncryptionFileSelected
/// decryptSelectedFile(key) →  EncryptionLoading → DecryptionSuccess
/// ```
class EncryptionCubit extends Cubit<EncryptionState> {
  final EncryptionRepository _repository;

  /// Holds the last successfully picked file path across state transitions.
  String? _selectedFilePath;

  /// Canonical filename with a guaranteed extension, built from both
  /// [PlatformFile.name] and [PlatformFile.extension] at pick time.
  /// [PlatformFile.extension] is derived from the MIME type by file_picker
  /// so it is reliable even when the content-URI display name has no suffix.
  String? _selectedFileName;

  String? get selectedFilePath => _selectedFilePath;
  String? get selectedFileName => _selectedFileName;

  EncryptionCubit({required EncryptionRepository repository})
    : _repository = repository,
      super(const EncryptionInitial());

  // ── File picking ───────────────────────────────────────────────────────────

  /// Opens the system file picker for selecting any file to encrypt.
  Future<void> pickFileForEncryption() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return; // user cancelled

      final file = result.files.single;
      final path = file.path;

      if (path == null) {
        emit(const EncryptionError(message: 'Could not resolve file path.'));
        return;
      }

      _selectedFilePath = path;
      _selectedFileName = _canonicalName(file);
      emit(
        EncryptionFileSelected(filePath: path, fileName: _selectedFileName!),
      );
    } catch (e) {
      emit(EncryptionError(message: 'File picker error: $e'));
    }
  }

  /// Opens the system file picker for selecting an encrypted `.enc` file.
  Future<void> pickFileForDecryption() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['enc'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final path = file.path;

      if (path == null) {
        emit(const EncryptionError(message: 'Could not resolve file path.'));
        return;
      }

      final extension = p.extension(file.name).toLowerCase();
      if (extension != '.enc') {
        emit(
          const EncryptionError(
            message: 'Please select an encrypted .enc file.',
          ),
        );
        return;
      }

      _selectedFilePath = path;
      _selectedFileName = _canonicalName(file);
      emit(
        EncryptionFileSelected(filePath: path, fileName: _selectedFileName!),
      );
    } catch (e) {
      emit(EncryptionError(message: 'File picker error: $e'));
    }
  }

  // ── Key generation ─────────────────────────────────────────────────────────

  /// Generates a fresh AES-256 key and emits [EncryptionKeyGenerated].
  ///
  /// The UI listens for this state via [BlocListener] and copies the key
  /// into the `TextEditingController` automatically.
  ///
  /// After emitting the key, the cubit restores the previous stable state so
  /// the screen doesn't reset (e.g. the picked filename remains visible).
  void generateKey() {
    final key = _repository.generateKey();

    emit(EncryptionKeyGenerated(generatedKey: key));
  }

  // ── Encryption ─────────────────────────────────────────────────────────────

  /// Encrypts the previously selected file with [secretKey].
  ///
  /// Requires [pickFileForEncryption] to have been called first.
  Future<void> encryptSelectedFile(
    String secretKey, {
    String? customFileName,
    String? categoryId,
    Uint8List? salt,
  }) async {
    final filePath = _selectedFilePath;

    if (filePath == null) {
      emit(
        const EncryptionError(
          message: 'No file selected. Please pick a file first.',
        ),
      );
      return;
    }

    if (secretKey.trim().isEmpty) {
      emit(
        const EncryptionError(
          message: 'Please enter or generate a secret key.',
        ),
      );
      return;
    }

    emit(const EncryptionLoading(message: 'Encrypting file…'));

    try {
      // Preserve the original file extension. If the user typed a custom
      // filename without an extension, splice the original extension onto
      // it so the embedded header (and therefore the decrypted filename)
      // carries the right suffix.
      final originalExt = _selectedFileName != null
          ? p.extension(_selectedFileName!)
          : p.extension(filePath);

      String? finalFileName;
      if (customFileName != null && customFileName.trim().isNotEmpty) {
        final cust = customFileName.trim();
        finalFileName = p.extension(cust).isEmpty && originalExt.isNotEmpty
            ? '$cust$originalExt'
            : cust;
      } else if (_selectedFileName != null &&
          p.extension(_selectedFileName!).isEmpty &&
          p.extension(filePath).isNotEmpty) {
        // Fallback: source filename had no extension (e.g. Android content
        // URI) but the on-disk path does — use that.
        finalFileName = '${_selectedFileName!}${p.extension(filePath)}';
      } else {
        finalFileName = _selectedFileName;
      }

      final result = await _repository.encryptFile(
        filePath: filePath,
        secretKey: secretKey.trim(),
        originalFileName: finalFileName,
        categoryId: categoryId,
        salt: salt,
      );
      _selectedFilePath = null;
      _selectedFileName = null;
      emit(EncryptionSuccess(result: result, secretKey: secretKey.trim()));
    } on Failure catch (f) {
      emit(EncryptionError(message: f.message));
    } catch (e) {
      emit(EncryptionError(message: 'Unexpected error: $e'));
    }
  }

  // ── Decryption ─────────────────────────────────────────────────────────────

  /// Decrypts the previously selected encrypted file with [secretKey].
  ///
  /// Requires [pickFileForDecryption] to have been called first.
  Future<void> decryptSelectedFile(String secretKey) async {
    final filePath = _selectedFilePath;

    if (filePath == null) {
      emit(
        const EncryptionError(
          message: 'No file selected. Please pick an encrypted file first.',
        ),
      );
      return;
    }

    if (secretKey.trim().isEmpty) {
      emit(const EncryptionError(message: 'Please enter the secret key.'));
      return;
    }

    emit(const EncryptionLoading(message: 'Decrypting file…'));

    try {
      final outputPath = await _repository.decryptFile(
        encryptedFilePath: filePath,
        secretKey: secretKey.trim(),
      );
      _selectedFilePath = null;
      _selectedFileName = null;
      emit(DecryptionSuccess(outputPath: outputPath));
    } on Failure catch (f) {
      emit(EncryptionError(message: f.message));
    } catch (e) {
      emit(EncryptionError(message: 'Unexpected error: $e'));
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Resets the cubit to its initial state (e.g. user wants to start over).
  void reset() {
    _selectedFilePath = null;
    _selectedFileName = null;
    emit(const EncryptionInitial());
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Builds a filename that is guaranteed to carry an extension.
  ///
  /// On Android, content-URI display names often have no suffix (e.g.
  /// `"photo"` instead of `"photo.jpg"`). [PlatformFile.extension] is
  /// populated by file_picker from the file's MIME type, so appending it
  /// covers that case without double-adding when the name already has one.
  static String _canonicalName(PlatformFile file) {
    final ext = file.extension; // "jpg", "pdf", etc. — no leading dot
    if (ext != null && ext.isNotEmpty && !file.name.contains('.')) {
      return '${file.name}.$ext';
    }
    return file.name;
  }
}
