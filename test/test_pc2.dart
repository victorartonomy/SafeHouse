import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PointyCastle bug test', () {
    final key = enc.Key.fromSecureRandom(32).bytes;
    final iv = enc.IV.fromSecureRandom(12).bytes;
    
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
      
    final chunk1 = Uint8List.fromList([10, 11, 12]);
    final chunk2 = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]);
    
    final out1 = Uint8List(100);
    final n1 = cipher.processBytes(chunk1, 0, chunk1.length, out1, 0);
    
    final out2 = Uint8List(100);
    final n2 = cipher.processBytes(chunk2, 0, chunk2.length, out2, 0);
    
    final out3 = Uint8List(100);
    final n3 = cipher.doFinal(out3, 0);
    
    final ciphertext = Uint8List(n1 + n2 + n3);
    ciphertext.setRange(0, n1, out1.sublist(0, n1));
    ciphertext.setRange(n1, n1 + n2, out2.sublist(0, n2));
    ciphertext.setRange(n1 + n2, n1 + n2 + n3, out3.sublist(0, n3));
    
    final decipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
      
    final decOut = Uint8List(100);
    final dn = decipher.processBytes(ciphertext, 0, ciphertext.length, decOut, 0);
    final dn2 = decipher.doFinal(decOut, dn);
    
    final decBytes = decOut.sublist(0, dn + dn2);
    print('Decrypted bytes: $decBytes');
    
    expect(decBytes.sublist(0, 3), [10, 11, 12]);
    expect(decBytes.sublist(3), chunk2);
  });
}
