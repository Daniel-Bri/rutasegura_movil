import 'package:flutter/material.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/auth_service.dart';
import 'package:taller_movil/services/notificacion_service.dart';

class _Item {
  final String label;
  final String route;
  final IconData icon;
  const _Item({required this.label, required this.route, required this.icon});
}

class _Section {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final List<String> roles;
  final List<_Item> items;
  const _Section({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.roles,
    required this.items,
  });
}

const _sections = [
  _Section(
    id: 'perfil',
    label: 'Mi Perfil',
    icon: Icons.person_outline,
    color: Color(0xFF6366F1),
    roles: ['cliente', 'taller'],
    items: [
      _Item(label: 'Mis Vehículos',    route: '/acceso/mis-vehiculos',    icon: Icons.directions_car_outlined),
      _Item(label: 'Registrar Taller', route: '/acceso/registrar-taller', icon: Icons.store_outlined),
    ],
  ),
  _Section(
    id: 'emergencias',
    label: 'Emergencias',
    icon: Icons.warning_amber_rounded,
    color: AppColors.danger,
    roles: ['cliente'],
    items: [
      _Item(label: 'Reportar Emergencia', route: '/emergencias/reportar', icon: Icons.add_alert_outlined),
    ],
  ),
  _Section(
    id: 'solicitudes',
    label: 'Solicitudes',
    icon: Icons.assignment_outlined,
    color: AppColors.primary,
    roles: ['cliente', 'taller'],
    items: [
      _Item(label: 'Ver Estado',           route: '/solicitudes/estado',             icon: Icons.track_changes_outlined),
      _Item(label: 'Cancelar Solicitud',   route: '/solicitudes/cancelar',           icon: Icons.cancel_outlined),
      _Item(label: 'Verificar Llegada',    route: '/solicitudes/verificar-llegada',  icon: Icons.where_to_vote_outlined),
      _Item(label: 'Ver Disponibles',      route: '/solicitudes/disponibles',        icon: Icons.list_alt_outlined),
      _Item(label: 'Detalle Incidente',    route: '/solicitudes/detalle',            icon: Icons.info_outline),
    ],
  ),
  _Section(
    id: 'talleres',
    label: 'Servicios',
    icon: Icons.build_outlined,
    color: Color(0xFF0891B2),
    roles: ['taller', 'tecnico'],
    items: [
      _Item(label: 'Gestionar Técnicos',    route: '/talleres/gestionar-tecnicos',   icon: Icons.people_outline),
      _Item(label: 'Disponibilidad',        route: '/talleres/disponibilidad',       icon: Icons.toggle_on_outlined),
      _Item(label: 'Estado del Servicio',   route: '/talleres/estado-servicio',      icon: Icons.update_outlined),
      _Item(label: 'Registrar Servicio',    route: '/talleres/servicio-realizado',   icon: Icons.task_alt_outlined),
      _Item(label: 'Compartir Ubicación',   route: '/comunicacion/compartir-ubicacion', icon: Icons.location_on_outlined),
      _Item(label: 'Cobro por Visita',      route: '/talleres/cobro-visita',            icon: Icons.receipt_outlined),
    ],
  ),
  _Section(
    id: 'pagos',
    label: 'Cotización y Pagos',
    icon: Icons.payments_outlined,
    color: Color(0xFF059669),
    roles: ['cliente', 'taller'],
    items: [
      _Item(label: 'Mis Cotizaciones',     route: '/pagos/ver',         icon: Icons.receipt_long_outlined),
      _Item(label: 'Realizar Pago',        route: '/pagos/realizar',    icon: Icons.payment_outlined),
      _Item(label: 'Generar Cotización',   route: '/pagos/generar',     icon: Icons.request_quote_outlined),
      _Item(label: 'Confirmar Cotización', route: '/pagos/confirmar',   icon: Icons.check_circle_outline),
      _Item(label: 'Ver Comisiones',       route: '/pagos/comisiones',  icon: Icons.bar_chart_outlined),
    ],
  ),
  _Section(
    id: 'comunicacion',
    label: 'Comunicación',
    icon: Icons.chat_bubble_outline,
    color: Color(0xFF7C3AED),
    roles: ['cliente', 'taller', 'tecnico'],
    items: [
      _Item(label: 'Chat',                 route: '/comunicacion/chat',              icon: Icons.chat_outlined),
      _Item(label: 'Notificaciones',       route: '/comunicacion/notificaciones',    icon: Icons.notifications_outlined),
      _Item(label: 'Ver Técnico en Mapa',  route: '/comunicacion/ver-tecnico',       icon: Icons.map_outlined),
    ],
  ),
  _Section(
    id: 'reportes',
    label: 'Reportes',
    icon: Icons.analytics_outlined,
    color: Color(0xFFD97706),
    roles: ['cliente', 'taller', 'admin'],
    items: [
      _Item(label: 'Historial de Servicios', route: '/reportes/historial',           icon: Icons.history_outlined),
      _Item(label: 'Calificar Servicio',     route: '/reportes/calificar',           icon: Icons.star_outline),
      _Item(label: 'Mis Reportes',           route: '/reportes/mis-reportes',        icon: Icons.bar_chart_outlined),
      _Item(label: 'Recordatorios',          route: '/mantenimiento/recordatorios',  icon: Icons.alarm_outlined),
      _Item(label: 'Ranking Talleres',       route: '/reportes/ranking-talleres',    icon: Icons.emoji_events_outlined),
      _Item(label: 'Métricas del Taller',    route: '/reportes/metricas-taller',     icon: Icons.trending_up_outlined),
      _Item(label: 'Métricas Globales',      route: '/reportes/metricas-globales',   icon: Icons.public_outlined),
      _Item(label: 'Auditoría',              route: '/reportes/auditoria',           icon: Icons.policy_outlined),
    ],
  ),
  _Section(
    id: 'admin',
    label: 'Administración',
    icon: Icons.admin_panel_settings_outlined,
    color: Color(0xFFDC2626),
    roles: ['admin'],
    items: [
      _Item(label: 'Gestionar Usuarios', route: '/gestionar-usuarios', icon: Icons.manage_accounts_outlined),
      _Item(label: 'Aprobar Talleres',   route: '/aprobar-talleres',   icon: Icons.verified_outlined),
    ],
  ),
];

