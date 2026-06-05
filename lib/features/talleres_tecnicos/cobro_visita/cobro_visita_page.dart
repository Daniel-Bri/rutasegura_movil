import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taller_movil/core/config/app_config.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/auth_service.dart';
import 'package:taller_movil/services/api_helper.dart';
import 'package:taller_movil/shared/app_drawer.dart';

/// Pantalla para que el técnico/taller registre un cobro por desplazamiento
/// cuando llegó al sitio pero no realizó el servicio (cliente canceló o tenía seguro).
/// Recibe [asignacionId] como argumento de ruta.
class CobroVisitaPage extends StatefulWidget {
  const CobroVisitaPage({super.key});

  @override
  State<CobroVisitaPage> createState() => _CobroVisitaPageState();
}

class _CobroVisitaPageState extends State<CobroVisitaPage> {
  final _auth        = AuthService();
  final _montoCtrl   = TextEditingController();
  final _conceptoCtrl = TextEditingController(text: 'Cobro por desplazamiento al sitio');
  final _formKey     = GlobalKey<FormState>();

  int? _asignacionId;
  bool _loading = false;
  bool _exito   = false;
  String _error = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) _asignacionId = args;
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _conceptoCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_asignacionId == null) return;

    setState(() { _loading = true; _error = ''; });

    try {
      final token = await _auth.getToken();
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/talleres/asignaciones/$_asignacionId/cobro-visita'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'monto':    double.parse(_montoCtrl.text.trim()),
          'concepto': _conceptoCtrl.text.trim(),
        }),
      );

      if (res.statusCode == 200) {
        setState(() { _exito = true; _loading = false; });
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else {
        final detail = res.body.isNotEmpty
            ? (jsonDecode(res.body) as Map<String, dynamic>)['detail']
            : null;
        setState(() { _error = detail?.toString() ?? 'Error al registrar cobro'; _loading = false; });
      }
    } on TokenExpiradoException {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Cobro por Visita', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _exito ? _buildExito() : _buildForm(),
      ),
    );
  }

  Widget _buildExito() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(height: 40),
      const Icon(Icons.check_circle_outline, size: 72, color: AppColors.success),
      const SizedBox(height: 16),
      const Text('Cobro registrado', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
      const SizedBox(height: 8),
      const Text('El cliente fue notificado del cobro por desplazamiento.',
          textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14)),
        child: const Text('Volver al inicio'),
      )),
    ],
  );

  Widget _buildForm() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Aviso informativo
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💡 Cobro por desplazamiento', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF92400E), fontSize: 14)),
              SizedBox(height: 6),
              Text(
                'Usa esta pantalla cuando llegaste al sitio pero no pudiste realizar el servicio '
                '(el cliente canceló o el seguro lo cubrió). '
                'Este cobro es independiente de la cotización.',
                style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Monto
        const Text('Monto del cobro (Bs.) *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _montoCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Ej: 50.00',
            prefixText: 'Bs. ',
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            filled: true, fillColor: Colors.white,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'El monto es requerido';
            final n = double.tryParse(v.trim());
            if (n == null || n <= 0) return 'Ingresa un monto válido mayor a 0';
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Concepto
        const Text('Concepto',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _conceptoCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Descripción del cobro',
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            filled: true, fillColor: Colors.white,
          ),
          validator: (_) => null,
        ),

        if (_error.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8)),
            child: Text(_error, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ),
        ],

        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _loading ? null : _registrar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD97706),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Registrar cobro por visita',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        )),
      ],
    ),
  );
}
