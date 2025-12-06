import 'dart:convert';
import 'dart:io';
import 'dart:math';
// 'Uint8List' is available via `package:flutter/foundation.dart` so the
// explicit `dart:typed_data` import is not required here.

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:encrypt/encrypt.dart' as enc;

class KeyService {
  static const String _privateKeyFileName = 'owner_private_key.json';

  Future<pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>?> getStoredKeyPair() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_privateKeyFileName');

      if (!await file.exists()) {
        return null;
      }

      final jsonStr = await file.readAsString();
      final json = jsonDecode(jsonStr);
      
      final modulus = BigInt.parse(json['modulus']);
      final privateExponent = BigInt.parse(json['privateExponent']);
      final p = BigInt.parse(json['p']);
      final q = BigInt.parse(json['q']);
      final publicExponent = BigInt.parse(json['publicExponent']);

      final pubKey = pc.RSAPublicKey(modulus, publicExponent);
      final privKey = pc.RSAPrivateKey(modulus, privateExponent, p, q);

      return pc.AsymmetricKeyPair(pubKey, privKey);
    } catch (e) {
      debugPrint('Error reading key pair: $e');
      return null;
    }
  }

  Future<pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>> generateAndStoreKeyPair() async {
    final keyParams = pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64);
    final secureRandom = _getSecureRandom();
    final rngParams = pc.ParametersWithRandom(keyParams, secureRandom);
    
    final generator = pc.RSAKeyGenerator();
    generator.init(rngParams);
    
    final pair = generator.generateKeyPair();
    final pubKey = pair.publicKey as pc.RSAPublicKey;
    final privKey = pair.privateKey as pc.RSAPrivateKey;
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_privateKeyFileName');
    
    final json = {
      'modulus': pubKey.modulus.toString(),
      'publicExponent': pubKey.publicExponent.toString(),
      'privateExponent': privKey.privateExponent.toString(),
      'p': privKey.p.toString(),
      'q': privKey.q.toString(),
    };
    
    await file.writeAsString(jsonEncode(json));
    
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
    
    final sb = StringBuffer();
    sb.writeln('-----BEGIN RSA PUBLIC KEY-----');
    for (int i = 0; i < dataBase64.length; i += 64) {
      sb.writeln(dataBase64.substring(i, (i + 64 < dataBase64.length) ? i + 64 : dataBase64.length));
    }
    sb.write('-----END RSA PUBLIC KEY-----');

    return sb.toString();
  }



  Future<Uint8List> decryptSymmetricKey(String encryptedKeyBase64, pc.AsymmetricKeyPair keyPair) async {
    final privKey = keyPair.privateKey as pc.RSAPrivateKey;
    final pubKey = keyPair.publicKey as pc.RSAPublicKey;
    
    // Aggressively sanitize Base64 string (remove anything that isn't A-Z, a-z, 0-9, +, /, or =)
    String sanitizedBase64 = encryptedKeyBase64.replaceAll(RegExp(r'[^a-zA-Z0-9+/=]'), '');
    
    // Normalize (fix padding)
    try {
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
