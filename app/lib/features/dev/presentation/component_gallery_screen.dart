import 'package:everslot/core/errors/app_exception.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/organization/domain/tag.dart';
import 'package:everslot/features/organization/presentation/tag_widgets.dart';
import 'package:everslot/shared/filters/domain/entity_filter.dart';
import 'package:everslot/shared/filters/presentation/filter_bar.dart';
import 'package:everslot/shared/status/presentation/entity_status_style.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:material_ui/material_ui.dart';

/// Component gallery (dev flavor, T1.3.10 acceptance / T1.3.15): every design-system component
/// with live toggles for dark theme, right-to-left, large text (200 %) and reduced motion.
/// The debug menu links here; accessibility guideline tests run against this screen.
class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key, this.animateIndicators = true});

  /// Indeterminate indicators animate forever; tests turn this off to let frames settle.
  final bool animateIndicators;

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  bool _dark = false;
  bool _rtl = false;
  bool _largeText = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    // Start from the app's current brightness/direction.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _dark = Theme.of(context).brightness == Brightness.dark;
        _rtl = Directionality.of(context) == TextDirection.rtl;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Theme(
      data: _dark ? AppTheme.dark() : AppTheme.light(),
      child: Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: MediaQuery(
          data: media.copyWith(
            textScaler: _largeText ? const TextScaler.linear(2) : media.textScaler,
            disableAnimations: _reduceMotion || media.disableAnimations,
          ),
          child: Builder(builder: _scaffold),
        ),
      ),
    );
  }

  Widget _scaffold(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.galleryTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: Space.xxxl),
        children: [
          SwitchListTile(value: _dark, onChanged: (v) => setState(() => _dark = v), title: Text(l.galleryDarkTheme)),
          SwitchListTile(value: _rtl, onChanged: (v) => setState(() => _rtl = v), title: Text(l.galleryRtl)),
          SwitchListTile(
            value: _largeText,
            onChanged: (v) => setState(() => _largeText = v),
            title: Text(l.galleryLargeText),
          ),
          SwitchListTile(
            value: _reduceMotion,
            onChanged: (v) => setState(() => _reduceMotion = v),
            title: Text(l.galleryReduceMotion),
          ),
          _Section(
            title: l.galleryButtons,
            child: _ButtonsDemo(animate: widget.animateIndicators),
          ),
          _Section(title: l.galleryChips, child: const _ChipsDemo()),
          _Section(title: l.galleryInputs, child: const _InputsDemo()),
          _Section(title: l.galleryStatuses, child: const _StatusDemo()),
          _Section(title: l.galleryPriorities, child: const _PriorityDemo()),
          _Section(title: l.galleryProgress, child: const _ProgressDemo()),
          _Section(title: l.galleryColors, child: const _ColorsDemo()),
          _Section(title: l.galleryIcons, child: const _IconsDemo()),
          _Section(
            title: l.galleryStates,
            child: _StatesDemo(animate: widget.animateIndicators),
          ),
          _Section(title: l.galleryRows, child: const _RowsDemo()),
          _Section(title: l.galleryDialogs, child: const _DialogsDemo()),
          _Section(title: l.galleryFilters, child: const _FiltersDemo()),
          _Section(title: l.galleryMotion, child: const _MotionDemo()),
          _Section(title: l.galleryLayout, child: const _LayoutDemo()),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionHeader(title),
      Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.lg),
        child: child,
      ),
    ],
  );
}

class _ButtonsDemo extends StatelessWidget {
  const _ButtonsDemo({required this.animate});

