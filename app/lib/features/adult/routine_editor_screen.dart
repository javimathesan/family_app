import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/app_session.dart';
import '../../data/family_store.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/common.dart';

/// El adulto arma la rutina y los premios de **cada hijo**. Cada tarea existe
/// una sola vez ("Levantarse") y cada hijo tiene su horario: hora (y otra para
/// el finde), días y puntos. Los cambios llegan a todos los teléfonos.
class RoutineEditorScreen extends StatefulWidget {
  const RoutineEditorScreen({super.key, this.initialKid});

  /// Hijo con el que abre (si no, el primero).
  final String? initialKid;

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  String? _kid;

  @override
  void initState() {
    super.initState();
    _kid = widget.initialKid;
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final session = SessionScope.of(context);
    if (!session.flag('tour_routine')) {
      WidgetsBinding.instance.addPostFrameCallback((_) => session.setFlag('tour_routine'));
    }
    final kids = kidsOf(store);
    final kid = kids.where((k) => k.id == _kid).firstOrNull ?? kids.firstOrNull;
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Rutina y premios', style: TextStyle(fontWeight: FontWeight.w800)),
              bottom: const TabBar(tabs: [Tab(text: 'Tareas'), Tab(text: 'Premios')]),
            ),
            body: kid == null
                ? const _NoKids()
                : Column(
                    children: [
                      _KidPicker(kids: kids, selected: kid.id, onSelected: (id) => setState(() => _kid = id)),
                      Expanded(child: TabBarView(children: [_TasksTab(kid: kid), _RewardsTab(kid: kid)])),
                    ],
                  ),
            floatingActionButton: kid == null
                ? null
                : FloatingActionButton.extended(
                    onPressed: () => DefaultTabController.of(context).index == 0
                        ? addTaskMenu(context, kid)
                        : addRewardMenu(context, kid),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  ),
          );
        },
      ),
    );
  }
}

/// Hijos ya aprobados del hogar.
List<Member> kidsOf(FamilyStore store) => [for (final c in store.children) if (!store.isPendingMember(c.id)) c];

class _NoKids extends StatelessWidget {
  const _NoKids();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('👨‍👩‍👧', style: TextStyle(fontSize: 56), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text('Primero sumá a tus hijos', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('La rutina y los premios se arman para cada hijo: cada uno con sus tareas y sus horarios.',
              textAlign: TextAlign.center, style: mutedText(context)),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(Routes.invite),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Sumar a un hijo'),
            ),
          ),
        ],
      );
}

/// Fila de hijos (con su avatar y su color) para elegir de quién es la rutina.
class _KidPicker extends StatelessWidget {
  const _KidPicker({required this.kids, required this.selected, required this.onSelected});

