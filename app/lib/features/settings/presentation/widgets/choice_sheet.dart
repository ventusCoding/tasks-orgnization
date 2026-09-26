import 'package:everslot/design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

/// One option of [pickChoice].
class Choice<T> {
  const Choice(this.value, this.label, {this.subtitle, this.icon});

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

/// Single-choice bottom sheet (selected option checked, `selected` semantics). Returns the picked
/// value, or null when dismissed. Wrap nullable values (e.g. "system language") in a sentinel.
Future<T?> pickChoice<T>(
  BuildContext context, {
  required String title,
  required List<Choice<T>> choices,
  required T selected,
}) => showAppSheet<T>(
  context,
  title: title,
  builder: (ctx) => ListView(
    shrinkWrap: true,
    padding: const EdgeInsetsDirectional.only(bottom: Space.lg),
    children: [
      for (final c in choices)
        ListTile(
          key: ValueKey('choice-${c.value}'),
          leading: c.icon == null ? null : Icon(c.icon),
          title: Text(c.label),
          subtitle: c.subtitle == null ? null : Text(c.subtitle!),
          selected: c.value == selected,
          trailing: c.value == selected ? const Icon(Icons.check) : null,
          onTap: () => Navigator.pop(ctx, c.value),
        ),
    ],
  ),
);

/// Interface languages: `''` = follow the system (nullable values can't be told apart from a
/// dismissed sheet), otherwise `en` / `fr` / `ar`.
List<Choice<String>> languageChoices(BuildContext context) {
  final l = context.l10n;
  return [
    Choice('', l.settingsLanguageSystem, icon: Icons.phone_android),
    Choice('en', l.settingsLanguageEnglish),
    Choice('fr', l.settingsLanguageFrench),
    Choice('ar', l.settingsLanguageArabic),
  ];
}

/// Display name of a stored language code (null = system).
String languageLabel(BuildContext context, String? code) {
  for (final c in languageChoices(context)) {
    if (c.value == (code ?? '')) return c.label;
  }
  return code ?? context.l10n.settingsLanguageSystem;
}
