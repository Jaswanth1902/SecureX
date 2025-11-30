import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class EncryptionService {
  Future<Uint8List> decryptFileAES256(
    Uint8List encryptedData,
    Uint8List iv,
    Uint8List authTag,
    Uint8List key,
  ) async {
    try {
      final algorithm = AesGcm.with256bits();
      final secretBox = SecretBox(
        encryptedData,
        nonce: iv,
        mac: Mac(authTag),
      );

      final clear = await algorithm.decrypt(
        secretBox,
        secretKey: SecretKey(key),
      );

      return Uint8List.fromList(clear);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }
}
