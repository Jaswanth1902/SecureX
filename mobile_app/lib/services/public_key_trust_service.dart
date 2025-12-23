// ========================================
// PUBLIC KEY TRUST SERVICE
// Implements Trust-On-First-Use (TOFU) for RSA public keys
// Prevents man-in-the-middle attacks
// ========================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../utils/secure_logger.dart';

class PublicKeyTrustService {
  static const String _trustStoreKey = 'trusted_public_keys';
  
  // ========================================
  // CALCULATE KEY FINGERPRINT
  // ========================================
  
  /// Calculate SHA256 fingerprint of a public key PEM
  /// This creates a unique hash that identifies the key
  static String calculateFingerprint(String publicKeyPem) {
    // Remove PEM headers and whitespace
    final keyContent = publicKeyPem
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll(' ', '');
    
    // Calculate SHA256 hash
    final bytes = utf8.encode(keyContent);
    final digest = sha256.convert(bytes);
    
    // Format as colon-separated hex (e.g., AA:BB:CC:DD...)
    final hexString = digest.toString();
    final formatted = StringBuffer();
    for (int i = 0; i < hexString.length; i += 2) {
      if (i > 0) formatted.write(':');
      formatted.write(hexString.substring(i, i + 2).toUpperCase());
    }
    
    return formatted.toString();
  }
  
  // ========================================
  // TRUST MANAGEMENT
  // ========================================
  
  /// Get trusted fingerprint for an owner ID
  static Future<String?> getTrustedFingerprint(String ownerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trustStore = prefs.getString(_trustStoreKey);
      
      if (trustStore == null) return null;
      
      final Map<String, dynamic> store = jsonDecode(trustStore);
      return store[ownerId] as String?;
    } catch (e) {
      SecureLogger.error('Failed to get trusted fingerprint', e);
      return null;
    }
  }
  
  /// Store a fingerprint as trusted for an owner ID
  static Future<void> trustFingerprint(String ownerId, String fingerprint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trustStore = prefs.getString(_trustStoreKey);
      
      Map<String, dynamic> store = {};
      if (trustStore != null) {
        store = jsonDecode(trustStore);
      }
      
      store[ownerId] = fingerprint;
      await prefs.setString(_trustStoreKey, jsonEncode(store));
      
      SecureLogger.info('Fingerprint trusted for owner: $ownerId');
    } catch (e) {
      SecureLogger.error('Failed to  trust fingerprint', e);
      rethrow;
    }
  }
  
  /// Remove trust for an owner ID (force re-verification)
  static Future<void> removeTrust(String ownerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trustStore = prefs.getString(_trustStoreKey);
      
      if (trustStore == null) return;
      
      final Map<String, dynamic> store = jsonDecode(trustStore);
      store.remove(ownerId);
      await prefs.setString(_trustStoreKey, jsonEncode(store));
      
      SecureLogger.info('Trust removed for owner: $ownerId');
    } catch (e) {
      SecureLogger.error('Failed to remove trust', e);
    }
  }
  
  // ========================================
  // VERIFICATION (TOFU)
  // ========================================
  
  /// Verify a public key against stored trust
  /// Returns verification result with details
  static Future<KeyVerificationResult> verifyKey(
    String ownerId,
    String publicKeyPem,
  ) async {
    final currentFingerprint = calculateFingerprint(publicKeyPem);
    final trustedFingerprint = await getTrustedFingerprint(ownerId);
    
    if (trustedFingerprint == null) {
      // First time seeing this owner's key
      return KeyVerificationResult(
        isValid: false,
        isTrusted: false,
        fingerprint: currentFingerprint,
        reason: KeyVerificationReason.firstUse,
        message: 'This is the first time you are connecting to this owner. '
                 'Please verify the key fingerprint before proceeding.',
      );
    }
    
    if (currentFingerprint == trustedFingerprint) {
      // Key matches stored trust
      return KeyVerificationResult(
        isValid: true,
        isTrusted: true,
        fingerprint: currentFingerprint,
        reason: KeyVerificationReason.trusted,
        message: 'Public key verified successfully.',
      );
    }
    
    // Key has changed - SECURITY ALERT!
    return KeyVerificationResult(
      isValid: false,
      isTrusted: false,
      fingerprint: currentFingerprint,
      reason: KeyVerificationReason.keyChanged,
      message: '⚠️ SECURITY WARNING: The owner\'s public key has changed! '
               'This could indicate a man-in-the-middle attack. '
               'Only proceed if you trust the network and the owner.',
      previousFingerprint: trustedFingerprint,
    );
  }
  
  // ========================================
  // UTILITY
  // ========================================
  
  /// Get all trusted owners
  static Future<List<String>> getTrustedOwners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trustStore = prefs.getString(_trustStoreKey);
      
      if (trustStore == null) return [];
      
      final Map<String, dynamic> store = jsonDecode(trustStore);
      return store.keys.toList();
    } catch (e) {
      SecureLogger.error('Failed to get trusted owners', e);
      return [];
    }
  }
  
  /// Clear all trust (use with caution)
  static Future<void> clearAllTrust() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_trustStoreKey);
      SecureLogger.warning('All public key trust cleared');
    } catch (e) {
      SecureLogger.error('Failed to clear trust', e);
    }
  }
}

// ========================================
// VERIFICATION RESULT
// ========================================

class KeyVerificationResult {
  final bool isValid;
  final bool isTrusted;
  final String fingerprint;
  final KeyVerificationReason reason;
  final String message;
  final String? previousFingerprint;
  
  KeyVerificationResult({
    required this.isValid,
    required this.isTrusted,
    required this.fingerprint,
    required this.reason,
    required this.message,
    this.previousFingerprint,
  });
  
  /// Format fingerprint for display (show first 16 chars)
  String get shortFingerprint {
    if (fingerprint.length <= 47) return fingerprint;
    return '${fingerprint.substring(0, 47)}...';
  }
}

// ========================================
// VERIFICATION REASONS
// ========================================

enum KeyVerificationReason {
  firstUse,    // First time seeing this key
  trusted,     // Key matches stored trust
  keyChanged,  // Key has changed (security alert!)
}
