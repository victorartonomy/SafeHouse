import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart';

void main() {
  final key = enc.Key.fromSecureRandom(32).bytes;
  final iv = enc.IV.fromSecureRandom(12).bytes;
  
  final cipher = GCMBlockCipher(AESEngine())
    ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    
  final data = Uint8List.fromList(List.generate(40, (i) => i));
  final ciphertext = <int>[];
  
  for (int i = 0; i < data.length; i++) {
    ciphertext.add(cipher.processByte(data[i]));
  }
  
  final outFinal = Uint8List(32);
  final nf = cipher.doFinal(outFinal, 0);
  ciphertext.addAll(outFinal.sublist(0, nf));
  
  final decipher = GCMBlockCipher(AESEngine())
    ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    
  final decOut = <int>[];
  for (int i = 0; i < ciphertext.length; i++) {
    decOut.add(decipher.processByte(ciphertext[i]));
  }
  final dn3 = Uint8List(32);
  final dnFinal = decipher.doFinal(dn3, 0);
  decOut.addAll(dn3.sublist(0, dnFinal));
  
  print('Original: $data');
  print('Decrypted: $decOut');
}
