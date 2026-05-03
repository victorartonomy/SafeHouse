import 'dart:convert';
import 'dart:io';

// Aliased to avoid a name clash with `Key` from `package:flutter/foundation`.
import 'package:encrypt/encrypt.dart' as enc show Key, IV;
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';

import '../../../../core/errors/failures.dart';

/// Stateless AES-256-GCM (AEAD) encryption/decryption service.
class AesEncryptionService {
  static const int keyLength = 32; // 256-bit key
  static const int ivLength = 12; // 96-bit IV — GCM standard
  static const int tagLength = 16; // 128-bit auth tag

  // Header magic + version. Two ASCII bytes ("SF") + u8 version.
  static const int magic0 = 0x53;
  static const int magic1 = 0x46;
  static const int headerVersion = 0x01;

  static const int magicSalt0 = 0x53;
  static const int magicSalt1 = 0x41;
  static const int magicSalt2 = 0x4C;
  static const int magicSalt3 = 0x54;

  /// Extracts the 16-byte salt from the file header if it exists.
  /// Returns `null` if the file is legacy and has no salt header.
  Future<Uint8List?> extractSalt(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    final handle = await file.open();
    try {
      final bytes = await handle.read(20);
      if (bytes.length == 20 &&
          bytes[0] == magicSalt0 &&
          bytes[1] == magicSalt1 &&
          bytes[2] == magicSalt2 &&
          bytes[3] == magicSalt3) {
        return bytes.sublist(4);
      }
      return null;
    } finally {
      await handle.close();
    }
  }

  /// Generates a cryptographically random 256-bit AES key.
  /// Returns the key as a standard base64 string safe for display/storage.
  String generateKey() {
    final key = enc.Key.fromSecureRandom(keyLength);
    return base64Encode(key.bytes);
  }

  /// Returns `true` when [base64Key] decodes to exactly 32 bytes.
  bool isValidKey(String base64Key) {
    try {
      final bytes = base64Decode(base64Key);
      return bytes.length == keyLength;
    } catch (_) {
      return false;
    }
  }

  Future<void> encryptFile({
    required String inputPath,
    required String outputPath,
    required String base64Key,
    String? originalFileName,
    Uint8List? salt,
  }) async {
    final keyBytes = _decodeKey(base64Key);

    if (!await File(inputPath).exists()) {
      throw const FilePickerFailure('Source file no longer exists.');
    }

    try {
      await compute(
        _encryptEntryPoint,
        _EncryptJob(
          inputPath: inputPath,
          outputPath: outputPath,
          keyBytes: keyBytes,
          originalFileName: originalFileName,
          salt: salt,
        ),
      );
    } catch (e) {
      throw EncryptionFailure('Encryption failed: $e');
    }
  }

  Future<String?> decryptFile({
    required String inputPath,
    required String outputPath,
    required String base64Key,
  }) async {
    final keyBytes = _decodeKey(base64Key);

    final input = File(inputPath);
    if (!await input.exists()) {
      throw const FilePickerFailure('Encrypted file no longer exists.');
    }
    if (await input.length() < ivLength + tagLength) {
      throw const EncryptionFailure(
        'Encrypted data is too short — likely not a SafeHouse file.',
      );
    }

    try {
      return await compute(
        _decryptEntryPoint,
        _DecryptJob(
          inputPath: inputPath,
          outputPath: outputPath,
          keyBytes: keyBytes,
        ),
      );
    } catch (_) {
      throw const EncryptionFailure(
        'Decryption failed — wrong key, tampered, or corrupt file.',
      );
    }
  }

  Uint8List _decodeKey(String base64Key) {
    if (!isValidKey(base64Key)) {
      throw const InvalidKeyFailure();
    }
    return Uint8List.fromList(base64Decode(base64Key));
  }
}

class _EncryptJob {
  final String inputPath;
  final String outputPath;
  final Uint8List keyBytes;
  final String? originalFileName;
  final Uint8List? salt;

