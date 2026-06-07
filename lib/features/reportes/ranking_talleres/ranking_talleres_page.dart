import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taller_movil/core/config/app_config.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/api_helper.dart';
import 'package:taller_movil/services/auth_service.dart';

class RankingTalleresPage extends StatefulWidget {
  const RankingTalleresPage({super.key});

  @override
  State<RankingTalleresPage> createState() => _RankingTalleresPageState();
}

class _RankingTalleresPageState extends State<RankingTalleresPage> {
  final _auth = AuthService();
  List<Map<String, dynamic>> _talleres = [];
  bool _loading = true;
  String? _error;
  int? _expandido;

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
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/reportes/ranking-talleres'),
        headers: await _authHeaders(),
      );
      verificarRespuesta(res);
      final data = jsonDecode(res.body) as List;
      if (!mounted) return;
      setState(() {
        _talleres = data.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is TokenExpiradoException) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  String _estrellas(double rating) {
    final llenas = rating.floor();
    final media = (rating - llenas) >= 0.5;
    return '${'★' * llenas}${media ? '½' : ''}${'☆' * (5 - llenas - (media ? 1 : 0))}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking de Talleres'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)))
              : _talleres.isEmpty
                  ? const Center(child: Text('No hay talleres registrados aún.'))
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _talleres.length,
                        itemBuilder: (context, i) => _TallerCard(
                          taller: _talleres[i],
                          posicion: i + 1,
                          estrellas: _estrellas,
                          expandido: _expandido == i,
                          onToggle: () => setState(() => _expandido = _expandido == i ? null : i),
                        ),
                      ),
                    ),
    );
  }
}

class _TallerCard extends StatelessWidget {
  const _TallerCard({
    required this.taller,
    required this.posicion,
    required this.estrellas,
    required this.expandido,
    required this.onToggle,
  });

  final Map<String, dynamic> taller;
  final int posicion;
  final String Function(double) estrellas;
  final bool expandido;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final rating = (taller['rating'] as num?)?.toDouble() ?? 0.0;
    final totalCal = taller['total_calificaciones'] as int? ?? 0;
    final especialidades = List<String>.from(taller['especialidades'] ?? []);
    final resenas = List<Map<String, dynamic>>.from(taller['resenas_recientes'] ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Posición
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$posicion',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(taller['nombre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(taller['direccion'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      if (taller['telefono'] != null)
                        Text(taller['telefono'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                // Rating
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(estrellas(rating),
                        style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 16, letterSpacing: 1)),
                    Text('${rating.toStringAsFixed(1)} / 5.0',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('$totalCal reseña${totalCal != 1 ? 's' : ''}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ],
            ),

            // Especialidades
            if (especialidades.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: especialidades
                    .map((e) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(e, style: TextStyle(fontSize: 11, color: AppColors.primary)),
                        ))
                    .toList(),
              ),
            ],

            // Botón reseñas
            if (totalCal > 0) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onToggle,
                child: Text(
                  expandido ? 'Ocultar reseñas' : 'Ver reseñas recientes',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              if (expandido) ...[
                const SizedBox(height: 8),
                ...resenas.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('★' * (r['puntuacion'] as int) + '☆' * (5 - (r['puntuacion'] as int)),
                                  style: const TextStyle(color: Color(0xFFF59E0B))),
                              if (r['created_at'] != null)
                                Text(
                                  (r['created_at'] as String).substring(0, 10),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                            ],
                          ),
                          if (r['comentario'] != null && (r['comentario'] as String).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(r['comentario'], style: const TextStyle(fontSize: 13)),
                            ),
                        ],
                      ),
                    )),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