  /// False in tests: the busy button's spinner never settles.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton(onPressed: () {}, child: Text(l.actionSave)),
        FilledButton.tonal(onPressed: () {}, child: Text(l.actionApply)),
        OutlinedButton(onPressed: () {}, child: Text(l.actionEdit)),
        TextButton(onPressed: () {}, child: Text(l.actionCancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: context.colors.error, foregroundColor: context.colors.onError),
          onPressed: () {},
          child: Text(l.actionDelete),
        ),
        FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: Text(l.actionAdd)),
        IconButton(tooltip: l.actionSearch, onPressed: () {}, icon: const Icon(Icons.search)),
        IconButton.filledTonal(tooltip: l.actionMore, onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        FloatingActionButton.extended(
          heroTag: null,
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: Text(l.actionAdd),
        ),
        FilledButton(onPressed: null, child: Text(l.galleryDisabled)),
        // Design-system wrappers (T1.3.10): ≥ 48 dp, busy state, required tooltips.
        AppButton(label: l.actionSave, icon: Icons.check, onPressed: () {}),
        AppButton(label: l.actionEdit, variant: AppButtonVariant.secondary, onPressed: () {}),
        AppButton(label: l.actionCancel, variant: AppButtonVariant.text, onPressed: () {}),
        AppButton(label: l.actionDelete, variant: AppButtonVariant.destructive, onPressed: () {}),
        if (animate) AppButton(label: l.actionSave, busy: true, onPressed: () {}),
        AppIconButton(icon: Icons.inbox_outlined, tooltip: l.actionInbox, badge: 3, onPressed: () {}),
      ],
    );
  }
}

class _ChipsDemo extends StatefulWidget {
  const _ChipsDemo();

  @override
  State<_ChipsDemo> createState() => _ChipsDemoState();
}

class _ChipsDemoState extends State<_ChipsDemo> {
  bool _selected = true;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tags = [
      Tag(id: 'w', name: l.categoryDefaultWork, sortKey: 'a0', color: CategoryPalette.at(0)),
      Tag(id: 'h', name: l.categoryDefaultHome, sortKey: 'a1', color: CategoryPalette.at(3)),
      Tag(id: 's', name: l.categoryDefaultStudy, sortKey: 'a2'),
    ];
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        FilterChip(
          label: Text(l.filterCategory),
          selected: _selected,
          onSelected: (v) => setState(() => _selected = v),
        ),
        ChoiceChip(
          label: Text(l.priorityHigh),
          selected: !_selected,
          onSelected: (v) => setState(() => _selected = !v),
        ),
        ActionChip(avatar: const Icon(Icons.add, size: 18), label: Text(l.tagAdd), onPressed: () {}),
        TagChip(tag: tags[0]),
        TagChip(tag: tags[1], onTap: () {}, onDeleted: () {}),
        TagChip(tag: tags[2], selected: _selected, onTap: () {}),
      ],
    );
  }
}

class _InputsDemo extends StatefulWidget {
  const _InputsDemo();

  @override
  State<_InputsDemo> createState() => _InputsDemoState();
}

class _InputsDemoState extends State<_InputsDemo> {
  bool _checked = true;
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(labelText: l.categoryName, hintText: l.gallerySampleText),
        ),
        const SizedBox(height: Space.md),
        AppSearchField(onChanged: (_) {}),
        const SizedBox(height: Space.md),
        AppSegmented<int>(
          segments: [(0, l.actionToday, Icons.today), (1, l.tabPlan, null), (2, l.tabLists, null)],
          selected: _segment,
          onChanged: (v) => setState(() => _segment = v),
        ),
        const SizedBox(height: Space.md),
        TextField(minLines: 2, maxLines: 4, decoration: InputDecoration(labelText: l.gallerySampleText)),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _checked,
          onChanged: (v) => setState(() => _checked = v ?? false),
          title: Text(l.gallerySampleText),
        ),
      ],
    );
  }
}

class _StatusDemo extends StatelessWidget {
  const _StatusDemo();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Space.sm,
    runSpacing: Space.sm,
    children: [
      for (final s in {
        ...EntityStatusStyle.itemStatuses,
        ...EntityStatusStyle.occurrenceStatuses,
        ...EntityStatusStyle.lifecycleStatuses,
      })
        EntityStatusPill(s),
    ],
  );
}

