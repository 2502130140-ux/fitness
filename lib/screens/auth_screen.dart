import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/biometric_service.dart';
import 'fitness_home.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final user = TextEditingController();
  final pass = TextEditingController();
  final bio = BiometricService();
  bool registering = false, busy = false, hidePass = true;

  @override
  void dispose() { user.dispose(); pass.dispose(); super.dispose(); }

  Future<void> _enter({bool biometric = false}) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString('fit_user');
      final savedPass = prefs.getString('fit_pass');
      bool ok = false;
      var name = user.text.trim();
      if (biometric) {
        if (!(prefs.getBool('fit_bio') ?? false)) {
          _msg('Primero inicia sesión y activa la huella desde tu perfil.');
          return;
        }
        final result = await bio.autenticar();
        ok = result == ResultadoBiometria.exito;
        if (!ok) _msg(result.mensaje.isEmpty ? 'No se pudo validar la huella.' : result.mensaje);
        name = savedUser ?? 'Usuario';
      } else if (registering) {
        if (name.isEmpty || pass.text.length < 4) { _msg('Escribe usuario y contraseña de mínimo 4 caracteres.'); return; }
        if (savedUser != null) { _msg('Ya existe una cuenta. Inicia sesión.'); return; }
        await prefs.setString('fit_user', name);
        await prefs.setString('fit_pass', pass.text);
        await prefs.setBool('fit_bio', false);
        ok = true;
      } else {
        ok = savedUser == name && savedPass == pass.text;
        if (!ok) _msg('Usuario o contraseña incorrectos.');
        name = savedUser ?? name;
      }
      if (ok && mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FitnessHome(userName: name)));
    } catch (e) { if (mounted) _msg('No se pudo iniciar sesión: $e'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  void _msg(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFD4FF00);
    return Scaffold(
      body: SafeArea(child: Stack(children: [
        Positioned(top: -90, right: -70, child: Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, color: lime.withValues(alpha: .07)))),
        Positioned(bottom: -100, left: -90, child: Container(width: 270, height: 270, decoration: BoxDecoration(shape: BoxShape.circle, color: lime.withValues(alpha: .05)))),
        Center(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 24, 24, 28), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(height: 92, width: 92, alignment: Alignment.center, decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(28)), child: const Icon(Icons.fitness_center, color: Colors.black, size: 42)),
          const SizedBox(height: 24),
          const Text('FITNESS', style: TextStyle(fontSize: 36, letterSpacing: 4, fontWeight: FontWeight.w900)),
          const Text('INDEPENDIENTE', style: TextStyle(color: lime, fontWeight: FontWeight.w800, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text('Entrena. Mide. Supérate.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 30),
          Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: const Color(0xFF171A1A), borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFF2B3030))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(registering ? 'CREA TU CUENTA' : 'BIENVENIDA/O', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5), Text(registering ? 'Comienza tu progreso hoy.' : '¿Lista/o para tu siguiente reto?', style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 22),
            _field(user, 'Usuario', Icons.person_outline),
            const SizedBox(height: 12),
            TextField(controller: pass, obscureText: hidePass, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Contraseña', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(hidePass ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => hidePass = !hidePass)), filled: true, fillColor: const Color(0xFF0D1010), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
            const SizedBox(height: 18),
            SizedBox(height: 52, child: FilledButton(onPressed: busy ? null : () => _enter(), style: FilledButton.styleFrom(backgroundColor: lime, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text(busy ? 'UN MOMENTO...' : registering ? 'CREAR CUENTA' : 'INICIAR SESIÓN', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5)))),
            if (!registering) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: busy ? null : () => _enter(biometric: true), icon: const Icon(Icons.fingerprint, size: 28, color: lime), label: const Text('ENTRAR CON HUELLA'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0xFF424848)), minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
            ],
            const SizedBox(height: 8),
            TextButton(onPressed: busy ? null : () => setState(() => registering = !registering), child: Text(registering ? 'Ya tengo cuenta · Iniciar sesión' : 'Crear cuenta nueva', style: const TextStyle(color: lime))),
          ])),
          const SizedBox(height: 18), const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shield_outlined, color: Colors.white38, size: 16), SizedBox(width: 6), Text('Tu huella se valida de forma segura en el dispositivo', style: TextStyle(color: Colors.white38, fontSize: 11))]),
        ]))))
      ])),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon) => TextField(controller: controller, textInputAction: TextInputAction.next, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: const Color(0xFF0D1010), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)));
}
