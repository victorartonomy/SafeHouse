import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart';

void main() {
  final key = enc.Key.fromSecureRandom(32).bytes;
  final iv = enc.IV.fromSecureRandom(12).bytes;
  
  final cipher = GCMBlockCipher(AESEngine())
    ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    
  final data = Uint8List.fromList(List.generate(40, (i) => i));
  final ciphertext = Uint8List(100);
  final cn = cipher.processBytes(data, 0, data.length, ciphertext, 0);
  final cn2 = cipher.doFinal(ciphertext, cn);
  final ct = ciphertext.sublist(0, cn + cn2);
  
  final decipher = GCMBlockCipher(AESEngine())
    ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    
  final ctChunk1 = ct.sublist(0, 32);
  final ctChunk2 = ct.sublist(32);
  
  final decOut1 = Uint8List(100);
  final dn1 = decipher.processBytes(ctChunk1, 0, ctChunk1.length, decOut1, 0);
  
  final decOut2 = Uint8List(100);
  final dn2 = decipher.processBytes(ctChunk2, 0, ctChunk2.length, decOut2, 0);
  
  final decOut3 = Uint8List(100);
  final dn3 = decipher.doFinal(decOut3, 0);
  
  final result = [...decOut1.sublist(0, dn1), ...decOut2.sublist(0, dn2), ...decOut3.sublist(0, dn3)];
  print('Original: $data');
  print('Decrypted: $result');
}
