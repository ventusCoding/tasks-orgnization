import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get localeName => Localizations.localeOf(this).toLanguageTag();
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