class _PriorityDemo extends StatefulWidget {
  const _PriorityDemo();

  @override
  State<_PriorityDemo> createState() => _PriorityDemoState();
}

class _PriorityDemoState extends State<_PriorityDemo> {
  int _value = 2;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: Space.lg,
        runSpacing: Space.sm,
        children: [for (var p = 0; p <= 4; p++) PriorityBadge(p, showLabel: true)],
      ),
      const SizedBox(height: Space.md),
      PrioritySelector(value: _value, onChanged: (v) => setState(() => _value = v)),
    ],
  );
}

class _ProgressDemo extends StatelessWidget {
  const _ProgressDemo();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ProgressRing(
              progress: 0.66,
              semanticsLabel: l.galleryProgress,
              child: Text(AppFormat(context.localeName).percent(0.66), style: context.text.labelSmall),
            ),
            const SizedBox(width: Space.lg),
            Expanded(child: LinearProgressIndicator(value: 0.4, semanticsLabel: l.galleryProgress)),
          ],
        ),
        const SizedBox(height: Space.md),
        SegmentedBar(
          segments: [
            BarSegment(5, c.completed, l.entityStatusCompleted),
            BarSegment(2, c.ongoing, l.entityStatusOngoing),
            BarSegment(1, c.waiting, l.entityStatusWaiting),
            BarSegment(1, c.blocked, l.entityStatusBlocked),
            BarSegment(3, c.todo, l.entityStatusTodo),
          ],
        ),
      ],
    );
  }
}

class _ColorsDemo extends StatelessWidget {
  const _ColorsDemo();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final names = [
      l.categoryDefaultWork,
      l.categoryDefaultPersonal,
      l.categoryDefaultHealth,
      l.categoryDefaultStudy,
      l.categoryDefaultHome,
      l.categoryDefaultSocial,
    ];
    final brightness = Theme.of(context).brightness;
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        for (var i = 0; i < CategoryPalette.colors.length; i++)
          Builder(
            builder: (context) {
              final argb = CategoryPalette.colors[i];
              final tile = CategoryColors.background(
                argb,
                brightness,
                highContrast: context.a11y.highContrastCategories,
              );
              return Container(
                padding: const EdgeInsetsDirectional.fromSTEB(Space.sm, Space.xs, Space.md, Space.xs),
                decoration: BoxDecoration(
                  color: tile,
                  borderRadius: BorderRadius.circular(Radii.sm),
                  border: BorderDirectional(
                    start: BorderSide(
                      color: CategoryColors.accent(argb, brightness, highContrast: context.a11y.highContrastCategories),
                      width: 4,
                    ),
                  ),
                ),
                child: Text(names[i % names.length], style: TextStyle(color: CategoryColors.onBackground(tile))),
              );
            },
          ),
      ],
    );
  }
}

class _IconsDemo extends StatelessWidget {
  const _IconsDemo();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Space.md,
    runSpacing: Space.md,
    children: [for (final icon in IconCatalog.all.take(24)) Icon(icon.icon, color: context.colors.onSurfaceVariant)],
  );
}

class _StatesDemo extends StatelessWidget {
  const _StatesDemo({required this.animate});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmptyState(title: l.stateEmpty, message: l.placeholderScreen, actionLabel: l.actionAdd, onAction: () {}),
        ErrorState(error: const NetworkException('offline'), onRetry: () {}),
        TickerMode(enabled: animate, child: const LoadingState()),
      ],
    );
  }
}

class _DialogsDemo extends StatefulWidget {
  const _DialogsDemo();

  @override
  State<_DialogsDemo> createState() => _DialogsDemoState();
}

class _DialogsDemoState extends State<_DialogsDemo> {
  String? _picked;

