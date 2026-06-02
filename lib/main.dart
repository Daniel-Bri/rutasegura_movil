import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/auth_service.dart';
// ignore: unused_import
import 'package:taller_movil/services/notificacion_service.dart';
import 'package:taller_movil/shared/acceso_denegado_page.dart';

// Acceso y Registro
import 'package:taller_movil/features/acceso_registro/iniciar_sesion/iniciar_sesion_page.dart';
import 'package:taller_movil/features/acceso_registro/registrarse/registrarse_page.dart';
import 'package:taller_movil/features/acceso_registro/cambiar_contrasena/cambiar_contrasena_page.dart';
import 'package:taller_movil/features/acceso_registro/recuperar_contrasena/recuperar_contrasena_page.dart';
import 'package:taller_movil/features/acceso_registro/registrar_vehiculo/registrar_vehiculo_page.dart';
import 'package:taller_movil/features/acceso_registro/gestionar_vehiculos/gestionar_vehiculos_page.dart';
import 'package:taller_movil/features/acceso_registro/registrar_taller/registrar_taller_page.dart';
import 'package:taller_movil/features/acceso_registro/aprobar_talleres/aprobar_talleres_page.dart';
import 'package:taller_movil/features/acceso_registro/gestionar_usuarios/gestionar_usuarios_page.dart';

// Dashboard
import 'package:taller_movil/features/dashboard/dashboard_page.dart';

// Emergencias
import 'package:taller_movil/features/emergencias/reportar_emergencia/reportar_emergencia_page.dart';
import 'package:taller_movil/features/emergencias/enviar_audio/enviar_audio_page.dart';
import 'package:taller_movil/features/emergencias/agregar_descripcion/agregar_descripcion_page.dart';

// Solicitudes
import 'package:taller_movil/features/solicitudes/ver_estado_solicitud/ver_estado_solicitud_page.dart';
import 'package:taller_movil/features/solicitudes/cancelar_solicitud/cancelar_solicitud_page.dart';
import 'package:taller_movil/features/solicitudes/ver_solicitudes_disponibles/ver_solicitudes_disponibles_page.dart';
import 'package:taller_movil/features/solicitudes/ver_detalle_incidente/ver_detalle_incidente_page.dart';
import 'package:taller_movil/features/solicitudes/aceptar_solicitud/aceptar_solicitud_page.dart';
import 'package:taller_movil/features/solicitudes/rechazar_solicitud/rechazar_solicitud_page.dart';
import 'package:taller_movil/features/solicitudes/verificar_llegada/verificar_llegada_page.dart';

// Talleres y Técnicos
import 'package:taller_movil/features/talleres_tecnicos/gestionar_tecnicos/gestionar_tecnicos_page.dart';
import 'package:taller_movil/features/talleres_tecnicos/gestionar_disponibilidad/gestionar_disponibilidad_page.dart';
import 'package:taller_movil/features/talleres_tecnicos/actualizar_estado_servicio/actualizar_estado_servicio_page.dart';
import 'package:taller_movil/features/talleres_tecnicos/registrar_servicio_realizado/registrar_servicio_realizado_page.dart';

// Cotización y Pagos
import 'package:taller_movil/features/cotizacion_pagos/generar_cotizacion/generar_cotizacion_page.dart';
import 'package:taller_movil/features/cotizacion_pagos/ver_cotizacion/ver_cotizacion_page.dart';
import 'package:taller_movil/features/cotizacion_pagos/confirmar_cotizacion/confirmar_cotizacion_page.dart';
import 'package:taller_movil/features/cotizacion_pagos/realizar_pago/realizar_pago_page.dart';
import 'package:taller_movil/features/cotizacion_pagos/ver_comisiones/ver_comisiones_page.dart';

// Comunicación
import 'package:taller_movil/features/comunicacion/chat/chat_page.dart';
import 'package:taller_movil/features/comunicacion/notificaciones/notificaciones_page.dart';
import 'package:taller_movil/features/comunicacion/ver_tecnico_mapa/ver_tecnico_mapa_page.dart';
import 'package:taller_movil/features/comunicacion/compartir_ubicacion/compartir_ubicacion_page.dart';

// Reportes
import 'package:taller_movil/features/reportes/historial_servicios/historial_servicios_page.dart';
import 'package:taller_movil/features/reportes/calificar_servicio/calificar_servicio_page.dart';
import 'package:taller_movil/features/reportes/recordatorios_mantenimiento/recordatorios_mantenimiento_page.dart';
import 'package:taller_movil/features/reportes/metricas_taller/metricas_taller_page.dart';
import 'package:taller_movil/features/reportes/metricas_globales/metricas_globales_page.dart';
import 'package:taller_movil/features/reportes/auditoria/auditoria_page.dart';

import 'dart:async';
import 'package:taller_movil/services/websocket_service.dart';
import 'package:taller_movil/services/offline_queue_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  runApp(const RutaSegura());
}

class RutaSegura extends StatefulWidget {
  const RutaSegura({super.key});

  @override
  State<RutaSegura> createState() => _RutaSeguraState();
}

class _RutaSeguraState extends State<RutaSegura> {
  StreamSubscription? _notifSub;
  StreamSubscription? _msgSub;

