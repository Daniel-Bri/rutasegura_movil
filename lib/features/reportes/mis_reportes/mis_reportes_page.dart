import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:record/record.dart';
import 'package:taller_movil/core/config/app_config.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/api_helper.dart';
import 'package:taller_movil/services/auth_service.dart';

class MisReportesPage extends StatefulWidget {
  const MisReportesPage({super.key});

  @override
  State<MisReportesPage> createState() => _MisReportesPageState();
}

class _MisReportesPageState extends State<MisReportesPage> {
  final _auth = AuthService();
  final _recorder = AudioRecorder();
  final _queryCtrl = TextEditingController();

  Map<String, dynamic>? _resultado;
  bool _loading = false;
  bool _grabando = false;
  bool _transcribiendo = false;
  bool _exportando = false;
  String _error = '';

  // Filtros de fecha
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _chipPeriodo = '';  // '', 'mes', '3m', '6m', 'todo'

  // Filtro de monto (client-side)
  double? _montoMinimo;  // null = todos

  static const _periodoChips = [
    ('Este mes', 'mes'),
    ('3 meses', '3m'),
    ('6 meses', '6m'),
    ('Todo', 'todo'),
  ];

  static const _montoBtns = [
    ('Todos', null),
    ('>Bs 100', 100.0),
    ('>Bs 200', 200.0),
    ('>Bs 500', 500.0),
  ];