  const _EncryptJob({
    required this.inputPath,
    required this.outputPath,
    required this.keyBytes,
    required this.originalFileName,
    this.salt,
  });
}

class _DecryptJob {
  final String inputPath;
  final String outputPath;
  final Uint8List keyBytes;

  const _DecryptJob({
    required this.inputPath,
    required this.outputPath,
    required this.keyBytes,
  });
}

Future<void> _encryptEntryPoint(_EncryptJob job) async {
  final iv = enc.IV.fromSecureRandom(AesEncryptionService.ivLength).bytes;

  final cipher = GCMBlockCipher(AESEngine())
    ..init(
      true,
      AEADParameters(
        KeyParameter(job.keyBytes),
        AesEncryptionService.tagLength * 8,
        iv,
        Uint8List(0),
      ),
    );

  final sink = File(job.outputPath).openWrite();
  try {
    if (job.salt != null) {
      final saltHeader = Uint8List(20);
      saltHeader[0] = AesEncryptionService.magicSalt0;
      saltHeader[1] = AesEncryptionService.magicSalt1;
      saltHeader[2] = AesEncryptionService.magicSalt2;
      saltHeader[3] = AesEncryptionService.magicSalt3;
      saltHeader.setRange(4, 20, job.salt!);
      sink.add(saltHeader);
    }

    sink.add(iv);

    var pending = <int>[];

    if (job.originalFileName != null && job.originalFileName!.isNotEmpty) {
      final nameBytes = Uint8List.fromList(utf8.encode(job.originalFileName!));
      if (nameBytes.length > 0xFFFF) {
        throw EncryptionFailure(
          'Filename too long (>65535 UTF-8 bytes): ${nameBytes.length}',
        );
      }
      final header = Uint8List(5 + nameBytes.length);
      header[0] = AesEncryptionService.magic0;
      header[1] = AesEncryptionService.magic1;
      header[2] = AesEncryptionService.headerVersion;
      header[3] = (nameBytes.length >> 8) & 0xFF;
      header[4] = nameBytes.length & 0xFF;
      header.setRange(5, 5 + nameBytes.length, nameBytes);

      pending.addAll(header);
    }

    await for (final chunk in File(job.inputPath).openRead()) {
      pending.addAll(chunk);
      if (pending.length >= 16) {
        final processLen = (pending.length ~/ 16) * 16;
        final toProcess = Uint8List.fromList(pending.sublist(0, processLen));
        final out = Uint8List(processLen + 32);
        final n = cipher.processBytes(toProcess, 0, processLen, out, 0);
        if (n > 0) sink.add(Uint8List.fromList(out.sublist(0, n)));
        pending = pending.sublist(processLen);
      }
    }

    if (pending.isNotEmpty) {
      final toProcess = Uint8List.fromList(pending);
      final out = Uint8List(toProcess.length + 32);
      final n = cipher.processBytes(toProcess, 0, toProcess.length, out, 0);
      if (n > 0) sink.add(Uint8List.fromList(out.sublist(0, n)));
    }

    final tail = Uint8List(32);
    final tailLen = cipher.doFinal(tail, 0);
    if (tailLen > 0) {
      final emitted = Uint8List.fromList(tail.sublist(0, tailLen));
      sink.add(emitted);
    }

    await sink.flush();
    await sink.close();
  } catch (e) {
    try {
      await sink.close();
    } catch (_) {}
    final destFile = File(job.outputPath);
    if (await destFile.exists()) {
      await destFile.delete();
    }
    rethrow;
  }
}

