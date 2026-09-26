// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get actionAdd => 'Ajouter';

  @override
  String get actionApply => 'Appliquer';

  @override
  String get actionArchive => 'Archiver';

  @override
  String get actionBack => 'Retour';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionClear => 'Effacer';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionConfirm => 'Confirmer';

  @override
  String get actionContinue => 'Continuer';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionDone => 'Terminé';

  @override
  String get actionDuplicate => 'Dupliquer';

  @override
  String get actionEdit => 'Modifier';

  @override
  String get actionInbox => 'Notifications';

  @override
  String get actionMore => 'Plus';

  @override
  String get actionNext => 'Suivant';

  @override
  String get actionOpen => 'Ouvrir';

  @override
  String get actionRedo => 'Rétablir';

  @override
  String get actionRestore => 'Restaurer';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionSearch => 'Rechercher';

  @override
  String get actionSettings => 'Réglages';

  @override
  String get actionShare => 'Partager';

  @override
  String get actionSkip => 'Passer';

  @override
  String get actionToday => 'Aujourd\'hui';

  @override
  String get actionUndo => 'Annuler';

  @override
  String get appName => 'Everslot';

  @override
  String get appTagline => 'Maîtrisez chaque créneau de votre journée.';

  @override
  String get attachmentsAdd => 'Ajouter une pièce jointe';

  @override
  String attachmentsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pièces jointes ajoutées',
      one: '1 pièce jointe ajoutée',
    );
    return '$_temp0';
  }

  @override
  String get attachmentsCacheCleared => 'Cache vidé';

  @override
  String attachmentsCacheSize(String size) {
    return 'Cache local : $size';
  }

  @override
  String get attachmentsCameraPrimerBody =>
      'Everslot demande l\'accès à l\'appareil photo pour joindre des photos. Elles restent sur votre appareil jusqu\'à leur envoi sur votre compte.';

  @override
  String get attachmentsCameraPrimerTitle => 'Utiliser l\'appareil photo';

  @override
  String get attachmentsCaption => 'Légende';

  @override
  String get attachmentsClearCache => 'Vider le cache';

  @override
  String attachmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pièces jointes',
      one: '1 pièce jointe',
    );
    return '$_temp0';
  }

  @override
  String get attachmentsDownloadWhenOnline =>
      'Ce fichier sera téléchargé lorsque vous serez en ligne.';

  @override
  String get attachmentsEditCaption => 'Modifier la légende';

  @override
  String get attachmentsEmpty => 'Aucune pièce jointe';

  @override
  String get attachmentsGoToItem => 'Aller à l\'élément';

  @override
  String get attachmentsKindAudio => 'Audio';

  @override
  String get attachmentsKindFile => 'Fichier';

  @override
  String get attachmentsKindPdf => 'PDF';

  @override
  String get attachmentsKindPhoto => 'Photo';

  @override
  String get attachmentsKindVideo => 'Vidéo';

  @override
  String get attachmentsLocalOnly => 'Stocké sur cet appareil';

  @override
  String attachmentsMore(int count) {
    return '+$count';
  }

  @override
  String get attachmentsMoveEarlier => 'Déplacer avant';

  @override
  String get attachmentsMoveLater => 'Déplacer après';

  @override
  String get attachmentsNoPreview => 'Aucun aperçu pour ce type de fichier';

  @override
  String get attachmentsOpenSettings => 'Ouvrir les réglages';

  @override
  String get attachmentsOpenWith => 'Ouvrir avec…';

  @override
  String attachmentsPendingUploads(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count envois en attente',
      one: '1 envoi en attente',
    );
    return '$_temp0';
  }

  @override
  String get attachmentsPermissionBody =>
      'Everslot ne peut pas accéder à votre appareil photo ou à vos photos. Vous pouvez l\'autoriser dans les réglages du système.';

  @override
  String get attachmentsPermissionTitle => 'Accès nécessaire';

  @override
  String attachmentsRejectedDuplicate(String name) {
    return '$name est déjà joint';
  }

  @override
  String attachmentsRejectedEmpty(String name) {
    return '$name est vide';
  }

  @override
  String attachmentsRejectedTooLarge(String name, String limit) {
    return '$name dépasse $limit';
  }

  @override
  String attachmentsRejectedTooMany(int count) {
    return 'Limite de $count pièces jointes atteinte';
  }

  @override
  String attachmentsRejectedType(String name) {
    return '$name : ce type de fichier n\'est pas pris en charge';
  }

  @override
  String attachmentsRejectedUnreadable(String name) {
    return 'Impossible de lire $name';
  }

  @override
  String get attachmentsRemove => 'Retirer';

  @override
  String get attachmentsRemoved => 'Pièce jointe retirée';

  @override
  String get attachmentsRetry => 'Réessayer l\'envoi';

  @override
  String attachmentsSemantics(String kind, int index, int total) {
    return '$kind $index sur $total';
  }

  @override
  String get attachmentsSettingsTitle => 'Pièces jointes';

  @override
  String attachmentsSizeB(String size) {
    return '$size o';
  }

  @override
  String attachmentsSizeGb(String size) {
    return '$size Go';
  }

  @override
  String attachmentsSizeKb(String size) {
    return '$size Ko';
  }

  @override
  String attachmentsSizeMb(String size) {
    return '$size Mo';
  }

  @override
  String get attachmentsSourceCamera => 'Prendre une photo';

  @override
  String get attachmentsSourceFiles => 'Choisir des fichiers';

  @override
  String get attachmentsSourcePhotos => 'Choisir des photos';

  @override
  String get attachmentsStatusDownloading => 'Téléchargement';

  @override
  String get attachmentsStatusFailed =>
      'Échec de l\'envoi — touchez pour réessayer';

  @override
  String get attachmentsStatusNotDownloaded =>
      'Non téléchargé — touchez pour récupérer';

  @override
  String get attachmentsStatusProcessing => 'Traitement';

  @override
  String attachmentsStatusUploading(int percent) {
    return 'Envoi $percent %';
  }

  @override
  String get attachmentsStatusUploadingShort => 'Envoi en cours';

  @override
  String get attachmentsStatusWaiting => 'En attente du réseau';

  @override
  String attachmentsStorageUsed(String size) {
    return 'Stockage utilisé : $size';
  }

  @override
  String attachmentsViewerPosition(int index, int total) {
    return '$index / $total';
  }

  @override
  String get attachmentsWifiOnly =>
      'Envoyer les pièces jointes en Wi-Fi uniquement';

  @override
  String get categoriesEmpty => 'Aucune catégorie';

  @override
  String get categoriesTitle => 'Catégories';

  @override
  String get categoryArchived => 'Archivée';

  @override
  String get categoryDefaultHealth => 'Santé';

  @override
  String get categoryDefaultHome => 'Maison';

  @override
  String get categoryDefaultPersonal => 'Personnel';

  @override
  String get categoryDefaultSocial => 'Social';

  @override
  String get categoryDefaultStudy => 'Études';

  @override
  String get categoryDefaultWork => 'Travail';

  @override
  String get categoryDeleteBody =>
      'Les éléments de cette catégorie resteront, sans catégorie.';

  @override
  String get categoryEdit => 'Modifier la catégorie';

  @override
  String get categoryName => 'Nom';

  @override
  String get categoryNew => 'Nouvelle catégorie';

  @override
  String get categoryNone => 'Sans catégorie';

  @override
  String get categoryPick => 'Catégorie';

  @override
  String get categoryUnavailable => 'Compte comme temps indisponible';

  @override
  String get categoryUnavailableHint =>
      'Exclu des statistiques de capacité (sommeil, congés…).';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get confirmDeleteBody =>
      'Vous pourrez le restaurer depuis la corbeille pendant 30 jours.';

  @override
  String confirmDeleteTitle(String item) {
    return 'Supprimer $item ?';
  }

  @override
  String deletedSnack(String item) {
    return '$item supprimé';
  }

  @override
  String get devMenu => 'Menu développeur';

  @override
  String durationDaysShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String durationHoursMinutesShort(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationHoursShort(int hours) {
    return '$hours h';
  }

  @override
  String durationMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get errorAuth => 'Veuillez vous reconnecter.';

  @override
  String get errorNetwork => 'Serveur injoignable. Vérifiez votre connexion.';

  @override
  String get errorNotConfigured =>
      'Cette fonction nécessite la configuration cloud (voir guide.md).';

  @override
  String get errorNotFound => 'Cet élément n\'existe plus.';

  @override
  String get errorPermission => 'Une autorisation est nécessaire.';

  @override
  String get errorUnknown => 'Erreur inattendue.';

  @override
  String get errorUnsupportedVersion =>
      'Mettez à jour Everslot pour continuer la synchronisation.';

  @override
  String get errorValidation => 'Veuillez vérifier les champs indiqués.';

  @override
  String get localOnlyBanner =>
      'La synchronisation cloud n\'est pas configurée — vos données restent sur cet appareil.';

  @override
  String get notFoundTitle => 'Page introuvable';

  @override
  String get notifActionComplete => 'Terminer';

  @override
  String get notifActionDone => 'Fait';

  @override
  String get notifActionInputPlaceholder => 'Valeur';

  @override
  String get notifActionLogCraving => 'Noter une envie';

  @override
  String get notifActionLogValue => 'Noter une valeur';

  @override
  String get notifActionMarkBlocked => 'Marquer bloqué';

  @override
  String get notifActionMarkOngoing => 'Marquer en cours';

  @override
  String get notifActionMarkRead => 'Marquer comme lu';

  @override
  String get notifActionMarkWaiting => 'Marquer en attente';

  @override
  String get notifActionMute => 'Couper';

  @override
  String get notifActionOpen => 'Ouvrir';

  @override
  String get notifActionReschedule => 'Replanifier';

  @override
  String get notifActionSend => 'Envoyer';

  @override
  String get notifActionSkip => 'Passer';

  @override
  String get notifActionSnooze => 'Reporter';

  @override
  String get notifActionStart => 'Démarrer';

  @override
  String get notifActionStop => 'Arrêter';

  @override
  String get notifActions => 'Actions';

  @override
  String get notifAddReminder => 'Ajouter un rappel';

  @override
  String get notifAdjCatchUp => 'En retard';

  @override
  String get notifAdjDeferred => 'Reporté (heures calmes)';

  @override
  String get notifAdjNotLocal => 'Livré sur un autre appareil';

  @override
  String get notifAdjPaused => 'Suspendu — boîte seulement';

  @override
  String get notifAdjShifted => 'Déplacé dans la plage horaire';

  @override
  String get notifAdjSilent => 'Silencieux (heures calmes)';

  @override
  String get notifAdvanced => 'Avancé…';

  @override
  String get notifAdvancedTitle => 'Règle de rappel';

  @override
  String get notifAfter => 'après';

  @override
  String get notifAllowPrecise => 'Autoriser les rappels précis';

  @override
  String get notifAnchorDue => 'échéance';

  @override
  String get notifAnchorEnd => 'fin';

  @override
  String get notifAnchorFollowUp => 'relance';

  @override
  String get notifAnchorPeriodEnd => 'fin de période';

  @override
  String get notifAnchorPeriodStart => 'début de période';

  @override
  String get notifAnchorSlot => 'créneau';

  @override
  String get notifAnchorStart => 'début';

  @override
  String get notifAndroidLabel => 'Android';

  @override
  String get notifBadgeDue => 'En retard + aujourd’hui';

  @override
  String get notifBadgeOff => 'Désactivée';

  @override
  String get notifBadgePolicy => 'Pastille de l’icône';

  @override
  String get notifBadgeUnread => 'Non lus';

  @override
  String notifBannerCollapsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rappels',
      one: '$count rappel',
      zero: '$count rappel',
    );
    return '$_temp0';
  }

  @override
  String get notifBannerDismiss => 'Fermer';

  @override
  String get notifBannerInApp => 'Bannières dans l’app';

  @override
  String get notifBannerToggle => 'Bannière dans l’app';

  @override
  String get notifBefore => 'avant';

  @override
  String get notifBodyChildOverdue => 'Un sous-élément est en retard';

  @override
  String get notifBodyChildrenComplete =>
      'Tous les sous-éléments sont faits — le terminer ?';

  @override
  String notifBodyCleanDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
      zero: '$days jour',
    );
    return '$_temp0 sans — bravo !';
  }

  @override
  String notifBodyDueIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '$minutes min',
      zero: '$minutes min',
    );
    return 'Échéance dans $_temp0';
  }

  @override
  String get notifBodyDueNow => 'Échéance maintenant';

  @override
  String notifBodyEndedAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '$minutes min',
      zero: '$minutes min',
    );
    return 'Terminé il y a $_temp0';
  }

  @override
  String get notifBodyEndingNow => 'Se termine maintenant';

  @override
  String notifBodyEndsIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '$minutes min',
      zero: '$minutes min',
    );
    return 'Se termine dans $_temp0';
  }

  @override
  String notifBodyInDays(int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
      zero: '$days jour',
    );
    return 'Dans $_temp0 · $date';
  }

  @override
  String notifBodyInactivity(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
      zero: '$days jour',
    );
    return 'Aucune activité depuis $_temp0';
  }

  @override
  String notifBodyMilestone(String label) {
    return 'Étape atteinte : $label';
  }

  @override
  String notifBodyNotDone(String title) {
    return 'Vous n’avez pas encore noté $title aujourd’hui';
  }

  @override
  String notifBodyOverdue(String title) {
    return '$title est en retard';
  }

  @override
  String notifBodyQuotaBehind(String done, String target, int remaining) {
    return '$done/$target fait — encore $remaining';
  }

  @override
  String get notifBodySnoozed => 'Rappel reporté';

  @override
  String notifBodyStartedAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '$minutes min',
      zero: '$minutes min',
    );
    return 'Commencé il y a $_temp0';
  }

  @override
  String get notifBodyStartingNow => 'Commence maintenant';

  @override
  String notifBodyStartsIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '$minutes min',
      zero: '$minutes min',
    );
    return 'Commence dans $_temp0';
  }

  @override
  String notifBodyStatusAge(String status, String age) {
    return 'Toujours $status · $age';
  }

  @override
  String notifBodyStatusChange(String status) {
    return 'Désormais $status';
  }

  @override
  String notifBodyStreakRisk(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
      zero: '$days jour',
    );
    return 'Gardez votre série de $_temp0';
  }

  @override
  String get notifBodyTest => 'Notification de test d’Everslot';

  @override
  String notifBodyTimeFor(String title) {
    return 'C’est l’heure : $title';
  }

  @override
  String notifBodyToday(String date) {
    return 'Aujourd’hui · $date';
  }

  @override
  String get notifCategoryDigest => 'Récapitulatif';

  @override
  String get notifCategoryMilestone => 'Étape';

  @override
  String get notifCategoryNag => 'Relance';

  @override
  String get notifCategoryReminder => 'Rappel';

  @override
  String get notifCategoryStreak => 'Série';

  @override
  String get notifCategorySystem => 'Système';

  @override
  String get notifChannelBlocked =>
      'Certaines catégories de notifications sont bloquées';

  @override
  String get notifChannelDigest => 'Récapitulatifs';

  @override
  String get notifChannelForeground => 'Quand Everslot est ouvert';

  @override
  String notifChannelName(String section, String profile) {
    return '$section · $profile';
  }

  @override
  String get notifChannelQuiet => 'Heures calmes';

  @override
  String get notifChannelSystem => 'Avis système';

  @override
  String get notifChipAtDue => 'À l’échéance';

  @override
  String get notifChipAtEnd => 'À la fin';

  @override
  String get notifChipAtFollowUp => 'À la relance';

  @override
  String get notifChipAtSlot => 'À l’heure prévue';

  @override
  String get notifChipAtStart => 'Au début';

  @override
  String get notifChipAtTime => 'À une heure…';

  @override
  String notifChipBefore(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min avant',
      one: '$minutes min avant',
      zero: '$minutes min avant',
    );
    return '$_temp0';
  }

  @override
  String get notifChipCustom => 'Personnalisé…';

  @override
  String notifChipDayBeforeAt(String time) {
    return '1 jour avant à $time';
  }

  @override
  String get notifChipEvery => 'Chaque jour à…';

  @override
  String get notifChipIfNotDoneBy => 'Si pas fait avant…';

  @override
  String get notifChipMilestones => 'Étapes';

  @override
  String notifChipOnDayAt(String time) {
    return 'Le jour même à $time';
  }

  @override
  String get notifChipStreakRisk => 'Série en danger';

  @override
  String get notifConditions => 'Conditions';

  @override
  String get notifContent => 'Contenu';

  @override
  String get notifContentBody => 'Modèle du texte';

  @override
  String get notifContentTitle => 'Modèle du titre';

  @override
  String notifCreateCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ajouter $count rappels',
      one: 'Ajouter $count rappel',
      zero: 'Ajouter $count rappel',
    );
    return '$_temp0';
  }

  @override
  String get notifCustomize => 'Personnaliser';

  @override
  String get notifDateOnlyTime => 'Heure par défaut des éléments à date seule';

  @override
  String get notifDefaultLateness => 'Livrer les rappels en retard jusqu’à';

  @override
  String get notifDefaultProfile => 'Profil par défaut';

  @override
  String get notifDefaultsAddCategory => 'Ajouter des défauts de catégorie';

  @override
  String get notifDefaultsAllDay => 'Éléments sur la journée';

  @override
  String get notifDefaultsCategory => 'Défauts par catégorie';

  @override
  String get notifDefaultsDateOnly => 'Éléments à date seule';

  @override
  String get notifDefaultsEntry => 'Rappels par défaut';

  @override
  String get notifDefaultsOther => 'Autres défauts';

  @override
  String get notifDefaultsTimed => 'Éléments horaires';

  @override
  String get notifDefaultsTitle => 'Rappels par défaut';

  @override
  String get notifDelivery => 'Distribution';

  @override
  String get notifDeviceAll => 'Tous les appareils';

  @override
  String get notifDeviceLastActive => 'Dernier appareil actif';

  @override
  String get notifDevicePrimary => 'Appareil principal seulement';

  @override
  String get notifDiagBadge => 'Pastille';

  @override
  String get notifDiagBattery => 'Optimisation de la batterie';

  @override
  String get notifDiagBatteryBody =>
      'Certains téléphones arrêtent les apps en arrière-plan. Suivez le guide de votre téléphone pour garder des rappels à l’heure.';

  @override
  String notifDiagBatteryOpen(String maker) {
    return 'Ouvrir le guide pour $maker';
  }

  @override
  String get notifDiagBlocked => 'Canaux bloqués';

  @override
  String notifDiagBudget(int used, int total) {
    return 'Budget $used/$total';
  }

  @override
  String get notifDiagCapabilities => 'Capacités';

  @override
  String get notifDiagCopied => 'Diagnostic copié (sans contenu)';

  @override
  String get notifDiagCopy => 'Copier le diagnostic';

  @override
  String get notifDiagCoverage => 'Couvert jusqu’à';

  @override
  String get notifDiagExact => 'Alarmes exactes';

  @override
  String get notifDiagLastReplan => 'Dernière planification';

  @override
  String notifDiagMismatch(int count) {
    return 'Écarts entre le système et la planification : $count';
  }

  @override
  String get notifDiagNext => 'Prochains déclenchements';

  @override
  String get notifDiagPendingOs => 'En attente dans le système';

  @override
  String get notifDiagPermission => 'Notifications autorisées';

  @override
  String get notifDiagProvisional => 'Livraison provisoire (discrète)';

  @override
  String get notifDiagPush => 'Push';

  @override
  String get notifDiagPushOff =>
      'Push non configuré — rappels locaux uniquement';

  @override
  String get notifDiagPushOn => 'Push actif';

  @override
  String notifDiagReplanInfo(String time, int ms, String reason) {
    return '$time · $ms ms · $reason';
  }

  @override
  String get notifDiagReplanNow => 'Replanifier maintenant';

  @override
  String get notifDiagSchedule => 'Planification';

  @override
  String get notifDiagTimeSensitive => 'Urgentes';

  @override
  String get notifDiagTitle => 'Diagnostic des notifications';

  @override
  String get notifDiagTracked => 'Suivis (boîte seule ou hors budget)';

  @override
  String get notifDiagnostics => 'Diagnostic';

  @override
  String notifDigestAt(String time) {
    return 'à $time';
  }

  @override
  String get notifDigestDailyAgenda => 'Programme du jour';

  @override
  String get notifDigestEveningReview => 'Bilan du soir';

  @override
  String notifDigestFirst(String first) {
    return 'Premier : $first';
  }

  @override
  String get notifDigestMonthly => 'Rapport mensuel';

  @override
  String get notifDigestOverdue => 'Récapitulatif des retards';

  @override
  String get notifDigestPlanTomorrow => 'Préparer demain';

  @override
  String notifDigestSummary(int tasks, int habits, int items) {
    String _temp0 = intl.Intl.pluralLogic(
      tasks,
      locale: localeName,
      other: '$tasks tâches',
      one: '$tasks tâche',
      zero: '$tasks tâche',
    );
    String _temp1 = intl.Intl.pluralLogic(
      habits,
      locale: localeName,
      other: '$habits habitudes',
      one: '$habits habitude',
      zero: '$habits habitude',
    );
    String _temp2 = intl.Intl.pluralLogic(
      items,
      locale: localeName,
      other: '$items éléments',
      one: '$items élément',
      zero: '$items élément',
    );
    return '$_temp0 · $_temp1 · $_temp2';
  }

  @override
  String get notifDigestWeekly => 'Bilan de la semaine';

  @override
  String get notifDigests => 'Récapitulatifs';

  @override
  String get notifDisable => 'Désactiver';

  @override
  String get notifEditorTitle => 'Nouveau rappel';

  @override
  String get notifEnable => 'Activer';

  @override
  String get notifExactOff =>
      'Les rappels peuvent arriver jusqu’à une heure en retard';

  @override
  String get notifExactOffBody =>
      'Autorisez les rappels précis pour qu’ils sonnent à la minute près.';

  @override
  String get notifFieldAfterDays => 'Après (jours)';

  @override
  String get notifFieldAfterMinutes => 'Après (minutes)';

  @override
  String get notifFieldAtTime => 'À l’heure';

  @override
  String get notifFieldDateTime => 'Date et heure';

  @override
  String get notifFieldDayForm => 'N jours avant ou après à une heure';

  @override
  String get notifFieldDayOffset => 'Jours (négatif = avant)';

  @override
  String get notifFieldDigestKind => 'Récapitulatif';

  @override
  String get notifFieldEveryMinutes => 'Toutes les (minutes)';

  @override
  String get notifFieldMaxTimes => 'Au plus (fois)';

  @override
  String get notifFieldMetric => 'Mesure';

  @override
  String get notifFieldMinStreak => 'Série minimale';

  @override
  String get notifFieldOffset => 'Décalage en minutes (négatif = avant)';

  @override
  String get notifFieldStatuses => 'Statuts';

  @override
  String get notifFieldThresholds =>
      'Seuils (séparés par des virgules, vide = auto)';

  @override
  String get notifFieldToStatus => 'Nouveau statut';

  @override
  String get notifFieldUntil => 'Jusqu’à';

  @override
  String get notifFrom => 'De';

  @override
  String get notifHideContent => 'Masquer le contenu des notifications';

  @override
  String notifImpact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '$count élément',
      zero: '$count élément',
    );
    return 'Concerne $_temp0 utilisant les défauts';
  }

  @override
  String get notifImportance => 'Importance';

  @override
  String get notifImportanceDefault => 'Normale';

  @override
  String get notifImportanceHigh => 'Élevée';

  @override
  String get notifImportanceLow => 'Faible';

  @override
  String get notifImportanceMin => 'Minimale';

  @override
  String get notifImportanceUrgent => 'Urgente';

  @override
  String get notifInboxAlreadyDone => 'Déjà fait';

  @override
  String get notifInboxCaughtUp => 'Vous êtes à jour';

  @override
  String get notifInboxChangeSnooze => 'Modifier le report';

  @override
  String get notifInboxDismissSelected => 'Ignorer';

  @override
  String get notifInboxDismissed => 'Notification ignorée';

  @override
  String get notifInboxEmpty => 'Aucune notification';

  @override
  String get notifInboxEmptyBody => 'Les rappels reçus apparaissent ici.';

  @override
  String get notifInboxFilterAll => 'Tous';

  @override
  String get notifInboxFilterUnread => 'Non lus';

  @override
  String get notifInboxHistory => 'Historique des rappels';

  @override
  String get notifInboxHistoryEmpty => 'Aucun rappel pour l’instant';

  @override
  String get notifInboxLate => 'En retard';

  @override
  String get notifInboxMarkAllRead => 'Tout marquer comme lu';

  @override
  String get notifInboxMarkedRead => 'Marqué comme lu';

  @override
  String get notifInboxMarkedUnread => 'Marqué comme non lu';

  @override
  String get notifInboxMuteRule => 'Couper ce rappel';

  @override
  String notifInboxNagCount(int count) {
    return '×$count';
  }

  @override
  String get notifInboxRemindAgain => 'Me le rappeler…';

  @override
  String get notifInboxSearch => 'Rechercher';

  @override
  String notifInboxSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnés',
      one: '$count sélectionné',
      zero: '$count sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get notifInboxSnoozed => 'Reportés';

  @override
  String notifInboxSnoozedUntil(String time) {
    return 'Reporté jusqu’à $time';
  }

  @override
  String get notifInboxTitle => 'Boîte de réception';

  @override
  String get notifInboxToday => 'Aujourd’hui';

  @override
  String get notifInboxToggle => 'Afficher dans la boîte';

  @override
  String notifInboxUnreadSemantics(String title) {
    return 'Rappel non lu, $title';
  }

  @override
  String get notifInboxWakeNow => 'Réveiller';

  @override
  String get notifInboxYesterday => 'Hier';

  @override
  String get notifInherit => 'Hériter';

  @override
  String notifInheritedFrom(String source) {
    return 'Depuis $source';
  }

  @override
  String notifInheritedFromProfile(String name) {
    return 'Hérité de $name';
  }

  @override
  String get notifInterruption => 'Niveau d’interruption (iOS)';

  @override
  String get notifInterruptionActive => 'Actif';

  @override
  String get notifInterruptionPassive => 'Passif';

  @override
  String get notifInterruptionTimeSensitive => 'Urgent';

  @override
  String get notifIosLabel => 'iOS';

  @override
  String get notifIssueAnchorUnavailable =>
      'Ce repère n’est pas disponible pour cet élément';

  @override
  String get notifIssueEmptyContent => 'Le titre ne peut pas être vide';

  @override
  String get notifIssueLateness => 'Le retard doit être d’au moins 1 minute';

  @override
  String get notifIssueNoChannel =>
      'Choisissez au moins un mode de notification';

  @override
  String get notifIssueOffsetOutOfRange =>
      'Le décalage doit rester sous 30 jours';

  @override
  String get notifIssueRepeatInterval => 'Répéter au moins toutes les minutes';

  @override
  String get notifIssueRepeatMax => '10 répétitions maximum';

  @override
  String get notifIssueSchedule => 'Récurrence invalide';

  @override
  String get notifIssueStatuses => 'Choisissez au moins un statut';

  @override
  String get notifIssueThresholds => 'Seuils invalides';

  @override
  String get notifIssueTooManyActions =>
      'Android n’affiche que les 3 premières actions';

  @override
  String get notifIssueUnknownTrigger =>
      'Ce type de règle n’est pas pris en charge';

  @override
  String notifIssueUnknownVariable(String names) {
    return 'Variable inconnue : $names';
  }

  @override
  String get notifItemKind => 'Type d’élément';

  @override
  String get notifItemKindAllDay => 'Toute la journée';

  @override
  String get notifItemKindAny => 'Tous';

  @override
  String get notifItemKindDateOnly => 'Date seule';

  @override
  String get notifItemKindTimed => 'Horaire';

  @override
  String get notifLateness => 'Livrer si en retard de (minutes)';

  @override
  String get notifMakePrimary => 'Utiliser cet appareil comme principal';

  @override
  String get notifMaxNag => 'Répétitions maximales';

  @override
  String notifMergedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rappels',
      one: '$count rappel',
      zero: '$count rappel',
    );
    return '$_temp0';
  }

  @override
  String get notifMetricCleanDays => 'Jours sans';

  @override
  String get notifMetricMoney => 'Argent économisé';

  @override
  String get notifMetricStreak => 'Série';

  @override
  String get notifMetricTotal => 'Total';

  @override
  String get notifMetricUnits => 'Unités évitées';

  @override
  String notifMinutesValue(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '$minutes min',
      zero: '$minutes min',
    );
    return '$_temp0';
  }

  @override
  String get notifModeCustom => 'Personnalisé';

  @override
  String get notifModeInherit => 'Par défaut';

  @override
  String get notifModeInheritPlus => 'Défaut + les miens';

  @override
  String get notifModeOff => 'Désactivé';

  @override
  String get notifMultiDevice => 'Envoyer à';

  @override
  String get notifMute1h => '1 heure';

  @override
  String get notifMuteFor => 'Couper…';

  @override
  String get notifMuteForever => 'Jusqu’à réactivation';

  @override
  String get notifMuteToday => 'Reste de la journée';

  @override
  String get notifMuteTomorrow => 'Jusqu’à demain';

  @override
  String get notifMuteWeek => 'Une semaine';

  @override
  String get notifMuted => 'Coupé';

  @override
  String get notifMutedForever => 'Coupé jusqu’à réactivation';

  @override
  String get notifMutedSnack => 'Coupé jusqu’à demain';

  @override
  String notifMutedUntil(String time) {
    return 'Coupé jusqu’à $time';
  }

  @override
  String get notifMutes => 'Coupés';

  @override
  String get notifMutesNone => 'Rien n’est coupé';

  @override
  String get notifNever => 'Jamais';

  @override
  String get notifNextFirings => 'Prochains rappels';

  @override
  String get notifNo => 'Non';

  @override
  String get notifNoReminders => 'Aucun rappel';

  @override
  String get notifNoUpcoming => 'Rien de prévu dans les 14 prochains jours';

  @override
  String get notifNoiseBlocked =>
      'Trop de notifications (plus de 1 440 par jour)';

  @override
  String get notifNoiseCluster =>
      'Plusieurs rappels à la même minute — un seul son sera joué';

  @override
  String notifNoiseConfirm(int perDay) {
    return 'Ce rappel envoie environ $perDay notifications par jour. Enregistrer quand même ?';
  }

  @override
  String notifNoiseWarn(int perDay) {
    return 'Environ $perDay notifications par jour';
  }

  @override
  String get notifOffsetAmount => 'Durée';

  @override
  String get notifOnlyIfStatus => 'Seulement si le statut est';

  @override
  String get notifOpenSettings => 'Ouvrir les réglages';

  @override
  String get notifOutsideDrop => 'Ignorer en dehors';

  @override
  String get notifOutsideShiftEnd => 'Déplacer à la fin';

  @override
  String get notifOutsideShiftStart => 'Déplacer au début';

  @override
  String get notifPause1h => '1 heure';

  @override
  String get notifPauseAll => 'Tout suspendre';

  @override
  String get notifPauseCustom => 'Personnalisé…';

  @override
  String get notifPauseTomorrow => 'Jusqu’à demain 08:00';

  @override
  String notifPausedUntil(String time) {
    return 'Suspendu jusqu’à $time';
  }

  @override
  String get notifPermissionOff => 'Les notifications sont désactivées';

  @override
  String get notifPermissionOffBody => 'Activez-les pour recevoir vos rappels.';

  @override
  String get notifPreview => 'Aperçu';

  @override
  String get notifPrimerAllow => 'Autoriser les notifications';

  @override
  String get notifPrimerBody =>
      'Everslot vous rappelle avant le début des tâches, quand une habitude est due et quand une liste demande une relance. Vous décidez exactement quand.';

  @override
  String get notifPrimerExactBody =>
      'Android a besoin de votre autorisation pour livrer les rappels à la minute près. Sans elle, ils peuvent avoir jusqu’à une heure de retard.';

  @override
  String get notifPrimerExactTitle => 'Rappels précis';

  @override
  String get notifPrimerLater => 'Plus tard';

  @override
  String get notifPrimerTimeSensitiveBody =>
      'Les rappels importants peuvent passer outre les modes de concentration. Modifiable à tout moment dans les réglages iOS.';

  @override
  String get notifPrimerTimeSensitiveTitle => 'Rappels urgents';

  @override
  String get notifPrimerTitle => 'Ne manquez rien d’important';

  @override
  String get notifProfile => 'Profil';

  @override
  String get notifProfileAlarm => 'Alarme';

  @override
  String get notifProfileBuiltin => 'Intégré';

  @override
  String get notifProfileChannelWarning =>
      'Modifier l’importance, le son ou la vibration crée une nouvelle catégorie Android ; l’ancienne apparaît comme supprimée dans les réglages.';

  @override
  String get notifProfileDelete => 'Supprimer le profil';

  @override
  String notifProfileDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rappels utilisent ce profil.',
      one: '$count rappel utilise ce profil.',
      zero: '$count rappel utilise ce profil.',
    );
    return '$_temp0 Les déplacer vers :';
  }

  @override
  String get notifProfileDuplicate => 'Dupliquer';

  @override
  String get notifProfileGentle => 'Doux';

  @override
  String get notifProfileNag => 'Insister jusqu’à fait';

  @override
  String get notifProfileName => 'Nom';

  @override
  String get notifProfileNew => 'Nouveau profil';

  @override
  String get notifProfileNone => 'Aucun profil';

  @override
  String get notifProfileRename => 'Renommer';

  @override
  String get notifProfileStandard => 'Standard';

  @override
  String get notifProfilesEntry => 'Profils';

  @override
  String get notifProfilesTitle => 'Profils de notification';

  @override
  String get notifProvenanceAncestor => 'élément parent';

  @override
  String get notifProvenanceCategory => 'catégorie';

  @override
  String get notifProvenanceChecklist => 'liste';

  @override
  String get notifProvenanceGlobal => 'défauts globaux';

  @override
  String get notifProvenanceOccurrence => 'cette occurrence seulement';

  @override
  String get notifProvenanceSection => 'défauts de la section';

  @override
  String get notifQuietAdd => 'Ajouter des heures calmes';

  @override
  String get notifQuietDefer => 'Reporter à la fin';

  @override
  String get notifQuietDrop => 'Ignorer';

  @override
  String get notifQuietHours => 'Heures calmes';

  @override
  String get notifQuietMode => 'Mode';

  @override
  String get notifQuietNone => 'Aucune heure calme';

  @override
  String get notifQuietSilent => 'Livrer en silence';

  @override
  String notifQuietWindow(String from, String to) {
    return '$from – $to';
  }

  @override
  String get notifRedactedBody => 'Ouvrez Everslot pour le voir';

  @override
  String get notifRedactedTitle => 'Rappel d’Everslot';

  @override
  String get notifRepeat => 'Répéter (insister)';

  @override
  String get notifRespectQuiet => 'Respecter les heures calmes';

  @override
  String get notifResume => 'Reprendre';

  @override
  String get notifRuleDeleted => 'Rappel supprimé';

  @override
  String get notifRuleEnabled => 'Rappel activé';

  @override
  String get notifRuleSaved => 'Rappel enregistré';

  @override
  String get notifSaturationBody =>
      'Ouvrez Everslot pour garder vos rappels à jour';

  @override
  String get notifSaturationTitle => 'Ouvrez Everslot';

  @override
  String get notifSectionChecklists => 'Listes';

  @override
  String get notifSectionDigests => 'Récapitulatifs';

  @override
  String get notifSectionHabits => 'Habitudes';

  @override
  String get notifSectionPlanner => 'Planning';

  @override
  String get notifSectionQuit => 'Arrêts';

  @override
  String get notifSectionSystem => 'Système';

  @override
  String get notifSectionTitle => 'Notifications';

  @override
  String get notifSendTest => 'Envoyer une notification de test';

  @override
  String get notifSettingsSections => 'Sections';

  @override
  String get notifSettingsTitle => 'Notifications';

  @override
  String notifShowAll(int count) {
    return 'Tout afficher ($count)';
  }

  @override
  String get notifSkipAck => 'Déjà vu';

  @override
  String get notifSkipCap => 'Limite quotidienne atteinte';

  @override
  String get notifSkipDone => 'Déjà fait';

  @override
  String get notifSkipExpired => 'Trop tard';

  @override
  String get notifSkipMuted => 'Coupé';

  @override
  String get notifSkipNoChannel => 'Aucun canal';

  @override
  String get notifSkipQuiet => 'Ignoré (heures calmes)';

  @override
  String get notifSkipStatus => 'Statut non concerné';

  @override
  String get notifSkipWeekday => 'Pas ce jour-là';

  @override
  String get notifSkipWindow => 'Hors de la plage horaire';

  @override
  String get notifSnoozeCustom => 'Personnalisé…';

  @override
  String get notifSnoozeEvening => 'Ce soir';

  @override
  String notifSnoozeHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours heures',
      one: '$hours heure',
      zero: '$hours heure',
    );
    return '$_temp0';
  }

  @override
  String get notifSnoozeLimit => 'Limite de reports atteinte';

  @override
  String notifSnoozeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '$minutes min',
      zero: '$minutes min',
    );
    return '$_temp0';
  }

  @override
  String get notifSnoozeOptions => 'Reports proposés (minutes)';

  @override
  String get notifSnoozePresets => 'Reports proposés';

  @override
  String get notifSnoozeTomorrow => 'Demain matin';

  @override
  String notifSnoozedSnack(String time) {
    return 'Reporté jusqu’à $time';
  }

  @override
  String get notifSound => 'Son';

  @override
  String get notifSoundAlarm => 'Alarme';

  @override
  String get notifSoundBell => 'Cloche';

  @override
  String get notifSoundChime => 'Carillon';

  @override
  String get notifSoundDefault => 'Par défaut';

  @override
  String get notifSoundNone => 'Aucun';

  @override
  String get notifSoundPop => 'Pop';

  @override
  String get notifSoundSoft => 'Doux';

  @override
  String get notifSticky => 'Garder jusqu’à fait (Android)';

  @override
  String notifSumAbsolute(String dateTime) {
    return 'Le $dateTime';
  }

  @override
  String notifSumAfterDue(String duration) {
    return '$duration après l’échéance';
  }

  @override
  String notifSumAfterEnd(String duration) {
    return '$duration après la fin';
  }

  @override
  String notifSumAfterStart(String duration) {
    return '$duration après le début';
  }

  @override
  String get notifSumAtDue => 'À l’échéance';

  @override
  String get notifSumAtEnd => 'À la fin';

  @override
  String get notifSumAtFollowUp => 'À la relance';

  @override
  String get notifSumAtPeriodEnd => 'À la fin de la période';

  @override
  String get notifSumAtPeriodStart => 'Au début de la période';

  @override
  String get notifSumAtSlot => 'À l’heure prévue';

  @override
  String get notifSumAtStart => 'Au début';

  @override
  String notifSumBeforeDue(String duration) {
    return '$duration avant l’échéance';
  }

  @override
  String notifSumBeforeEnd(String duration) {
    return '$duration avant la fin';
  }

  @override
  String notifSumBeforeStart(String duration) {
    return '$duration avant le début';
  }

  @override
  String get notifSumChildOverdue => 'Quand un sous-élément est en retard';

  @override
  String get notifSumChildrenComplete =>
      'Quand tous les sous-éléments sont faits';

  @override
  String notifSumDaysAfter(int days, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
      zero: '$days jour',
    );
    return '$_temp0 après à $time';
  }

  @override
  String notifSumDaysBefore(int days, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
      zero: '$days jour',
    );
    return '$_temp0 avant à $time';
  }

  @override
  String notifSumInactivity(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
      zero: '$days jour',
    );
    return 'Après $_temp0 sans activité';
  }

  @override
  String get notifSumMilestones => 'Étapes';

  @override
  String notifSumNotDoneBy(String time) {
    return 'Si pas fait avant $time';
  }

  @override
  String get notifSumNotDoneByEnd => 'Si pas fait avant la fin';

  @override
  String notifSumOnDayAt(String time) {
    return 'Le jour même à $time';
  }

  @override
  String get notifSumOverdue => 'En cas de retard';

  @override
  String notifSumQuotaBehind(String time) {
    return 'En retard sur l’objectif, à $time';
  }

  @override
  String notifSumRepeat(int minutes, int times) {
    return 'répète toutes les $minutes min ×$times';
  }

  @override
  String get notifSumSchedule => 'Selon une récurrence';

  @override
  String notifSumStale(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
      zero: '$days jour',
    );
    return 'Après $_temp0 sans progrès';
  }

  @override
  String notifSumStatusAge(String duration) {
    return 'Toujours en attente ou bloqué après $duration';
  }

  @override
  String notifSumStatusChange(String status) {
    return 'Quand il devient $status';
  }

  @override
  String notifSumStreakRisk(String time) {
    return 'Série en danger, à $time';
  }

  @override
  String get notifSumUnknown => 'Règle non prise en charge';

  @override
  String get notifSystemNotification => 'Notification système';

  @override
  String get notifTestSent => 'Notification de test dans 5 secondes';

  @override
  String get notifThisDeviceIsPrimary =>
      'Cet appareil est l’appareil principal';

  @override
  String get notifTimeWindow => 'Plage horaire';

  @override
  String notifTitleFollowUp(String title) {
    return 'Relancer : $title';
  }

  @override
  String get notifTo => 'À';

  @override
  String get notifTrigger => 'Déclencheur';

  @override
  String get notifTriggerAbsolute => 'À une date et heure';

  @override
  String get notifTriggerChildOverdue => 'Sous-élément en retard';

  @override
  String get notifTriggerChildrenComplete => 'Sous-éléments terminés';

  @override
  String get notifTriggerDigest => 'Récapitulatif';

  @override
  String get notifTriggerInactivity => 'Inactivité';

  @override
  String get notifTriggerMilestone => 'Étape';

  @override
  String get notifTriggerNotDoneBy => 'Si pas fait avant';

  @override
  String get notifTriggerOverdue => 'Retard';

  @override
  String get notifTriggerQuotaBehind => 'Retard sur l’objectif';

  @override
  String get notifTriggerRelative => 'Relatif à l’élément';

  @override
  String get notifTriggerSchedule => 'Récurrence';

  @override
  String get notifTriggerStale => 'Sans progrès';

  @override
  String get notifTriggerStatusAge => 'Ancienneté du statut';

  @override
  String get notifTriggerStatusChange => 'Changement de statut';

  @override
  String get notifTriggerStreakRisk => 'Série en danger';

  @override
  String get notifUnitDays => 'jours';

  @override
  String get notifUnitHours => 'heures';

  @override
  String get notifUnitMinutes => 'minutes';

  @override
  String get notifUnitWeeks => 'semaines';

  @override
  String get notifUnknown => 'Inconnu';

  @override
  String get notifUnmute => 'Réactiver';

  @override
  String get notifUntilAcknowledged => 'lu';

  @override
  String get notifUntilCompleted => 'terminé';

  @override
  String get notifUntilMax => 'maximum atteint';

  @override
  String get notifVariables => 'Variables';

  @override
  String get notifVibration => 'Vibration';

  @override
  String get notifVibrationDefault => 'Par défaut';

  @override
  String get notifVibrationLong => 'Longue';

  @override
  String get notifVibrationNone => 'Aucune';

  @override
  String get notifVibrationShort => 'Courte';

  @override
  String get notifWeekdays => 'Seulement le';

  @override
  String get notifYes => 'Oui';

  @override
  String get pickerColor => 'Couleur';

  @override
  String get pickerDate => 'Date';

  @override
  String get pickerDays => 'Jours';

  @override
  String get pickerDuration => 'Durée';

  @override
  String get pickerHours => 'Heures';

  @override
  String get pickerIcon => 'Icône';

  @override
  String get pickerMinutes => 'Minutes';

  @override
  String get pickerNoColor => 'Sans couleur';

  @override
  String get pickerSearchIcons => 'Rechercher une icône';

  @override
  String get pickerTime => 'Heure';

  @override
  String get placeholderScreen => 'Cet écran est en construction.';

  @override
  String get priorityHigh => 'Haute';

  @override
  String get priorityLow => 'Basse';

  @override
  String get priorityMedium => 'Moyenne';

  @override
  String get priorityNone => 'Sans priorité';

  @override
  String get priorityUrgent => 'Urgente';

  @override
  String get pvActualColumn => 'Actual';

  @override
  String get pvAddTask => 'Add task';

  @override
  String get pvAddZone => 'Add time zone';

  @override
  String get pvAllDay => 'All day';

  @override
  String get pvAllDaySection => 'All day & untimed';

  @override
  String get pvApplyToView => 'Apply to this view';

  @override
  String get pvAutoAdvance => 'Auto-advance';

  @override
  String get pvAutoScrollNow => 'Scroll to now on open';

  @override
  String get pvBacklogEmpty => 'Your backlog is empty';

  @override
  String get pvCancelOccurrence => 'Cancel this occurrence';

  @override
  String get pvCannotUnschedule =>
      'Recurring occurrences can\'t be moved to the backlog';

  @override
  String get pvCapacity => 'Capacity';

  @override
  String get pvCategories => 'Categories';

  @override
  String get pvClearFilters => 'Clear';

  @override
  String get pvClocksForward => 'Clocks forward';

  @override
  String get pvColCategory => 'Category';

  @override
  String get pvColDate => 'Date';

  @override
  String get pvColDuration => 'Duration';

  @override
  String get pvColEnd => 'End';

  @override
  String get pvColLocation => 'Place';

  @override
  String get pvColPriority => 'Priority';

  @override
  String get pvColRecurrence => 'Repeats';

  @override
  String get pvColStart => 'Start';

  @override
  String get pvColStatus => 'Status';

  @override
  String get pvColTitle => 'Title';

  @override
  String get pvColTracking => 'Tracking';

  @override
  String get pvCollapse => 'Collapse';

  @override
  String get pvColorBy => 'Color by';

  @override
  String get pvColorByCategory => 'Category';

  @override
  String get pvColorByPriority => 'Priority';

  @override
  String get pvColorByStatus => 'Status';

  @override
  String get pvColorByTask => 'Task';

  @override
  String get pvColumns => 'Columns';

  @override
  String get pvCompletion => 'Completion';

  @override
  String get pvContinues => 'continues';

  @override
  String pvCopySuffix(String name) {
    return '$name (copy)';
  }

  @override
  String get pvCreate => 'Create';

  @override
  String get pvCreateHere => 'Create here';

  @override
  String get pvCreatedSnack => 'Task created';

  @override
  String pvDayHeaderSemantics(String day, String items) {
    return '$day, $items';
  }

  @override
  String get pvDayRibbon => 'Day';

  @override
  String pvDayStats(String done, String total, String planned) {
    return '$done/$total · $planned';
  }

  @override
  String get pvDaySummary => 'Day summary';

  @override
  String get pvDayTicker => 'Day ticker';

  @override
  String pvDaysSince(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String pvDaysUntil(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'in 1 day',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get pvDaysVisible => 'Days visible';

  @override
  String get pvDaysVisibleLandscape => 'Days in landscape';

  @override
  String get pvDefaultBadge => 'Default';

  @override
  String get pvDeleteView => 'Delete view';

  @override
  String get pvDemoData => 'Demo data (developer)';

  @override
  String get pvDensity => 'Density';

  @override
  String get pvDensityComfortable => 'Comfortable';

  @override
  String get pvDensityCompact => 'Compact';

  @override
  String get pvDimPast => 'Dim past';

  @override
  String get pvDoneTotal => 'Done';

  @override
  String get pvDragToSchedule => 'Drag onto the grid to schedule';

  @override
  String get pvDropNotSupported =>
      'This grouping can\'t be changed by dragging yet';

  @override
  String get pvDuplicateView => 'Duplicate view';

  @override
  String pvElapsed(String duration) {
    return '$duration elapsed';
  }

  @override
  String get pvEmptyDay => 'Nothing planned';

  @override
  String get pvEmptyRange => 'Nothing in this range';

  @override
  String pvEmptySlotSemantics(String day, String time) {
    return '$day $time, empty, double-tap to create';
  }

  @override
  String get pvEmptyWeekTitle => 'Nothing planned this week';

  @override
  String get pvExpand => 'Expand';

  @override
  String get pvExpandInline => 'Expand day inline';

  @override
  String get pvExtend => 'Extend';

  @override
  String pvExtendBy(int minutes) {
    return '+$minutes min';
  }

  @override
  String get pvExtraZones => 'Extra time zones';

  @override
  String get pvFillFromBacklog => 'Fill from backlog';

  @override
  String get pvFillGap => 'Fill this gap';

  @override
  String get pvFilter => 'Filter';

  @override
  String get pvFilters => 'Filters';

  @override
  String get pvFinish => 'Finish';

  @override
  String pvFreeGap(String duration) {
    return 'free $duration';
  }

  @override
  String get pvFreeInWorkHours => 'Free in work hours';

  @override
  String pvFreeRun(String from, String to, String duration) {
    return 'Free $from–$to · $duration';
  }

  @override
  String get pvFrom => 'From';

  @override
  String get pvGotIt => 'Got it';

  @override
  String get pvGroupBy => 'Group by';

  @override
  String get pvGroupCategory => 'Category';

  @override
  String get pvGroupDay => 'Day';

  @override
  String get pvGroupNone => 'None';

  @override
  String get pvGroupPriority => 'Priority';

  @override
  String get pvGroupStatus => 'Status';

  @override
  String get pvGroupTask => 'Task';

  @override
  String get pvHeatMetric => 'Metric';

  @override
  String pvHiddenRange(String from, String to) {
    return 'Hidden $from–$to';
  }

  @override
  String get pvHideEmptySlots => 'Collapse empty slots';

  @override
  String get pvHintLongPress => 'Long-press empty space to create a task';

  @override
  String get pvHintPinch =>
      'Pinch to zoom; pinch sideways to change the number of days';

  @override
  String pvHintSlotSize(String size) {
    return 'Tap $size to change the row size';
  }

  @override
  String get pvHorizonDay => 'Today';

  @override
  String get pvHorizonMonth => 'This month';

  @override
  String get pvHorizonQuarter => 'This quarter';

  @override
  String get pvHorizonWeek => 'This week';

  @override
  String get pvHorizonYear => 'This year';

  @override
  String get pvHorizonsHint =>
      'Unscheduled intentions per horizon (stored on this device until horizons sync).';

  @override
  String get pvIgnoreLowPriority => 'Ignore low-priority tasks';

  @override
  String pvImportanceRule(String priority) {
    return 'Important from priority $priority';
  }

  @override
  String pvItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get pvJumpToDate => 'Jump to date';

  @override
  String get pvKeepScreenOn => 'Keep screen on';

  @override
  String get pvLaneCap => 'Side-by-side lanes';

  @override
  String get pvLanes => 'Lanes';

  @override
  String pvLastRowShort(String duration) {
    return 'the last one $duration';
  }

  @override
  String get pvLess => 'Less';

  @override
  String get pvListBelow => 'List below';

  @override
  String get pvListMode => 'Accessible list';

  @override
  String get pvMapPlaceholder =>
      'The map needs task coordinates, which arrive with the place picker. Tasks with a place are listed below.';

  @override
  String get pvMarkDone => 'Mark done';

  @override
  String get pvMarkNotDone => 'Mark not done';

  @override
  String get pvMetricCompletion => 'Completion rate';

  @override
  String get pvMetricCount => 'Number of items';

  @override
  String get pvMetricPlanned => 'Planned hours';

  @override
  String get pvMinGap => 'Minimum gap';

  @override
  String get pvMonthBars => 'Bars';

  @override
  String get pvMonthDots => 'Dots';

  @override
  String get pvMonthTitles => 'Titles';

  @override
  String get pvMonthTitlesTimes => 'Titles and times';

  @override
  String pvMore(String count) {
    return '+$count';
  }

  @override
  String pvMoreItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more items',
      one: '1 more item',
    );
    return '$_temp0';
  }

  @override
  String get pvMoreLegend => 'More';

  @override
  String get pvMoreOptions => 'More options';

  @override
  String get pvMove => 'Move';

  @override
  String get pvMoveDoneBody =>
      'It\'s already done — moving it changes its history.';

  @override
  String get pvMoveDoneTitle => 'Move a completed task?';

  @override
  String pvMoveEarlier(int minutes) {
    return 'Move $minutes min earlier';
  }

  @override
  String pvMoveLater(int minutes) {
    return 'Move $minutes min later';
  }

  @override
  String get pvMoveTo => 'Move to…';

  @override
  String get pvMoveUnfinishedTomorrow => 'Move unfinished to tomorrow';

  @override
  String pvMovedSnack(String when) {
    return 'Moved to $when';
  }

  @override
  String get pvNext => 'Next';

  @override
  String get pvNextDay => 'Next day';

  @override
  String pvNextDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Next $count days',
      one: 'Next day',
    );
    return '$_temp0';
  }

  @override
  String get pvNextUp => 'Next up';

  @override
  String get pvNextWeek => 'Next week';

  @override
  String get pvNoCategory => 'No category';

  @override
  String get pvNoOpenings => 'No free time found';

  @override
  String pvNoRoom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items didn\'t fit',
      one: '1 item didn\'t fit',
    );
    return '$_temp0';
  }

  @override
  String get pvNoRoutine => 'No routine block today';

  @override
  String get pvNoTasks => 'No tasks';

  @override
  String get pvNothingNow => 'Nothing scheduled right now';

  @override
  String get pvNow => 'Now';

  @override
  String get pvOneOff => 'One-off';

  @override
  String get pvOpenDay => 'Open day';

  @override
  String get pvOpenings => 'Openings';

  @override
  String get pvOverdue => 'Overdue';

  @override
  String get pvOverlapCascade => 'Cascade';

  @override
  String get pvOverlapColumns => 'Columns';

  @override
  String get pvOverlapStyle => 'Overlap style';

  @override
  String get pvOverlayChecklistDue => 'Checklist items due';

  @override
  String get pvOverlayDeviceCalendars => 'Device calendars';

  @override
  String get pvOverlayFreeSlots => 'Free time';

  @override
  String get pvOverlayHabits => 'Habits due';

  @override
  String get pvOverlayHeat => 'Busy-hour heat';

  @override
  String get pvOverlays => 'Overlays';

  @override
  String get pvPagingDay => 'One day';

  @override
  String get pvPagingFree => 'Free scroll';

  @override
  String get pvPagingMode => 'Swipe moves';

  @override
  String get pvPagingWeek => 'One week';

  @override
  String get pvPause => 'Pause';

  @override
  String get pvPickDate => 'Pick a date';

  @override
  String get pvPin => 'Pin';

  @override
  String get pvPinned => 'Pinned';

  @override
  String get pvPlanColumn => 'Plan';

  @override
  String get pvPlanFirstTask => 'Plan your first task';

  @override
  String get pvPlanned => 'Planned';

  @override
  String get pvPostpone => 'Postpone';

  @override
  String pvPostponeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get pvPostponeNextWeek => 'Next week';

  @override
  String get pvPostponeTomorrow => 'Tomorrow';

  @override
  String get pvPrevious => 'Previous';

  @override
  String get pvPreviousDay => 'Previous day';

  @override
  String get pvPreviousWeek => 'Previous week';

  @override
  String get pvPriorities => 'Priorities';

  @override
  String get pvQuadDelegate => 'Delegate';

  @override
  String get pvQuadDo => 'Do';

  @override
  String get pvQuadEliminate => 'Eliminate';

  @override
  String get pvQuadSchedule => 'Schedule';

  @override
  String get pvQuickCreateHint => 'What\'s the plan?';

  @override
  String get pvQuickCreateTitle => 'New task';

  @override
  String get pvRadial12 => '12 h';

  @override
  String get pvRadial24 => '24 h';

  @override
  String get pvRadialHours => 'Dial';

  @override
  String get pvRecurring => 'Recurring';

  @override
  String get pvRenameView => 'Rename view';

  @override
  String get pvRenderAuto => 'Auto';

  @override
  String get pvRenderMode => 'Render';

  @override
  String get pvRenderTable => 'Table';

  @override
  String get pvRenderTimeline => 'Timeline';

  @override
  String pvRepeatedHour(String time, String offset) {
    return '$time ($offset)';
  }

  @override
  String get pvRepeats => 'repeats';

  @override
  String get pvResetView => 'Reset view settings';

  @override
  String pvResizedSnack(String duration) {
    return 'Duration $duration';
  }

  @override
  String get pvRibbonStyle => 'Ribbon';

  @override
  String get pvRoutineComplete => 'Routine complete';

  @override
  String get pvRoutineStart => 'Start routine';

  @override
  String pvRoutineSummary(int done, int total) {
    return '$done of $total steps done';
  }

  @override
  String get pvRowHeight => 'Row height';

  @override
  String get pvRowsOccurrences => 'Occurrences';

  @override
  String pvRowsPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows per day',
      one: '1 row per day',
    );
    return '$_temp0';
  }

  @override
  String get pvRowsTasks => 'Tasks';

  @override
  String get pvRules => 'Rules';

  @override
  String get pvSaveAsNewView => 'Save as new view';

  @override
  String get pvSaveViewAs => 'Save view as…';

  @override
  String get pvSavedViews => 'Saved views';

  @override
  String get pvScale => 'Scale';

  @override
  String get pvScaleDays => 'Days';

  @override
  String get pvScaleHours => 'Hours';

  @override
  String get pvScaleMonths => 'Months';

  @override
  String get pvScaleWeeks => 'Weeks';

  @override
  String get pvScheduleOn => 'Schedule on…';

  @override
  String get pvScheduledSnack => 'Scheduled';

  @override
  String get pvScopeAll => 'All occurrences';

  @override
  String get pvScopeFollowing => 'This and following';

  @override
  String get pvScopeThis => 'This occurrence';

  @override
  String get pvScopeTitle => 'Change a recurring task';

  @override
  String pvSelected(int count) {
    return '$count selected';
  }

  @override
  String get pvSetDefaultView => 'Set as default';

  @override
  String get pvShareAvailability => 'Share availability';

  @override
  String get pvShowCancelled => 'Show cancelled';

  @override
  String get pvShowCompleted => 'Show completed';

  @override
  String get pvShowEmptyDays => 'Show empty days';

  @override
  String get pvShowNotes => 'Show notes';

  @override
  String get pvShowWeekends => 'Show weekends';

  @override
  String get pvSinceGroup => 'Since';

  @override
  String get pvSkip => 'Skip';

  @override
  String get pvSkipRemaining => 'Skip remaining';

  @override
  String get pvSkipStep => 'Skip step';

  @override
  String get pvSlotCustom => 'Custom size';

  @override
  String get pvSlotCustomHint => 'Minutes or h:mm (1 min – 24 h)';

  @override
  String get pvSlotInvalid => 'Enter a size between 1 minute and 24 hours';

  @override
  String get pvSlotPresets => 'Presets';

  @override
  String get pvSlotSize => 'Slot size';

  @override
  String get pvSlotsStyle => 'Slots';

  @override
  String get pvSnap => 'Snap';

  @override
  String get pvSortBy => 'Sort by';

  @override
  String get pvStart => 'Start';

  @override
  String pvStartsAt(String time) {
    return 'Starts at $time';
  }

  @override
  String get pvStatusCancelled => 'Cancelled';

  @override
  String get pvStatusDone => 'Done';

  @override
  String get pvStatusInProgress => 'In progress';

  @override
  String get pvStatusMissed => 'Missed';

  @override
  String get pvStatusScheduled => 'Planned';

  @override
  String get pvStatusSkipped => 'Skipped';

  @override
  String pvStatusSnack(String status) {
    return 'Marked $status';
  }

  @override
  String get pvStatuses => 'Statuses';

  @override
  String pvStep(int n, int total) {
    return 'Step $n of $total';
  }

  @override
  String get pvStop => 'Stop';

  @override
  String get pvSwipeVertical => 'Swipe vertically';

  @override
  String pvTableThreshold(String size) {
    return 'Table from $size';
  }

  @override
  String get pvTextFilterHint => 'Search titles and notes';

  @override
  String pvTileSemantics(
    String title,
    String day,
    String start,
    String end,
    String status,
  ) {
    return '$title, $day, $start to $end, $status';
  }

  @override
  String pvTimeLeft(String duration) {
    return '$duration left';
  }

  @override
  String get pvTo => 'To';

  @override
  String get pvTopCategories => 'Top categories';

  @override
  String get pvTracked => 'Tracked';

  @override
  String get pvTrackingCheck => 'Check';

  @override
  String get pvTrackingEvent => 'Event';

  @override
  String get pvTrackingModes => 'Tracking';

  @override
  String get pvTrackingTimer => 'Timer';

  @override
  String get pvUnpin => 'Unpin';

  @override
  String get pvUnscheduleUnsupported =>
      'Moving tasks back to the backlog isn\'t available yet';

  @override
  String get pvUnscheduled => 'Unscheduled';

  @override
  String get pvUntimed => 'Untimed';

  @override
  String get pvUpcoming => 'Upcoming';

  @override
  String pvUrgencyRule(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Urgent within $days days',
      one: 'Urgent within 1 day',
    );
    return '$_temp0';
  }

  @override
  String get pvVarianceLate => 'Started late';

  @override
  String get pvVarianceNotDone => 'Not done';

  @override
  String get pvVarianceOnPlan => 'On plan';

  @override
  String get pvVarianceOverran => 'Overran';

  @override
  String get pvVarianceUnplanned => 'Unplanned';

  @override
  String get pvViewAgenda => 'Agenda';

  @override
  String get pvViewBacklog => 'Backlog';

  @override
  String get pvViewCountdown => 'Countdowns';

  @override
  String get pvViewDayList => 'Day list';

  @override
  String get pvViewFocus => 'Focus';

  @override
  String get pvViewFreeSlots => 'Free slots';

  @override
  String get pvViewHorizons => 'Horizons';

  @override
  String get pvViewKanban => 'Kanban';

  @override
  String get pvViewLoadHeatmap => 'Load heatmap';

  @override
  String get pvViewMap => 'Map';

  @override
  String get pvViewMatrix => 'Eisenhower matrix';

  @override
  String get pvViewMonth => 'Month';

  @override
  String get pvViewMultiWeek => 'Multi-week';

  @override
  String get pvViewNDay => 'N days';

  @override
  String get pvViewName => 'View name';

  @override
  String get pvViewPlanVsActual => 'Plan vs actual';

  @override
  String get pvViewQuarter => 'Quarter';

  @override
  String get pvViewRadial => '24-hour clock';

  @override
  String get pvViewRibbon => 'Ribbon';

  @override
  String get pvViewRoutine => 'Routine player';

  @override
  String get pvViewSaved => 'View saved';

  @override
  String get pvViewSettings => 'View settings';

  @override
  String get pvViewSwimlanes => 'Swimlanes';

  @override
  String get pvViewSwitcher => 'Change view';

  @override
  String get pvViewTable => 'Table';

  @override
  String get pvViewTimeline => 'Timeline';

  @override
  String get pvViewWeekList => 'Week list';

  @override
  String get pvViewWeekTable => 'Week table';

  @override
  String get pvViewWorkWeek => 'Work week';

  @override
  String get pvViewYear => 'Year';

  @override
  String get pvVisibleHours => 'Visible hours';

  @override
  String get pvVisibleHoursAll => 'All 24 hours';

  @override
  String pvWeekNumber(int week) {
    return 'W$week';
  }

  @override
  String get pvWeekNumbers => 'Week numbers';

  @override
  String get pvWeekRibbon => 'Week';

  @override
  String get pvWeekSummary => 'Week summary';

  @override
  String pvWeeksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String get pvWithPlace => 'Tasks with a place';

  @override
  String get pvWorkHours => 'Work hours';

  @override
  String get pvZoneHint => 'e.g. Asia/Tokyo';

  @override
  String get pvZoomAroundNow => 'Zoom around now';

  @override
  String get pvZoomFixed => 'Fixed slot';

  @override
  String get pvZoomMode => 'Zoom';

  @override
  String get pvZoomSemantic => 'Semantic';

  @override
  String get recurAddDate => 'Ajouter';

  @override
  String get recurAddTime => 'Ajouter une heure';

  @override
  String get recurAdvancedTitle => 'Répétition personnalisée';

  @override
  String get recurAfterHint =>
      'La suivante arrive ce délai après l’achèvement de la précédente.';

  @override
  String recurAnchorMoved(String date) {
    return 'Première occurrence : $date';
  }

  @override
  String get recurCountCompletions => 'Achèvements';

  @override
  String get recurCountMode => 'Décompte';

  @override
  String get recurCountOccurrences => 'Occurrences';

  @override
  String get recurCurrent => 'Règle actuelle';

  @override
  String get recurEnds => 'Fin';

  @override
  String get recurEndsAfter => 'Après un nombre de fois';

  @override
  String recurEndsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fois',
      one: '1 fois',
    );
    return '$_temp0';
  }

  @override
  String get recurEndsNever => 'Jamais';

  @override
  String get recurEndsOn => 'À une date';

  @override
  String get recurExceptionCancelled => 'Retirée';

  @override
  String get recurExceptionEdited => 'Modifiée';

  @override
  String recurExceptionMoved(String to) {
    return 'Déplacée au $to';
  }

  @override
  String get recurExceptionOpen => 'Ouvrir';

  @override
  String get recurExceptionRestore => 'Restaurer';

  @override
  String get recurExceptionRestoreAll => 'Tout restaurer';

  @override
  String get recurExceptionsEmpty => 'Aucune occurrence retirée ou déplacée';

  @override
  String get recurExceptionsRestored => 'Restaurées';

  @override
  String get recurExceptionsTitle => 'Occurrences passées et déplacées';

  @override
  String get recurExdates => 'Occurrences exclues';

  @override
  String get recurFloatingNote => 'Les heures suivent votre fuseau actuel';

  @override
  String get recurFrequency => 'Fréquence';

  @override
  String get recurHours => 'Heures';

  @override
  String get recurInterval => 'Tous les';

  @override
  String get recurIssueCount => 'Le nombre de fois doit être d’au moins 1';

  @override
  String get recurIssueCountAndUntil =>
      'Choisissez une date de fin ou un nombre de fois';

  @override
  String get recurIssueDate => 'Date non valide';

  @override
  String get recurIssueEmptyWeekdays => 'Sélectionnez au moins un jour';

  @override
  String get recurIssueInterval => 'L’intervalle doit être d’au moins 1';

  @override
  String get recurIssueMissing => 'La règle est incomplète';

  @override
  String get recurIssueOrdinal =>
      '« 1er », « dernier »… ne fonctionnent qu’avec une répétition mensuelle ou annuelle';

  @override
  String recurIssueQuota(int max) {
    return 'Ce quota est impossible avec cet écart ($max max.)';
  }

  @override
  String recurIssueTooFrequent(int count) {
    return 'Trop fréquent : $count par jour (1440 max.)';
  }

  @override
  String get recurIssueUnsupported =>
      'Ces options ne peuvent pas être combinées';

  @override
  String get recurIssueUntilBeforeStart => 'La date de fin est avant le début';

  @override
  String get recurIssueValue => 'Une valeur est hors limites';

  @override
  String get recurIssueWindow => 'La plage doit finir après son début';

  @override
  String get recurLess => 'Moins d’options';

  @override
  String get recurMinutes => 'Minutes';

  @override
  String recurMonthDayFromEnd(int day) {
    return '${day}e jour avant la fin';
  }

  @override
  String get recurMonthDays => 'Jours du mois';

  @override
  String get recurMonthDaysFromEnd => 'En partant de la fin';

  @override
  String get recurMonths => 'Mois';

  @override
  String get recurMore => 'Plus d’options';

  @override
  String get recurOrdinal1 => '1er';

  @override
  String get recurOrdinal2 => '2e';

  @override
  String get recurOrdinal3 => '3e';

  @override
  String get recurOrdinal4 => '4e';

  @override
  String get recurOrdinal5 => '5e';

  @override
  String get recurOrdinalEvery => 'Chaque';

  @override
  String get recurOrdinalLast => 'Dernier';

  @override
  String get recurOrdinalSecondLast => 'Avant-dernier';

  @override
  String get recurOverflow => 'Quand un mois est trop court';

  @override
  String get recurOverflowClamp => 'Prendre son dernier jour';

  @override
  String get recurOverflowSkip => 'Sauter ce mois';

  @override
  String get recurPerDay => 'Jour';

  @override
  String get recurPerMonth => 'Mois';

  @override
  String get recurPerWeek => 'Semaine';

  @override
  String get recurPerYear => 'Année';

  @override
  String get recurPickerTitle => 'Répétition';

  @override
  String get recurPresetAfterCompletion => 'Après achèvement…';

  @override
  String get recurPresetCustom => 'Personnalisé…';

  @override
  String get recurPresetEveryNDays => 'Tous les quelques jours…';

  @override
  String get recurPresetIntraday => 'Toutes les quelques heures ou minutes…';

  @override
  String get recurPresetNone => 'Ne se répète pas';

  @override
  String get recurPresetQuota => 'Plusieurs fois par semaine ou par mois…';

  @override
  String get recurPresetSpecificDays => 'Jours précis…';

  @override
  String get recurPresetTimesPerDay => 'Plusieurs fois par jour…';

  @override
  String get recurPreview => 'Prochaines occurrences';

  @override
  String get recurPreviewCalendar => '60 prochains jours';

  @override
  String get recurPreviewEmpty => 'Aucune occurrence à venir';

  @override
  String get recurQuotaMinGap => 'Jours minimum entre deux';

  @override
  String get recurQuotaOnDays => 'Seulement ces jours';

  @override
  String get recurQuotaPer => 'Par';

  @override
  String get recurQuotaTimes => 'Combien de fois';

  @override
  String get recurRdates => 'Occurrences ajoutées';

  @override
  String recurRemoveTime(String time) {
    return 'Retirer $time';
  }

  @override
  String get recurSetPos => 'Ne garder que les positions';

  @override
  String get recurSetPosHint =>
      '1 = première, −1 = dernière date correspondante de chaque période';

  @override
  String get recurSummary => 'Résumé';

  @override
  String get recurTimes => 'Heures de la journée';

  @override
  String get recurType => 'Type';

  @override
  String get recurTypeAfter => 'Après achèvement';

  @override
  String get recurTypeFixed => 'Calendrier';

  @override
  String get recurTypeQuota => 'Quota';

  @override
  String get recurUnitDay => 'Jours';

  @override
  String get recurUnitHour => 'Heures';

  @override
  String get recurUnitMinute => 'Minutes';

  @override
  String get recurUnitMonth => 'Mois';

  @override
  String get recurUnitWeek => 'Semaines';

  @override
  String get recurUnitYear => 'Années';

  @override
  String get recurWarnAllDaySubDaily =>
      'Un élément sur la journée ne peut pas se répéter dans la journée';

  @override
  String get recurWarnDst =>
      'Certaines heures tombent lors d’un changement d’heure et sont décalées';

  @override
  String get recurWarnNever => 'Ne se produit pas dans les 5 prochaines années';

  @override
  String recurWarnPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count occurrences par jour',
      one: '1 occurrence par jour',
    );
    return '$_temp0';
  }

  @override
  String get recurWeekStart => 'La semaine commence le';

  @override
  String get recurWeekdayOrdinal => 'Lequel dans la période';

  @override
  String get recurWeekdays => 'Jours de la semaine';

  @override
  String get recurWindow => 'Plage horaire';

  @override
  String get recurWindowAnchorSeries =>
      'Continuer la chaîne depuis la première occurrence';

  @override
  String get recurWindowAnchorWindow =>
      'Recommencer chaque jour au début de la plage';

  @override
  String get recurWindowEnd => 'Jusqu’à';

  @override
  String get recurWindowNone => 'Toute la journée';

  @override
  String get recurWindowStart => 'De';

  @override
  String recurZoneNote(String zone) {
    return 'Heures de $zone';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'hier',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String relativeInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dans $count jours',
      one: 'demain',
    );
    return '$_temp0';
  }

  @override
  String relativeInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dans $count heures',
      one: 'dans 1 heure',
    );
    return '$_temp0';
  }

  @override
  String relativeInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dans $count minutes',
      one: 'dans 1 minute',
    );
    return '$_temp0';
  }

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String get relativeNow => 'maintenant';

  @override
  String get savedSnack => 'Enregistré';

  @override
  String get stateEmpty => 'Rien pour l\'instant';

  @override
  String get stateErrorBody => 'Veuillez réessayer.';

  @override
  String get stateErrorTitle => 'Un problème est survenu';

  @override
  String get stateLoading => 'Chargement…';

  @override
  String get syncError => 'Problème de synchronisation';

  @override
  String get syncIdle => 'Synchronisé';

  @override
  String get syncLocalOnly => 'Sur cet appareil uniquement';

  @override
  String get syncOffline => 'Hors ligne — synchronisation plus tard';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications en attente',
      one: '1 modification en attente',
      zero: 'Aucune modification en attente',
    );
    return '$_temp0';
  }

  @override
  String get syncPulling => 'Mise à jour…';

  @override
  String get syncPushing => 'Envoi des modifications…';

  @override
  String get tabHabits => 'Habitudes';

  @override
  String get tabInsights => 'Statistiques';

  @override
  String get tabLists => 'Listes';

  @override
  String get tabPlan => 'Planning';

  @override
  String get tabToday => 'Aujourd\'hui';

  @override
  String get tasksActionDuplicateSeries => 'Dupliquer comme nouvelle série';

  @override
  String get tasksActionDuplicateTo => 'Dupliquer vers…';

  @override
  String get tasksActionExceptions => 'Occurrences passées et déplacées';

  @override
  String get tasksActionMoveToToday => 'Déplacer à aujourd’hui';

  @override
  String get tasksActionOpenSeries => 'Ouvrir la série';

  @override
  String get tasksActionPause => 'Mettre la série en pause';

  @override
  String get tasksActionPauseTimer => 'Pause';

  @override
  String get tasksActionReopen => 'Rouvrir';

  @override
  String get tasksActionReschedule => 'Replanifier…';

  @override
  String get tasksActionRestoreSeries => 'Revenir à la série';

  @override
  String get tasksActionResume => 'Reprendre la série';

  @override
  String get tasksActionResumeTimer => 'Reprendre';

  @override
  String get tasksActionSeriesHistory => 'Historique de la série';

  @override
  String get tasksActionShare => 'Partager en texte';

  @override
  String get tasksActionStart => 'Démarrer';

  @override
  String get tasksActionStop => 'Arrêter';

  @override
  String get tasksActionUnschedule => 'Remettre à planifier';

  @override
  String get tasksActualAsPlanned => 'Comme prévu';

  @override
  String get tasksActualCustom => 'Personnaliser…';

  @override
  String get tasksActualEndBeforeStart => 'La fin doit être après le début';

  @override
  String get tasksActualJustNow => 'À l’instant';

  @override
  String get tasksActualNotSet => 'Non renseigné';

  @override
  String get tasksActualTime => 'Horaire réel';

  @override
  String get tasksActualTitle => 'Quand l’avez-vous fait ?';

  @override
  String get tasksAddEntry => 'Ajouter une session';

  @override
  String tasksAnchorMoved(String date) {
    return 'Début déplacé au $date pour correspondre à la répétition';
  }

  @override
  String get tasksAttachments => 'Pièces jointes';

  @override
  String get tasksAttachmentsPlaceholder =>
      'Les photos et fichiers seront bientôt disponibles ici';

  @override
  String get tasksBacklogLabel => 'Non planifiée';

  @override
  String get tasksBulkDelete => 'Supprimer';

  @override
  String tasksBulkDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments mis à jour',
      one: '1 élément mis à jour',
    );
    return '$_temp0';
  }

  @override
  String get tasksBulkDuplicate => 'Dupliquer';

  @override
  String get tasksBulkEarlier15 => '15 min plus tôt';

  @override
  String get tasksBulkEarlierDay => '1 jour plus tôt';

  @override
  String get tasksBulkLater15 => '15 min plus tard';

  @override
  String get tasksBulkLater1h => '1 heure plus tard';

  @override
  String get tasksBulkLaterDay => '1 jour plus tard';

  @override
  String get tasksBulkLaterWeek => '1 semaine plus tard';

  @override
  String get tasksBulkMove => 'Déplacer';

  @override
  String get tasksBulkSetCategory => 'Définir la catégorie';

  @override
  String get tasksBulkSetPriority => 'Définir la priorité';

  @override
  String get tasksBulkSetTracking => 'Définir le mode de suivi';

  @override
  String get tasksBulkTarget => 'Pour les éléments répétés';

  @override
  String get tasksBulkTargetOccurrence => 'Seulement ces occurrences';

  @override
  String get tasksBulkTargetSeries => 'Toute la série';

  @override
  String tasksBulkTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments sélectionnés',
      one: '1 élément sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get tasksChecklistEmpty => 'Aucune liste pour l’instant';

  @override
  String get tasksChecklistNone => 'Aucune';

  @override
  String get tasksChecklistOpen => 'Ouvrir la liste';

  @override
  String get tasksChecklistPick => 'Associer une liste';

  @override
  String tasksChecklistProgress(int done, int total) {
    return '$done/$total faits';
  }

  @override
  String get tasksChecklistUnlink => 'Dissocier';

  @override
  String get tasksColorCategoryDefault => 'Couleur de la catégorie';

  @override
  String get tasksCompletion => 'Avancement';

  @override
  String tasksCompletionValue(int percent) {
    return '$percent %';
  }

  @override
  String get tasksCreated => 'Tâche créée';

  @override
  String get tasksCustomDuration => 'Personnaliser…';

  @override
  String get tasksDeadlineNone => 'Aucune échéance';

  @override
  String get tasksDeadlineWarning => 'Planifiée après l’échéance';

  @override
  String get tasksDeleteConfirmBody => 'Elle reste 30 jours dans la corbeille.';

  @override
  String get tasksDeleteConfirmTitle => 'Supprimer cette tâche ?';

  @override
  String get tasksDeleted => 'Tâche supprimée';

  @override
  String get tasksDetailNotFound => 'Cette tâche n’existe plus';

  @override
  String get tasksDetailTitle => 'Tâche';

  @override
  String get tasksDiscard => 'Abandonner';

  @override
  String tasksDuplicateToConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dupliquer vers $count dates',
      one: 'Dupliquer vers 1 date',
      zero: 'Choisissez des dates',
    );
    return '$_temp0';
  }

  @override
  String get tasksDuplicateToTitle => 'Dupliquer vers…';

  @override
  String get tasksDuplicated => 'Tâche dupliquée';

  @override
  String tasksDuplicatedTo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copiée vers $count dates',
      one: 'Copiée vers 1 date',
    );
    return '$_temp0';
  }

  @override
  String get tasksDurationMode => 'Durée';

  @override
  String get tasksEditorEditOccurrenceTitle => 'Modifier l’occurrence';

  @override
  String get tasksEditorEditTitle => 'Modifier la tâche';

  @override
  String get tasksEditorNewTitle => 'Nouvelle tâche';

  @override
  String get tasksEndMode => 'Heure de fin';

  @override
  String get tasksEntryDelete => 'Supprimer la session';

  @override
  String get tasksEntryEdit => 'Modifier la session';

  @override
  String get tasksEntryFuture =>
      'Une session ne peut pas commencer dans le futur';

  @override
  String get tasksEntryNegative => 'La fin doit être après le début';

  @override
  String get tasksEntryOverlap => 'Chevauche une autre session';

  @override
  String get tasksEntryRunning => 'En cours';

  @override
  String get tasksErrAllDay =>
      'Les tâches sur la journée couvrent des jours entiers';

  @override
  String get tasksErrDuration =>
      'La durée doit être comprise entre 0 minute et 365 jours';

  @override
  String get tasksErrEstimate => 'L’estimation est hors limites';

  @override
  String get tasksErrPriority => 'Priorité non valide';

  @override
  String get tasksErrRecurrenceInvalid =>
      'La règle de répétition n’est pas valide';

  @override
  String get tasksErrRecurrenceNoDate =>
      'Une tâche répétée a besoin d’une date';

  @override
  String get tasksErrTitleEmpty => 'Saisissez un titre';

  @override
  String get tasksErrTitleTooLong =>
      'Le titre est trop long (300 caractères max.)';

  @override
  String get tasksErrZone => 'Fuseau horaire inconnu';

  @override
  String get tasksEvtCompleted => 'Terminée';

  @override
  String get tasksEvtCreated => 'Créée';

  @override
  String get tasksEvtDeleted => 'Supprimée';

  @override
  String get tasksEvtDeletedOccurrence => 'Occurrence retirée';

  @override
  String tasksEvtOccurrence(String date) {
    return 'Occurrence du $date';
  }

  @override
  String get tasksEvtPaused => 'Série en pause';

  @override
  String get tasksEvtReopened => 'Rouverte';

  @override
  String tasksEvtRescheduled(String from, String to) {
    return 'Replanifiée de $from à $to';
  }

  @override
  String get tasksEvtRestored => 'Restaurée';

  @override
  String get tasksEvtResumed => 'Série reprise';

  @override
  String get tasksEvtScheduled => 'Planifiée';

  @override
  String get tasksEvtSkipped => 'Passée';

  @override
  String tasksEvtSkippedReason(String reason) {
    return 'Passée : $reason';
  }

  @override
  String get tasksEvtSplit => 'Série scindée';

  @override
  String get tasksEvtStarted => 'Commencée';

  @override
  String get tasksEvtStatusChanged => 'Statut modifié';

  @override
  String get tasksEvtStopped => 'Arrêtée';

  @override
  String get tasksEvtTimeEntry => 'Session ajoutée';

  @override
  String get tasksEvtUnscheduled => 'Remise à planifier';

  @override
  String tasksEvtUpdated(String fields) {
    return 'Modifiée : $fields';
  }

  @override
  String get tasksFieldAllDay => 'Toute la journée';

  @override
  String get tasksFieldCategory => 'Catégorie';

  @override
  String get tasksFieldChecklist => 'Liste associée';

  @override
  String get tasksFieldColor => 'Couleur';

  @override
  String get tasksFieldDate => 'Date';

  @override
  String get tasksFieldDeadline => 'Échéance';

  @override
  String get tasksFieldDuration => 'Durée';

  @override
  String get tasksFieldEnd => 'Fin';

  @override
  String get tasksFieldEndDate => 'Date de fin';

  @override
  String get tasksFieldEstimate => 'Estimation';

  @override
  String get tasksFieldIcon => 'Icône';

  @override
  String get tasksFieldLocation => 'Lieu';

  @override
  String get tasksFieldNoDate => 'Sans date (à planifier)';

  @override
  String get tasksFieldNotes => 'Notes';

  @override
  String get tasksFieldPriority => 'Priorité';

  @override
  String get tasksFieldRepeat => 'Répétition';

  @override
  String get tasksFieldStart => 'Début';

  @override
  String get tasksFieldStartDate => 'Date de début';

  @override
  String get tasksFieldTimeZone => 'Fuseau horaire';

  @override
  String get tasksFieldTitle => 'Titre';

  @override
  String get tasksFieldTitleHint => 'Que voulez-vous faire ?';

  @override
  String get tasksFieldTracking => 'Suivi';

  @override
  String get tasksFieldUrl => 'Lien';

  @override
  String get tasksFilterAll => 'Toutes';

  @override
  String get tasksFilterDone => 'Faites';

  @override
  String get tasksFilterMissed => 'Manquées';

  @override
  String get tasksFilterMoved => 'Déplacées';

  @override
  String get tasksFilterSkipped => 'Passées';

  @override
  String get tasksFromTemplate => 'À partir d’un modèle…';

  @override
  String get tasksHistory => 'Historique';

  @override
  String get tasksHistoryEmpty => 'Pas encore d’historique';

  @override
  String get tasksHistoryLoadMore => 'Charger plus';

  @override
  String get tasksIconDefault => 'Icône de la catégorie';

  @override
  String get tasksMarkedDone => 'Marquée comme faite';

  @override
  String get tasksMarkedSkipped => 'Passée';

  @override
  String get tasksMdBold => 'Gras';

  @override
  String get tasksMdBullet => 'Liste à puces';

  @override
  String get tasksMdCheckbox => 'Case à cocher';

  @override
  String get tasksMdCode => 'Code';

  @override
  String get tasksMdHeading => 'Titre';

  @override
  String get tasksMdItalic => 'Italique';

  @override
  String get tasksMdNumbered => 'Liste numérotée';

  @override
  String get tasksMoved => 'Déplacée';

  @override
  String tasksMovedFrom(String time) {
    return 'Déplacée depuis $time';
  }

  @override
  String get tasksNextDay => '+1 jour';

  @override
  String tasksNextLabel(String when) {
    return 'Prochaine : $when';
  }

  @override
  String get tasksNextMonth => 'Mois suivant';

  @override
  String get tasksNextOccurrences => 'Prochaines occurrences';

  @override
  String get tasksNoUpcoming => 'Rien à venir';

  @override
  String get tasksNotesEdit => 'Modifier';

  @override
  String get tasksNotesHint => 'Ajouter des notes (gras, listes, cases…)';

  @override
  String get tasksNotesPreview => 'Aperçu';

  @override
  String get tasksOccurrenceDeleted => 'Occurrence retirée';

  @override
  String tasksOpenLinkBody(String url) {
    return '$url va s’ouvrir en dehors d’Everslot.';
  }

  @override
  String get tasksOpenLinkTitle => 'Ouvrir le lien ?';

  @override
  String get tasksOrphansBody =>
      'Les occurrences avec un historique sont toujours conservées comme tâches ponctuelles.';

  @override
  String tasksOrphansCompleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count occurrences terminées',
      one: '1 occurrence terminée',
    );
    return '$_temp0';
  }

  @override
  String get tasksOrphansDiscard => 'Supprimer les déplacées';

  @override
  String get tasksOrphansKeep => 'Garder comme tâches ponctuelles';

  @override
  String tasksOrphansMoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count occurrences déplacées',
      one: '1 occurrence déplacée',
    );
    return '$_temp0';
  }

  @override
  String tasksOrphansOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count occurrences avec notes ou temps suivi',
      one: '1 occurrence avec notes ou temps suivi',
    );
    return '$_temp0';
  }

  @override
  String tasksOrphansSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count occurrences passées',
      one: '1 occurrence passée',
    );
    return '$_temp0';
  }

  @override
  String get tasksOrphansTitle => 'Certaines occurrences ne correspondent plus';

  @override
  String get tasksOutcomeNote => 'Note de résultat';

  @override
  String get tasksOutcomeNoteHint => 'Comment ça s’est passé ?';

  @override
  String get tasksOverdue => 'En retard';

  @override
  String tasksOverlapHint(String title, String range) {
    return 'Chevauche $title $range';
  }

  @override
  String tasksOverlapMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'et $count autres',
      one: 'et 1 autre',
    );
    return '$_temp0';
  }

  @override
  String get tasksPauseSnack => 'Série en pause';

  @override
  String get tasksPausedBadge => 'En pause';

  @override
  String tasksPlannedVsActual(String planned, String actual) {
    return 'Prévu $planned · réel $actual';
  }

  @override
  String tasksPlusDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count jours',
      one: '+1 jour',
    );
    return '$_temp0';
  }

  @override
  String get tasksPostpone15 => '+15 min';

  @override
  String get tasksPostpone1h => '+1 heure';

  @override
  String get tasksPostponeEvening => 'Ce soir';

  @override
  String get tasksPostponeNextWeek => 'La semaine prochaine, même heure';

  @override
  String get tasksPostponePick => 'Choisir une date et une heure…';

  @override
  String get tasksPostponeTitle => 'Replanifier';

  @override
  String get tasksPostponeTomorrow => 'Demain, même heure';

  @override
  String get tasksPrevMonth => 'Mois précédent';

  @override
  String get tasksQuickAdd => 'Ajouter';

  @override
  String get tasksQuickAddNew => 'Ajouter et nouvelle';

  @override
  String get tasksQuickMore => 'Plus d’options';

  @override
  String get tasksQuickTitleHint => 'Nouvelle tâche';

  @override
  String get tasksQuotaDone => 'Terminé pour cette période';

  @override
  String tasksQuotaProgress(int done, int total) {
    return '$done/$total sur la période';
  }

  @override
  String get tasksRating => 'Note';

  @override
  String tasksRatingValue(int value) {
    return '$value sur 5';
  }

  @override
  String get tasksReminders => 'Rappels';

  @override
  String get tasksRemindersDefault => 'Par défaut';

  @override
  String get tasksReopened => 'Rouverte';

  @override
  String get tasksRepeatNone => 'Ne se répète pas';

  @override
  String get tasksRestored => 'Tâche restaurée';

  @override
  String get tasksResumeSnack => 'Série reprise';

  @override
  String tasksRolledOver(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tâches inachevées déplacées à aujourd’hui',
      one: '1 tâche inachevée déplacée à aujourd’hui',
    );
    return '$_temp0';
  }

  @override
  String tasksRunningTimer(String title, String elapsed) {
    return 'Minuteur en cours : $title, $elapsed';
  }

  @override
  String get tasksSaveAsTemplate => 'Enregistrer comme modèle';

  @override
  String get tasksSaved => 'Tâche enregistrée';

  @override
  String get tasksScopeAll => 'Toutes les occurrences';

  @override
  String get tasksScopeDeleteTitle => 'Supprimer une tâche répétée';

  @override
  String get tasksScopeFollowing => 'Celle-ci et les suivantes';

  @override
  String get tasksScopePastKept =>
      'Les occurrences passées gardent leurs horaires d’origine.';

  @override
  String get tasksScopeRewritePast => 'Réécrire aussi les occurrences passées';

  @override
  String get tasksScopeThis => 'Cette occurrence';

  @override
  String get tasksScopeThisDisabled =>
      'Seuls l’heure, la durée, le titre et les notes peuvent changer pour une seule occurrence.';

  @override
  String get tasksScopeTitle => 'Appliquer les modifications à';

  @override
  String get tasksSeriesEmpty => 'Aucune occurrence sur cette période';

  @override
  String get tasksSeriesHistoryTitle => 'Historique de la série';

  @override
  String get tasksSeriesStats => 'Statistiques de la série';

  @override
  String tasksShareRepeats(String rule) {
    return 'Répétition : $rule';
  }

  @override
  String get tasksSkipCustomHint => 'Autre raison (facultatif)';

  @override
  String get tasksSkipForgot => 'Oublié';

  @override
  String get tasksSkipNotNeeded => 'Pas nécessaire';

  @override
  String get tasksSkipOther => 'Autre';

  @override
  String get tasksSkipSick => 'Malade';

  @override
  String get tasksSkipTitle => 'Pourquoi passer ?';

  @override
  String get tasksSkipTooBusy => 'Trop occupé';

  @override
  String get tasksStatusCancelled => 'Annulée';

  @override
  String get tasksStatusDone => 'Faite';

  @override
  String get tasksStatusInProgress => 'En cours';

  @override
  String get tasksStatusMissed => 'Manquée';

  @override
  String get tasksStatusScheduled => 'Planifiée';

  @override
  String get tasksStatusSkipped => 'Passée';

  @override
  String get tasksTemplateDelete => 'Supprimer le modèle';

  @override
  String get tasksTemplateSaved => 'Modèle enregistré';

  @override
  String get tasksTemplatesEmpty =>
      'Aucun modèle. Enregistrez une tâche comme modèle depuis son menu.';

  @override
  String get tasksTemplatesTitle => 'Modèles';

  @override
  String get tasksTimeEntries => 'Sessions';

  @override
  String get tasksTimeTracking => 'Suivi du temps';

  @override
  String get tasksTooManyOccurrences =>
      'Trop d’occurrences à afficher — zoomez';

  @override
  String tasksTracked(String duration) {
    return 'Suivi : $duration';
  }

  @override
  String get tasksTrackingCheck => 'Case à cocher';

  @override
  String get tasksTrackingCheckHint =>
      'À cocher ou à passer ; peut être manquée.';

  @override
  String get tasksTrackingEvent => 'Événement';

  @override
  String get tasksTrackingEventHint =>
      'Un bloc de temps (réunion, repas) : pas de case, jamais manqué.';

  @override
  String get tasksTrackingTimer => 'Minuteur';

  @override
  String get tasksTrackingTimerHint =>
      'Mesurez le temps passé ; terminée à l’arrêt du minuteur.';

  @override
  String get tasksUnsavedBody => 'Vos modifications seront perdues.';

  @override
  String get tasksUnsavedTitle => 'Abandonner les modifications ?';

  @override
  String get tasksUntitled => 'Tâche sans titre';

  @override
  String get tasksUpdated => 'Mise à jour';

  @override
  String get tasksUrlInvalid => 'Saisissez une adresse web valide';

  @override
  String tasksZoneBadge(String zone) {
    return 'Heure de $zone';
  }

  @override
  String get tasksZoneFixed => 'Fixe';

  @override
  String get tasksZoneFixedHint => 'Ancré à un fuseau horaire';

  @override
  String get tasksZoneFloating => 'Flottant';

  @override
  String get tasksZoneFloatingHint => 'Même heure où que vous soyez';

  @override
  String get tasksZonePickTitle => 'Choisir un fuseau horaire';

  @override
  String get tasksZoneSearch => 'Rechercher un fuseau';
}
