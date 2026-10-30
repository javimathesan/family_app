import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/app_session.dart';
import '../../data/family_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/common.dart';

/// Inicio: elegir qué hacer la primera vez, esperar aprobación o elegir perfil.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final Widget body;
    if (session.mode == SessionMode.none) {
      body = const _FirstSteps();
    } else if (session.pendingApproval) {
      body = const _WaitingApproval();
    } else {
      body = const _ProfilePicker();
    }
    return Scaffold(body: SafeArea(child: body));
  }
}

class _FirstSteps extends StatelessWidget {
  const _FirstSteps();

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      children: [
        Text('Family App', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Hábitos, responsabilidades y premios para toda la familia.', style: mutedText(context).copyWith(fontSize: 16)),
        const SizedBox(height: 28),
        _Choice(
          icon: Icons.home_outlined,
          title: 'Crear mi hogar',
          subtitle: 'Soy el adulto a cargo. Después invito al resto con un QR.',
          onTap: session.cloudAvailable ? () => Navigator.of(context).pushNamed(Routes.createHome) : null,
        ),
        const SizedBox(height: 12),
        _Choice(
          icon: Icons.qr_code_scanner,
          title: 'Me invitaron',
          subtitle: 'Escaneo el QR que me muestra un adulto del hogar.',
          onTap: session.cloudAvailable ? () => Navigator.of(context).pushNamed(Routes.join) : null,
        ),
        const SizedBox(height: 12),
        _Choice(
          icon: Icons.science_outlined,
          title: 'Probar con datos de ejemplo',
          subtitle: 'Una familia inventada para conocer la app. Queda solo en este teléfono.',
          onTap: () => session.startDemo(),
        ),
        if (!session.cloudAvailable) ...[
          const SizedBox(height: 20),
          const InfoCard(
            color: AppColors.warmBg,
            child: Text(
              'Sin conexión con el servidor: por ahora solo está disponible la demostración. '
              'Revisá internet y volvé a abrir la app.',
              style: TextStyle(color: Color(0xFF7C2D12), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: InfoCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: IconBadge(icon: icon, background: accent.withValues(alpha: 0.12), color: accent),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _WaitingApproval extends StatelessWidget {
  const _WaitingApproval();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 64, color: Color(0xFF1D4ED8)),
            const SizedBox(height: 12),
            Text('Esperando aprobación', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Un adulto del hogar tiene que confirmar tu alta.', textAlign: TextAlign.center, style: mutedText(context).copyWith(fontSize: 16)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed(Routes.join),
              child: const Text('Ver estado'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePicker extends StatelessWidget {
  const _ProfilePicker();

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final store = FamilyScope.of(context);
    final profiles = session.profilesOnThisDevice;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      children: [
        Text('Family App', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          session.isDemo ? '${store.homeName} · demostración' : (store.homeName.isEmpty ? 'Cargando tu hogar…' : store.homeName),
          style: mutedText(context).copyWith(fontSize: 15),
        ),
        const SizedBox(height: 24),
        Text('¿Quién usa la app?', style: sectionTitle(context)),
        const SizedBox(height: 12),
        if (profiles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        for (final m in profiles) ...[
          InfoCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: AvatarView(config: m.avatar, size: 48, background: m.accent.withValues(alpha: 0.15)),
              title: Text(m.nickname, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              subtitle: Text(m.mode == null ? m.role.label : '${m.role.label} · ${m.mode!.label}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                store.signInAs(m.id);
                Navigator.of(context).pushReplacementNamed(m.role.isAdult ? Routes.adult : Routes.child);
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (session.isDemo) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => session.leave(),
            icon: const Icon(Icons.logout),
            label: const Text('Salir de la demostración'),
          ),
        ],
      ],
    );
  }
}
