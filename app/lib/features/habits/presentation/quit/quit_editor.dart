import 'package:decimal/decimal.dart';
import 'package:everslot/core/ids/ids.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/attachments/presentation/attachment_strip.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/application/habit_service.dart';
import 'package:everslot/features/habits/domain/catalogs.dart';
import 'package:everslot/features/habits/domain/check_in.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/domain/habit_records.dart';
import 'package:everslot/features/habits/domain/habit_settings.dart';
import 'package:everslot/features/habits/domain/quit.dart';
import 'package:everslot/features/habits/presentation/habit_ui.dart';
import 'package:everslot/features/habits/presentation/manage_habits_screen.dart';
import 'package:everslot/features/notifications/presentation/notification_settings_section.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Create / edit a quit tracker (T5.3.02): preset, mode (*Quit completely* / *Cut down* with a daily
/// limit), quit date **and time** (may be in the past), baseline per day, cost (per unit or pack
/// price ÷ units per pack) and currency, time per unit, motivation (+ photo), auto-success, section
/// and reminders. `quit_started_at` is the first quit and never changes with relapses.
class QuitEditor extends ConsumerStatefulWidget {
  const QuitEditor({this.existing, this.presetKey, super.key});

  final QuitHabit? existing;

  /// Preset key (`habits.quit_substance`) to prefill a new tracker.
  final String? presetKey;

  @override
  ConsumerState<QuitEditor> createState() => _QuitEditorState();
}

class _QuitEditorState extends ConsumerState<QuitEditor> {
  late final String _id = widget.existing?.id ?? Ids.v7();
  final _name = TextEditingController();
  final _baseline = TextEditingController();
  final _limit = TextEditingController();
  final _cost = TextEditingController();
  final _packUnits = TextEditingController();
  final _currency = TextEditingController();
  final _tpu = TextEditingController();
  final _lmu = TextEditingController();
  final _motivation = TextEditingController();
  final _reminders = NotificationRulesDraft();

