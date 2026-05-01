import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'YASTIK6_API_KEY', obfuscate: true)
  static final String apiKey = _Env.apiKey;

  @EnviedField(varName: 'BASE_URL', obfuscate: true)
  static final String baseUrl = _Env.baseUrl;

  @EnviedField(varName: 'GOOGLE_DRIVE_CLIENT_ID', obfuscate: true)
  static final String googleDriveClientId = _Env.googleDriveClientId;
}