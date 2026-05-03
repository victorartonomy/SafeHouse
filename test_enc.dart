import 'dart:io';
import 'dart:typed_data';
import 'package:safe_house/features/encryption/data/datasources/aes_encryption_service.dart';

void main() async {
  final service = AesEncryptionService();
  final key = service.generateKey();
  
  // Create a 2MB dummy file
  final dummyFile = File('dummy.jpg');
  final originalBytes = Uint8List(2 * 1024 * 1024);
  for (int i = 0; i < originalBytes.length; i++) {
    originalBytes[i] = i % 256;
  }
  await dummyFile.writeAsBytes(originalBytes);
  
  print('Original size: ${await dummyFile.length()}');
  
  final salt = Uint8List.fromList(List.generate(16, (i) => i));
  await service.encryptFile(
    inputPath: 'dummy.jpg',
    outputPath: 'dummy.enc',
    base64Key: key,
    originalFileName: 'dummy.jpg',
    salt: salt,
  );
  
  final encFile = File('dummy.enc');
  print('Encrypted size: ${await encFile.length()}');
  
  final extractedName = await service.decryptFile(
    inputPath: 'dummy.enc',
    outputPath: 'dummy_dec.jpg',
    base64Key: key,
  );
  
  print('Extracted name: $extractedName');
  
  final decFile = File('dummy_dec.jpg');
  print('Decrypted size: ${await decFile.length()}');
  
  final decBytes = await decFile.readAsBytes();
  var same = originalBytes.length == decBytes.length;
  if (same) {
    for (int i = 0; i < originalBytes.length; i++) {
      if (originalBytes[i] != decBytes[i]) {
        same = false;
        print('Mismatch at $i: ${originalBytes[i]} != ${decBytes[i]}');
        break;
      }
    }
  }
  print('Content same: $same');
}