Future<String?> _decryptEntryPoint(_DecryptJob job) async {
  final input = File(job.inputPath);

  final ivHandle = await input.open();
  Uint8List iv;
  int offset = 0;
  try {
    final possibleSaltHeader = await ivHandle.read(20);
    if (possibleSaltHeader.length == 20 &&
        possibleSaltHeader[0] == AesEncryptionService.magicSalt0 &&
        possibleSaltHeader[1] == AesEncryptionService.magicSalt1 &&
        possibleSaltHeader[2] == AesEncryptionService.magicSalt2 &&
        possibleSaltHeader[3] == AesEncryptionService.magicSalt3) {
      offset = 20;
    }
    await ivHandle.setPosition(offset);
    iv = await ivHandle.read(AesEncryptionService.ivLength);
  } finally {
    await ivHandle.close();
  }

  final cipher = GCMBlockCipher(AESEngine())
    ..init(
      false,
      AEADParameters(
        KeyParameter(job.keyBytes),
        AesEncryptionService.tagLength * 8,
        iv,
        Uint8List(0),
      ),
    );

  final sink = File(job.outputPath).openWrite();
  final headerParser = _HeaderParser();

  try {
    var pending = <int>[];
    await for (final chunk in input.openRead(offset + AesEncryptionService.ivLength)) {
      pending.addAll(chunk);
      if (pending.length >= 16) {
        final processLen = (pending.length ~/ 16) * 16;
        final toProcess = Uint8List.fromList(pending.sublist(0, processLen));
        final out = Uint8List(processLen + 32);
        final n = cipher.processBytes(toProcess, 0, processLen, out, 0);
        if (n > 0) {
          final emitted = Uint8List.fromList(out.sublist(0, n));
          headerParser.feed(emitted, sink);
        }
        pending = pending.sublist(processLen);
      }
    }

    if (pending.isNotEmpty) {
      final toProcess = Uint8List.fromList(pending);
      final out = Uint8List(toProcess.length + 32);
      final n = cipher.processBytes(toProcess, 0, toProcess.length, out, 0);
      if (n > 0) {
        final emitted = Uint8List.fromList(out.sublist(0, n));
        headerParser.feed(emitted, sink);
      }
    }

    final tail = Uint8List(32);
    final tailLen = cipher.doFinal(tail, 0);
    if (tailLen > 0) {
      final emittedTail = Uint8List.fromList(tail.sublist(0, tailLen));
      headerParser.feed(emittedTail, sink);
    }

    headerParser.flushPending(sink);

    await sink.flush();
    await sink.close();
    return headerParser.originalName;
  } catch (err) {
    try {
      await sink.close();
    } catch (_) {}
    try {
      final partial = File(job.outputPath);
      if (await partial.exists()) await partial.delete();
    } catch (_) {}
    rethrow;
  }
}

class _HeaderParser {
  String? originalName;
  bool _decided = false;
  final List<int> _buf = <int>[];

  void feed(Uint8List bytes, IOSink sink) {
    if (_decided) {
      sink.add(bytes);
      return;
    }
    _buf.addAll(bytes);

    if (_buf.length < 3) return;

    final hasMagic = _buf[0] == AesEncryptionService.magic0 &&
        _buf[1] == AesEncryptionService.magic1 &&
        _buf[2] == AesEncryptionService.headerVersion;

    if (!hasMagic) {
      sink.add(Uint8List.fromList(_buf));
      _buf.clear();
      _decided = true;
      return;
    }

    if (_buf.length < 5) return;
    final nameLen = ((_buf[3] & 0xFF) << 8) | (_buf[4] & 0xFF);

    final totalHeaderLen = 5 + nameLen;
    if (_buf.length < totalHeaderLen) return;

    originalName = utf8.decode(_buf.sublist(5, totalHeaderLen));
    if (_buf.length > totalHeaderLen) {
      sink.add(Uint8List.fromList(_buf.sublist(totalHeaderLen)));
    }
    _buf.clear();
    _decided = true;
  }

  void flushPending(IOSink sink) {
    if (_decided) return;
    if (_buf.isNotEmpty) sink.add(Uint8List.fromList(_buf));
    _buf.clear();
    _decided = true;
  }
}
