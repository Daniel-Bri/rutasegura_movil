import 'package:flutter/material.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/taller_service.dart';
import 'package:taller_movil/services/api_helper.dart';

/// CU31 – El cliente confirma que el técnico llegó a su ubicación.
class VerificarLlegadaPage extends StatefulWidget {
  const VerificarLlegadaPage({super.key});

  @override
  State<VerificarLlegadaPage> createState() => _VerificarLlegadaPageState();
}

class _VerificarLlegadaPageState extends State<VerificarLlegadaPage> {
  final _svc = TallerService();

  List<AsignacionModel> _asignaciones = [];
  bool _loading = false;
  bool _confirmando = false;
  String _error = '';
  bool _confirmado = false;
  int? _asignacionConfirmada;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final data = await _svc.listarMisAsignacionesCliente();
      if (!mounted) return;
      setState(() {
        _asignaciones = data.where((a) => a.estado == 'en_camino').toList();
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

  Future<void> _confirmar(int asignacionId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar llegada'),
        content: const Text(
          '¿El técnico ya llegó a tu ubicación?\nEsto iniciará la fase de reparación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No todavía'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, confirmar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() { _confirmando = true; _error = ''; });
    try {
      await _svc.confirmarLlegadaTecnico(asignacionId);
      if (!mounted) return;
      setState(() {
        _confirmado = true;
        _asignacionConfirmada = asignacionId;
        _confirmando = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is TokenExpiradoException) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _confirmando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Verificar Llegada del Técnico',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _confirmado ? _buildSuccess() : _buildContent(),
      ),
    );
  }

  Widget _buildSuccess() => Column(
    children: [
      const SizedBox(height: 40),
      const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
      const SizedBox(height: 16),
      Text(
        'Llegada confirmada (asignación #$_asignacionConfirmada)',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      const Text(
        'El técnico está en tu ubicación. El servicio está en progreso.',
        style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 32),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Volver al inicio'),
        ),
      ),
    ],
  );

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_error, style: const TextStyle(color: AppColors.danger)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
        ],
      );
    }

    if (_asignaciones.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.directions_car_outlined, size: 48, color: Color(0xFF9CA3AF)),
              SizedBox(height: 12),
              Text(
                'No tienes técnicos en camino en este momento.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Técnicos en camino:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
        ),
        const SizedBox(height: 16),
        ..._asignaciones.map((a) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Asignación #${a.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.text,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'En camino',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Incidente #${a.incidenteId}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              if (a.eta != null) ...[
                const SizedBox(height: 4),
                Text(
                  'ETA estimado: ${a.eta} minutos',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmando ? null : () => _confirmar(a.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: _confirmando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirmar llegada',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
