import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/family_store.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/common.dart';

/// Selector de perfil del hogar. En la versión real cada persona usa su
/// propio celular; en esta demo permite probar todos los roles en uno.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          children: [
            Text('family_app', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(store.homeName, style: mutedText(context).copyWith(fontSize: 15)),
            const SizedBox(height: 24),
            Text('¿Quién usa la app?', style: sectionTitle(context)),
            const SizedBox(height: 12),
            for (final m in store.members.where((m) => !store.isPendingMember(m.id))) ...[
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(Routes.join),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Me invitaron: unirme a un hogar'),
            ),
          ],
        ),
      ),
    );
  }
}
