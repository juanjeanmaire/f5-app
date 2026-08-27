import 'package:url_launcher/url_launcher.dart';

/// Abre WhatsApp con un mensaje pre-cargado, usando el link universal
/// wa.me (funciona tanto si WhatsApp está instalado como, de no estarlo,
/// cayendo a WhatsApp Web). No apunta a un contacto específico: abre el
/// selector de contactos/chats de WhatsApp para que el capitán elija a
/// quién mandárselo.
///
/// Devuelve `true` si se pudo abrir, `false` si no había nada que lo
/// pudiera manejar (ej. dispositivo sin WhatsApp ni navegador).
Future<bool> shareViaWhatsApp(String message) async {
  final uri = Uri.https('wa.me', '/', {'text': message});
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
