import 'dart:convert';
import 'dart:io';

// Aliased to avoid a name clash with `Key` from `package:flutter/foundation`.
import 'package:encrypt/encrypt.dart' as enc show Key, IV;
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';

import '../../../../core/errors/failures.dart';

/// Stateless AES-256-GCM (AEAD) encryption/decryption service.
///
/// On-disk wire format:
///
///   `[IV (12 bytes)] || [ciphertext] || [auth tag (16 bytes)]`
///
/// Plaintext format (inside the ciphertext, version 0x01):
///
///   `[magic 0x53 0x46] || [version 0x01] || [nameLen u16-BE] ||
///    [filename UTF-8 bytes] || [original file bytes]`
///
/// Embedding the filename inside the *authenticated* plaintext means:
/// 1. Decryption can recover the original extension even if the Hive history
///    record is gone (e.g. reinstall, share-imported file).
/// 2. The auth tag covers the filename, so an attacker cannot mutate it
///    without producing a tag mismatch.
///
/// Files encrypted by older versions (no header) are still decryptable —
/// the decoder detects the absence of the magic bytes and treats the entire
/// plaintext as the file body.
class AesEncryptionService {
  static const int keyLength = 32; // 256-bit key
  static const int ivLength = 12; // 96-bit IV — GCM standard
  static const int tagLength = 16; // 128-bit auth tag

  // Header magic + version. Two ASCII bytes ("SF") + u8 version.
  static const int magic0 = 0x53;
  static const int magic1 = 0x46;
  static const int headerVersion = 0x01;

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

  /// Encrypts [inputPath] to [outputPath] using AES-256-GCM with [base64Key].
  ///
  /// Embeds [originalFileName] (if non-null) in the authenticated plaintext
  /// header, so decryption can recover the file extension without external
  /// metadata.
  Future<void> encryptFile({
    required String inputPath,
    required String outputPath,
    required String base64Key,
    String? originalFileName,
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
        ),
      );
    } catch (e) {
      throw EncryptionFailure('Encryption failed: $e');
    }
  }

  /// Decrypts [inputPath] to [outputPath] using AES-256-GCM with [base64Key].
  ///
  /// Returns the embedded original filename if the encrypted file carries a
  /// v1 header; returns `null` for legacy files without a header.
  ///
  /// Throws [EncryptionFailure] if the auth tag fails to verify — the most
  /// common cause is a wrong key, a tampered ciphertext, or a truncated file.
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Uint8List _decodeKey(String base64Key) {
    if (!isValidKey(base64Key)) {
      throw const InvalidKeyFailure();
    }
    return Uint8List.fromList(base64Decode(base64Key));
  }
}

// ── Isolate payloads ─────────────────────────────────────────────────────────

class _EncryptJob {
  final String inputPath;
  final String outputPath;
  final Uint8List keyBytes;
  final String? originalFileName;

  const _EncryptJob({
    required this.inputPath,
    required this.outputPath,
    required this.keyBytes,
    required this.originalFileName,
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

// ── Top-level isolate entry points ───────────────────────────────────────────

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
    sink.add(iv);

    // Header (only when caller supplied a filename — otherwise legacy format).
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

      debugPrint(
        '[Enc] header bytes=${header.length} name="${job.originalFileName}"',
      );

      final out = Uint8List(header.length + 32);
      final n = cipher.processBytes(header, 0, header.length, out, 0);
      debugPrint('[Enc] header processBytes emitted n=$n');
      if (n > 0) sink.add(Uint8List.fromList(out.sublist(0, n)));
    }

    var encChunk = 0;
    var totalCt = 0;
    await for (final chunk in File(job.inputPath).openRead()) {
      final data = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
      final out = Uint8List(data.length + 32);
      final n = cipher.processBytes(data, 0, data.length, out, 0);
      debugPrint('[Enc] chunk#$encChunk in=${data.length} ct=$n');
      encChunk++;
      if (n > 0) {
        final emitted = Uint8List.fromList(out.sublist(0, n));
        totalCt += emitted.length;
        sink.add(emitted);
      }
    }

    final tail = Uint8List(32);
    final tailLen = cipher.doFinal(tail, 0);
    debugPrint('[Enc] doFinal tailLen=$tailLen');
    if (tailLen > 0) {
      final emitted = Uint8List.fromList(tail.sublist(0, tailLen));
      totalCt += emitted.length;
      sink.add(emitted);
    }
    debugPrint('[Enc] totalCiphertext=$totalCt (excludes IV)');

    await sink.flush();
  } finally {
    await sink.close();
  }
}

