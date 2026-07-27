import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoService {
  static const String _keyStorageKey = 'yastik6_encryption_key';

  final FlutterSecureStorage _secureStorage;
  encrypt.Key? _encryptionKey;

  // Dependency Injection ile test edilebilir yapıyı koruyoruz
  CryptoService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Uygulama başlarken çağrılır. Anahtarı donanımdan çeker veya yeni üretir.
  Future<void> init() async {
    String? base64Key = await _secureStorage.read(key: _keyStorageKey);

    if (base64Key == null) {
      // 32 byte (256 bit) rastgele güvenli anahtar üretimi
      final secureRandomKey = encrypt.Key.fromSecureRandom(32);
      base64Key = base64.encode(secureRandomKey.bytes);

      // Üretilen anahtarı donanım kasasına kaydet
      await _secureStorage.write(key: _keyStorageKey, value: base64Key);
    }

    // Şifreleme işlemlerinde kullanmak üzere anahtarı hafızaya al
    _encryptionKey = encrypt.Key.fromBase64(base64Key);
  }

  /// Dışarı aktarılacak saf veriyi AES-256 ile şifreler.
  String encryptData(String rawData) {
    if (_encryptionKey == null) {
      throw Exception("CryptoService is not initialized. Call init() first.");
    }

    // Her şifrelemede benzersiz bir Başlangıç Vektörü (IV) üret (16 byte)
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));

    final encrypted = encrypter.encrypt(rawData, iv: iv);

    // IV ve şifreli veriyi çözme aşamasında ayırabilmek için birleştirerek döndür
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Buluttan gelen şifreli veriyi tekrar okunabilir hale getirir.
  String decryptData(String encryptedPayload) {
    if (_encryptionKey == null) {
      throw Exception("CryptoService is not initialized. Call init() first.");
    }

    // IV ve asıl şifreli veriyi ayır
    final parts = encryptedPayload.split(':');
    if (parts.length != 2) {
      throw const FormatException("Invalid encrypted payload format.");
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);

    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));

    // Şifreyi çöz ve orijinal veriyi döndür
    return encrypter.decrypt(encryptedData, iv: iv);
  }

  /// Veritabanı gibi binary dosyaları şifrelemek için yardımcı metot
  String encryptBytes(List<int> bytes) {
    final base64Data = base64.encode(bytes);
    return encryptData(base64Data);
  }

  /// Şifreli veriyi çözüp tekrar binary dosyaya dönüştürmek için yardımcı metot
  List<int> decryptToBytes(String encryptedPayload) {
    final decryptedString = decryptData(encryptedPayload);
    return base64.decode(decryptedString);
  }
}