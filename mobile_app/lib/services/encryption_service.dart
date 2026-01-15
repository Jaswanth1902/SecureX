// ========================================
// ENCRYPTION SERVICE - MOBILE APP
// Uses package:cryptography for AES-256-GCM
// ========================================

import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/asymmetric/api.dart';


class EncryptionService {
  // ========================================
  // GENERATE AES-256 KEY
  // ========================================

  Uint8List generateAES256Key() {
    final rnd = Random.secure();
    final key = Uint8List(32);
    for (int i = 0; i < key.length; i++) {
      key[i] = rnd.nextInt(256);
    }
    return key;
  }

  // ========================================
  // ENCRYPT KEY - RSA-2048-OAEP (encrypt/pointycastle)
  // ========================================

  Future<String> encryptSymmetricKeyRSA(Uint8List aesKey, String publicKeyPem) async {
    try {
      final parser = enc.RSAKeyParser();
      final publicKey = parser.parse(publicKeyPem) as RSAPublicKey;
      
      final encrypter = enc.Encrypter(enc.RSA(
        publicKey: publicKey,
        encoding: enc.RSAEncoding.OAEP,
        digest: enc.RSADigest.SHA256,
      ));
      
      final encrypted = encrypter.encryptBytes(aesKey);
      return encrypted.base64;
    } catch (e) {
      throw EncryptionException('RSA Encryption failed: $e');
    }
  }

  // ========================================
  // ENCRYPT FILE - AES-256-GCM (cryptography)
  // ========================================

  Future<Map<String, dynamic>> encryptFileAES256(
    Uint8List fileData,
    Uint8List key,
  ) async {
    try {
      // Recommended IV length for AES-GCM is 12 bytes
      final rnd = Random.secure();
      final iv = Uint8List(12);
      for (int i = 0; i < iv.length; i++) {
        iv[i] = rnd.nextInt(256);
      }

      final algorithm = AesGcm.with256bits();
      final secretKey = SecretKey(key);

      final secretBox = await algorithm.encrypt(
        fileData,
        secretKey: secretKey,
        nonce: iv,
      );

      final cipherText = Uint8List.fromList(secretBox.cipherText);
      final authTag = Uint8List.fromList(secretBox.mac.bytes);

      // SECURITY FIX: Do NOT return the key in the result
      // Key should be immediately encrypted with RSA and then securely wiped
      return {
        'encrypted': cipherText,
        'iv': iv,
        'authTag': authTag,
        // 'key': key, // REMOVED - Security vulnerability fixed (Bug #33)
      };
    } catch (e, st) {
      final message = 'Encryption failed: $e\n$st';
      throw EncryptionException(message);
    }
  }

  // ========================================
  // DECRYPT FILE - AES-256-GCM (cryptography)
  // ========================================

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
    } catch (e, st) {
      final message = 'Decryption failed: $e\n$st';
      throw EncryptionException(message);
    }
  }

  // ========================================
  // HASH FILE - SHA-256 (cryptography)
  // ========================================

  Future<String> hashFileSHA256(Uint8List data) async {
    final sha256 = Sha256();
    final hash = await sha256.hash(data);
    return base64Encode(hash.bytes);
  }

  // ========================================
  // SHRED DATA - OVERWRITE MEMORY
  // ========================================

  void shredData(Uint8List data) {
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < data.length; j++) {
        data[j] = (i % 2 == 0) ? 0xFF : 0x00;
      }
    }
  }

  // ========================================
  // VERIFY ENCRYPTION
  // ========================================

  Future<bool> verifyEncryption(
    Uint8List originalData,
    Map<String, dynamic> encryptionResult,
  ) async {
    try {
      final decrypted = await decryptFileAES256(
        encryptionResult['encrypted'],
        encryptionResult['iv'],
        encryptionResult['authTag'],
        encryptionResult['key'],
      );
      return _bytesEqual(originalData, decrypted);
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // HELPER: COMPARE BYTES
  // ========================================

  bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ========================================
// ENCRYPTION EXCEPTION
// ========================================

class EncryptionException implements Exception {
  final String message;

  EncryptionException(this.message);

  @override
  String toString() => message;
}
