import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fitness_screen.dart';
import '../services/biometric_service.dart';

class FitnessHome extends StatefulWidget {
  final String userName;
  const FitnessHome({super.key, required this.userName});
  @override State<FitnessHome> createState() => _FitnessHomeState();
}

class _FitnessHomeState extends State<FitnessHome> {
  bool bio = false;
  int tab = 0;
  static const lime = Color(0xFFD4FF00);
  static const bg = Color(0xFF080A0A);
  static const panel = Color(0xFF171A1A);

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final p = await SharedPreferences.getInstance(); if (mounted) setState(() => bio = p.getBool('fit_bio') ?? false); }
  Future<void> _toggleBiometric(bool enabled) async {
    if (enabled) {
      final result = await BiometricService().autenticar();
      if (result != ResultadoBiometria.exito) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.mensaje))); return; }
    }
    final p = await SharedPreferences.getInstance(); await p.setBool('fit_bio', enabled); if (mounted) setState(() => bio = enabled);
  }
  void _openWorkout() => Navigator.push(context, MaterialPageRoute(builder: (_) => const FitnessScreen()));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    body: SafeArea(child: IndexedStack(index: tab, children: [_home(), _training(), _profile()])),
    bottomNavigationBar: NavigationBar(backgroundColor: const Color(0xFF141717), indicatorColor: lime.withValues(alpha: .18), selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: lime), label: 'Inicio'),
      NavigationDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt, color: lime), label: 'Entrenar'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: lime), label: 'Perfil'),
    ]),
  );

  Widget _home() => ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 26), children: [
    _header(), const SizedBox(height: 24),
    Text('Hola, ${widget.userName} 👋', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
    const SizedBox(height: 5), const Text('¿Qué actividad quieres hacer hoy?', style: TextStyle(color: Colors.white54)),
    const SizedBox(height: 18),
    _hero(),
    const SizedBox(height: 26),
    _title('Elige tu entrenamiento', '4 actividades'),
    const SizedBox(height: 12),
    GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .92, children: [
      _activityCard('Fuerza', 'Pesas · cuerpo completo', 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=900&q=85', Icons.fitness_center),
      _activityCard('Cardio', 'Corre · activa tu ritmo', 'https://images.unsplash.com/photo-1558611848-73f7eb4001a1?auto=format&fit=crop&w=900&q=85', Icons.directions_run),
      _activityCard('Piernas', 'Sentadillas · zancadas', 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=900&q=85', Icons.sports_gymnastics),
      _activityCard('Movilidad', 'Estira · recupera', 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=900&q=85', Icons.self_improvement),
    ]),
    const SizedBox(height: 22),
    _featureCard(icon: Icons.sensors, title: 'Tu actividad, medida en vivo', description: 'Pasos, distancia, acelerómetro, giroscopio y GPS en un solo panel.', action: 'Abrir monitor', onTap: _openWorkout),
    const SizedBox(height: 12),
    _featureCard(icon: Icons.history, title: 'Historial de entrenamiento', description: 'Guarda tus sesiones localmente y consulta tu progreso.', action: 'Ver historial', onTap: _openWorkout),
  ]);

  Widget _header() => Row(children: [
    Container(width: 42, height: 42, decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.fitness_center, color: Colors.black)),
    const SizedBox(width: 10), const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('FITNESS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)), Text('INDEPENDIENTE', style: TextStyle(color: lime, fontSize: 9, letterSpacing: 1.5))]),
    const Spacer(), IconButton(onPressed: () => setState(() => tab = 2), icon: const Icon(Icons.account_circle_outlined, color: Colors.white70, size: 28)),
  ]);

  Widget _hero() => ClipRRect(borderRadius: BorderRadius.circular(26), child: SizedBox(height: 245, child: Stack(fit: StackFit.expand, children: [
    _photo('https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=1200&q=90', Icons.directions_run),
    DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [Colors.black.withValues(alpha: .08), Colors.black.withValues(alpha: .88)]))),
    Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(20)), child: const Text('RETO DE HOY', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1))),
      const Spacer(), const Text('MÁS FUERTE\nCADA DÍA.', style: TextStyle(fontSize: 28, height: 1.08, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5), const Text('Muévete a tu ritmo. Supera tus límites.', style: TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 13), SizedBox(height: 42, child: FilledButton.icon(onPressed: _openWorkout, icon: const Icon(Icons.play_arrow_rounded), label: const Text('INICIAR SESIÓN'), style: FilledButton.styleFrom(backgroundColor: lime, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontWeight: FontWeight.w900)))),
    ])),
  ])));

  Widget _activityCard(String name, String subtitle, String url, IconData icon) => InkWell(onTap: _openWorkout, borderRadius: BorderRadius.circular(20), child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Stack(fit: StackFit.expand, children: [
    _photo(url, icon),
    DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: .05), Colors.black.withValues(alpha: .86)]))),
    Positioned(top: 10, right: 10, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 17, color: Colors.black))),
    Positioned(left: 13, right: 10, bottom: 13, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(subtitle, maxLines: 2, style: const TextStyle(color: Colors.white70, fontSize: 10.5)), const SizedBox(height: 7), const Row(children: [Text('EXPLORAR', style: TextStyle(color: lime, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)), Icon(Icons.arrow_forward, color: lime, size: 14)])])),
  ])));

  Widget _photo(String url, IconData fallback) => Image.network(url, fit: BoxFit.cover, loadingBuilder: (context, child, progress) => progress == null ? child : Container(color: const Color(0xFF252A27), child: const Center(child: CircularProgressIndicator(color: lime, strokeWidth: 2))), errorBuilder: (_, __, ___) => Container(color: const Color(0xFF242A26), child: Center(child: Icon(fallback, size: 62, color: lime.withValues(alpha: .65)))));

  Widget _title(String text, String right) => Row(children: [Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const Spacer(), Text(right, style: const TextStyle(color: Colors.white38, fontSize: 11))]);
  Widget _featureCard({required IconData icon, required String title, required String description, required String action, required VoidCallback onTap}) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF292E2E))), child: Row(children: [Container(width: 45, height: 45, decoration: BoxDecoration(color: lime.withValues(alpha: .13), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: lime)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), const SizedBox(height: 4), Text(description, style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.3))])), const SizedBox(width: 5), TextButton(onPressed: onTap, child: Text(action, style: const TextStyle(color: lime, fontSize: 10, fontWeight: FontWeight.bold)))]));

  Widget _training() => ListView(padding: const EdgeInsets.fromLTRB(18, 20, 18, 26), children: [
    _header(), const SizedBox(height: 24), const Text('Entrena a tu manera', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 6), const Text('Selecciona una actividad y registra tu sesión.', style: TextStyle(color: Colors.white54)), const SizedBox(height: 18),
    _hero(), const SizedBox(height: 18),
    _featureCard(icon: Icons.track_changes, title: 'Entrenamiento libre', description: 'Activa los sensores y registra pasos, tiempo, distancia y ruta GPS.', action: 'Iniciar', onTap: _openWorkout),
    const SizedBox(height: 12),
    _featureCard(icon: Icons.directions_walk, title: 'Caminata', description: 'Conteo de pasos y recorrido GPS.', action: 'Comenzar', onTap: _openWorkout),
  ]);

  Widget _profile() => ListView(padding: const EdgeInsets.fromLTRB(18, 20, 18, 26), children: [
    _header(), const SizedBox(height: 24), const Text('Tu perfil', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 15),
    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF292E2E))), child: Row(children: [CircleAvatar(radius: 28, backgroundColor: lime, child: const Icon(Icons.person, color: Colors.black, size: 28)), const SizedBox(width: 14), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const Text('Cuenta Fitness', style: TextStyle(color: Colors.white54))])])),
    const SizedBox(height: 16), Container(decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF292E2E))), child: SwitchListTile(secondary: const Icon(Icons.fingerprint, color: lime, size: 30), title: const Text('Inicio de sesión con huella', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(bio ? 'Activado en este dispositivo' : 'Activa el acceso biométrico', style: const TextStyle(color: Colors.white54)), value: bio, activeColor: lime, onChanged: _toggleBiometric)),
    const SizedBox(height: 12), _featureCard(icon: Icons.shield_outlined, title: 'Privacidad y seguridad', description: 'La huella es validada por Android. La app no almacena datos biométricos.', action: 'Entendido', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tu huella se valida de forma segura en el dispositivo.')))),
  ]);
}
