import 'package:flutter/material.dart';
import 'package:taller_movil/services/offline_queue_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OfflineQueueService(),
      builder: (context, _) {
        final svc = OfflineQueueService();
        if (svc.pendientes == 0) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFFEF3C7),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, size: 16, color: Color(0xFF92400E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${svc.pendientes} acción${svc.pendientes > 1 ? 'es' : ''} pendiente${svc.pendientes > 1 ? 's' : ''} de sincronización',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
