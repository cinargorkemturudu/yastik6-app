import 'dart:ui'; // PlatformDispatcher için gerekli
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/app.dart';
import 'package:yastik_alti/core/app_log.dart';
import 'package:yastik_alti/di/providers.dart';
import 'package:yastik_alti/data/local/local_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Global Flutter UI Çökmelerini (Red Screen of Death) Yakalama
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details); // Geliştirme aşamasında ekranda da görmek için
    AppLog.error(
      'Fatal UI Crash: ${details.exceptionAsString()}',
      domain: 'GLOBAL_BOUNDARY',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // 2. Global Asenkron (Dart Isolate/Future) Çökmelerini Yakalama
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppLog.error(
      'Unhandled Asynchronous Crash',
      domain: 'GLOBAL_BOUNDARY',
      error: error,
      stackTrace: stack,
    );
    return true; // Framework'e "bu hatayı ben ele aldım, uygulamayı zorla kapatma" diyoruz.
  };

  try {
    // 3. Doğru şemaya sahip veritabanını Singleton üzerinden açıyoruz
    final db = await LocalDatabase.instance.database;

    runApp(
      ProviderScope(
        overrides: [
          // StateProvider olduğu için syntax overrideWith((ref) => db) şekline döndü
          databaseProvider.overrideWith((ref) => db),
        ],
        child: const MyApp(),
      ),
    );
  } catch (error, stackTrace) {
    AppLog.error(
      'Critical Startup Failure: Could not initialize app dependencies',
      domain: 'GLOBAL_BOUNDARY',
      error: error,
      stackTrace: stackTrace,
    );

    // Anti-Pattern Koruması: Başlangıçta veritabanı veya kritik bir bağımlılık çökerse
    runApp(const FallbackUI());
  }
}

/// Çökme durumunda gösterilecek acil durum arayüzü (Silent Failure engelleyici)
class FallbackUI extends StatelessWidget {
  const FallbackUI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF121212), // AppColors.background eşdeğeri
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Uygulama Başlatılamadı',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Kritik bir hata oluştu veya veritabanı yüklenemedi.\nLütfen uygulamayı kapatıp tekrar açmayı deneyin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}