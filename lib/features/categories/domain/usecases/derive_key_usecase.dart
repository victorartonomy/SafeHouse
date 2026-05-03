import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';

/// Derives a 256-bit AES key from a user password + per-category salt using
/// PBKDF2-HMAC-SHA256 with 100,000 iterations.
///
/// Output is base64-encoded so it is drop-in compatible with the existing
/// `AesEncryptionService` which expects a base64 key string.
class DeriveKeyUseCase {
  static const int _iterations = 100000;
  static const int _keyLength = 32; // 256 bits

  String call({required String password, required Uint8List salt}) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _iterations, _keyLength));
    final keyBytes = derivator.process(
      Uint8List.fromList(utf8.encode(password)),
    );
    return base64Encode(keyBytes);
  }
}
