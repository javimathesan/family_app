import 'package:flutter/material.dart';

import '../../data/app_session.dart';
import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// El adulto arma la rutina (tareas con horario y puntos) y la tienda de
/// premios del hogar. Los cambios llegan a todos los teléfonos.
class RoutineEditorScreen extends StatelessWidget {
  const RoutineEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (!session.flag('tour_routine')) {
      WidgetsBinding.instance.addPostFrameCallback((_) => session.setFlag('tour_routine'));
    }
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Rutina y premios', style: TextStyle(fontWeight: FontWeight.w800)),
              bottom: const TabBar(tabs: [Tab(text: 'Tareas'), Tab(text: 'Premios')]),
            ),
            body: const TabBarView(children: [_TasksTab(), _RewardsTab()]),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                final tab = DefaultTabController.of(context).index;
                if (tab == 0) {
                  editTask(context, null);
                } else {
                  editReward(context, null);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------------ tareas

class _TasksTab extends StatelessWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final total = store.templates.fold<int>(0, (sum, t) => sum + t.points);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        Text('${store.templates.length} tareas · hasta $total puntos por día', style: mutedText(context).copyWith(fontSize: 14)),
        const SizedBox(height: 4),
        Text('Tocá una tarea para cambiarla. Cada tarea puede ser para todos o solo para algunos hijos.', style: mutedText(context)),
        for (final block in DayBlock.values) ...[
          const SizedBox(height: 18),
          Text(block.label, style: sectionTitle(context)),
          const SizedBox(height: 8),
          if (store.tasksFor(block).isEmpty)
            Text('Sin tareas en este bloque.', style: mutedText(context)),
          for (final t in store.tasksFor(block)) ...[
            InfoCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Text(t.icon, style: const TextStyle(fontSize: 26)),
                title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${hhmm(t.time)} · ${t.validation.label} · ${_whoLabel(store, t)}'),
                trailing: Text('+${t.points}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                onTap: () => editTask(context, t),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

String _whoLabel(FamilyStore store, TaskTemplate t) {
  if (t.assignedTo.isEmpty) return 'todos';
  final names = [
    for (final id in t.assignedTo)
      if (store.memberById(id) case final m?) m.nickname,
  ];
  return names.isEmpty ? 'nadie' : 'solo ${names.join(', ')}';
}

/// Abre el formulario de una tarea (nueva si [task] es `null`).
Future<void> editTask(BuildContext context, TaskTemplate? task) async {
  final store = FamilyScope.of(context);
  final result = await showModalBottomSheet<_TaskResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TaskForm(task: task),
  );
  if (result == null) return;
  if (result.delete && task != null) {
    store.removeTemplate(task.id);
  } else if (result.template != null) {
    store.saveTemplate(result.template!);
  }
}

class _TaskResult {
  const _TaskResult({this.template, this.delete = false});
  final TaskTemplate? template;
  final bool delete;
}

class _TaskForm extends StatefulWidget {
  const _TaskForm({required this.task});
  final TaskTemplate? task;

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  late final TextEditingController _name = TextEditingController(text: widget.task?.name ?? '');
  late DayBlock _block = widget.task?.block ?? DayBlock.morning;
  late TimeOfDay _time = widget.task?.time ?? const TimeOfDay(hour: 8, minute: 0);
  late int _points = widget.task?.points ?? 5;
  late Validation _validation = widget.task?.validation ?? Validation.self;
  late Set<String> _assigned = {...?widget.task?.assignedTo};
  late String? _emoji = widget.task?.emoji;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final isNew = widget.task == null;
    final name = _name.text.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isNew ? 'Nueva tarea' : 'Editar tarea', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              autofocus: isNew,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Por ejemplo: Pasear al perro',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            Text('Dibujito', style: sectionTitle(context)),
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final e in taskEmojis)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(e, style: const TextStyle(fontSize: 20)),
                        selected: (_emoji ?? taskEmojiFor(widget.task?.id ?? '', name)) == e,
                        onSelected: (_) => setState(() => _emoji = e),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Momento del día', style: sectionTitle(context)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in DayBlock.values)
                  ChoiceChip(label: Text(b.label), selected: _block == b, onSelected: (_) => setState(() => _block = b)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Text('Hora sugerida', style: sectionTitle(context))),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(context: context, initialTime: _time);
                    if (picked != null) setState(() => _time = picked);
                  },
                  icon: const Icon(Icons.schedule),
                  label: Text(hhmm(_time)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Text('Puntos', style: sectionTitle(context))),
                IconButton.outlined(
                  tooltip: 'Menos puntos',
                  onPressed: _points > 1 ? () => setState(() => _points--) : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 48,
                  child: Text('$_points', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                IconButton.outlined(
                  tooltip: 'Más puntos',
                  onPressed: _points < 50 ? () => setState(() => _points++) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('¿Para quién?', style: sectionTitle(context)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todos los hijos'),
                  selected: _assigned.isEmpty,
                  onSelected: (_) => setState(() => _assigned = {}),
                ),
                for (final c in store.children.where((c) => !store.isPendingMember(c.id)))
                  FilterChip(
                    label: Text(c.nickname),
                    selected: _assigned.contains(c.id),
                    onSelected: (on) => setState(() {
                      _assigned = {..._assigned};
                      if (on) {
                        _assigned.add(c.id);
                      } else {
                        _assigned.remove(c.id);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text('¿Quién la valida?', style: sectionTitle(context)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in Validation.values)
                  ChoiceChip(
                    label: Text(switch (v) {
                      Validation.self => 'La marca el hijo',
                      Validation.photo => 'Con foto',
                      Validation.adult => 'La aprueba un adulto',
                    }),
                    selected: _validation == v,
                    onSelected: (_) => setState(() => _validation = v),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _validation == Validation.self
                  ? 'Suma puntos apenas la marca.'
                  : 'Los puntos se suman cuando un adulto la aprueba en "Para aprobar".',
              style: mutedText(context),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (!isNew)
                  TextButton.icon(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('¿Borrar "${widget.task!.name}"?'),
                          content: const Text('Deja de aparecer en la rutina de todos. Los puntos ya ganados no se pierden.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) Navigator.pop(context, const _TaskResult(delete: true));
                    },
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFB42318)),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Borrar'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: name.isEmpty
                      ? null
                      : () => Navigator.pop(
                            context,
                            _TaskResult(
                              template: TaskTemplate(
                                id: widget.task?.id ?? store.newTemplateId(),
                                name: name,
                                block: _block,
                                time: _time,
                                points: _points,
                                validation: _validation,
                                windowMinutes: widget.task?.windowMinutes ?? 30,
                                assignedTo: _assigned,
                                emoji: _emoji,
                              ),
                            ),
                          ),
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- premios

class _RewardsTab extends StatelessWidget {
  const _RewardsTab();

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        Text('Los hijos los canjean con sus puntos de viernes a domingo, y vos aprobás cada pedido.', style: mutedText(context)),
        const SizedBox(height: 12),
        if (store.rewards.isEmpty) Text('Todavía no hay premios.', style: mutedText(context)),
        for (final r in store.rewards) ...[
          InfoCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: IconBadge(icon: r.icon, background: const Color(0xFFE8EEFF), color: AppColors.ink, size: 40),
              title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: Text('${r.cost} pts', style: const TextStyle(fontWeight: FontWeight.w800)),
              onTap: () => editReward(context, r),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Abre el formulario de un premio (nuevo si [reward] es `null`).
Future<void> editReward(BuildContext context, Reward? reward) async {
  final store = FamilyScope.of(context);
  final result = await showModalBottomSheet<_RewardResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RewardForm(reward: reward),
  );
  if (result == null) return;
  if (result.delete && reward != null) {
    store.removeReward(reward.id);
  } else if (result.reward != null) {
    store.saveReward(result.reward!);
  }
}

class _RewardResult {
  const _RewardResult({this.reward, this.delete = false});
  final Reward? reward;
  final bool delete;
}

class _RewardForm extends StatefulWidget {
  const _RewardForm({required this.reward});
  final Reward? reward;

  @override
  State<_RewardForm> createState() => _RewardFormState();
}

class _RewardFormState extends State<_RewardForm> {
  late final TextEditingController _name = TextEditingController(text: widget.reward?.name ?? '');
  late int _cost = widget.reward?.cost ?? 50;
  late String _icon = widget.reward?.iconKey ?? 'regalo';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final isNew = widget.reward == null;
    final name = _name.text.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isNew ? 'Nuevo premio' : 'Editar premio', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              autofocus: isNew,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Premio',
                hintText: 'Por ejemplo: Pizza el viernes',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            Row(
              children: [
                Expanded(child: Text('Cuesta', style: sectionTitle(context))),
                IconButton.outlined(
                  tooltip: 'Menos puntos',
                  onPressed: _cost > 10 ? () => setState(() => _cost -= 10) : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 72,
                  child: Text('$_cost pts', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                IconButton.outlined(
                  tooltip: 'Más puntos',
                  onPressed: _cost < 2000 ? () => setState(() => _cost += 10) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Ícono', style: sectionTitle(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in rewardIcons.entries)
                  Semantics(
                    button: true,
                    selected: _icon == e.key,
                    label: e.key,
                    child: InkResponse(
                      onTap: () => setState(() => _icon = e.key),
                      radius: 28,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _icon == e.key ? accent.withValues(alpha: 0.14) : AppColors.soft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _icon == e.key ? accent : Colors.transparent, width: 2),
                        ),
                        child: Icon(e.value, color: AppColors.ink),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (!isNew)
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context, const _RewardResult(delete: true)),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFB42318)),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Borrar'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: name.isEmpty
                      ? null
                      : () => Navigator.pop(
                            context,
                            _RewardResult(
                              reward: Reward(
                                id: widget.reward?.id ?? store.newRewardId(),
                                name: name,
                                cost: _cost,
                                iconKey: _icon,
                              ),
                            ),
                          ),
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
