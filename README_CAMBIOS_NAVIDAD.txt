CAMBIOS REALIZADOS EN SICA

1. Decoración navideña global reutilizable:
   lib/widgets/decoracion_navidad.dart
   Incluye guirnalda y esferas superiores, copos discretos, árbol/regalos y muñeco de nieve/Santa en las esquinas.
   La decoración se integra desde MaterialApp.builder, por lo que aparece en todas las pantallas y no bloquea los controles.

2. Acceso biométrico:
   El proyecto ya tenía implementado el servicio local_auth y el flujo en login.dart.
   Se conserva: el usuario inicia sesión con correo y contraseña, puede activar biometría, y después usar el botón de acceso biométrico.
   Android ya declara USE_BIOMETRIC y MainActivity extiende FlutterFragmentActivity.

Para abrir el proyecto: entra a la carpeta sica (donde está pubspec.yaml), ejecuta flutter pub get y luego flutter run.
