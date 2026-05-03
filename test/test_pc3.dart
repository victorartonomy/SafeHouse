import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PointyCastle bug workaround', () {
    final key = enc.Key.fromSecureRandom(32).bytes;
    final iv = enc.IV.fromSecureRandom(12).bytes;
    
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
      
    final chunk1 = Uint8List.fromList([10, 11, 12]);
    final chunk2 = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]);
    
    final allBytes = [...chunk1, ...chunk2];
    var offset = 0;
    
    final ciphertext = <int>[];
    
    while (allBytes.length - offset >= 16) {
      final block = Uint8List.fromList(allBytes.sublist(offset, offset + 16));
      final out = Uint8List(16);
      cipher.processBytes(block, 0, 16, out, 0);
      ciphertext.addAll(out);
      offset += 16;
    }
    
    if (offset < allBytes.length) {
      final block = Uint8List.fromList(allBytes.sublist(offset));
      final out = Uint8List(16);
      final n = cipher.processBytes(block, 0, block.length, out, 0);
      ciphertext.addAll(out.sublist(0, n));
    }
    
    final outFinal = Uint8List(16);
    final nf = cipher.doFinal(outFinal, 0);
    ciphertext.addAll(outFinal.sublist(0, nf));
    
    final decCipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
      
    final decOut = Uint8List(ciphertext.length);
    final dn = decCipher.processBytes(Uint8List.fromList(ciphertext), 0, ciphertext.length, decOut, 0);
    final dn2 = decCipher.doFinal(decOut, dn);
    
    final decBytes = decOut.sublist(0, dn + dn2);
    print('Decrypted bytes: $decBytes');
    expect(decBytes.sublist(0, 3), [10, 11, 12]);
    expect(decBytes.sublist(3), chunk2);
  });
}
