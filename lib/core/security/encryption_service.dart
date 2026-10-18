import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Provides AES-GCM encryption for vault items and sensitive data.
class EncryptionService {
  final AesGcm _algorithm = AesGcm.with256bits();

  SecretKey? _secretKey;

  /// Derive an encryption key from a user-provided PIN or password.
  Future<void> deriveKey(String pin) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: utf8.encode('workspace_vault_salt'),
    );

    _secretKey = secretKey;
  }

  /// Encrypt a plaintext string. Returns a base64-encoded string
  /// containing the nonce + ciphertext + MAC.
  Future<String> encrypt(String plainText) async {
    if (_secretKey == null) {
      throw StateError('Key not derived. Call deriveKey() first.');
    }

    final secretBox = await _algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: _secretKey!,
    );

    // Combine nonce + ciphertext + mac into a single byte array
    final combined = Uint8List(
      secretBox.nonce.length +
          secretBox.cipherText.length +
          secretBox.mac.bytes.length,
    );
    var offset = 0;
    combined.setRange(offset, offset + secretBox.nonce.length, secretBox.nonce);
    offset += secretBox.nonce.length;
    combined.setRange(
        offset, offset + secretBox.cipherText.length, secretBox.cipherText);
    offset += secretBox.cipherText.length;
    combined.setRange(
        offset, offset + secretBox.mac.bytes.length, secretBox.mac.bytes);

    return base64Encode(combined);
  }

  /// Decrypt a base64-encoded encrypted string back to plaintext.
  Future<String> decrypt(String encryptedBase64) async {
    if (_secretKey == null) {
      throw StateError('Key not derived. Call deriveKey() first.');
    }

    final combined = base64Decode(encryptedBase64);

    // Extract nonce (12 bytes), mac (16 bytes), ciphertext (remaining)
    const nonceLength = 12;
    const macLength = 16;

    final nonce = combined.sublist(0, nonceLength);
    final macBytes = combined.sublist(combined.length - macLength);
    final cipherText =
        combined.sublist(nonceLength, combined.length - macLength);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final decrypted = await _algorithm.decrypt(
      secretBox,
      secretKey: _secretKey!,
    );

    return utf8.decode(decrypted);
  }

  /// Hash a PIN for secure storage (for vault lock verification).
  Future<String> hashPin(String pin) async {
    final algorithm = Sha256();
    final digest = await algorithm.hash(utf8.encode(pin));
    return base64Encode(digest.bytes);
  }

  /// Verify a PIN against a stored hash.
  Future<bool> verifyPin(String pin, String storedHash) async {
    final computed = await hashPin(pin);
    return computed == storedHash;
  }

  /// Check if a key has been derived (vault is unlocked).
  bool get isUnlocked => _secretKey != null;

  /// Lock the vault by clearing the key from memory.
  void lock() {
    _secretKey = null;
  }
}