  final List<Member> kids;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        children: [
          for (final k in kids)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: ValueKey('kid_${k.id}'),
                avatar: AvatarView(config: k.avatar, size: 24),
                label: Text(k.nickname, style: const TextStyle(fontWeight: FontWeight.w800)),
                selected: k.id == selected,
                selectedColor: k.accent.withValues(alpha: .22),
                side: BorderSide(color: k.id == selected ? k.accent : Colors.transparent),
                onSelected: (_) => onSelected(k.id),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ tareas

class _TasksTab extends StatelessWidget {
  const _TasksTab({required this.kid});

  final Member kid;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final routine = store.routineOf(kid.id);
    int pts(int weekday) => routine
        .map((t) => t.slotFor(kid.id))
        .where((s) => s.days.isEmpty || s.days.contains(weekday))
        .fold<int>(0, (sum, s) => sum + s.points);
    final others = kidsOf(store).where((k) => k.id != kid.id).toList();

    if (routine.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
        children: [
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${kid.nickname} todavía no tiene tareas', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Elegí de la lista sugerida para su edad y después ajustá los horarios. '
                    'Mientras tanto, en su teléfono ve la rutina vacía.', style: mutedText(context)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => pickSuggestedTasks(context, kid),
                  icon: const Icon(Icons.checklist),
                  label: const Text('Elegir de la lista sugerida'),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: () => editTask(context, null, kid),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Crear una tarea'),
                ),
                if (others.any((o) => store.routineOf(o.id).isNotEmpty)) ...[
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () => _copyFrom(context, kid),
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Copiar la rutina de un hermano'),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      children: [
        Text('${routine.length} tareas · hasta ${pts(DateTime.monday)} pts en semana y ${pts(DateTime.saturday)} el finde',
            style: mutedText(context).copyWith(fontSize: 14)),
        const SizedBox(height: 4),
        Text('Tocá una tarea para cambiar el horario de ${kid.nickname}. Los otros hijos mantienen el suyo.', style: mutedText(context)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.checklist, size: 18),
              label: const Text('Lista sugerida'),
              onPressed: () => pickSuggestedTasks(context, kid),
            ),
            if (others.isNotEmpty)
              ActionChip(
                avatar: const Icon(Icons.copy_all_outlined, size: 18),
                label: Text('Copiar la rutina de ${kid.nickname} a…'),
                onPressed: () => _copyTo(context, kid, others),
              ),
          ],
        ),
        for (final block in DayBlock.values)
          if (routine.where((t) => t.block == block).toList() case final tasks when tasks.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(block.label, style: sectionTitle(context)),
            const SizedBox(height: 8),
            for (final t in tasks..sort((a, b) => _min(a.slotFor(kid.id).time).compareTo(_min(b.slotFor(kid.id).time)))) ...[
              InfoCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  key: ValueKey('tarea_${t.id}'),
                  leading: Text(t.icon, style: const TextStyle(fontSize: 26)),
                  title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${t.slotFor(kid.id).label(hhmm)} · ${t.validation.label}${_shared(store, t, kid)}'),
                  trailing: Text('+${t.slotFor(kid.id).points}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  onTap: () => editTask(context, t, kid),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
      ],
    );
  }
}

int _min(TimeOfDay t) => t.hour * 60 + t.minute;

/// " · también Luli" si otros hijos tienen la misma tarea.
String _shared(FamilyStore store, TaskTemplate t, Member kid) {
  final others = [for (final k in kidsOf(store)) if (k.id != kid.id && t.appliesTo(k.id)) k.nickname];
  return others.isEmpty ? '' : ' · también ${others.join(', ')}';
}

Future<void> _copyTo(BuildContext context, Member from, List<Member> others) async {
  final store = FamilyScope.of(context);
  final chosen = await showModalBottomSheet<Set<String>>(
    context: context,
    showDragHandle: true,
    builder: (_) => _PickKids(
      title: 'Copiar la rutina de ${from.nickname}',
      help: 'Las tareas y los horarios de ${from.nickname} se suman a quienes elijas. Después podés ajustarlos.',
      kids: others,
      action: 'Copiar',
    ),
  );
  if (chosen == null || chosen.isEmpty) return;
  store.copyRoutine(from.id, chosen);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rutina copiada. Revisá los horarios de cada uno.')));
  }
}

Future<void> _copyFrom(BuildContext context, Member to) async {
  final store = FamilyScope.of(context);
  final withRoutine = [for (final k in kidsOf(store)) if (k.id != to.id && store.routineOf(k.id).isNotEmpty) k];
  final chosen = await showModalBottomSheet<Set<String>>(
    context: context,
    showDragHandle: true,
    builder: (_) => _PickKids(
      title: '¿De quién copiamos la rutina?',
      help: 'Se copian sus tareas y horarios para ${to.nickname}.',
      kids: withRoutine,
      action: 'Copiar',
      single: true,
    ),
  );
  if (chosen == null || chosen.isEmpty) return;
  store.copyRoutine(chosen.first, [to.id]);
}

/// Elegir uno o varios hijos.
class _PickKids extends StatefulWidget {
  const _PickKids({required this.title, required this.help, required this.kids, required this.action, this.single = false});

  final String title;
  final String help;
  final List<Member> kids;
  final String action;
  final bool single;

