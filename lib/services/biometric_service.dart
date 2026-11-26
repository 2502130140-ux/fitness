import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

enum ResultadoBiometria {
  exito(''),
  noReconocido('No se pudo confirmar tu identidad.'),
  cancelado('Autenticación cancelada.'),
  sinHardware('Este dispositivo no tiene sensor biométrico.'),
  sinRegistro('Registra una huella o tu rostro en Ajustes.'),
  sinBloqueo('Configura un PIN o patrón en el dispositivo.'),
  bloqueado('Demasiados intentos. Usa tu contraseña.'),
  noDisponible('El sensor no está disponible ahora.'),
  error('Ocurrió un error inesperado.');

  const ResultadoBiometria(this.mensaje);
  final String mensaje;
}

/// Encapsula todo el uso del paquete local_auth.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// En Android normalmente devuelve BiometricType.strong o .weak.
  Future<List<BiometricType>> tiposDisponibles() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return <BiometricType>[];
    }
  }

  Future<bool> disponible() async {
    final tipos = await tiposDisponibles();
    return tipos.isNotEmpty;
  }

  Future<ResultadoBiometria> autenticar() async {
    try {
      final autenticado = await _auth.authenticate(
        localizedReason: 'Confirma tu identidad para continuar',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Autenticación biométrica',
            signInHint: 'Usa tu huella o tu rostro',
            cancelButton: 'Cancelar',
          ),
        ],
      );
      return autenticado
          ? ResultadoBiometria.exito
          : ResultadoBiometria.noReconocido;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.userRequestedFallback ||
        LocalAuthExceptionCode.timeout =>
        ResultadoBiometria.cancelado,
        LocalAuthExceptionCode.noBiometricHardware =>
        ResultadoBiometria.sinHardware,
        LocalAuthExceptionCode.noBiometricsEnrolled =>
        ResultadoBiometria.sinRegistro,
        LocalAuthExceptionCode.noCredentialsSet =>
        ResultadoBiometria.sinBloqueo,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout =>
        ResultadoBiometria.bloqueado,
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable ||
        LocalAuthExceptionCode.authInProgress ||
        LocalAuthExceptionCode.uiUnavailable =>
        ResultadoBiometria.noDisponible,
        _ => ResultadoBiometria.error,
      };
    } catch (_) {
      return ResultadoBiometria.error;
    }
  }
}