  void _show(Object? value) {
    if (!mounted || value == null) return;
    setState(() => _picked = '$value');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final format = AppFormat(context.localeName, l10n: l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            OutlinedButton(
              onPressed: () async => _show(
                await confirmDialog(
                  context,
                  title: l.galleryConfirm,
                  body: l.confirmDeleteBody,
                  destructive: true,
                  confirmLabel: l.actionDelete,
                ),
              ),
              child: Text(l.galleryConfirm),
            ),
            OutlinedButton(
              onPressed: () async => _show(await promptText(context, title: l.galleryPrompt)),
              child: Text(l.galleryPrompt),
            ),
            OutlinedButton(
              onPressed: () async {
                final date = await pickDate(context);
                _show(date == null ? null : format.dateMedium(date));
              },
              child: Text(l.pickerDate),
            ),
            OutlinedButton(
              onPressed: () async {
                final time = await pickTime(context);
                _show(time == null ? null : format.time(time));
              },
              child: Text(l.pickerTime),
            ),
            OutlinedButton(
              onPressed: () async {
                final minutes = await pickDuration(context);
                _show(minutes == null ? null : format.duration(minutes));
              },
              child: Text(l.pickerDuration),
            ),
            OutlinedButton(
              onPressed: () async {
                final color = await pickColor(context, allowNone: true);
                _show(color == null ? null : '#${color.toRadixString(16)}');
              },
              child: Text(l.pickerColor),
            ),
            OutlinedButton(
              onPressed: () async {
                final range = await pickTimeRange(context, start: LocalTime(9, 0), minutes: 60);
                _show(range == null ? null : '${format.time(range.start)} · ${format.duration(range.minutes)}');
              },
              child: Text(l.pickerTimeRange),
            ),
            OutlinedButton(onPressed: () async => _show(await pickIcon(context)), child: Text(l.pickerIcon)),
            OutlinedButton(
              onPressed: () => showAppSheet<void>(
                context,
                title: l.gallerySheetActions,
                builder: (ctx) => SheetScaffold(
                  actions: [
                    AppButton(
                      label: ctx.l10n.actionCancel,
                      variant: AppButtonVariant.text,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    AppButton(label: ctx.l10n.actionApply, onPressed: () => Navigator.pop(ctx)),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(ctx.l10n.gallerySheetBody),
                      const SizedBox(height: Space.md),
                      TextField(decoration: InputDecoration(labelText: ctx.l10n.gallerySampleText)),
                    ],
                  ),
                ),
              ),
              child: Text(l.gallerySheetActions),
            ),
            OutlinedButton(
              onPressed: () => showAppSheet<void>(
                context,
                title: l.gallerySheet,
                builder: (ctx) =>
                    Padding(padding: const EdgeInsets.all(Space.xl), child: Text(ctx.l10n.gallerySheetBody)),
              ),
              child: Text(l.gallerySheet),
            ),
            OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(l.savedSnack),
                    action: SnackBarAction(label: l.actionUndo, onPressed: () {}),
                  ),
                ),
              child: Text(l.galleryUndoSnack),
            ),
          ],
        ),
        if (_picked != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: Space.sm),
            child: Text(l.galleryPicked(_picked!)),
          ),
      ],
    );
  }
}

class _RowsDemo extends StatefulWidget {
  const _RowsDemo();

  @override
  State<_RowsDemo> createState() => _RowsDemoState();
}