  @override
  State<_PickKids> createState() => _PickKidsState();
}

class _PickKidsState extends State<_PickKids> {
  final Set<String> _chosen = {};

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(widget.help, style: mutedText(context)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in widget.kids)
                    FilterChip(
                      avatar: AvatarView(config: k.avatar, size: 22),
                      label: Text(k.nickname),
                      selected: _chosen.contains(k.id),
                      onSelected: (on) => setState(() {
                        if (widget.single) _chosen.clear();
                        on ? _chosen.add(k.id) : _chosen.remove(k.id);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _chosen.isEmpty ? null : () => Navigator.pop(context, _chosen),
                  child: Text(widget.action),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Botón "Agregar" en Tareas: crear una o elegir de la lista sugerida.
Future<void> addTaskMenu(BuildContext context, Member kid) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Crear una tarea'),
            subtitle: Text('Solo para ${kid.nickname} (después podés sumar a otros)'),
            onTap: () => Navigator.pop(ctx, 'nueva'),
          ),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: const Text('Elegir de la lista sugerida'),
            subtitle: Text('Ideas para ${kid.mode?.label ?? 'su edad'}'),
            onTap: () => Navigator.pop(ctx, 'lista'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  if (choice == 'nueva') {
    await editTask(context, null, kid);
  } else if (choice == 'lista') {
    await pickSuggestedTasks(context, kid);
  }
}

/// Lista sugerida: el adulto marca con ✓ lo que quiere para [kid].
Future<void> pickSuggestedTasks(BuildContext context, Member kid) async {
  final store = FamilyScope.of(context);
  final chosen = await showModalBottomSheet<List<TaskTemplate>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SuggestedSheet<TaskTemplate>(
      title: 'Ideas para ${kid.nickname}',
      kid: kid,
      items: [
        for (final s in FamilyStore.suggestedTasks)
          if (!store.routineOf(kid.id).any((t) => t.id == s.task.id)) (item: s.task, ages: s.ages),
      ],
      tile: (t) => (
        leading: Text(t.icon, style: const TextStyle(fontSize: 24)),
        title: t.name,
        subtitle: '${t.block.label} · ${TaskSlot(time: t.time, weekendTime: t.weekendTime, days: t.days, points: t.points).label(hhmm)} · +${t.points}',
      ),
    ),
  );
  if (chosen == null || chosen.isEmpty) return;
  store.addSuggestedTasks(kid.id, chosen);
}

/// Hoja con una lista para tildar, filtrada por edad.
class _SuggestedSheet<T> extends StatefulWidget {
  const _SuggestedSheet({required this.title, required this.kid, required this.items, required this.tile});

  final String title;
  final Member kid;
  final List<({T item, Set<AgeMode> ages})> items;
  final ({Widget leading, String title, String subtitle}) Function(T) tile;

  @override
  State<_SuggestedSheet<T>> createState() => _SuggestedSheetState<T>();
}

class _SuggestedSheetState<T> extends State<_SuggestedSheet<T>> {
  late AgeMode? _age = widget.kid.mode;
  final Set<int> _chosen = {};

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (final (i, e) in widget.items.indexed)
        if (_age == null || e.ages.contains(_age)) (i, e.item),
    ];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .85),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final a in AgeMode.values)
                    ChoiceChip(label: Text(a.label), selected: _age == a, onSelected: (_) => setState(() => _age = a)),
                  ChoiceChip(label: const Text('Todas'), selected: _age == null, onSelected: (_) => setState(() => _age = null)),
                ],
              ),
              const SizedBox(height: 6),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Ya tiene todas las de esta lista.', style: mutedText(context)),
                ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final (i, item) in shown)
                      Builder(builder: (context) {
                        final t = widget.tile(item);
                        return CheckboxListTile(
                          key: ValueKey('sugerida_$i'),
                          contentPadding: EdgeInsets.zero,
                          value: _chosen.contains(i),
                          onChanged: (on) => setState(() => on == true ? _chosen.add(i) : _chosen.remove(i)),
                          secondary: t.leading,
                          title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(t.subtitle),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _chosen.isEmpty
                      ? null
                      : () => Navigator.pop(context, [for (final i in _chosen.toList()..sort()) widget.items[i].item]),
                  child: Text(_chosen.isEmpty ? 'Elegí al menos una' : 'Agregar ${_chosen.length} a ${widget.kid.nickname}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Abre el formulario de una tarea para [kid] (nueva si [task] es `null`).
Future<void> editTask(BuildContext context, TaskTemplate? task, Member kid) async {
  final store = FamilyScope.of(context);
  final result = await showModalBottomSheet<_TaskResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TaskForm(task: task, kid: kid),
  );
  if (result == null) return;
  if (result.unassign && task != null) {
    store.unassignTask(task.id, kid.id);
  } else if (result.template != null) {
    store.saveTemplate(result.template!);
  }
}

class _TaskResult {
  const _TaskResult({this.template, this.unassign = false});
  final TaskTemplate? template;
  final bool unassign;
}

class _TaskForm extends StatefulWidget {
  const _TaskForm({required this.task, required this.kid});
  final TaskTemplate? task;
  final Member kid;

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  late final TaskSlot? _slot = widget.task?.slotFor(widget.kid.id);
  late final TextEditingController _name = TextEditingController(text: widget.task?.name ?? '');
  late DayBlock _block = widget.task?.block ?? DayBlock.morning;
  late TimeOfDay _time = _slot?.time ?? const TimeOfDay(hour: 8, minute: 0);
  late TimeOfDay? _weekendTime = _slot?.weekendTime;
  late int _points = _slot?.points ?? 5;
  late Validation _validation = widget.task?.validation ?? Validation.self;
  late String? _emoji = widget.task?.emoji;
  late Set<int> _days = {...?_slot?.days};
  bool _forAll = false;

  /// Hijos que tienen la tarea (incluye a [widget.kid]).
  late Set<String> _who;

  bool _whoReady = false;
  void _whoInit(FamilyStore store) {
    if (_whoReady) return;
    _whoReady = true;
    final t = widget.task;
    _who = t == null ? {widget.kid.id} : {for (final k in kidsOf(store)) if (t.appliesTo(k.id)) k.id};
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  TaskTemplate _build(FamilyStore store) {
    final t = widget.task;
    final kid = widget.kid.id;
    final slot = TaskSlot(time: _time, weekendTime: _weekendTime, days: _days, points: _points);
    final allKids = {for (final k in kidsOf(store)) k.id};
    // Si antes era "para todos" y siguen todos, queda así (para los hijos que se sumen).
    final assigned = t != null && t.assignedTo.isEmpty && _who.containsAll(allKids) ? <String>{} : {..._who};
    final newcomers = t == null ? <String>{} : {for (final id in _who) if (!t.appliesTo(id)) id};
    final custom = <String, TaskSlot>{
      if (t != null && !_forAll)
        for (final e in t.custom.entries)
          if (_who.contains(e.key)) e.key: e.value,
    };
    final base = t == null || _forAll;
    if (!base) {
      custom[kid] = slot;
      for (final id in newcomers) {
        custom[id] = slot;
      }
    }
    return TaskTemplate(
      id: t?.id ?? store.newTemplateId(),
      name: _name.text.trim(),
      block: _block,
      time: base ? slot.time : t.time,
      weekendTime: base ? slot.weekendTime : t.weekendTime,
      days: base ? slot.days : t.days,
      points: base ? slot.points : t.points,
      validation: _validation,
      windowMinutes: t?.windowMinutes ?? 30,
      assignedTo: assigned,
      emoji: _emoji,
      custom: custom,
    );
  }

  Widget _timeButton(TimeOfDay value, ValueChanged<TimeOfDay> onPicked, {Key? key}) => OutlinedButton.icon(
        key: key,
        onPressed: () async {
          final picked = await showTimePicker(context: context, initialTime: value);
          if (picked != null) onPicked(picked);
        },
        icon: const Icon(Icons.schedule),
        label: Text(hhmm(value)),
      );

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    _whoInit(store);
    final isNew = widget.task == null;
    final name = _name.text.trim();
    final kid = widget.kid;
    final others = kidsOf(store).where((k) => k.id != kid.id).toList();
    final sharedWith = [for (final k in others) if (_who.contains(k.id)) k.nickname];
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isNew ? 'Nueva tarea para ${kid.nickname}' : widget.task!.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),

            // ---------------------------------------------- horario del hijo
            Material(
              color: kid.accent.withValues(alpha: .10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: kid.accent.withValues(alpha: .35)),
              ),
              child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AvatarView(config: kid.avatar, size: 28),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Horario de ${kid.nickname}', style: sectionTitle(context))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(child: Text('Hora', style: TextStyle(fontWeight: FontWeight.w700))),
                      _timeButton(_time, (v) => setState(() => _time = v), key: const ValueKey('hora_semana')),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Otra hora el fin de semana', style: TextStyle(fontWeight: FontWeight.w700)),
                    value: _weekendTime != null,
                    onChanged: (on) => setState(() => _weekendTime = on ? TimeOfDay(hour: (_time.hour + 2).clamp(0, 23), minute: _time.minute) : null),
                  ),
                  if (_weekendTime != null)
                    Row(
                      children: [
                        const Expanded(child: Text('Sábado y domingo')),
                        _timeButton(_weekendTime!, (v) => setState(() => _weekendTime = v), key: const ValueKey('hora_finde')),
                      ],
                    ),
                  const SizedBox(height: 10),
                  const Text('¿Qué días?', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (label, set) in [
                        ('Todos los días', <int>{}),
                        ('Lunes a viernes', TaskTemplate.weekdays),
                        ('Fin de semana', TaskTemplate.weekend),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: TaskTemplate.daysText(_days) == label,
                          onSelected: (_) => setState(() => _days = {...set}),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final (i, d) in const ['L', 'M', 'M', 'J', 'V', 'S', 'D'].indexed)
                        FilterChip(
                          label: Text(d),
                          tooltip: const ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][i],
                          showCheckmark: false,
                          selected: _days.isEmpty || _days.contains(i + 1),
                          onSelected: (on) => setState(() {
                            final next = _days.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : {..._days};
                            if (on) {
                              next.add(i + 1);
                            } else if (next.length > 1) {
                              next.remove(i + 1);
                            }
                            _days = next.length == 7 ? <int>{} : next;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(child: Text('Puntos', style: TextStyle(fontWeight: FontWeight.w700))),
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
                  if (!isNew && sharedWith.isNotEmpty)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _forAll,
                      onChanged: (v) => setState(() => _forAll = v ?? false),
                      title: const Text('Usar este horario para todos'),
                      subtitle: Text('También para ${sharedWith.join(', ')}'),
                    ),
                ],
              ),
              ),
            ),
            const SizedBox(height: 16),

            // ---------------------------------------------- la tarea (común)
            Text('La tarea', style: sectionTitle(context)),
            if (sharedWith.isNotEmpty)
              Text('El nombre, el dibujito y la validación son iguales para todos los que la tienen.', style: mutedText(context)),
            const SizedBox(height: 8),
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
            const Text('Dibujito', style: TextStyle(fontWeight: FontWeight.w700)),
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
            const Text('Momento del día', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in DayBlock.values)
                  ChoiceChip(label: Text(b.label), selected: _block == b, onSelected: (_) => setState(() => _block = b)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('¿Quién la valida?', style: TextStyle(fontWeight: FontWeight.w700)),
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
            if (others.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('¿Quién más la tiene?', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('Los que sumes arrancan con el horario de ${kid.nickname}.', style: mutedText(context)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in others)
                    FilterChip(
                      avatar: AvatarView(config: k.avatar, size: 22),
                      label: Text(k.nickname),
                      selected: _who.contains(k.id),
                      onSelected: (on) => setState(() => on ? _who.add(k.id) : _who.remove(k.id)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (!isNew)
                  TextButton.icon(
                    onPressed: () async {
                      final last = sharedWith.isEmpty;
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(last ? '¿Borrar "${widget.task!.name}"?' : '¿Quitarle "${widget.task!.name}" a ${kid.nickname}?'),
                          content: Text(last
                              ? 'Nadie más la tiene, así que se borra. Los puntos ya ganados no se pierden.'
                              : 'Los demás la siguen teniendo. Los puntos ya ganados no se pierden.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(last ? 'Borrar' : 'Quitar')),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) Navigator.pop(context, const _TaskResult(unassign: true));
                    },
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFB42318)),
                    icon: const Icon(Icons.remove_circle_outline),
                    label: Text(sharedWith.isEmpty ? 'Borrar' : 'Quitar a ${kid.nickname}'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: name.isEmpty ? null : () => Navigator.pop(context, _TaskResult(template: _build(store))),
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
  const _RewardsTab({required this.kid});

  final Member kid;

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final rewards = store.rewardsFor(kid.id);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      children: [
        Text('${kid.nickname} los canjea con sus puntos de viernes a domingo, y vos aprobás cada pedido.', style: mutedText(context)),
        const SizedBox(height: 8),
        if (rewards.isEmpty)
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${kid.nickname} todavía no tiene premios', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => pickSuggestedRewards(context, kid),
                  icon: const Icon(Icons.checklist),
                  label: const Text('Elegir de la lista sugerida'),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: () => editReward(context, null, kid),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Crear un premio'),
                ),
              ],
            ),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(Icons.checklist, size: 18),
              label: const Text('Lista sugerida'),
              onPressed: () => pickSuggestedRewards(context, kid),
            ),
          ),
        const SizedBox(height: 8),
        for (final r in rewards) ...[
          InfoCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              key: ValueKey('premio_${r.id}'),
              leading: IconBadge(icon: r.icon, background: const Color(0xFFE8EEFF), color: AppColors.ink, size: 40),
              title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: _sharedReward(store, r, kid),
              trailing: Text('${r.cost} pts', style: const TextStyle(fontWeight: FontWeight.w800)),
              onTap: () => editReward(context, store.rewardById(r.id), kid),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

Widget? _sharedReward(FamilyStore store, Reward r, Member kid) {
  final others = [for (final k in kidsOf(store)) if (k.id != kid.id && r.appliesTo(k.id)) k.nickname];
  return others.isEmpty ? null : Text('También ${others.join(', ')}');
}

Future<void> addRewardMenu(BuildContext context, Member kid) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Crear un premio'),
            subtitle: Text('Para ${kid.nickname} (después podés sumar a otros)'),
            onTap: () => Navigator.pop(ctx, 'nuevo'),
          ),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: const Text('Elegir de la lista sugerida'),
            onTap: () => Navigator.pop(ctx, 'lista'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  if (choice == 'nuevo') {
    await editReward(context, null, kid);
  } else if (choice == 'lista') {
    await pickSuggestedRewards(context, kid);
  }
}

Future<void> pickSuggestedRewards(BuildContext context, Member kid) async {
  final store = FamilyScope.of(context);
  final chosen = await showModalBottomSheet<List<Reward>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SuggestedSheet<Reward>(
      title: 'Premios para ${kid.nickname}',
      kid: kid,
      items: [
        for (final s in FamilyStore.suggestedRewards)
          if (!store.rewardsFor(kid.id).any((r) => r.id == s.reward.id)) (item: s.reward, ages: s.ages),
      ],
      tile: (r) => (
        leading: Icon(r.icon),
        title: r.name,
        subtitle: '${r.cost} pts',
      ),
    ),
  );
  if (chosen == null || chosen.isEmpty) return;
  store.addSuggestedRewards(kid.id, chosen);
}

/// Abre el formulario de un premio para [kid] (nuevo si [reward] es `null`).
Future<void> editReward(BuildContext context, Reward? reward, Member kid) async {
  final store = FamilyScope.of(context);
  final result = await showModalBottomSheet<_RewardResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RewardForm(reward: reward, kid: kid),
  );
  if (result == null) return;
  if (result.unassign && reward != null) {
    final others = {for (final k in kidsOf(store)) if (k.id != kid.id && reward.appliesTo(k.id)) k.id};
    if (others.isEmpty) {
      store.removeReward(reward.id);
    } else {
      store.saveReward(reward.copyWith(assignedTo: others, costs: {...reward.costs}..remove(kid.id)));
    }
  } else if (result.reward != null) {
    store.saveReward(result.reward!);
  }
}

class _RewardResult {
  const _RewardResult({this.reward, this.unassign = false});
  final Reward? reward;
  final bool unassign;
}

class _RewardForm extends StatefulWidget {
  const _RewardForm({required this.reward, required this.kid});
  final Reward? reward;
  final Member kid;

  @override
  State<_RewardForm> createState() => _RewardFormState();
}

class _RewardFormState extends State<_RewardForm> {
  late final TextEditingController _name = TextEditingController(text: widget.reward?.name ?? '');
  late int _cost = widget.reward?.costFor(widget.kid.id) ?? 50;
  late String _icon = widget.reward?.iconKey ?? 'regalo';
  bool _forAll = false;
  Set<String>? _who;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Reward _build(FamilyStore store) {
    final r = widget.reward;
    final kid = widget.kid.id;
    final who = _who!;
    final allKids = {for (final k in kidsOf(store)) k.id};
    final assigned = r != null && r.assignedTo.isEmpty && who.containsAll(allKids) ? <String>{} : {...who};
    if (r == null || _forAll) {
      return Reward(id: r?.id ?? store.newRewardId(), name: _name.text.trim(), cost: _cost, iconKey: _icon, monthly: r?.monthly ?? false, assignedTo: assigned);
    }
    final costs = {
      for (final e in r.costs.entries)
        if (who.contains(e.key)) e.key: e.value,
      kid: _cost,
    }..removeWhere((id, c) => c == r.cost);
    if (_cost == r.cost) costs.remove(kid);
    return r.copyWith(name: _name.text.trim(), iconKey: _icon, assignedTo: assigned, costs: costs);
  }

  @override
  Widget build(BuildContext context) {
    final store = FamilyScope.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final isNew = widget.reward == null;
    final name = _name.text.trim();
    final kid = widget.kid;
    final others = kidsOf(store).where((k) => k.id != kid.id).toList();
    _who ??= isNew ? {kid.id} : {for (final k in kidsOf(store)) if (widget.reward!.appliesTo(k.id)) k.id};
    final sharedWith = [for (final k in others) if (_who!.contains(k.id)) k.nickname];
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isNew ? 'Nuevo premio para ${kid.nickname}' : 'Editar premio',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
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
                Expanded(child: Text('Le cuesta a ${kid.nickname}', style: sectionTitle(context))),
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
            if (!isNew && sharedWith.isNotEmpty)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _forAll,
                onChanged: (v) => setState(() => _forAll = v ?? false),
                title: const Text('Mismo costo para todos'),
                subtitle: Text('También para ${sharedWith.join(', ')}'),
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
            if (others.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('¿Quién más lo puede pedir?', style: sectionTitle(context)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in others)
                    FilterChip(
                      avatar: AvatarView(config: k.avatar, size: 22),
                      label: Text(k.nickname),
                      selected: _who!.contains(k.id),
                      onSelected: (on) => setState(() => on ? _who!.add(k.id) : _who!.remove(k.id)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (!isNew)
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context, const _RewardResult(unassign: true)),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFB42318)),
                    icon: const Icon(Icons.remove_circle_outline),
                    label: Text(sharedWith.isEmpty ? 'Borrar' : 'Quitar a ${kid.nickname}'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: name.isEmpty ? null : () => Navigator.pop(context, _RewardResult(reward: _build(store))),
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
