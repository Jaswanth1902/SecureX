import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:encrypt/encrypt.dart' as enc;

class KeyService {
  static const String _privateKeyFileName = 'owner_private_key.json';

  Future<pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>?> getStoredKeyPair(String userEmail) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      // Sanitize email for filename
      final safeEmail = userEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final file = File('${directory.path}/private_key_$safeEmail.json');

      if (!await file.exists()) {
        // Fallback: Check for legacy global key file
        final legacyFile = File('${directory.path}/owner_private_key.json');
        if (await legacyFile.exists()) {
           debugPrint('Warning: Using legacy key file. Consider migrating.');
           // Use legacy logic to read it
           final jsonStr = await legacyFile.readAsString();
           final json = jsonDecode(jsonStr);
           // ... (rest of parsing logic is same, helper method ideally)
           return _parseKeyJson(json);
        }
        return null; // No key found
      }

      final jsonStr = await file.readAsString();
      final jsonMap = jsonDecode(jsonStr);
      
      // Check if encrypted (v1_aes)
      if (jsonMap.containsKey('version') && jsonMap['version'] == 'v1_aes') {
         try {
           final key = enc.Key.fromUtf8('SafeCopy_Owner_Key_Storage_2025!');
           final iv = enc.IV.fromBase64(jsonMap['iv']);
           final encrypter = enc.Encrypter(enc.AES(key));
           
           final decrypted = encrypter.decrypt64(jsonMap['data'], iv: iv);
           return _parseKeyJson(jsonDecode(decrypted));
         } catch (e) {
           debugPrint('Error decrypting key file: $e');
           // Fallback or rethrow? If we can't decrypt, we can't use it.
           return null;
         }
      }
      
      // Fallback for old plain-text files
      return _parseKeyJson(jsonMap);

    } catch (e) {
      debugPrint('Error reading key pair: $e');
      return null;
    }
  }

  pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey> _parseKeyJson(Map<String, dynamic> json) {
      final modulus = BigInt.parse(json['modulus']);
      final privateExponent = BigInt.parse(json['privateExponent']);
      final p = BigInt.parse(json['p']);
      final q = BigInt.parse(json['q']);
      final publicExponent = BigInt.parse(json['publicExponent']);

      final pubKey = pc.RSAPublicKey(modulus, publicExponent);
      final privKey = pc.RSAPrivateKey(modulus, privateExponent, p, q);

      return pc.AsymmetricKeyPair(pubKey, privKey);
  }

  Future<pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>> generateAndStoreKeyPair(String userEmail) async {
    final keyParams = pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64);
    final secureRandom = _getSecureRandom();
    final rngParams = pc.ParametersWithRandom(keyParams, secureRandom);
    
    final generator = pc.RSAKeyGenerator();
    generator.init(rngParams);
    
    final pair = generator.generateKeyPair();
    final pubKey = pair.publicKey as pc.RSAPublicKey;
    final privKey = pair.privateKey as pc.RSAPrivateKey;
    
    final directory = await getApplicationDocumentsDirectory();
    final safeEmail = userEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final file = File('${directory.path}/private_key_$safeEmail.json');
    
    final jsonMap = {
      'modulus': pubKey.modulus.toString(),
      'publicExponent': pubKey.publicExponent.toString(),
      'privateExponent': privKey.privateExponent.toString(),
      'p': privKey.p.toString(),
      'q': privKey.q.toString(),
    };
    
    // Security Fix #11: Encrypt private key file at rest (obfuscation)
    // Using a derived key from device ID or hardcoded salt (in this context) prevents plain text ready access
    // Ideally this would be user-password derived, but for automated service usage we use a fixed obfuscation key
    final key = enc.Key.fromUtf8('SafeCopy_Owner_Key_Storage_2025!'); // 32 chars
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    
    final plainText = jsonEncode(jsonMap);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    // Store encrypted data + IV
    final storageData = jsonEncode({
      'iv': iv.base64,
      'data': encrypted.base64,
      'version': 'v1_aes'
    });
    
    await file.writeAsString(storageData);
    
    return pc.AsymmetricKeyPair(pubKey, privKey);
  }
  
  pc.SecureRandom _getSecureRandom() {
    final secureRandom = pc.FortunaRandom();
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(255));
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }
  
  Future<String> getPublicKeyPem(pc.RSAPublicKey publicKey) async {
    // Simple PEM encoding for RSA Public Key (PKCS#1)
    // Sequence(Integer(n), Integer(e))
    
    final topLevel = ASN1Sequence();
    topLevel.add(ASN1Integer(publicKey.modulus));
    topLevel.add(ASN1Integer(publicKey.publicExponent));
    
    final dataBase64 = base64Encode(topLevel.encode());
    
    String pem = '-----BEGIN RSA PUBLIC KEY-----\n';
    for (int i = 0; i < dataBase64.length; i += 64) {
      pem += dataBase64.substring(i, (i + 64 < dataBase64.length) ? i + 64 : dataBase64.length) + '\n';
    }
    pem += '-----END RSA PUBLIC KEY-----';
    
    return pem;
  }



  Future<Uint8List> decryptSymmetricKey(String encryptedKeyBase64, pc.AsymmetricKeyPair keyPair) async {
    final privKey = keyPair.privateKey as pc.RSAPrivateKey;
    final pubKey = keyPair.publicKey as pc.RSAPublicKey;
    
    // Aggressively sanitize Base64 string but allow URL-safe chars (- and _)
    String sanitizedBase64 = encryptedKeyBase64.replaceAll(RegExp(r'[^a-zA-Z0-9+/=_ -]'), '');
    
    // Normalize (fix padding and replace URL safe chars with standard)
    try {
      sanitizedBase64 = sanitizedBase64.replaceAll('-', '+').replaceAll('_', '/');
      sanitizedBase64 = base64.normalize(sanitizedBase64);
    } catch (e) {
      debugPrint('Warning: base64.normalize failed: $e');
    }

    debugPrint('DEBUG: Full Key for Inspection (Sanitized):');
    debugPrint(sanitizedBase64);

    try {
      // Use 'encrypt' package which supports SHA-256 OAEP easily
      final encrypter = enc.Encrypter(enc.RSA(
        publicKey: pubKey,
        privateKey: privKey,
        encoding: enc.RSAEncoding.OAEP,
        digest: enc.RSADigest.SHA256,
      ));

      final encrypted = enc.Encrypted.fromBase64(sanitizedBase64);
      final decrypted = encrypter.decryptBytes(encrypted);
      
      return Uint8List.fromList(decrypted);
    } catch (e) {
      debugPrint('CRITICAL ERROR in decryptSymmetricKey: $e');
      rethrow;
    }
  }
}
