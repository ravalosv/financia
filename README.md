# Financia

Aplicación de gestión financiera personal desarrollada con Flutter y Dart. Permite administrar cuentas, presupuestos, categorías, transacciones, metas de ahorro y autenticación biométrica, con análisis y visualizaciones para tomar mejores decisiones. Todo el procesamiento sensible se realiza de forma local priorizando la privacidad.

## Tecnologías

- Flutter (`sdk: flutter`) y Dart (`sdk: ^3.10.1`)
- Gestión de estado: `get`
- Persistencia local: `hive`, `hive_flutter`, `sqflite`, `path`
- OCR y captura: `google_mlkit_text_recognition`, `camera`, `image_picker`
- Seguridad: `encrypt`
- UI y utilidades: `fl_chart`, `intl`, `path_provider`
- Autenticación biométrica: `local_auth`
- Compras dentro de la app: `in_app_purchase`
- Archivos: `file_picker`

## Plataformas soportadas

- Android, iOS, Web, Windows, macOS y Linux

## Requisitos previos

- Flutter SDK instalado y configurado
- Dart SDK compatible
- Android Studio (Android) y/o Xcode (iOS) para compilaciones nativas
- Herramientas de plataforma según el destino (por ejemplo, Chrome para Web)

## Instalación

1. Clonar el repositorio
2. Instalar dependencias: `flutter pub get`

## Ejecución

- Dispositivo por defecto: `flutter run`
- Windows: `flutter run -d windows`
- Web: `flutter run -d chrome`
- Android: conectar un dispositivo/emulador y ejecutar `flutter run -d android`
- iOS: usar un simulador y ejecutar `flutter run -d ios`

## Estructura del proyecto

- `lib/` código fuente principal
  - `controllers/` controladores de lógica y estado
  - `models/` modelos de datos (incluye archivos `.g.dart` generados)
  - `routes/` rutas de navegación
  - `theme/` tema y estilos
  - `utils/` utilidades y helpers
  - `views/` pantallas y widgets de UI
  - `main.dart` punto de entrada
- `assets/` recursos gráficos e imágenes
- `test/` pruebas unitarias y de widgets
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` soporte por plataforma

## Configuración

- Asegurar que los recursos declarados en `pubspec.yaml` estén presentes (por ejemplo, `assets/financia.png`)
- Variables de entorno sensibles no se almacenan en el repositorio; usar mecanismos seguros del sistema

## Calidad y pruebas

- Análisis estático: `flutter analyze`
- Formateo: `dart format .`
- Pruebas: `flutter test`

## Branding (iconos y splash)

- Generar iconos: `flutter pub run flutter_launcher_icons`
- Generar splash: `flutter pub run flutter_native_splash:create`

## Compilación y despliegue

- Android (APK): `flutter build apk --release`
- Web: `flutter build web`
- Windows: `flutter build windows`
- iOS/macOS/Linux: usar los comandos `flutter build` correspondientes y herramientas de plataforma

## Contribución

- Crear ramas por funcionalidad, abrir PRs pequeños y descriptivos
- Seguir las reglas en `analysis_options.yaml` y buenas prácticas de Flutter

## Licencia

Proyecto privado; la licencia está pendiente de definición.