  @override
  void initState() {
    super.initState();
    _notifSub = WebSocketService().on('notificacion').listen((payload) {
      _showSnack(
        payload['titulo'] as String? ?? 'Notificación',
        payload['mensaje'] as String? ?? '',
      );
    });
    _msgSub = WebSocketService().on('nuevo_mensaje').listen((payload) {
      final remitente = payload['remitente'] as String? ?? 'Nuevo mensaje';
      final contenido = payload['contenido'] as String? ?? '';
      _showSnack('Mensaje de $remitente', contenido);
    });
  }

  void _showSnack(String titulo, String mensaje) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      backgroundColor: const Color(0xFF1E3A8A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 4),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
          if (mensaje.isNotEmpty)
            Text(mensaje, style: const TextStyle(fontSize: 12, color: Color(0xFFBFDBFE)), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    ));
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _msgSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RutaSegura',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const _SplashRouter(),
      routes: {
        // ── Auth ──────────────────────────────────────────
        '/login':                    (_) => const IniciarSesionPage(),
        '/registro':                 (_) => const RegistrarsePage(),
        '/recuperar-contrasena':     (_) => const RecuperarContrasenaPage(),
        '/dashboard':                (_) => const DashboardPage(),
        '/acceso/cambiar-contrasena': (_) => const CambiarContrasenaPage(),

        // ── Pantalla de acceso denegado ───────────────────
        '/acceso-denegado': (_) => const AccesoDenegadoPage(),

        // ── Acceso y Registro ─────────────────────────────
        '/acceso/registrar-vehiculo': (_) => const RegistrarVehiculoPage(),
        '/acceso/mis-vehiculos':      (_) => const GestionarVehiculosPage(),
        '/acceso/registrar-taller':   (_) => const RegistrarTallerPage(),
        '/aprobar-talleres':          (_) => const AprobarTalleresPage(),
        '/gestionar-usuarios':        (_) => const GestionarUsuariosPage(),

        // ── Emergencias ───────────────────────────────────
        '/emergencias/reportar':     (_) => const ReportarEmergenciaPage(),
        '/emergencias/audio':        (ctx) => EnviarAudioPage(
                                     incidenteId: (ModalRoute.of(ctx)?.settings.arguments as int?) ?? 0),
        '/emergencias/descripcion':  (_) => const AgregarDescripcionPage(),
        // ubicacion y fotos se navegan desde ReportarEmergencia (requieren incidenteId)

        // ── Solicitudes ───────────────────────────────────
        '/solicitudes/estado':       (_) => const VerEstadoSolicitudPage(),
        '/solicitudes/cancelar':     (_) => const CancelarSolicitudPage(),
        '/solicitudes/disponibles':  (_) => const VerSolicitudesDisponiblesPage(),
        '/solicitudes/detalle':      (_) => const VerDetalleIncidentePage(),
        '/solicitudes/aceptar':          (_) => const AceptarSolicitudPage(),
        '/solicitudes/rechazar':         (_) => const RechazarSolicitudPage(),
        '/solicitudes/verificar-llegada': (_) => const VerificarLlegadaPage(),

        // ── Talleres y Técnicos ───────────────────────────
        '/talleres/gestionar-tecnicos':  (_) => const GestionarTecnicosPage(),
        '/talleres/disponibilidad':      (_) => const GestionarDisponibilidadPage(),
        '/talleres/estado-servicio':     (_) => const ActualizarEstadoServicioPage(),
        '/talleres/servicio-realizado':  (_) => const RegistrarServicioRealizadoPage(),

        // ── Cotización y Pagos ────────────────────────────
        '/pagos/generar':    (_) => const GenerarCotizacionPage(),
        '/pagos/ver':        (_) => const VerCotizacionPage(),
        '/pagos/confirmar':  (_) => const ConfirmarCotizacionPage(),
        '/pagos/realizar':   (_) => const RealizarPagoPage(),
        '/pagos/comisiones': (_) => const VerComisionesPage(),

        // ── Comunicación ──────────────────────────────────
        '/comunicacion/chat':                  (_) => const ChatPage(),
        '/comunicacion/notificaciones':        (_) => const NotificacionesPage(),
        '/comunicacion/ver-tecnico':           (_) => const VerTecnicoMapaPage(),
        '/comunicacion/compartir-ubicacion':   (_) => const CompartirUbicacionPage(),

        // ── Reportes ──────────────────────────────────────
        '/reportes/historial':          (_) => const HistorialServiciosPage(),
        '/reportes/calificar':          (_) => const CalificarServicioPage(),
        '/mantenimiento/recordatorios': (_) => const RecordatoriosMantenimientoPage(),
        '/reportes/metricas-taller':    (_) => const MetricasTallerPage(),
        '/reportes/metricas-globales':  (_) => const MetricasGlobalesPage(),
        '/reportes/auditoria':          (_) => const AuditoriaPage(),
      },
    );
  }
}

// ── Splash Router ────────────────────────────────────────────
class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  bool _pushInitDone = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (snapshot.data!) {
          if (!_pushInitDone) {
            _pushInitDone = true;
            NotificacionService().inicializar(context).ignore();
          }
          WebSocketService().conectar();
          OfflineQueueService().init().then((_) => OfflineQueueService().sincronizar());
          return const DashboardPage();
        }
        return const IniciarSesionPage();
      },
    );
  }
}