class _RowsDemoState extends State<_RowsDemo> {
  final _rows = ['a', 'b'];
  final _done = <String>{};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.appColors;
    return Column(
      children: [
        for (final id in _rows)
          SwipeRow(
            id: id,
            start: RowSwipeAction(
              label: l.actionDone,
              icon: Icons.check,
              color: c.success,
              onTriggered: () {
                setState(() => _done.add(id));
                return false;
              },
            ),
            end: RowSwipeAction(
              label: l.actionDelete,
              icon: Icons.delete_outline,
              color: c.danger,
              onTriggered: () {
                setState(() => _rows.remove(id));
                return true;
              },
            ),
            child: ListTile(
              leading: AppAvatar(
                name: id == 'a' ? 'Sam Lee' : 'سارة علي',
                colorArgb: CategoryPalette.at(id == 'a' ? 0 : 4),
              ),
              title: Text('${l.gallerySampleText} ${id.toUpperCase()}'),
              subtitle: Text(_done.contains(id) ? l.actionDone : l.gallerySwipeHint),
              trailing: const CountBadge(2),
            ),
          ),
      ],
    );
  }
}

class _FiltersDemo extends StatefulWidget {
  const _FiltersDemo();

  @override
  State<_FiltersDemo> createState() => _FiltersDemoState();
}

class _FiltersDemoState extends State<_FiltersDemo> {
  EntityFilter _filter = EntityFilter(
    priorities: const {3, 4},
    dateFrom: LocalDate(2026, 9, 1),
    dateTo: LocalDate(2026, 9, 30),
  );

  @override
  Widget build(BuildContext context) => FilterBar(
    value: _filter,
    padding: EdgeInsetsDirectional.zero,
    fields: FilterField.values,
    statusOptions: EntityStatusStyle.filterOptions(context, EntityStatusStyle.itemStatuses),
    onChanged: (v) => setState(() => _filter = v),
  );
}

class _MotionDemo extends StatefulWidget {
  const _MotionDemo();

  @override
  State<_MotionDemo> createState() => _MotionDemoState();
}

class _MotionDemoState extends State<_MotionDemo> {
  bool _alternate = false;

  Widget _page(BuildContext context, String title, IconData icon) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Icon(icon, size: 96, color: context.colors.primary)),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton(
          onPressed: () =>
              Navigator.of(context)
                  .push(AppMotion.sharedAxisRoute<void>((ctx) => _page(ctx, l.gallerySharedAxis, Icons.swap_horiz))),
          child: Text(l.gallerySharedAxis),
        ),
        OutlinedButton(
          onPressed: () =>
              Navigator.of(context)
                  .push(AppMotion.fadeThroughRoute<void>((ctx) => _page(ctx, l.galleryFadeThrough, Icons.gradient))),
          child: Text(l.galleryFadeThrough),
        ),
        OutlinedButton(
          onPressed: () =>
              Navigator.of(context)
                  .push(AppMotion.containerRoute<void>((ctx) => _page(ctx, l.galleryContainer, Icons.open_in_full))),
          child: Text(l.galleryContainer),
        ),
        IconButton(
          tooltip: l.galleryFadeThrough,
          onPressed: () => setState(() => _alternate = !_alternate),
          icon: FadeThroughSwitcher(
            child: Icon(_alternate ? Icons.dark_mode_outlined : Icons.light_mode_outlined, key: ValueKey(_alternate)),
          ),
        ),
      ],
    );
  }
}

class _LayoutDemo extends StatelessWidget {
  const _LayoutDemo();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String sizeLabel(WindowSizeClass size) => switch (size) {
      WindowSizeClass.compact => l.galleryWindowCompact,
      WindowSizeClass.medium => l.galleryWindowMedium,
      WindowSizeClass.expanded => l.galleryWindowExpanded,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.galleryWindowSize(sizeLabel(context.windowSize))),
        const SizedBox(height: Space.sm),
        SizedBox(
          height: 160,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.outlineVariant),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: TwoPaneScaffold(
              breakpoint: 480,
              listWidth: 180,
              list: ListView(
                children: [
                  for (final name in [l.categoryDefaultWork, l.categoryDefaultHome, l.categoryDefaultHealth])
                    ListTile(title: Text(name), onTap: () {}),
                ],
              ),
              detail: Center(child: Text(l.gallerySampleText)),
            ),
          ),
        ),
      ],
    );
  }
}
