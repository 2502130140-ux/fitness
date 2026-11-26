import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

/// Panel de entrenamiento con sensores, GPS, mapa y guardado local.
class FitnessScreen extends StatefulWidget {
  const FitnessScreen({super.key});
  @override State<FitnessScreen> createState() => _FitnessScreenState();
}
class _FitnessScreenState extends State<FitnessScreen> with WidgetsBindingObserver {
  StreamSubscription<StepCount>? _stepsSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<Position>? _gpsSub;
  bool _running=false, _paused=false, _permissionBusy=false;
  int _stepBase=0, _steps=0;
  DateTime? _started;
  double _accelMagnitude=0, _gyroMagnitude=0;
  double _ax=0,_ay=0,_az=0,_gx=0,_gy=0,_gz=0,_pitch=0,_roll=0;
  String _activity='En reposo';
  final List<LatLng> _route=[];
  final List<Map<String,dynamic>> _history=[];
  LatLng? _current;
  final MapController _map=MapController();
  static const _historyKey='fitness_sessions_sica';
  @override void initState(){super.initState(); WidgetsBinding.instance.addObserver(this); _loadHistory();}
  @override void dispose(){WidgetsBinding.instance.removeObserver(this); _cancelStreams(); super.dispose();}
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.paused||state==AppLifecycleState.inactive||state==AppLifecycleState.detached){if(_running) _pauseForBackground();}}
  Future<void> _loadHistory() async {final p=await SharedPreferences.getInstance(); final raw=p.getString(_historyKey); if(raw==null)return; try{final list=jsonDecode(raw) as List; if(mounted)setState(()=>_history.addAll(list.map((e)=>Map<String,dynamic>.from(e))));}catch(_){} }
  Future<void> _saveHistory() async {final p=await SharedPreferences.getInstance(); await p.setString(_historyKey,jsonEncode(_history));}
  Future<bool> _permissions() async {
    bool service=await Geolocator.isLocationServiceEnabled(); if(!service){if(mounted)_message('Activa la ubicación/GPS del teléfono para registrar la ruta.');return false;}
    LocationPermission perm=await Geolocator.checkPermission(); if(perm==LocationPermission.denied)perm=await Geolocator.requestPermission();
    if(perm==LocationPermission.denied||perm==LocationPermission.deniedForever){if(mounted)_message('Se necesita permiso de ubicación para trazar el recorrido.');return false;}
    return true;
  }
  Future<void> _start() async {if(_permissionBusy)return;setState(()=>_permissionBusy=true);try{if(!await _permissions())return;
    final activityPermission=await Permission.activityRecognition.request();
    if(!activityPermission.isGranted && mounted){_message('Permiso de actividad física denegado: el conteo de pasos puede no estar disponible.');}
    _route.clear();_steps=0;_stepBase=0;_started=DateTime.now();
    _stepsSub=Pedometer.stepCountStream.listen((e){if(!mounted)return;if(_stepBase==0)_stepBase=e.steps;setState(()=>_steps=math.max(0,e.steps-_stepBase));},onError:(_){if(mounted)_message('El podómetro no está disponible en este teléfono.');});
    _accelSub=accelerometerEventStream().listen((e){final m=math.sqrt(e.x*e.x+e.y*e.y+e.z*e.z);if(!mounted)return;setState((){_accelMagnitude=m;_ax=e.x;_ay=e.y;_az=e.z;_pitch=math.atan2(e.y,math.sqrt(e.x*e.x+e.z*e.z))*180/math.pi;_roll=math.atan2(e.x,e.z)*180/math.pi;_activity=m<10.4?'Reposo':m<13.0?'Caminata':'Trote/actividad intensa';});});
    _gyroSub=gyroscopeEventStream().listen((e){final m=math.sqrt(e.x*e.x+e.y*e.y+e.z*e.z);if(mounted)setState((){_gyroMagnitude=m;_gx=e.x;_gy=e.y;_gz=e.z;});});
    _gpsSub=Geolocator.getPositionStream(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high,distanceFilter:3)).listen((p){final point=LatLng(p.latitude,p.longitude);if(!mounted)return;setState(()=>_current=point);if(_route.isEmpty||Geolocator.distanceBetween(_route.last.latitude,_route.last.longitude,p.latitude,p.longitude)>2){_route.add(point);if(_route.length==1){try{_map.move(point,16);}catch(_){}}}},onError:(_){if(mounted)_message('No se pudo recibir ubicación GPS.');});
    if(mounted)setState(()=>_running=true);
  }catch(e){if(mounted)_message('No se pudieron iniciar los sensores: $e');}finally{if(mounted)setState(()=>_permissionBusy=false);}}
  void _pauseForBackground(){_cancelStreams();if(mounted)setState(()=>_running=false);}
  void _cancelStreams(){_stepsSub?.cancel();_accelSub?.cancel();_gyroSub?.cancel();_gpsSub?.cancel();_stepsSub=null;_accelSub=null;_gyroSub=null;_gpsSub=null;}
  Future<void> _stopAndSave() async {final started=_started;if(started==null)return;_cancelStreams();final duration=DateTime.now().difference(started);final dist=_steps*.75;final entry={'date':started.toIso8601String(),'durationSeconds':duration.inSeconds,'steps':_steps,'distanceMeters':dist,'route':_route.map((p)=>[p.latitude,p.longitude]).toList()};_history.insert(0,entry);await _saveHistory();if(mounted)setState(()=>_running=false);_started=null;if(mounted)_message('Entrenamiento guardado en el historial.');}
  void _message(String s){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
  String _duration(){if(_started==null)return '00:00';final d=DateTime.now().difference(_started!);return '${d.inMinutes.toString().padLeft(2,'0')}:${(d.inSeconds%60).toString().padLeft(2,'0')}';}
  double get _distance=>_steps*.75;
  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFD4FF00);
    const panel = Color(0xFF171A1A);
    return Scaffold(
      backgroundColor: const Color(0xFF080A0A),
      appBar: AppBar(title: const Text('Actividad Fitness', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(icon: const Icon(Icons.history), tooltip: 'Historial', onPressed: () => _showHistory(context))]),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 26), children: [
        ClipRRect(borderRadius: BorderRadius.circular(24), child: SizedBox(height: 180, child: Stack(fit: StackFit.expand, children: [
          Image.network('https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=1200&q=85', fit: BoxFit.cover, loadingBuilder: (_, child, progress) => progress == null ? child : Container(color: panel), errorBuilder: (_, __, ___) => Container(color: const Color(0xFF242A26), child: const Icon(Icons.fitness_center, size: 80, color: lime))),
          DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [Colors.black.withValues(alpha: .12), Colors.black.withValues(alpha: .84)]))),
          Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(15)), child: const Text('FITNESS TRACKER', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1))), const Spacer(), Icon(_running ? Icons.circle : Icons.circle_outlined, color: _running ? lime : Colors.white60, size: 11), const SizedBox(width: 5), Text(_running ? 'EN VIVO' : 'LISTO', style: TextStyle(color: _running ? lime : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold))]),
            const Spacer(), Text(_running ? '¡Sigue moviéndote!' : 'Tu sesión,\ntu progreso.', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.05)), const SizedBox(height: 4), const Text('Sensores y actividad en tiempo real', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ])),
        ]))),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2B3030))),
          child: Row(children: [
            Expanded(child: FilledButton.icon(
              onPressed: _running || _permissionBusy ? null : _start,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(_permissionBusy ? 'Solicitando...' : 'Iniciar'),
              style: FilledButton.styleFrom(backgroundColor: lime, foregroundColor: Colors.black, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontWeight: FontWeight.w900)),
            )),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(
              onPressed: _running ? _stopAndSave : null,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Guardar'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            )),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [const Text('Resumen de sesión', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), const Spacer(), Text(_running ? 'ACTIVO' : 'EN ESPERA', style: TextStyle(color: _running ? lime : Colors.white38, fontSize: 10, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 10),
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.25, children: [
          _metric('PASOS', _steps.toString(), Icons.directions_walk), _metric('DISTANCIA', '${(_distance / 1000).toStringAsFixed(2)} km', Icons.route), _metric('DURACIÓN', _duration(), Icons.timer_outlined), _metric('MOVIMIENTO', _activity, Icons.bolt),
        ]),
        const SizedBox(height: 12),
        Card(color: panel, child: ExpansionTile(leading: const Icon(Icons.sensors, color: lime), title: const Text('Sensores', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('Acelerómetro · Giroscopio · Orientación', style: TextStyle(color: Colors.white54, fontSize: 11)), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12), children: [
          _sensorLine('ACELERÓMETRO · X / Y / Z', 'X ${_ax.toStringAsFixed(2)} · Y ${_ay.toStringAsFixed(2)} · Z ${_az.toStringAsFixed(2)} m/s²'),
          _sensorLine('INTENSIDAD', '${_accelMagnitude.toStringAsFixed(2)} m/s² · $_activity'),
          _sensorLine('GIROSCOPIO · X / Y / Z', 'X ${_gx.toStringAsFixed(3)} · Y ${_gy.toStringAsFixed(3)} · Z ${_gz.toStringAsFixed(3)} rad/s'),
          _sensorLine('ORIENTACIÓN', 'Pitch ${_pitch.toStringAsFixed(1)}° · Roll ${_roll.toStringAsFixed(1)}°'),
        ])),
        Card(color: panel, child: ExpansionTile(leading: const Icon(Icons.map_outlined, color: lime), title: const Text('GPS y recorrido', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(_current == null ? 'Esperando ubicación' : 'Ubicación recibida', style: const TextStyle(color: Colors.white54, fontSize: 11)), childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12), children: [
          SizedBox(height: 250, child: ClipRRect(borderRadius: BorderRadius.circular(14), child: _route.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.location_searching, size: 42, color: Colors.white30), SizedBox(height: 10), Text('Al iniciar y recibir GPS, aquí se trazará tu ruta.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))]))) : FlutterMap(mapController: _map, options: MapOptions(initialCenter: _route.last, initialZoom: 15), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'fitness.independiente'), PolylineLayer(polylines: [Polyline(points: _route, color: lime, strokeWidth: 4)]), MarkerLayer(markers: [Marker(point: _route.last, width: 35, height: 35, child: const Icon(Icons.location_on, color: lime, size: 32))])]))),
          if (_current != null) Padding(padding: const EdgeInsets.only(top: 9), child: Text('Lat ${_current!.latitude.toStringAsFixed(5)} · Lon ${_current!.longitude.toStringAsFixed(5)}', style: const TextStyle(color: Colors.white54, fontSize: 11))),
        ])),
        Card(color: panel, child: ExpansionTile(leading: const Icon(Icons.history, color: lime), title: const Text('Historial', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${_history.length} sesiones guardadas', style: const TextStyle(color: Colors.white54, fontSize: 11)), children: [
          if (_history.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Aún no hay sesiones. Finaliza una para guardarla.', style: TextStyle(color: Colors.white54)))
          else ..._history.take(10).map((h) => ListTile(leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: lime.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.directions_run, color: lime)), title: Text('${h['steps']} pasos · ${(((h['distanceMeters'] ?? 0) as num) / 1000).toStringAsFixed(2)} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), subtitle: Text('${DateTime.tryParse(h['date'] ?? '')?.toLocal().toString().split('.').first ?? 'Fecha'} · ${((h['durationSeconds'] ?? 0) as num).toInt()} s', style: const TextStyle(color: Colors.white54, fontSize: 10))))
        ])),
        const SizedBox(height: 8), const Text('Los sensores se pausan cuando la app pasa a segundo plano.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 10)),
      ]),
    );
  }

  void _showHistory(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_history.length} entrenamientos guardados. Abre la sección Historial para verlos.')));
  }

  Widget _metric(String title, String value, IconData icon) => Card(color: const Color(0xFF171A1A), margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(12), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: const Color(0xFFD4FF00), size: 22), const SizedBox(height: 6), Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)), const SizedBox(height: 3), SizedBox(width: double.infinity, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18), maxLines: 1)))])));
  Widget _sensorLine(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 11), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Color(0xFFD4FF00), fontSize: 10, letterSpacing: .8, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12)), const SizedBox(height: 5), const Divider(color: Color(0xFF282D2D), height: 1)]));
}