// Items visibles por rol dentro de cada sección
const _itemRoles = <String, List<String>>{
  '/acceso/mis-vehiculos':               ['cliente'],
  '/acceso/registrar-taller':            ['taller'],
  '/emergencias/reportar':               ['cliente'],
  '/solicitudes/estado':                 ['cliente'],
  '/solicitudes/cancelar':               ['cliente'],
  '/solicitudes/verificar-llegada':      ['cliente'],
  '/solicitudes/disponibles':            ['taller'],
  '/solicitudes/detalle':                ['taller'],
  '/talleres/gestionar-tecnicos':        ['taller'],
  '/talleres/disponibilidad':            ['taller'],
  '/talleres/estado-servicio':           ['taller', 'tecnico'],
  '/talleres/servicio-realizado':        ['taller', 'tecnico'],
  '/comunicacion/compartir-ubicacion':   ['tecnico'],
  '/talleres/cobro-visita':              ['taller', 'tecnico'],
  '/pagos/ver':                          ['cliente', 'taller'],
  '/pagos/realizar':                     ['cliente'],
  '/pagos/generar':                      ['taller'],
  '/pagos/confirmar':                    ['taller'],
  '/pagos/comisiones':                   ['taller'],
  '/comunicacion/chat':                  ['cliente', 'taller', 'tecnico'],
  '/comunicacion/notificaciones':        ['cliente', 'taller'],
  '/comunicacion/ver-tecnico':           ['cliente'],
  '/reportes/historial':                 ['cliente', 'taller'],
  '/reportes/calificar':                 ['cliente'],
  '/reportes/mis-reportes':             ['cliente'],
  '/mantenimiento/recordatorios':        ['cliente'],
  '/reportes/ranking-talleres':          ['cliente', 'taller', 'admin'],
  '/reportes/metricas-taller':           ['taller'],
  '/reportes/metricas-globales':         ['admin'],
  '/reportes/auditoria':                 ['admin'],
  '/gestionar-usuarios':                 ['admin'],
  '/aprobar-talleres':                   ['admin'],
};

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});
  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _auth = AuthService();
  Map<String, dynamic>? _user;
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _auth.getUser().then((u) {
      if (mounted) setState(() => _user = u);
    });
  }

  Future<void> _logout() async {
    await NotificacionService().eliminarToken();
    await _auth.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _go(String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }

  void _toggle(String id) => setState(() {
    _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id);
  });

  String get _role => _user?['role'] as String? ?? 'cliente';

  String get _roleLabel => const {
    'admin': 'Administrador',
    'taller': 'Taller',
    'tecnico': 'Técnico',
    'cliente': 'Cliente',
  }[_role] ?? _role;

  bool _canSeeItem(String route) {
    final allowed = _itemRoles[route];
    if (allowed == null) return true;
    return allowed.contains(_role);
  }

  @override
  Widget build(BuildContext context) {
    final name    = (_user?['full_name'] ?? _user?['username'] ?? '...') as String;
    final email   = (_user?['email'] ?? '') as String;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final visibleSections = _sections.where((s) {
      if (!s.roles.contains(_role)) return false;
      return s.items.any((i) => _canSeeItem(i.route));
    }).toList();

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Cabecera ──────────────────────────────────────
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: Text(initial,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            accountName: Text(name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
            accountEmail: Row(children: [
              Flexible(child: Text(email,
                  style: const TextStyle(fontSize: 12, color: Colors.white70))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_roleLabel,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ]),
          ),

          // ── Navegación ────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Inicio
                _NavTile(
                  icon: Icons.home_outlined,
                  label: 'Inicio',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                ),

                // Secciones filtradas por rol
                for (final section in visibleSections) ...[
                  _SectionTile(
                    section: section,
                    isOpen: _expanded.contains(section.id),
                    onToggle: () => _toggle(section.id),
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _expanded.contains(section.id)
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Container(
                      color: const Color(0xFFF9FAFB),
                      child: Column(
                        children: section.items
                            .where((i) => _canSeeItem(i.route))
                            .map((item) => _SubItem(
                                  label: item.label,
                                  icon: item.icon,
                                  color: section.color,
                                  onTap: () => _go(item.route),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                  ),
                ],
              ],
            ),
          ),

          // ── Pie ───────────────────────────────────────────
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          _NavTile(
            icon: Icons.lock_outline,
            label: 'Cambiar contraseña',
            color: AppColors.primary,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/acceso/cambiar-contrasena');
            },
          ),
          _NavTile(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            color: AppColors.danger,
            onTap: _logout,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color, size: 22),
    title: Text(label,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
            color: color == AppColors.danger ? AppColors.danger : AppColors.text)),
    horizontalTitleGap: 8,
    onTap: onTap,
  );
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.section, required this.isOpen, required this.onToggle});
  final _Section section;
  final bool isOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: section.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(section.icon, color: section.color, size: 18),
    ),
    title: Text(section.label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text)),
    trailing: AnimatedRotation(
      turns: isOpen ? 0.5 : 0,
      duration: const Duration(milliseconds: 200),
      child: const Icon(Icons.expand_more, color: Color(0xFF9CA3AF), size: 20),
    ),
    horizontalTitleGap: 8,
    onTap: onToggle,
  );
}

class _SubItem extends StatelessWidget {
  const _SubItem({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.only(left: 56, right: 16),
    dense: true,
    leading: Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
    title: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.text)),
    horizontalTitleGap: 6,
    onTap: onTap,
  );
}