  QuitPreset _preset = QuitPreset.all.first;
  QuitMode _mode = QuitMode.abstain;
  String _unit = HabitUnits.cigarettes;
  bool _perPack = false;
  bool _autoSuccess = true;
  HabitSettings _settings = HabitSettings.defaults;
  String? _icon;
  int? _color;
  String? _sectionId;
  late DateTime _quitAt;
  bool _initialized = false;
  String? _nameError;
  String? _error;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    for (final c in [_name, _baseline, _limit, _cost, _packUnits, _currency, _tpu, _lmu, _motivation]) {
      c.dispose();
    }
    _reminders.dispose();
    super.dispose();
  }

  static String _num(num v) => v == v.roundToDouble() ? v.round().toString() : v.toString();

  void _init() {
    if (_initialized) return;
    _initialized = true;
    final prefs = ref.read(userPreferencesProvider);
    _quitAt = ref.read(clockProvider).nowUtc();
    final e = widget.existing;
    if (e != null) {
      _preset = QuitPreset.of(e.substance);
      _name.text = e.name;
      _mode = e.mode;
      _unit = e.unit ?? _preset.unit;
      _baseline.text = _num(e.baselinePerDay);
      if (e.dailyLimit != null) _limit.text = _num(e.dailyLimit!);
      if (e.unitCost != null) _cost.text = e.unitCost.toString();
      _currency.text = e.currency ?? prefs.currency;
      if (e.timePerUnitMinutes != null) _tpu.text = _num(e.timePerUnitMinutes!);
      if (e.lifeMinutesPerUnit != null) _lmu.text = _num(e.lifeMinutesPerUnit!);
      _motivation.text = e.motivation ?? '';
      _autoSuccess = e.autoSuccess;
      _settings = e.settings;
      _icon = e.icon;
      _color = e.color;
      _sectionId = e.sectionId;
      _quitAt = e.quitStartedAt;
      return;
    }
    _currency.text = prefs.currency;
    _sectionId = ref.read(habitSectionsRepositoryProvider).defaultId(DefaultSections.anytime);
    final key = widget.presetKey;
    _applyPreset(key == null ? QuitPreset.all.first : QuitPreset.of(QuitSubstance.parse(key)), rename: true);
  }

  void _applyPreset(QuitPreset p, {bool rename = false}) {
    final l = context.l10n;
    final previousName = l.quitPresetName(_preset.substance);
    _preset = p;
    _mode = p.mode;
    _unit = p.unit;
    _icon = p.icon;
    _color = CategoryPalette.at(p.colorIndex);
    _baseline.text = _num(p.baselinePerDay);
    _tpu.text = p.timePerUnitMinutes == null ? '' : _num(p.timePerUnitMinutes!);
    _lmu.text = p.lifeMinutesPerUnit == null ? '' : _num(p.lifeMinutesPerUnit!);
    _packUnits.text = p.unitsPerPack == null ? '' : '${p.unitsPerPack}';
    _perPack = p.unitsPerPack != null;
    if (rename || _name.text.isEmpty || _name.text == previousName) _name.text = l.quitPresetName(p.substance);
  }

  double? _d(TextEditingController c) => parseLocalizedDecimal(c.text);

  Decimal? _unitCost() {
    final cost = _d(_cost);
    if (cost == null) return null;
    final price = decimalOf(cost);
    if (!_perPack) return price;
    return QuitPreset.unitCostFromPack(price, int.tryParse(_packUnits.text.trim()));
  }

  QuitHabit _draft() {
    final service = ref.read(habitPeriodServiceProvider);
    final base = QuitHabit(
      id: _id,
      name: _name.text,
      startDate: LocalDate(2000, 1, 1),
      sortKey: widget.existing?.sortKey ?? '',
      mode: _mode,
      quitStartedAt: _quitAt,
      substance: _preset.substance,
      dailyLimit: _mode == QuitMode.reduce ? (_d(_limit) ?? 0) : null,
      baselinePerDay: _d(_baseline) ?? 0,
      unitCost: _unitCost(),
      currency: _currency.text.trim().isEmpty ? null : _currency.text.trim().toUpperCase(),
      timePerUnitMinutes: _d(_tpu),
      lifeMinutesPerUnit: _d(_lmu),
      unit: _unit,
      icon: _icon,
      color: _color,
      sectionId: _sectionId,
      motivation: _motivation.text,
      autoSuccess: _autoSuccess,
      archivedAt: widget.existing?.archivedAt,
      notifyMode: widget.existing?.notifyMode ?? 'inherit',
      createdAt: widget.existing?.createdAt,
      settings: _settings,
    );
    return base.copyWith(startDate: service.dateOf(base, _quitAt));
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() {
      _nameError = null;
      _error = null;
    });
    final habit = _draft();
    try {
      habit.validate();
      if (habit.quitStartedAt.isAfter(ref.read(clockProvider).nowUtc().add(const Duration(minutes: 1)))) {
        throw HabitValidationException(HabitValidationCode.quitStartInFuture);
      }
    } on HabitValidationException catch (e) {
      setState(
        () => e.field == 'name' ? _nameError = l.validationMessage(e.code) : _error = l.validationMessage(e.code),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final service = ref.read(habitServiceProvider);
      if (_isNew) {
        await service.create(habit, reminders: _reminders);
      } else {
        await service.update(habit);
      }
      if (!mounted) return;
      showInfoSnackBar(context, l.habitsSavedSnack);
      Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickQuitAt() async {
    final service = ref.read(habitPeriodServiceProvider);
    final zone = service.currentZone;
    final local = service.resolver.toLocal(_quitAt, zone);
    final today = service.resolver.toLocal(ref.read(clockProvider).nowUtc(), zone).date;
    final date = await pickDate(context, initial: local.date, last: today);
    if (date == null || !mounted) return;
    final time = await pickTime(context, initial: local.time, use24h: ref.read(userPreferencesProvider).use24h);
    if (time == null) return;
    setState(() => _quitAt = service.resolver.resolve(date.atTime(time), zone).utc);
  }

  @override
  Widget build(BuildContext context) {
    _init();
    final l = context.l10n;
    final prefs = ref.watch(userPreferencesProvider);
    final fmt = AppFormat(context.localeName, use24h: prefs.use24h, l10n: l);
    final service = ref.watch(habitPeriodServiceProvider);
    final sections = ref.watch(allHabitSectionsProvider).value ?? const <HabitSection>[];
    final section = sections.where((s) => s.id == _sectionId).firstOrNull;
    final quitLocal = service.resolver.toLocal(_quitAt, service.currentZone);
    final unitCost = _unitCost();
    final smoking = _preset.hasHealthContent;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l.quitEditorNewTitle : l.quitEditorEditTitle),
        actions: [TextButton(onPressed: _saving ? null : _save, child: Text(l.actionSave))],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, Space.sm, Space.lg, Space.xxxl),
        children: [
          Text(l.quitPresetTitle, style: context.text.titleSmall),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final p in QuitPreset.all)
                ChoiceChip(
                  avatar: Icon(IconCatalog.iconFor(p.icon), size: 18),
                  label: Text(l.quitPresetLabel(p.substance)),
                  selected: _preset.substance == p.substance,
                  onSelected: (_) => setState(() => _applyPreset(p)),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _name,
            maxLength: Habit.maxNameLength,
            decoration: InputDecoration(labelText: l.habitsFieldName, errorText: _nameError),
          ),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(IconCatalog.iconFor(_icon, fallback: Icons.smoke_free)),
                  title: Text(l.habitsFieldIcon),
                  onTap: () async {
                    final icon = await pickIcon(context, selected: _icon);
                    if (icon != null) setState(() => _icon = icon);
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ColorDot(_color == null ? context.colors.outline : Color(_color!), size: 20),
                  title: Text(l.habitsFieldColor),
                  onTap: () async {
                    final c = await pickColor(context, selected: _color, allowNone: true);
                    if (c != null) setState(() => _color = c == -1 ? null : c);
                  },
                ),
              ),
            ],
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.view_agenda_outlined),
            title: Text(l.habitsFieldSection),
            subtitle: Text(section == null ? l.habitsNone : sectionName(context, section)),
            onTap: () async {
              final id = await pickHabitSection(context, ref, selectedId: _sectionId);
              if (id != null) setState(() => _sectionId = id.isEmpty ? null : id);
            },
          ),
          SectionHeader(
            l.quitModeTitle,
            padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.sm),
          ),
          SegmentedButton<QuitMode>(
            segments: [
              ButtonSegment(value: QuitMode.abstain, label: Text(l.quitModeAbstain)),
              ButtonSegment(value: QuitMode.reduce, label: Text(l.quitModeReduce)),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          if (_mode == QuitMode.reduce)
            TextField(
              controller: _limit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.quitDailyLimit, suffixText: l.unitLabel(_unit, 2)),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(l.quitStartedAt),
            subtitle: Text(fmt.dateTime(quitLocal)),
            onTap: _pickQuitAt,
          ),
          TextField(
            controller: _baseline,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.quitBaseline, suffixText: l.unitLabel(_unit, 2)),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final u in HabitUnits.quit)
                ChoiceChip(
                  label: Text(l.unitLabel(u, 2)),
                  selected: _unit == u,
                  onSelected: (_) => setState(() => _unit = u),
                ),
            ],
          ),
          SectionHeader(
            l.quitCostTitle,
            padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.sm),
          ),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l.quitUnitCost)),
              ButtonSegment(value: true, label: Text(l.quitPackPrice)),
            ],
            selected: {_perPack},
            onSelectionChanged: (s) => setState(() => _perPack = s.first),
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _cost,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: _perPack ? l.quitPackPrice : l.quitUnitCost),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: TextField(
                  controller: _currency,
                  maxLength: 3,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: l.quitCurrency, counterText: ''),
                ),
              ),
            ],
          ),
          if (_perPack)
            TextField(
              controller: _packUnits,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.quitUnitsPerPack),
              onChanged: (_) => setState(() {}),
            ),
          if (_perPack && unitCost != null && _currency.text.length == 3)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: Space.xs),
              child: Text(
                l.quitCostPerUnit(fmt.currency(unitCost.toDouble(), _currency.text.toUpperCase())),
                style: context.text.bodySmall,
              ),
            ),
          TextField(
            controller: _tpu,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.quitTimePerUnit, suffixText: l.habitsUnitMin),
          ),
          if (smoking || _lmu.text.isNotEmpty)
            TextField(
              controller: _lmu,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.quitLifePerUnit,
                suffixText: l.habitsUnitMin,
                helperText: l.quitPopulationEstimateHelp,
                helperMaxLines: 3,
              ),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: Space.sm),
            child: Text(l.quitEstimatesNote, style: context.text.bodySmall),
          ),
          SectionHeader(
            l.quitMotivation,
            padding: const EdgeInsetsDirectional.only(top: Space.lg, bottom: Space.sm),
          ),
          TextField(
            controller: _motivation,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(hintText: l.quitMotivationHint),
          ),
          const SizedBox(height: Space.sm),
          if (_isNew)
            Text(l.quitPhotoAfterSave, style: context.text.bodySmall)
          else
            AttachmentStrip(ownerType: 'habit', ownerId: _id),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.quitAutoSuccess),
            subtitle: Text(l.quitAutoSuccessHint),
            value: _autoSuccess,
            onChanged: (v) => setState(() => _autoSuccess = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.quitRitualEnable),
            subtitle: Text(l.quitRitualEnableHint),
            value: _settings.pledge.enabled,
            onChanged: (v) => setState(() {
              final p = _settings.pledge;
              _settings = _settings.copyWith(
                pledge: p.copyWith(
                  enabled: v,
                  morning: p.morning ?? LocalTime(8, 0),
                  evening: p.evening ?? LocalTime(21, 0),
                ),
              );
            }),
          ),
          if (_settings.pledge.enabled)
            for (final (label, time, isMorning) in [
              (l.quitPledgeMorning, _settings.pledge.morning ?? LocalTime(8, 0), true),
              (l.quitReviewEvening, _settings.pledge.evening ?? LocalTime(21, 0), false),
            ])
              ListTile(
                contentPadding: const EdgeInsetsDirectional.only(start: Space.lg),
                leading: Icon(isMorning ? Icons.wb_sunny_outlined : Icons.nightlight_outlined),
                title: Text(label),
                trailing: Text(fmt.time(time)),
                onTap: () async {
                  final t = await pickTime(context, initial: time, use24h: prefs.use24h);
                  if (t == null) return;
                  setState(() {
                    final p = _settings.pledge;
                    _settings = _settings.copyWith(
                      pledge: isMorning ? p.copyWith(morning: t) : p.copyWith(evening: t),
                    );
                  });
                },
              ),
          const SizedBox(height: Space.md),
          NotificationSettingsSection(
            targetType: NotificationTargetType.habit,
            targetId: _id,
            section: NotificationSection.quit,
            itemKind: ItemKind.any,
            draft: _isNew ? _reminders : null,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: Space.md),
              child: Text(_error!, style: TextStyle(color: context.colors.error)),
            ),
          const SizedBox(height: Space.lg),
          FilledButton(onPressed: _saving ? null : _save, child: Text(l.actionSave)),
        ],
      ),
    );
  }
}
