import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_house/features/encryption/data/datasources/aes_encryption_service.dart';

void main() {
  test('Encryption/Decryption bit-for-bit test', () async {
    final service = AesEncryptionService();
    final key = service.generateKey();
    
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
    final encBytes = await encFile.readAsBytes();
    print('Encrypted: ${encBytes.sublist(0, 50)}');
    
    final extractedName = await service.decryptFile(
      inputPath: 'dummy.enc',
      outputPath: 'dummy_dec.jpg',
      base64Key: key,
    );
    
    print('Extracted name: $extractedName');
    
    final decFile = File('dummy_dec.jpg');
    print('Decrypted size: ${await decFile.length()}');
    
    final decBytes = await decFile.readAsBytes();
    expect(originalBytes.length, decBytes.length, reason: 'Size mismatch');
    
    print('Original: ${originalBytes.sublist(0, 20)}');
    print('Decrypted: ${decBytes.sublist(0, 20)}');
    
    var same = true;
    for (int i = 0; i < originalBytes.length; i++) {
      if (originalBytes[i] != decBytes[i]) {
        same = false;
        print('Mismatch at $i: ${originalBytes[i]} != ${decBytes[i]}');
        break;
      }
    }
    expect(same, isTrue, reason: 'Content mismatch');
  });
}
