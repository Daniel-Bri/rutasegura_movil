import 'package:flutter/material.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/location_sharing_service.dart';

class CompartirUbicacionPage extends StatefulWidget {
  const CompartirUbicacionPage({super.key});

  @override
  State<CompartirUbicacionPage> createState() =>
      _CompartirUbicacionPageState();
}

class _CompartirUbicacionPageState extends State<CompartirUbicacionPage> {
  final _svc = LocationSharingService();

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _svc.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compartir Ubicación',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
            const SizedBox(height: 4),
            Text(
              _svc.compartiendo
                  ? 'Tu ubicación se está enviando al cliente'
                  : 'Activa para que el cliente te vea en el mapa',
              style: const TextStyle(fontSize: 13, color: AppColors.grey),
            ),
            const SizedBox(height: 28),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _svc.compartiendo ? const Color(0xFFBBF7D0) : const Color(0xFFF3F4F6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: _svc.compartiendo ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _svc.compartiendo ? Icons.location_on : Icons.location_off_outlined,
                      size: 40,
                      color: _svc.compartiendo ? AppColors.success : AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _svc.compartiendo ? 'Compartiendo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: _svc.compartiendo ? AppColors.success : AppColors.grey,
                    ),
                  ),
                  if (_svc.latitud != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${_svc.latitud!.toStringAsFixed(5)}, ${_svc.longitud!.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.grey),
                    ),
                  ],
                  if (_svc.envios > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_svc.envios} ${_svc.envios == 1 ? 'envío' : 'envíos'} realizados',
                      style: const TextStyle(fontSize: 11, color: AppColors.grey),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_svc.compartiendo) ...[
              _InfoRow(Icons.sync, 'Actualización automática', 'Cada 5 segundos'),
              const SizedBox(height: 10),
              _InfoRow(Icons.access_time_outlined, 'Último envío', _svc.ultimaActualizacion),
              const SizedBox(height: 10),
              _InfoRow(Icons.info_outline, 'Modo', 'Sigue activo al salir de esta pantalla'),
              const SizedBox(height: 20),
            ],

            if (_svc.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_svc.error!, style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                    ),
                  ],
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _svc.compartiendo ? _svc.detener : () => _svc.iniciar(),
                icon: Icon(
                  _svc.compartiendo ? Icons.stop_circle_outlined : Icons.play_circle_outlined,
                  size: 20,
                ),
                label: Text(_svc.compartiendo ? 'Detener compartición' : 'Iniciar compartición'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _svc.compartiendo ? AppColors.danger : AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.text,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFF3F4F6), height: 1),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.text),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Text('Mi Ubicación',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
        ],
      ),
    );
  }
}