Future<String?> _decryptEntryPoint(_DecryptJob job) async {
  final input = File(job.inputPath);

  // Read the first 12 bytes (IV) for cipher init.
  final ivHandle = await input.open();
  Uint8List iv;
  try {
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
    var chunkIdx = 0;
    var totalBytesWritten = 0;
    await for (final chunk in input.openRead(AesEncryptionService.ivLength)) {
      final data = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
      final out = Uint8List(data.length + 32);
      final n = cipher.processBytes(data, 0, data.length, out, 0);
      debugPrint(
        '[Dec] chunk#$chunkIdx in=${data.length} pt=$n decided=${headerParser._decided}',
      );
      chunkIdx++;
      if (n > 0) {
        // Copy-out to detach from `out` (defensive against any PC reuse).
        final emitted = Uint8List.fromList(out.sublist(0, n));
        totalBytesWritten += emitted.length;
        headerParser.feed(emitted, sink);
      }
    }

    final tail = Uint8List(32);
    final tailLen = cipher.doFinal(tail, 0);
    debugPrint('[Dec] doFinal tailLen=$tailLen');
    if (tailLen > 0) {
      final emittedTail = Uint8List.fromList(tail.sublist(0, tailLen));
      totalBytesWritten += emittedTail.length;
      headerParser.feed(emittedTail, sink);
    }
    debugPrint('[Dec] totalPlaintext=$totalBytesWritten');

    // No more bytes — flush whatever is still buffered (legacy file with
    // a body shorter than the magic-byte probe length).
    headerParser.flushPending(sink);

    debugPrint('[Dec] done. extractedName="${headerParser.originalName}"');

    await sink.flush();
    await sink.close();
    return headerParser.originalName;
  } catch (err) {
    try {
      await sink.close();
    } catch (_) {
      /* already closed */
    }
    try {
      final partial = File(job.outputPath);
      if (await partial.exists()) await partial.delete();
    } catch (_) {
      /* best effort */
    }
    rethrow;
  }
}

/// Streaming parser for the optional v1 plaintext header.
///
/// Buffers decrypted output until it knows whether bytes 0..2 are the magic
/// + version. If yes, parses [nameLen, filename] then forwards remainder to
/// the sink. If no, dumps everything to the sink (legacy path).
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

    // Need ≥3 bytes to check magic+version.
    if (_buf.length < 3) return;

    final hasMagic = _buf[0] == AesEncryptionService.magic0 &&
        _buf[1] == AesEncryptionService.magic1 &&
        _buf[2] == AesEncryptionService.headerVersion;

    if (!hasMagic) {
      // Legacy file — pass everything through verbatim.
      sink.add(Uint8List.fromList(_buf));
      _buf.clear();
      _decided = true;
      return;
    }

    // Need ≥5 bytes for u16-BE name length.
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

  /// Drain anything still buffered when the input ends. This covers the
  /// edge case where a legacy file's plaintext is shorter than 3 bytes,
  /// or where the header was complete but no body bytes followed.
  void flushPending(IOSink sink) {
    if (_decided) return;
    if (_buf.isNotEmpty) sink.add(Uint8List.fromList(_buf));
    _buf.clear();
    _decided = true;
  }
}
