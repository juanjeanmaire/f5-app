# F5 App — Frontend (Flutter)

## Estado actual

MVP completo: login con Google, grupos con capitanes, pool de jugadores,
carga de partidos con ELO (F5/F6/F7), historial personal por jugador,
generador de equipos, y configuración de ELO por grupo.

## Configuración necesaria antes de que ande el login

1. En Google Cloud Console, crear un OAuth Client ID de tipo **Android**
   (con el SHA-1 del keystore correspondiente) y otro de tipo **Web
   application** (el "server client ID", usado por el backend).
2. El backend usa el Web Client ID como `GOOGLE_CLIENT_ID`.
3. Flutter usa el mismo Web Client ID como `serverClientId`, vía
   `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` (ver
   `core/config/app_config.dart`).
4. `applicationId` del proyecto: `com.freire.f5app`

## Build

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://f5-backend-8inv.onrender.com `
  --dart-define=GOOGLE_SERVER_CLIENT_ID=1092181236529-ovdp2jao98d3t2n165tiaccjtqibokmc.apps.googleusercontent.com
```
