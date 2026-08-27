/// Configuración de la app, pensada para overridearse en build time con
/// --dart-define, sin hardcodear nada sensible en el código.
///
/// Ejemplo:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000 \
///                --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
class AppConfig {
  AppConfig._();

  /// 10.0.2.2 es el alias especial que usa el emulador de Android para
  /// llegar al localhost de la máquina host. Si probás en un dispositivo
  /// físico, necesitás la IP de tu red local del backend.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// El "server client ID" (tipo Web application) de Google Cloud Console.
  /// Es el mismo valor que GOOGLE_CLIENT_ID en el .env del backend — el
  /// idToken que genera este client ID es el que el backend valida.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
