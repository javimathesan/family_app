import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/app_session.dart';
import '../../data/family_cloud.dart';
import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/common.dart';

/// Familias amigas: los adultos de dos hogares se aprueban mutuamente y
/// eligen quiénes pueden jugar. Solo se comparten apodo y avatar; no hay chat.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, this.initialCode});

  /// Código que llegó al escanear un QR de amistad.
  final String? initialCode;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _handledInitial = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_handledInitial && widget.initialCode != null) {
      _handledInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _acceptCode(widget.initialCode!));
    }
  }

  Future<List<Member>?> _pickMembers(String title, {List<String> preselected = const []}) {
    final store = FamilyScope.of(context);
    final people = [for (final m in store.members) if (!store.isPendingMember(m.id)) m];
    final chosen = {...(preselected.isEmpty ? [for (final m in people) if (!m.role.isAdult) m.id] : preselected)};
    return showDialog<List<Member>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Solo se comparte el apodo y el avatar.'),
                for (final m in people)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: chosen.contains(m.id),
                    secondary: AvatarView(config: m.avatar, size: 36),
                    title: Text(m.nickname),
                    onChanged: (v) => setD(() => v! ? chosen.add(m.id) : chosen.remove(m.id)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, [for (final m in people) if (chosen.contains(m.id)) m]), child: const Text('Listo')),
          ],
        ),
      ),
    );
  }

  Future<void> _invite() async {
    final session = SessionScope.of(context);
    final kids = await _pickMembers('¿Quiénes van a poder jugar con esa familia?');
    if (kids == null || !mounted) return;
    try {
      final code = await session.createFriendInvite(kids);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Código de amistad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mostráselo a un adulto de la otra familia. Lo escanea con la cámara o lo escribe en "Tengo un código". Vence en 24 horas.'),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(data: 'familyapp://app/amigos?code=$code', backgroundColor: Colors.white),
              ),
              SelectableText(code, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Listo'))],
        ),
      );
    } catch (error) {
      if (mounted) _snack(error is JoinException ? error.message : 'No se pudo crear el código. Revisá la conexión.');
    }
  }

  Future<void> _acceptCode([String? preset]) async {
    final session = SessionScope.of(context);
    var code = preset;
    if (code == null) {
      final controller = TextEditingController();
      code = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tengo un código'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'AMI-XXXX', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Seguir')),
          ],
        ),
      );
      controller.dispose();
    }
    if (code == null || code.trim().isEmpty || !mounted) return;
    try {
      final other = await session.lookupFriendInvite(code);
      if (!mounted) return;
      final kids = await _pickMembers('Amistad con ${other.homeName}: ¿quiénes van a poder jugar?');
      if (kids == null || !mounted) return;
      await session.acceptFriendInvite(code, kids);
      _snack('¡Listo! Ahora son amigos de ${other.homeName}.');
    } catch (error) {
      _snack(error is JoinException ? error.message : 'No se pudo usar el código. Revisá la conexión.');
    }
  }

  /// Tarjeta de una familia amiga, plegable para que muchas entren en pantalla.
  Widget _friendCard(Friendship f, {required bool expanded}) {
    final store = FamilyScope.of(context);
    final session = SessionScope.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey('amistad_${f.id}_$expanded'),
        initiallyExpanded: expanded,
        shape: const Border(),
        collapsedShape: const Border(),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text('🤝 ${f.otherHome}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        subtitle: Text('${f.theirs.length} de su familia · ${f.mine.length} de la tuya'),
        children: [
          Text('Pueden jugar de su familia:', style: mutedText(context)),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final k in f.theirs) Chip(avatar: AvatarView(config: k.avatar, size: 24), label: Text(k.nickname)),
              if (f.theirs.isEmpty) const Text('nadie todavía'),
            ],
          ),
          const SizedBox(height: 6),
          Text('Pueden jugar de tu familia:', style: mutedText(context)),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final m in store.members)
                if (!store.isPendingMember(m.id))
                  FilterChip(
                    label: Text(m.nickname),
                    selected: f.mine.any((k) => k.id == m.id),
                    onSelected: !session.isAdmin
                        ? null
                        : (on) {
                            final ids = {for (final k in f.mine) k.id};
                            on ? ids.add(m.id) : ids.remove(m.id);
                            session.setFriendKids(f.id, [for (final x in store.members) if (ids.contains(x.id)) x]);
                          },
                  ),
            ],
          ),
          if (session.isAdmin)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('¿Terminar la amistad con ${f.otherHome}?'),
                      content: const Text('Ya no van a poder jugar juntos. Para volver hace falta un código nuevo.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Terminar')),
                      ],
                    ),
                  );
                  if (ok == true) await session.endFriendship(f.id);
                },
                icon: const Icon(Icons.link_off),
                label: const Text('Terminar amistad'),
              ),
            ),
        ],
      ),
    );
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final session = SessionScope.of(context);
    final friends = [...store.friendships]..sort((a, b) => a.otherHome.toLowerCase().compareTo(b.otherHome.toLowerCase()));
    final query = _search.text.trim().toLowerCase();
    final shown = [
      for (final f in friends)
        if (query.isEmpty ||
            f.otherHome.toLowerCase().contains(query) ||
            f.theirs.any((k) => k.nickname.toLowerCase().contains(query)))
          f,
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Familias amigas', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const InfoCard(
              color: Color(0xFFE8F5E9),
              child: Text(
                '🛡️ Los chicos juegan solo con familias que aprobaron un adulto de cada casa. '
                'Se ve únicamente el apodo y el avatar, y en lugar de chat hay reacciones fijas. '
                'Podés terminar una amistad cuando quieras.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            if (!session.isCloud)
              Text('Para jugar con otras familias, primero creá tu hogar (no funciona en la demostración).', style: mutedText(context).copyWith(fontSize: 15))
            else if (!session.isAdmin)
              Text('Las amistades las maneja un adulto administrador del hogar.', style: mutedText(context).copyWith(fontSize: 15))
            else ...[
              FilledButton.icon(onPressed: _invite, icon: const Icon(Icons.qr_code_2), label: const Text('Invitar a una familia')),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: _acceptCode, icon: const Icon(Icons.keyboard), label: const Text('Tengo un código')),
            ],
            const SizedBox(height: 20),
            Text(friends.isEmpty ? 'Amistades' : 'Amistades (${friends.length})', style: sectionTitle(context)),
            const SizedBox(height: 8),
            if (friends.isEmpty) Text('Todavía no tienen familias amigas.', style: mutedText(context)),
            if (friends.length > 3) ...[
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar familia o apodo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (friends.isNotEmpty && shown.isEmpty) Text('Ninguna familia coincide con la búsqueda.', style: mutedText(context)),
            // Teléfono: una debajo de otra; tablet: dos columnas.
            LayoutBuilder(
              builder: (context, box) {
                final columns = box.maxWidth >= 700 ? 2 : 1;
                final width = (box.maxWidth - 12 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 12,
                  children: [
                    for (final f in shown) SizedBox(width: width, child: _friendCard(f, expanded: friends.length <= 3 || query.isNotEmpty)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
