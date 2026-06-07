import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taller_movil/core/config/app_config.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/api_helper.dart';
import 'package:taller_movil/services/auth_service.dart';
import 'package:taller_movil/shared/app_drawer.dart';

class CalificarServicioPage extends StatefulWidget {
  const CalificarServicioPage({super.key});

  @override
  State<CalificarServicioPage> createState() => _CalificarServicioPageState();
}

class _CalificarServicioPageState extends State<CalificarServicioPage> {
  final _auth = AuthService();
  List<Map<String, dynamic>> _pendientes = [];
  bool _loading = true;
  String _error = '';

  Future<Map<String, String>> _authHeaders() async {
    final token = await _auth.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/reportes/calificaciones/pendientes'),
        headers: await _authHeaders(),
      );
      verificarRespuesta(res);
      final data = jsonDecode(res.body) as List;
      if (!mounted) return;
      setState(() {
        _pendientes = data.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is TokenExpiradoException) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _abrirFormulario(Map<String, dynamic> item) async {
    final calificado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioCalificacion(item: item),
    );
    if (calificado == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Calificar Servicio', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _cargar),
        ],
      ),
      drawer: const AppDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error.isNotEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off, size: 48, color: AppColors.danger),
          const SizedBox(height: 12),
          Text(_error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
        ]),
      ));
    }

    if (_pendientes.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.star_outline, size: 64, color: Color(0xFFD1D5DB)),
          SizedBox(height: 16),
          Text('Sin servicios por calificar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          SizedBox(height: 8),
          Text('Cuando un servicio finalice, aparecerá aquí para que puedas valorarlo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
        ]),
      ));
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pendientes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final item = _pendientes[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.build_outlined, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['taller_nombre'] as String? ?? 'Taller',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Incidente #${item['incidente_id']}  ·  Asignación #${item['asignacion_id']}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                      if (item['fecha_finalizacion'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Finalizado: ${(item['fecha_finalizacion'] as String).substring(0, 10)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _abrirFormulario(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Calificar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FormularioCalificacion extends StatefulWidget {
  const _FormularioCalificacion({required this.item});
  final Map<String, dynamic> item;

  @override
  State<_FormularioCalificacion> createState() => _FormularioCalificacionState();
}

class _FormularioCalificacionState extends State<_FormularioCalificacion> {
  final _auth = AuthService();
  int _puntuacion = 5;
  final _comentarioCtrl = TextEditingController();
  bool _enviando = false;
  String _error = '';

  Future<Map<String, String>> _authHeaders() async {
    final token = await _auth.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() { _enviando = true; _error = ''; });
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/reportes/calificaciones'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'asignacion_id': widget.item['asignacion_id'],
          'puntuacion': _puntuacion,
          'resena': _comentarioCtrl.text.trim(),
        }),
      );
      verificarRespuesta(res, esperado: 200);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('¡Calificación enviada! Gracias por tu valoración.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final taller = widget.item['taller_nombre'] as String? ?? 'Taller';
    final incId = widget.item['incidente_id'];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Calificar servicio', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 4),
            Text('$taller · Incidente #$incId', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 20),

            // Estrellas interactivas
            const Text('Puntuación', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final estrella = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _puntuacion = estrella),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      estrella <= _puntuacion ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 38,
                      color: estrella <= _puntuacion ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              ['', 'Malo', 'Regular', 'Bueno', 'Muy bueno', 'Excelente'][_puntuacion],
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),

            // Comentario
            const Text('Reseña (opcional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe tu experiencia con el taller...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            if (_error.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(_error, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _enviando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enviar calificación', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
