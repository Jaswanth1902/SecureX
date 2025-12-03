import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';

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
    
    final buffer = StringBuffer('-----BEGIN RSA PUBLIC KEY-----\n');
    for (int i = 0; i < dataBase64.length; i += 64) {
      buffer.write('${dataBase64.substring(i, (i + 64 < dataBase64.length) ? i + 64 : dataBase64.length)}\n');
    }
    buffer.write('-----END RSA PUBLIC KEY-----');
    
    return buffer.toString();
  }

  Future<Uint8List> decryptSymmetricKey(String encryptedKeyBase64, pc.AsymmetricKeyPair keyPair) async {
    final privKey = keyPair.privateKey as pc.RSAPrivateKey;
    
    // Use 'encrypt' package for easy RSA decryption
    // Note: 'encrypt' package expects its own RSA key types or parsing.
    // We can construct them or use pointycastle directly.
    // Let's use pointycastle directly for OAEP since 'encrypt' might default to PKCS1v1.5
    
    final cipher = pc.OAEPEncoding(pc.RSAEngine());
    cipher.init(false, pc.PrivateKeyParameter<pc.RSAPrivateKey>(privKey)); // false = decrypt
    
    final encryptedBytes = base64Decode(encryptedKeyBase64);
    final decrypted = cipher.process(Uint8List.fromList(encryptedBytes));
    
    return decrypted;
  }
}