  @override
  void dispose() {
    _queryCtrl.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _auth.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _consultar(String consulta) async {
    if (consulta.trim().isEmpty) return;
    setState(() { _loading = true; _error = ''; _resultado = null; });
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/reportes/mis-reportes/consulta'),
        headers: await _authHeaders(),
        body: jsonEncode({'consulta': consulta}),
      );
      verificarRespuesta(res);
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() { _resultado = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      if (e is TokenExpiradoException) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _iniciarGrabacion() async {
    final tienePermiso = await _recorder.hasPermission();
    if (!tienePermiso) {
      setState(() => _error = 'Se necesita permiso de micrófono.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/consulta_reporte.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() { _grabando = true; _error = ''; });
  }

  Future<void> _detenerGrabacion() async {
    final path = await _recorder.stop();
    setState(() { _grabando = false; _transcribiendo = true; });
    if (path == null) { setState(() => _transcribiendo = false); return; }

    try {
      final token = await _auth.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/api/ia/transcribir-audio'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('audio', path,
            filename: 'consulta.m4a'));

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final texto = data['transcripcion'] as String? ?? '';
      if (!mounted) return;
      if (texto.isNotEmpty) {
        _queryCtrl.text = texto;
        setState(() => _transcribiendo = false);
        await _consultar(texto);
      } else {
        setState(() {
          _transcribiendo = false;
          _error = data['mensaje'] as String? ?? 'No se entendió el audio.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _transcribiendo = false; _error = 'Error al transcribir el audio.'; });
    } finally {
      try { File(path).deleteSync(); } catch (_) {}
    }
  }

  // ── Exportar ────────────────────────────────────────────

  List<Map<String, dynamic>> get _incidentes {
    final todos = ((_resultado?['incidentes'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>();
    if (_montoMinimo == null) return todos;
    return todos.where((i) {
      final m = i['monto_pagado'];
      if (m == null) return false;
      return (m as num).toDouble() >= _montoMinimo!;
    }).toList();
  }

  String get _periodoLabel => _resultado?['periodo_label'] as String? ?? 'reporte';

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _seleccionarChipPeriodo(String chip) {
    final hoy = DateTime.now();
    setState(() {
      _chipPeriodo = chip;
      _queryCtrl.clear();
      switch (chip) {
        case 'mes':
          _fechaInicio = DateTime(hoy.year, hoy.month, 1);
          _fechaFin = hoy;
        case '3m':
          _fechaInicio = DateTime(hoy.year, hoy.month - 2, 1);
          _fechaFin = hoy;
        case '6m':
          _fechaInicio = DateTime(hoy.year, hoy.month - 5, 1);
          _fechaFin = hoy;
        case 'todo':
          _fechaInicio = null;
          _fechaFin = null;
      }
    });
  }

  String _construirConsulta() {
    // Si hay texto libre usa ese
    final txt = _queryCtrl.text.trim();
    if (txt.isNotEmpty) return txt;
    // Si hay rango de fechas construye consulta
    if (_fechaInicio != null && _fechaFin != null) {
      return 'mis incidentes del ${_iso(_fechaInicio!)} al ${_iso(_fechaFin!)}';
    }
    if (_fechaInicio != null) {
      return 'mis incidentes desde ${_iso(_fechaInicio!)}';
    }
    if (_chipPeriodo == 'todo') return 'todos mis reportes';
    return 'dame los reportes de este mes';
  }

  Future<void> _abrirDatePicker(bool esInicio) async {
    final hoy = DateTime.now();
    final inicial = esInicio
        ? (_fechaInicio ?? hoy)
        : (_fechaFin ?? hoy);
    final picked = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: hoy,
      locale: const Locale('es'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _chipPeriodo = '';
      if (esInicio) {
        _fechaInicio = picked;
        if (_fechaFin != null && picked.isAfter(_fechaFin!)) _fechaFin = null;
      } else {
        _fechaFin = picked;
        if (_fechaInicio != null && picked.isBefore(_fechaInicio!)) _fechaInicio = null;
      }
    });
  }

  Future<Directory?> _dirDescarga() async {
    try {
      final d = await getDownloadsDirectory();
      if (d != null) return d;
    } catch (_) {}
    return getApplicationDocumentsDirectory();
  }

  Future<void> _exportarCSV() async {
    if (_resultado == null) return;
    setState(() => _exportando = true);
    try {
      final lineas = [
        'RutaSegura - Mis Incidentes',
        'Período: $_periodoLabel',
        'Total: ${_resultado!['total']}',
        '',
        'ID,Estado,Tipo,Taller,Monto Pagado (Bs),Fecha,Descripción',
        ..._incidentes.map((i) {
          final desc = (i['descripcion'] as String? ?? '').replaceAll(',', ';');
          final taller = (i['taller_nombre'] as String? ?? '').replaceAll(',', ';');
          final monto = i['monto_pagado'] != null
              ? (i['monto_pagado'] as num).toStringAsFixed(2)
              : '';
          final fecha = (i['created_at'] as String? ?? '').substring(0, 10);
          return '${i['id']},${i['estado']},${i['tipo_incidente'] ?? ''},\"$taller\",$monto,$fecha,\"$desc\"';
        }),
      ];
      final contenido = lineas.join('\n');
      final dir = await _dirDescarga();
      final file = File('${dir!.path}/mis_incidentes_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(contenido, encoding: utf8);
      if (!mounted) return;
      _mostrarExito('CSV guardado en:\n${file.path}');
    } catch (e) {
      if (!mounted) return;
      _mostrarError('No se pudo exportar: $e');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _exportarExcel() async {
    if (_resultado == null) return;
    setState(() => _exportando = true);
    try {
      // Excel acepta TSV con extensión .xls — sin complicaciones de librerías
      final lineas = [
        'RutaSegura - Mis Incidentes\t\t\t\t\t\t',
        'Período\t$_periodoLabel\t\t\t\t\t',
        'Total\t${_resultado!['total']}\t\t\t\t\t',
        '',
        'ID\tEstado\tTipo\tTaller\tMonto Pagado (Bs)\tFecha\tDescripción',
        ..._incidentes.map((i) {
          final monto = i['monto_pagado'] != null
              ? (i['monto_pagado'] as num).toStringAsFixed(2)
              : '';
          final fecha = (i['created_at'] as String? ?? '').substring(0, 10);
          return '${i['id']}\t${i['estado']}\t${i['tipo_incidente'] ?? ''}\t${i['taller_nombre'] ?? ''}\t$monto\t$fecha\t${i['descripcion'] ?? ''}';
        }),
      ];
      final contenido = lineas.join('\n');
      final dir = await _dirDescarga();
      final file = File('${dir!.path}/mis_incidentes_${DateTime.now().millisecondsSinceEpoch}.xls');
      await file.writeAsString(contenido, encoding: utf8);
      if (!mounted) return;
      _mostrarExito('Excel guardado en:\n${file.path}');
    } catch (e) {
      if (!mounted) return;
      _mostrarError('No se pudo exportar: $e');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _exportarPDF() async {
    if (_resultado == null) return;
    setState(() => _exportando = true);
    try {
      final pdf = pw.Document();
      final azul  = PdfColor.fromHex('#1D4ED8');
      final verde = PdfColor.fromHex('#16A34A');
      final gris  = PdfColor.fromHex('#6B7280');
      final light = PdfColor.fromHex('#F9FAFB');
      final borde = PdfColor.fromHex('#E5E7EB');

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          // ── Encabezado ──────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: azul,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('RutaSegura — Mis Incidentes',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text('Período: $_periodoLabel  ·  Total: ${_resultado!['total']} incidente(s)',
                    style: pw.TextStyle(fontSize: 9, color: PdfColor(0.85, 0.85, 0.85))),
                pw.Text('Generado: ${DateTime.now().toLocal().toString().substring(0, 16)}',
                    style: pw.TextStyle(fontSize: 9, color: PdfColor(0.85, 0.85, 0.85))),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ── Filas de incidentes ─────────────────────────
          ..._incidentes.map((inc) {
            final estado = inc['estado'] as String? ?? '—';
            final monto  = inc['monto_pagado'] != null
                ? 'Bs ${(inc['monto_pagado'] as num).toStringAsFixed(2)}'
                : '—';
            final fecha  = (inc['created_at'] as String? ?? '').length >= 10
                ? (inc['created_at'] as String).substring(0, 10)
                : '—';

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: light,
                border: pw.Border.all(color: borde),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Incidente #${inc['id']}',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: estado == 'resuelto' ? verde : azul,
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(estado,
                            style: pw.TextStyle(fontSize: 8, color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Divider(color: borde, thickness: 0.5),
                  pw.SizedBox(height: 4),
                  pw.Row(children: [
                    _pdfCell('Tipo', inc['tipo_incidente'] as String? ?? '—', gris),
                    pw.SizedBox(width: 20),
                    _pdfCell('Taller', inc['taller_nombre'] as String? ?? '—', gris),
                    pw.SizedBox(width: 20),
                    _pdfCell('Pagado', monto, verde),
                    pw.SizedBox(width: 20),
                    _pdfCell('Fecha', fecha, gris),
                  ]),
                  if ((inc['descripcion'] as String?)?.isNotEmpty == true) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(inc['descripcion'] as String,
                        style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#374151')),
                        maxLines: 2),
                  ],
                ],
              ),
            );
          }),

          // ── Pie ─────────────────────────────────────────
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text('Generado por RutaSegura',
                style: pw.TextStyle(fontSize: 8, color: gris)),
          ),
        ],
      ));

      final bytes = await pdf.save();
      final dir   = await _dirDescarga();
      final file  = File('${dir!.path}/mis_incidentes_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      _mostrarExito('PDF guardado en:\n${file.path}');
    } catch (e) {
      if (!mounted) return;
      _mostrarError('No se pudo exportar: $e');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  pw.Widget _pdfCell(String label, String value, PdfColor color) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label.toUpperCase(),
          style: pw.TextStyle(fontSize: 7, color: PdfColor.fromHex('#9CA3AF'))),
      pw.Text(value,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
    ],
  );

  void _mostrarExito(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(children: [
          Icon(Icons.check_circle_outline, color: AppColors.success),
          SizedBox(width: 8),
          Text('Exportado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.danger,
      content: Text(msg, style: const TextStyle(color: Colors.white)),
    ));
  }

  // ── Estado ──────────────────────────────────────────────

  String _estadoBadgeLabel(String? est) => {
    'pendiente': 'Pendiente',
    'en_proceso': 'En proceso',
    'resuelto': 'Atendido',
    'cancelado': 'Cancelado',
  }[est ?? ''] ?? (est ?? '—');

  Color _estadoColor(String? est) => {
    'pendiente': const Color(0xFFF59E0B),
    'en_proceso': AppColors.primary,
    'resuelto': AppColors.success,
    'cancelado': AppColors.danger,
  }[est ?? ''] ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Mis Reportes', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ── Card de filtros ─────────────────────────────
          _FiltroCard(
            // Período
            chipPeriodo: _chipPeriodo,
            periodoChips: _periodoChips,
            onChip: _seleccionarChipPeriodo,
            // Fechas
            fechaInicio: _fechaInicio,
            fechaFin: _fechaFin,
            onFechaInicio: () => _abrirDatePicker(true),
            onFechaFin: () => _abrirDatePicker(false),
            onLimpiarFechas: () => setState(() {
              _fechaInicio = null; _fechaFin = null; _chipPeriodo = '';
            }),
            fmt: _fmt,
            // Monto
            montoMinimo: _montoMinimo,
            montoBtns: _montoBtns,
            onMonto: (v) => setState(() => _montoMinimo = v),
            // Consulta texto
            queryCtrl: _queryCtrl,
            grabando: _grabando,
            transcribiendo: _transcribiendo,
            loading: _loading,
            onMic: _transcribiendo ? null : (_grabando ? _detenerGrabacion : _iniciarGrabacion),
            onBuscar: () => _consultar(_construirConsulta()),
          ),

          if (_grabando) ...[
            const SizedBox(height: 8),
            Row(children: [
              const SizedBox(width: 4),
              const Icon(Icons.circle, color: Colors.red, size: 9),
              const SizedBox(width: 6),
              const Text('Grabando… pulsá stop para detener',
                  style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
            ]),
          ],
          if (_transcribiendo) ...[
            const SizedBox(height: 8),
            const Row(children: [
              SizedBox(width: 4),
              SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Transcribiendo…', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ]),
          ],

          if (_error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ),
          ],

          const SizedBox(height: 14),

          // ── Resultado ──────────────────────────────────
          if (_resultado != null) ...[
            // Encabezado + exportar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(_periodoLabel,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_incidentes.length} resultado${_incidentes.length != 1 ? 's' : ''}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (_montoMinimo != null) ...[
                    const SizedBox(height: 4),
                    Text('Filtrado: pagos ≥ Bs ${_montoMinimo!.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _BtnExportar(icon: Icons.table_rows_outlined, label: 'CSV',
                          color: const Color(0xFF16A34A), loading: _exportando, onTap: _exportarCSV),
                      const SizedBox(width: 8),
                      _BtnExportar(icon: Icons.grid_on_outlined, label: 'Excel',
                          color: const Color(0xFF0891B2), loading: _exportando, onTap: _exportarExcel),
                      const SizedBox(width: 8),
                      _BtnExportar(icon: Icons.description_outlined, label: 'PDF',
                          color: const Color(0xFFDC2626), loading: _exportando, onTap: _exportarPDF),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Lista de incidentes
            ..._incidentes.map((inc) {
              final est = inc['estado'] as String?;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 5)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Incidente #${inc['id']}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.text)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _estadoColor(est).withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_estadoBadgeLabel(est),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _estadoColor(est))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if ((inc['tipo_incidente'] as String?) != null)
                      _Fila(icon: Icons.build_outlined, label: 'Tipo: ${inc['tipo_incidente']}'),
                    if ((inc['taller_nombre'] as String?)?.isNotEmpty == true)
                      _Fila(icon: Icons.store_outlined, label: 'Taller: ${inc['taller_nombre']}'),
                    if (inc['monto_pagado'] != null)
                      _Fila(
                        icon: Icons.payments_outlined,
                        label: 'Pagado: Bs ${(inc['monto_pagado'] as num).toStringAsFixed(2)}',
                        color: const Color(0xFF16A34A),
                      ),
                    if ((inc['created_at'] as String?) != null)
                      _Fila(icon: Icons.calendar_today_outlined,
                          label: (inc['created_at'] as String).substring(0, 10)),
                    if ((inc['descripcion'] as String?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(inc['descripcion'] as String,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              );
            }),

            if (_incidentes.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _montoMinimo != null
                        ? 'No hay incidentes con pagos ≥ Bs ${_montoMinimo!.toStringAsFixed(0)}'
                        : 'No hay incidentes en este período.',
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Botón de exportar ────────────────────────────────────
class _BtnExportar extends StatelessWidget {
  const _BtnExportar({
    required this.icon,
    required this.label,
    required this.color,
    required this.loading,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: loading
          ? const SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: Colors.white, size: 15),
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
    ),
  );
}

class _Fila extends StatelessWidget {
  const _Fila({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(children: [
      Icon(icon, size: 14, color: color ?? const Color(0xFF6B7280)),
      const SizedBox(width: 6),
      Expanded(child: Text(label,
          style: TextStyle(fontSize: 12, color: color ?? const Color(0xFF374151),
              fontWeight: color != null ? FontWeight.w700 : FontWeight.normal))),
    ]),
  );
}

// ── Card de filtros ──────────────────────────────────────
class _FiltroCard extends StatelessWidget {
  const _FiltroCard({
    required this.chipPeriodo,
    required this.periodoChips,
    required this.onChip,
    required this.fechaInicio,
    required this.fechaFin,
    required this.onFechaInicio,
    required this.onFechaFin,
    required this.onLimpiarFechas,
    required this.fmt,
    required this.montoMinimo,
    required this.montoBtns,
    required this.onMonto,
    required this.queryCtrl,
    required this.grabando,
    required this.transcribiendo,
    required this.loading,
    required this.onMic,
    required this.onBuscar,
  });

  final String chipPeriodo;
  final List<(String, String)> periodoChips;
  final void Function(String) onChip;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final VoidCallback onFechaInicio;
  final VoidCallback onFechaFin;
  final VoidCallback onLimpiarFechas;
  final String Function(DateTime) fmt;
  final double? montoMinimo;
  final List<(String, double?)> montoBtns;
  final void Function(double?) onMonto;
  final TextEditingController queryCtrl;
  final bool grabando;
  final bool transcribiendo;
  final bool loading;
  final VoidCallback? onMic;
  final VoidCallback onBuscar;

  @override
  Widget build(BuildContext context) {
    const sep = SizedBox(height: 14);
    const divider = Divider(color: Color(0xFFE5E7EB), height: 1);
    const labelStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.3);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(children: [
              Icon(Icons.filter_list_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Filtros de búsqueda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Período rápido ──────────────────────
                const Text('PERÍODO', style: labelStyle),
                const SizedBox(height: 8),
                Row(
                  children: periodoChips.map((c) {
                    final sel = chipPeriodo == c.$2;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onChip(c.$2),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE5E7EB)),
                          ),
                          child: Text(c.$1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : const Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                sep,
                divider,
                sep,

                // ── Rango de fechas ─────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RANGO DE FECHAS', style: labelStyle),
                    if (fechaInicio != null || fechaFin != null)
                      GestureDetector(
                        onTap: onLimpiarFechas,
                        child: const Text('Limpiar',
                            style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _DateField(
                      label: 'Desde',
                      value: fechaInicio != null ? fmt(fechaInicio!) : null,
                      onTap: onFechaInicio,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _DateField(
                      label: 'Hasta',
                      value: fechaFin != null ? fmt(fechaFin!) : null,
                      onTap: onFechaFin,
                    )),
                  ],
                ),

                sep,
                divider,
                sep,

                // ── Filtro de monto ─────────────────────
                const Text('MONTO MÍNIMO PAGADO', style: labelStyle),
                const SizedBox(height: 8),
                Row(
                  children: montoBtns.map((b) {
                    final sel = montoMinimo == b.$2;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onMonto(b.$2),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFF16A34A) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sel ? const Color(0xFF16A34A) : const Color(0xFFE5E7EB)),
                          ),
                          child: Text(b.$1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : const Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                sep,
                divider,
                sep,

                // ── Consulta libre ──────────────────────
                const Text('CONSULTA LIBRE (OPCIONAL)', style: labelStyle),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: queryCtrl,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Ej: mis incidentes de mayo…',
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Micrófono
                    GestureDetector(
                      onTap: onMic,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: grabando ? AppColors.danger : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: grabando ? AppColors.danger : const Color(0xFFE5E7EB)),
                        ),
                        child: transcribiendo
                            ? const Center(child: SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2)))
                            : Icon(grabando ? Icons.stop_rounded : Icons.mic_rounded,
                                color: grabando ? Colors.white : const Color(0xFF6B7280), size: 20),
                      ),
                    ),
                  ],
                ),

                sep,

                // ── Botón Buscar ────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : onBuscar,
                    icon: loading
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search_rounded, size: 18),
                    label: Text(loading ? 'Buscando…' : 'Buscar reportes',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: value != null ? AppColors.primary.withValues(alpha: 0.06) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: value != null ? AppColors.primary : const Color(0xFFE5E7EB)),
      ),
      child: Row(children: [
        Icon(Icons.calendar_today_outlined,
            size: 14, color: value != null ? AppColors.primary : const Color(0xFF9CA3AF)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value ?? label,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: value != null ? AppColors.primary : const Color(0xFF9CA3AF),
              )),
        ),
      ]),
    ),
  );
}
