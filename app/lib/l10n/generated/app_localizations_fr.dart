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
  String chartsAnonymousItem(String n) {
    return 'Élément $n';
  }

  @override
  String chartsBytesGb(String value) {
    return '$value Go';
  }

  @override
  String chartsBytesKb(String value) {
    return '$value Ko';
  }

  @override
  String chartsBytesMb(String value) {
    return '$value Mo';
  }

  @override
  String get chartsColumnLabel => 'Libellé';

  @override
  String chartsCounterSemantics(String days, String hours, String minutes) {
    return '$days jours, $hours heures, $minutes minutes';
  }

  @override
  String chartsCrosshair(String label, String value) {
    return '$label : $value';
  }

  @override
  String chartsDaysHours(String days, String hours) {
    return '$days j $hours h';
  }

  @override
  String chartsDaysOnly(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String chartsDeltaDown(String value) {
    return 'en baisse de $value';
  }

  @override
  String get chartsDeltaFlat => 'stable';

  @override
  String get chartsDeltaNew => 'nouveau';

  @override
  String chartsDeltaUp(String value) {
    return 'en hausse de $value';
  }

  @override
  String get chartsEmpty => 'Aucune donnée sur cette période';

  @override
  String get chartsError => 'Ce graphique n’a pas pu être calculé';

  @override
  String chartsEstimate(String value) {
    return '≈ $value';
  }

  @override
  String get chartsExplain => 'À propos de cet indicateur';

  @override
  String chartsFrozen(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gelés',
      one: '1 gelé',
    );
    return '$_temp0';
  }

  @override
  String get chartsGalleryDark => 'Thème sombre';

  @override
  String get chartsGalleryRtl => 'De droite à gauche';

  @override
  String get chartsGalleryTextScale => 'Grand texte';

  @override
  String get chartsGalleryTitle => 'Galerie de graphiques';

  @override
  String get chartsGalleryVision => 'Vision des couleurs';

  @override
  String get chartsHistogramCount => 'Nombre';

  @override
  String get chartsHistogramDensity => 'Part';

  @override
  String chartsHour(String hour) {
    return '$hour h';
  }

  @override
  String chartsHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String chartsHoursOnly(String hours) {
    return '$hours h';
  }

  @override
  String chartsKilo(String value) {
    return '$value k';
  }

  @override
  String chartsKpiSemantics(String title, String value, String delta) {
    return '$title : $value. $delta';
  }

  @override
  String get chartsLabelAbstinent => 'Abstinent';

  @override
  String get chartsLabelActual => 'Réel';

  @override
  String get chartsLabelAfterHours => 'Hors horaires';

  @override
  String get chartsLabelAgenda => 'Agenda';

  @override
  String get chartsLabelArchived => 'Archivées';

  @override
  String get chartsLabelArrivals => 'Arrivées';

  @override
  String get chartsLabelAttempt => 'Tentative';

  @override
  String get chartsLabelAttention => 'À surveiller';

  @override
  String get chartsLabelBaseline => 'Référence';

  @override
  String get chartsLabelBest => 'Record';

  @override
  String get chartsLabelBlocked => 'Bloqué';

  @override
  String get chartsLabelCancelled => 'Annulé';

  @override
  String get chartsLabelCapacity => 'Capacité';

  @override
  String get chartsLabelCheckIns => 'Validations';

  @override
  String get chartsLabelCompleted => 'Terminé';

  @override
  String get chartsLabelCount => 'Nombre';

  @override
  String get chartsLabelCravings => 'Envies';

  @override
  String get chartsLabelCreated => 'Créés';

  @override
  String get chartsLabelCurrent => 'Actuel';

  @override
  String get chartsLabelDeepWork => 'Travail profond';

  @override
  String get chartsLabelDepartures => 'Sorties';

  @override
  String get chartsLabelDone => 'Fait';

  @override
  String get chartsLabelDoneLate => 'En retard';

  @override
  String get chartsLabelDoneOnTime => 'À l’heure';

  @override
  String get chartsLabelEarly => 'En avance';

  @override
  String get chartsLabelEvent => 'Événements';

  @override
  String get chartsLabelExcused => 'Excusé';

  @override
  String get chartsLabelFailed => 'Non fait';

  @override
  String get chartsLabelFiles => 'Fichiers';

  @override
  String get chartsLabelFocus => 'Concentration';

  @override
  String get chartsLabelFree => 'Libre';

  @override
  String get chartsLabelFrozen => 'Gelé';

  @override
  String get chartsLabelFuture => 'À venir';

  @override
  String get chartsLabelGoal => 'Objectif';

  @override
  String get chartsLabelHabits => 'Habitudes';

  @override
  String get chartsLabelHighPriority => 'Priorité haute';

  @override
  String get chartsLabelIdeal => 'Idéal';

  @override
  String get chartsLabelImages => 'Images';

  @override
  String get chartsLabelInProgress => 'Actives';

  @override
  String get chartsLabelIntensity => 'Intensité';

  @override
  String get chartsLabelItems => 'Éléments';

  @override
  String get chartsLabelLapse => 'Écart';

  @override
  String get chartsLabelLate => 'En retard';

  @override
  String get chartsLabelLifeRegained => 'Vie regagnée';

  @override
  String get chartsLabelLimit => 'Limite';

  @override
  String get chartsLabelLists => 'Listes';

  @override
  String get chartsLabelLowPriority => 'Priorité basse';

  @override
  String get chartsLabelMaxIntensity => 'Intensité maximale';

  @override
  String get chartsLabelMean => 'Moyenne';

  @override
  String get chartsLabelMeanIntensity => 'Intensité moyenne';

  @override
  String get chartsLabelMeanUse => 'Consommation moyenne';

  @override
  String get chartsLabelMedian => 'Médiane';

  @override
  String get chartsLabelMissed => 'Manqué';

  @override
  String get chartsLabelMoney => 'Argent';

  @override
  String get chartsLabelMonth => 'Mois';

  @override
  String get chartsLabelMoods => 'Humeurs';

  @override
  String get chartsLabelMoved => 'Déplacé';

  @override
  String get chartsLabelMovedIn => 'Arrivés';

  @override
  String get chartsLabelMovedOut => 'Sortis';

  @override
  String get chartsLabelNet => 'Flux net';

  @override
  String get chartsLabelNextUp => 'À suivre';

  @override
  String get chartsLabelNo => 'Non';

  @override
  String get chartsLabelNotDue => 'Non prévu';

  @override
  String get chartsLabelNotTracked => 'Non suivi';

  @override
  String get chartsLabelOnTime => 'À l’heure';

  @override
  String get chartsLabelOneOff => 'Ponctuel';

  @override
  String get chartsLabelOngoing => 'En cours';

  @override
  String get chartsLabelOther => 'Autre';

  @override
  String get chartsLabelOver => 'Dépassement';

  @override
  String get chartsLabelOverLimit => 'Au-delà de la limite';

  @override
  String get chartsLabelOverdue => 'En retard';

  @override
  String get chartsLabelOverdue1 => '1–6 jours';

  @override
  String get chartsLabelOverdue14 => '14–29 jours';

  @override
  String get chartsLabelOverdue30 => '30 jours et +';

  @override
  String get chartsLabelOverdue7 => '7–13 jours';

  @override
  String get chartsLabelOverdueToday => '< 1 jour';

  @override
  String get chartsLabelOverlap => 'Chevauchement';

  @override
  String get chartsLabelP50 => 'P50';

  @override
  String get chartsLabelP70 => 'P70';

  @override
  String get chartsLabelP85 => 'P85';

  @override
  String get chartsLabelP95 => 'P95';

  @override
  String get chartsLabelPace => 'Rythme';

  @override
  String get chartsLabelPartial => 'Partiel';

  @override
  String get chartsLabelPaused => 'En pause';

  @override
  String get chartsLabelPdfs => 'PDF';

  @override
  String get chartsLabelPending => 'En attente';

  @override
  String get chartsLabelPerDay => 'Par jour';

  @override
  String get chartsLabelPerfectDay => 'Journée parfaite';

  @override
  String get chartsLabelPlaces => 'Lieux';

  @override
  String get chartsLabelPlanned => 'Prévu';

  @override
  String get chartsLabelPrevious => 'Précédent';

  @override
  String get chartsLabelProjection => 'Projection';

  @override
  String get chartsLabelProjection1m => 'Mois prochain';

  @override
  String get chartsLabelProjection1y => 'L’an prochain';

  @override
  String get chartsLabelProjection5y => 'Dans 5 ans';

  @override
  String get chartsLabelQuit => 'Arrêt';

  @override
  String get chartsLabelRate => 'Taux';

  @override
  String get chartsLabelRecurring => 'Récurrent';

  @override
  String get chartsLabelReduction => 'Réduction';

  @override
  String get chartsLabelRelapse => 'Rechute';

  @override
  String get chartsLabelRemaining => 'Restant';

  @override
  String get chartsLabelRemoved => 'Retirés';

  @override
  String get chartsLabelReopened => 'Rouverts';

  @override
  String get chartsLabelRollingMean => 'Moyenne glissante';

  @override
  String get chartsLabelSaved => 'Économisé';

  @override
  String get chartsLabelScope => 'Périmètre';

  @override
  String get chartsLabelScore => 'Score';

  @override
  String get chartsLabelSkipped => 'Passé';

  @override
  String get chartsLabelSpent => 'Dépensé';

  @override
  String get chartsLabelStale => 'Inactives';

  @override
  String get chartsLabelStreak => 'Série';

  @override
  String get chartsLabelSuccess => 'Réussi';

  @override
  String get chartsLabelTarget => 'Objectif';

  @override
  String get chartsLabelTask => 'Tâches';

  @override
  String get chartsLabelTasks => 'Tâches';

  @override
  String get chartsLabelTemplates => 'Modèles';

  @override
  String get chartsLabelTimeNotSpent => 'Temps économisé';

  @override
  String get chartsLabelTodo => 'À faire';

  @override
  String get chartsLabelTotal => 'Total';

  @override
  String get chartsLabelTrend => 'Tendance';

  @override
  String get chartsLabelTriggers => 'Déclencheurs';

  @override
  String get chartsLabelUncategorized => 'Sans catégorie';

  @override
  String get chartsLabelUnder => 'En dessous';

  @override
  String get chartsLabelUnits => 'Unités';

  @override
  String get chartsLabelUnplanned => 'Non prévus';

  @override
  String get chartsLabelUnspecified => 'Non précisé';

  @override
  String get chartsLabelUsed => 'Consommé';

  @override
  String get chartsLabelVolume => 'Volume';

  @override
  String get chartsLabelWaiting => 'En attente';

  @override
  String get chartsLabelWeek => 'Semaine';

  @override
  String get chartsLabelWeekend => 'Week-end';

  @override
  String get chartsLabelWhenLabel => 'Quand';

  @override
  String get chartsLabelWins => 'Victoires';

  @override
  String get chartsLabelWip => 'En cours';

  @override
  String get chartsLabelWithinLimit => 'Dans la limite';

  @override
  String get chartsLabelWithinLimitDays => 'Jours dans la limite';

  @override
  String get chartsLabelYear => 'Année';

  @override
  String get chartsLabelYes => 'Oui';

  @override
  String get chartsLegend => 'Légende';

  @override
  String get chartsLoading => 'Chargement…';

  @override
  String chartsMedianAt(String value) {
    return 'Médiane $value';
  }

  @override
  String get chartsMedianNotReached => 'Médiane non atteinte';

  @override
  String chartsMega(String value) {
    return '$value M';
  }

  @override
  String chartsMilestoneEta(String time) {
    return 'dans $time';
  }

  @override
  String get chartsMilestoneInWindow => 'En cours';

  @override
  String get chartsMilestoneNext => 'Prochain';

  @override
  String get chartsMilestoneReached => 'Atteint';

  @override
  String get chartsMilestoneRestarted =>
      'Le compteur a redémarré après un écart — chaque jour déjà accompli compte toujours.';

  @override
  String chartsMilestoneSources(String sources) {
    return 'Sources : $sources';
  }

  @override
  String chartsMinutesOnly(String minutes) {
    return '$minutes min';
  }

  @override
  String chartsNeedsMore(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore $count données nécessaires',
      one: 'Encore 1 donnée nécessaire',
    );
    return '$_temp0';
  }

  @override
  String get chartsNoConsistentTime => 'Pas d’heure régulière';

  @override
  String get chartsNotApplicable => '—';

  @override
  String chartsOrdinalAttempt(String n) {
    return 'Tentative $n';
  }

  @override
  String chartsOrdinalDepth(String n) {
    return 'Profondeur $n';
  }

  @override
  String chartsOrdinalLevel(String n) {
    return 'Niveau $n';
  }

  @override
  String chartsOrdinalMonth(String n) {
    return 'Mois $n';
  }

  @override
  String chartsOrdinalPriority(String n) {
    return 'Priorité $n';
  }

  @override
  String chartsOrdinalRun(String n) {
    return 'Exécution $n';
  }

  @override
  String chartsOrdinalWeek(String n) {
    return 'Semaine $n';
  }

  @override
  String chartsOrdinalYear(String n) {
    return 'Année $n';
  }

  @override
  String chartsOver(String value) {
    return '+$value';
  }

  @override
  String chartsPerDay(String value) {
    return '$value/jour';
  }

  @override
  String chartsPerWeek(String value) {
    return '$value/semaine';
  }

  @override
  String chartsPlusMinus(String value) {
    return '± $value';
  }

  @override
  String get chartsPopulationEstimate => 'Estimation populationnelle';

  @override
  String chartsPp(String value) {
    return '$value pts';
  }

  @override
  String chartsPpSpoken(String value) {
    return '$value points de pourcentage';
  }

  @override
  String chartsPrevious(String value) {
    return 'Précédent $value';
  }

  @override
  String chartsProbability(String value) {
    return '$value de probabilité';
  }

  @override
  String chartsRange(String from, String to) {
    return '$from–$to';
  }

  @override
  String chartsRatio(String value) {
    return '$value×';
  }

  @override
  String chartsSecondsOnly(String seconds) {
    return '$seconds s';
  }

  @override
  String get chartsSelected => 'Sélectionné';

  @override
  String chartsSeriesToggle(String series) {
    return 'Afficher ou masquer $series';
  }

  @override
  String get chartsShare => 'Partager le graphique';

  @override
  String get chartsShareHideNames => 'Masquer les noms';

  @override
  String get chartsShareMark => 'Créé avec Everslot';

  @override
  String get chartsStreakBest => 'Record';

  @override
  String get chartsStreakCurrent => 'En cours';

  @override
  String chartsSummaryBars(
    String title,
    String count,
    String label,
    String value,
  ) {
    return '$title : $count barres, la plus haute $label avec $value.';
  }

  @override
  String chartsSummaryCalendar(String title, String count) {
    return '$title : $count jours affichés.';
  }

  @override
  String chartsSummaryLine(
    String title,
    String range,
    String first,
    String last,
    String trend,
  ) {
    return '$title, $range : de $first à $last. $trend';
  }

  @override
  String chartsSummaryList(String title, String count) {
    return '$title : $count éléments.';
  }

  @override
  String chartsSummaryMilestones(String title, String done, String total) {
    return '$title : $done sur $total atteints.';
  }

  @override
  String chartsSummaryMinMax(String min, String max) {
    return 'Minimum $min, maximum $max.';
  }

  @override
  String chartsSummaryPunchCard(String title, String weekday, String hour) {
    return '$title : pic le $weekday à $hour.';
  }

  @override
  String chartsSummaryShare(String title, String label, String share) {
    return '$title : part la plus grande $label, $share.';
  }

  @override
  String chartsSummaryStreaks(String title, String length) {
    return '$title : plus longue série $length.';
  }

  @override
  String chartsSummaryValue(String title, String value) {
    return '$title : $value.';
  }

  @override
  String chartsTableSort(String column) {
    return 'Trier par $column';
  }

  @override
  String get chartsTapForDetails => 'Touchez deux fois pour les détails';

  @override
  String chartsTarget(String value) {
    return 'Objectif $value';
  }

  @override
  String chartsTooltip(String label, String value) {
    return '$label : $value';
  }

  @override
  String chartsTrendFalling(String slope) {
    return 'En baisse de $slope par semaine.';
  }

  @override
  String chartsTrendRising(String slope) {
    return 'En hausse de $slope par semaine.';
  }

  @override
  String get chartsTrendStable => 'Pas de tendance nette.';

  @override
  String get chartsViewAsChart => 'Afficher le graphique';

  @override
  String get chartsViewAsTable => 'Afficher le tableau';

  @override
  String get chartsVisionDeuteranopia => 'Deutéranopie';

  @override
  String get chartsVisionNormal => 'Normale';

  @override
  String get chartsVisionProtanopia => 'Protanopie';

  @override
  String get chartsVisionTritanopia => 'Tritanopie';

  @override
  String get chartsVsPrevious => 'vs période précédente';

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
  String get statsCardError => 'Cette carte n’a pas pu être calculée.';

  @override
  String get statsCompareToggle => 'Comparer à la période précédente';

  @override
  String statsDetailAllTime(String value) {
    return 'Au total : $value';
  }

  @override
  String statsDetailBacklog(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tâches non planifiées',
      one: '1 tâche non planifiée',
    );
    return '$_temp0';
  }

  @override
  String statsDetailBest(String value) {
    return 'Record : $value';
  }

  @override
  String statsDetailCoverage(String value) {
    return 'Temps suivi sur $value des tâches faites';
  }

  @override
  String statsDetailDelta30(String value) {
    return '$value vs il y a 30 jours';
  }

  @override
  String statsDetailLastDone(String date) {
    return 'Dernière fois le $date';
  }

  @override
  String statsDetailOfTotal(String done, String total) {
    return '$done sur $total';
  }

  @override
  String statsDetailOpen(String count) {
    return '$count ouvertes';
  }

  @override
  String statsDetailPerDay(String value) {
    return '$value par jour';
  }

  @override
  String statsDetailPeriods(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count périodes',
      one: '1 période',
    );
    return '$_temp0';
  }

  @override
  String statsDetailPlanned(String value) {
    return 'Prévu : $value';
  }

  @override
  String statsDetailQueue(String time) {
    return 'En attente de démarrage depuis $time';
  }

  @override
  String statsDetailReduction(String value) {
    return 'En baisse de $value vs référence';
  }

  @override
  String statsDetailSince(String date) {
    return 'Depuis le $date';
  }

  @override
  String statsDetailWorkItem(String time) {
    return 'En cours depuis $time';
  }

  @override
  String get statsDrillEmpty => 'Rien à afficher';

  @override
  String statsDrillMore(String count) {
    return '$count de plus';
  }

  @override
  String get statsDrillTitle => 'Derrière ce chiffre';

  @override
  String get statsEmptyHabits =>
      'Ajoutez une habitude pour suivre votre régularité.';

  @override
  String get statsEmptyLists =>
      'Créez une liste pour voir comment le travail avance.';

  @override
  String get statsEmptyPlanner =>
      'Planifiez quelques tâches et revenez voir vos statistiques.';

  @override
  String get statsEmptyQuit => 'Aucun suivi d’arrêt pour l’instant';

  @override
  String get statsEmptyQuitBody =>
      'Créez-en un dans Habitudes pour voir vos progrès ici.';

  @override
  String get statsEmptyTitle => 'Rien à afficher pour l’instant';

  @override
  String statsExclusionCancelled(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count occurrences annulées',
      one: '1 occurrence annulée',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionExcused(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unités excusées',
      one: '1 unité excusée',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionFrozen(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unités gelées',
      one: '1 unité gelée',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionPaused(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unités en pause',
      one: '1 unité en pause',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionSkipped(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unités passées',
      one: '1 unité passée',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionUnknown(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours non renseignés',
      one: '1 jour non renseigné',
    );
    return '$_temp0';
  }

  @override
  String statsExclusionUnplanned(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ajouts imprévus',
      one: '1 ajout imprévu',
    );
    return '$_temp0';
  }

  @override
  String get statsExplainEstimate => 'Ce chiffre est une estimation.';

  @override
  String get statsExplainExcluded => 'Exclus';

  @override
  String get statsExplainFormula => 'Mode de calcul';

  @override
  String get statsExplainGlossary => 'Glossaire des indicateurs';

  @override
  String statsExplainId(String id) {
    return 'Indicateur $id';
  }

  @override
  String statsExplainInterval(String lower, String upper) {
    return 'Intervalle à 95 % : $lower – $upper';
  }

  @override
  String statsExplainIntervalRule(String count) {
    return 'Une marge ± est affichée sous $count unités.';
  }

  @override
  String statsExplainMinData(String count) {
    return 'Affiché dès $count unités.';
  }

  @override
  String get statsExplainNothingExcluded => 'Rien d’exclu';

  @override
  String get statsExplainPopulation =>
      'Estimation populationnelle : les effets ne sont pas linéaires et varient selon les personnes ; ce n’est pas une prédiction personnelle.';

  @override
  String statsExplainPrevious(String value) {
    return 'Période précédente : $value';
  }

  @override
  String statsExplainSample(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Basé sur $count unités',
      one: 'Basé sur 1 unité',
    );
    return '$_temp0';
  }

  @override
  String get statsExplainSources => 'Sources';

  @override
  String get statsExplainThisView => 'Dans cette vue';

  @override
  String statsExplainValue(String value) {
    return 'Valeur : $value';
  }

  @override
  String get statsExplainWhat => 'Ce qui est mesuré';

  @override
  String get statsFilterApply => 'Appliquer';

  @override
  String get statsFilterCategories => 'Catégories';

  @override
  String get statsFilterClear => 'Effacer';

  @override
  String get statsFilterPriority => 'Priorité';

  @override
  String get statsFilterTags => 'Étiquettes';

  @override
  String get statsFilterTracking => 'Suivi';

  @override
  String get statsFilterTrackingCheck => 'Case à cocher';

  @override
  String get statsFilterTrackingEvent => 'Événement';

  @override
  String get statsFilterTrackingTimer => 'Minuteur';

  @override
  String get statsFilters => 'Filtres';

  @override
  String statsFiltersActive(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtres',
      one: '1 filtre',
    );
    return '$_temp0';
  }

  @override
  String get statsHealthClockNote =>
      'Les étapes suivent votre temps actuel sans tabac : le compteur redémarre après un écart.';

  @override
  String get statsHealthDisclaimer =>
      'Estimations éducatives fondées sur des moyennes de population de l’OMS, du NHS, des CDC et de l’American Cancer Society ; les résultats individuels varient. Ceci n’est pas un avis médical. Consultez un professionnel de santé.';

  @override
  String get statsHealthElapsedNote =>
      'Les pourcentages indiquent le temps écoulé, pas des mesures physiologiques.';

  @override
  String statsHealthRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get statsMetricClI01Desc =>
      'Temps passé par cet élément dans chaque statut.';

  @override
  String get statsMetricClI01Formula =>
      'Somme des intervalles par statut jusqu’à maintenant (ou suppression).';

  @override
  String get statsMetricClI01Title => 'Temps par statut';

  @override
  String get statsMetricClI02Desc =>
      'Temps entre le début du travail et l’achèvement.';

  @override
  String get statsMetricClI02Formula =>
      'Terminé − démarré (première sortie de « à faire »).';

  @override
  String get statsMetricClI02Title => 'Temps de cycle';

  @override
  String get statsMetricClI03Desc => 'Temps entre la création et l’achèvement.';

  @override
  String get statsMetricClI03Formula => 'Terminé − créé.';

  @override
  String get statsMetricClI03Title => 'Délai total';

  @override
  String get statsMetricClI04Desc =>
      'Depuis combien de temps un élément ouvert est en cours ou attend.';

  @override
  String get statsMetricClI04Formula =>
      'Démarré : maintenant − début ; non démarré : maintenant − création.';

  @override
  String get statsMetricClI04Title => 'Âge';

  @override
  String get statsMetricClI05Desc =>
      'Temps écoulé depuis la dernière activité sur cet élément.';

  @override
  String get statsMetricClI05Formula =>
      'Maintenant − dernière activité (statut, modification, pièce jointe ou enfant).';

  @override
  String get statsMetricClI05Title => 'Inactivité';

  @override
  String get statsMetricClI06Desc => 'Achèvement des éléments imbriqués.';

  @override
  String get statsMetricClI06Formula =>
      'Feuilles terminées ÷ feuilles comptables (annulées exclues).';

  @override
  String get statsMetricClI06Title => 'Avancement du sous-arbre';

  @override
  String get statsMetricClI07Desc =>
      'L’historique de l’élément en segments colorés avec notes.';

  @override
  String get statsMetricClI07Formula =>
      'Chaque intervalle de statut de la création à maintenant.';

  @override
  String get statsMetricClI07Title => 'Chronologie des statuts';

  @override
  String get statsMetricClL01Desc =>
      'Répartition des éléments de la liste par statut.';

  @override
  String get statsMetricClL01Formula =>
      'Éléments par statut ; % terminé sur les feuilles et sur tous les nœuds.';

  @override
  String get statsMetricClL01Title => 'Répartition des statuts';

  @override
  String get statsMetricClL02Desc => 'Achèvement quotidien de la liste.';

  @override
  String get statsMetricClL02Formula =>
      'Terminés ÷ (éléments − annulés) à la fin de chaque jour.';

  @override
  String get statsMetricClL02Title => 'Avancement dans le temps';

  @override
  String get statsMetricClL03Desc =>
      'Éléments terminés par semaine, avec moyenne glissante sur 4 semaines.';

  @override
  String get statsMetricClL03Formula =>
      'Achèvements par tranche (un élément rouvert compte une fois).';

  @override
  String get statsMetricClL03Title => 'Débit';

  @override
  String get statsMetricClL04Desc =>
      'Éléments en cours, en attente ou bloqués à la fin de chaque jour.';

  @override
  String get statsMetricClL04Formula =>
      'Nombre d’éléments en cours + en attente + bloqués.';

  @override
  String get statsMetricClL04Title => 'Travail en cours';

  @override
  String get statsMetricClL05Desc =>
      'Éléments ajoutés vs terminés chaque semaine.';

  @override
  String get statsMetricClL05Formula =>
      'Créés (ou déplacés ici) vs terminés par semaine ; flux net = différence.';

  @override
  String get statsMetricClL05Title => 'Arrivées vs sorties';

  @override
  String get statsMetricClL06Desc =>
      'Éléments ouverts sans activité depuis un moment, et les plus anciens.';

  @override
  String get statsMetricClL06Formula =>
      'Éléments ouverts inactifs ≥ au seuil ; les 10 plus anciens.';

  @override
  String get statsMetricClL06Title => 'Éléments inactifs';

  @override
  String get statsMetricClX01Desc =>
      'Vos listes : actives, archivées, modèles et inactives.';

  @override
  String get statsMetricClX01Formula =>
      'Nombre de listes ; inactive = aucune activité depuis N jours avec des éléments ouverts.';

  @override
  String get statsMetricClX01Title => 'Vue des listes';

  @override
  String get statsMetricClX02Desc =>
      'Éléments ajoutés vs terminés chaque semaine, toutes listes.';

  @override
  String get statsMetricClX02Formula =>
      'Créés vs terminés par semaine ; flux net = différence.';

  @override
  String get statsMetricClX02Title => 'Arrivées vs sorties (toutes les listes)';

  @override
  String get statsMetricClX03Desc =>
      'Éléments en cours, en attente ou bloqués, et les plus anciens.';

  @override
  String get statsMetricClX03Formula =>
      'Nombres sur les listes actives (archivées exclues).';

  @override
  String get statsMetricClX03Title => 'Travail en cours (toutes les listes)';

  @override
  String get statsMetricClX04Desc => 'Éléments terminés sur la période.';

  @override
  String get statsMetricClX04Formula =>
      'Achèvements finaux sur la période, comparés à la précédente.';

  @override
  String get statsMetricClX04Title => 'Éléments terminés';

  @override
  String get statsMetricClX05Desc =>
      'Éléments par statut dans toutes les listes.';

  @override
  String get statsMetricClX05Formula => 'Nombre d’éléments par statut.';

  @override
  String get statsMetricClX05Title => 'Répartition par statut';

  @override
  String get statsMetricGl01Desc =>
      'Votre journée, toutes sections : agenda, habitudes, listes et arrêts.';

  @override
  String get statsMetricGl01Formula =>
      'Mêmes chiffres que les indicateurs de chaque section pour aujourd’hui.';

  @override
  String get statsMetricGl01Title => 'Aujourd’hui';

  @override
  String get statsMetricGl02Desc =>
      'Cette semaine jusqu’ici vs les mêmes jours la semaine dernière.';

  @override
  String get statsMetricGl02Formula =>
      'Indicateurs des sections à date et leur évolution vs la semaine précédente.';

  @override
  String get statsMetricGl02Title => 'La semaine en bref';

  @override
  String get statsMetricGl03Desc =>
      'Votre semaine : chiffres clés, victoires, points d’attention et charge de la semaine suivante.';

  @override
  String get statsMetricGl03Formula =>
      'Indicateurs des sections et leur évolution vs la semaine précédente.';

  @override
  String get statsMetricGl03Title => 'Bilan hebdomadaire';

  @override
  String get statsMetricHbH01Desc =>
      'À quel point l’habitude est ancrée — les jours récents comptent plus.';

  @override
  String get statsMetricHbH01Formula =>
      'Score Loop : score = précédent × m + crédit × (1 − m), m = 0,5^(√f ÷ 13).';

  @override
  String get statsMetricHbH01Title => 'Force de l’habitude';

  @override
  String get statsMetricHbH02Desc =>
      'Unités réussies d’affilée jusqu’à maintenant ; aujourd’hui reste ouvert.';

  @override
  String get statsMetricHbH02Formula =>
      'Moteur de séries : passages, excuses, pauses et gels sont neutres.';

  @override
  String get statsMetricHbH02Title => 'Série actuelle';

  @override
  String get statsMetricHbH03Desc =>
      'Votre plus longue suite d’unités réussies.';

  @override
  String get statsMetricHbH03Formula =>
      'Longueur maximale de série, avec ses dates.';

  @override
  String get statsMetricHbH03Title => 'Meilleure série';

  @override
  String get statsMetricHbH04Desc => 'Vos dix plus longues séries.';

  @override
  String get statsMetricHbH04Formula =>
      'Séries triées par longueur puis par récence.';

  @override
  String get statsMetricHbH04Title => 'Meilleures séries';

  @override
  String get statsMetricHbH05Desc =>
      'Part des unités prévues que vous avez réussies.';

  @override
  String get statsMetricHbH05Formula =>
      'Réussies ÷ (unités prévues closes − excusées) ; intervalle de Wilson sous 20 unités.';

  @override
  String get statsMetricHbH05Title => 'Taux de réussite';

  @override
  String get statsMetricHbH06Desc =>
      'Comment chaque unité prévue s’est terminée.';

  @override
  String get statsMetricHbH06Formula =>
      'Nombre d’unités réussies, partielles, non faites, manquées, passées et excusées.';

  @override
  String get statsMetricHbH06Title => 'Bilan des résultats';

  @override
  String get statsMetricHbH07Desc =>
      'Réussites (et volume) par semaine, mois ou année.';

  @override
  String get statsMetricHbH07Formula => 'Sommes par tranche.';

  @override
  String get statsMetricHbH07Title => 'Historique';

  @override
  String get statsMetricHbH08Desc => 'Statut de chaque jour.';

  @override
  String get statsMetricHbH08Formula =>
      'Une case par jour : fait, partiel, non fait, manqué, passé, excusé, en pause, gelé.';

  @override
  String get statsMetricHbH08Title => 'Calendrier';

  @override
  String get statsMetricHbH09Desc =>
      'Chaque validation est un vote pour la personne que vous voulez être.';

  @override
  String get statsMetricHbH09Formula =>
      'Nombre total de validations manuelles (faites et progression).';

  @override
  String get statsMetricHbH09Title => 'Répétitions totales';

  @override
  String get statsMetricHbH10Desc =>
      'Part de l’objectif de la période atteinte.';

  @override
  String get statsMetricHbH10Formula =>
      'Réalisé ÷ (objectif quotidien × jours prévus − jours passés).';

  @override
  String get statsMetricHbH10Title => 'Progression vers l’objectif';

  @override
  String get statsMetricHbH11Desc =>
      'Tout ce que vous avez enregistré, dans l’unité de l’habitude.';

  @override
  String get statsMetricHbH11Formula =>
      'Somme des valeurs enregistrées sur la période et au total.';

  @override
  String get statsMetricHbH11Title => 'Volume total';

  @override
  String get statsMetricHbX01Desc => 'Habitudes prévues réalisées aujourd’hui.';

  @override
  String get statsMetricHbX01Formula =>
      'Faites ÷ prévues aujourd’hui (habitudes à construire).';

  @override
  String get statsMetricHbX01Title => 'Progression du jour';

  @override
  String get statsMetricHbX02Desc =>
      'Jours où toutes les habitudes prévues ont été faites.';

  @override
  String get statsMetricHbX02Formula =>
      'Jours où toutes les unités dues sont faites ; série de journées parfaites.';

  @override
  String get statsMetricHbX02Title => 'Journées parfaites';

  @override
  String get statsMetricHbX03Desc =>
      'Part des habitudes de chaque jour réalisée.';

  @override
  String get statsMetricHbX03Formula =>
      'Par jour : faites ÷ prévues, toutes habitudes.';

  @override
  String get statsMetricHbX03Title => 'Réalisation quotidienne';

  @override
  String get statsMetricHbX04Desc =>
      'Taux de réussite hebdomadaire de toutes les habitudes.';

  @override
  String get statsMetricHbX04Formula =>
      'Faites ÷ prévues par semaine, moyenne glissante 4 semaines ; Δ vs semaine précédente.';

  @override
  String get statsMetricHbX04Title => 'Tendance d’assiduité';

  @override
  String get statsMetricHbX05Desc =>
      'Argent économisé, unités évitées et vie regagnée, tous arrêts confondus.';

  @override
  String get statsMetricHbX05Formula =>
      'Sommes sur les suivis d’arrêt actifs (la vie regagnée est une estimation).';

  @override
  String get statsMetricHbX05Title => 'Bilan des arrêts';

  @override
  String get statsMetricPlS01Desc =>
      'Nombre d’échéances de la série sur la période.';

  @override
  String get statsMetricPlS01Formula =>
      'Occurrences de la règle dans la fenêtre ; closes et ouvertes comptées à part.';

  @override
  String get statsMetricPlS01Title => 'Occurrences attendues';

  @override
  String get statsMetricPlS02Desc =>
      'Répartition des occurrences de la série par résultat.';

  @override
  String get statsMetricPlS02Formula =>
      'Nombre d’occurrences faites (D), manquées (M), passées (K) et excusées (X).';

  @override
  String get statsMetricPlS02Title => 'Faits, manqués, passés';

  @override
  String get statsMetricPlS03Desc =>
      'Part des occurrences dues que vous avez réalisées.';

  @override
  String get statsMetricPlS03Formula =>
      'Faits ÷ (attendus − excusés), avec moyenne glissante sur 4 semaines et tendance hebdomadaire.';

  @override
  String get statsMetricPlS03Title => 'Assiduité';

  @override
  String get statsMetricPlS04Desc =>
      'Part des occurrences dues manquées ou non faites.';

  @override
  String get statsMetricPlS04Formula =>
      '(Manqués + non faits) ÷ (attendus − excusés).';

  @override
  String get statsMetricPlS04Title => 'Taux d’oubli';

  @override
  String get statsMetricPlS05Desc =>
      'Occurrences réalisées d’affilée ; les passages sont neutres par défaut.';

  @override
  String get statsMetricPlS05Formula =>
      'Moteur de séries, une unité par occurrence.';

  @override
  String get statsMetricPlS05Title => 'Série actuelle et record';

  @override
  String get statsMetricPlS06Desc =>
      'Temps suivi et prévu cumulé depuis le début de la série.';

  @override
  String get statsMetricPlS06Formula =>
      'Totaux cumulés des minutes réelles et prévues.';

  @override
  String get statsMetricPlS06Title => 'Temps investi';

  @override
  String get statsMetricPlS07Desc => 'Nombre total d’occurrences réalisées.';

  @override
  String get statsMetricPlS07Formula => 'Nombre d’occurrences faites.';

  @override
  String get statsMetricPlS07Title => 'Total réalisé';

  @override
  String get statsMetricPlS08Desc =>
      'Jours depuis la dernière occurrence réalisée.';

  @override
  String get statsMetricPlS08Formula =>
      'Aujourd’hui − date de la dernière réalisation.';

  @override
  String get statsMetricPlS08Title => 'Dernière réalisation';

  @override
  String get statsMetricPlS09Desc => 'Résultat de chaque jour pour la série.';

  @override
  String get statsMetricPlS09Formula =>
      'Pire résultat du jour : manqué > partiel > en retard > passé > fait > excusé.';

  @override
  String get statsMetricPlS09Title => 'Calendrier des résultats';

  @override
  String get statsMetricPlT01Desc => 'Durée prévue pour cette occurrence.';

  @override
  String get statsMetricPlT01Formula => 'Fin prévue − début prévu.';

  @override
  String get statsMetricPlT01Title => 'Durée prévue';

  @override
  String get statsMetricPlT02Desc =>
      'Temps réellement suivi sur cette occurrence, pauses exclues.';

  @override
  String get statsMetricPlT02Formula =>
      'Somme des sessions suivies ; inconnue si rien n’a été suivi.';

  @override
  String get statsMetricPlT02Title => 'Durée réelle';

  @override
  String get statsMetricPlT03Desc =>
      'Différence entre temps réel et prévu, et leur rapport.';

  @override
  String get statsMetricPlT03Formula =>
      'Réel − prévu ; rapport R = réel ÷ prévu (si prévu ≥ 5 min).';

  @override
  String get statsMetricPlT03Title => 'Écart de durée';

  @override
  String get statsMetricPlT04Desc =>
      'Avance ou retard du démarrage par rapport au plan.';

  @override
  String get statsMetricPlT04Formula =>
      'Début de la 1re session − début prévu ; à l’heure dans la marge de tolérance.';

  @override
  String get statsMetricPlT04Title => 'Retard au démarrage';

  @override
  String get statsMetricPlT05Desc =>
      'Avance ou retard de la fin de l’occurrence.';

  @override
  String get statsMetricPlT05Formula =>
      'Achèvement (ou fin de la dernière session) − fin prévue.';

  @override
  String get statsMetricPlT05Title => 'Retard de fin';

  @override
  String get statsMetricPlT06Desc => 'Ce qu’il est advenu de cette occurrence.';

  @override
  String get statsMetricPlT06Formula =>
      'Fait à l’heure, en retard, partiel, passé, manqué, annulé, en attente ou à venir.';

  @override
  String get statsMetricPlT06Title => 'Résultat';

  @override
  String get statsMetricPlT07Desc =>
      'Depuis combien de temps une occurrence non terminée est en retard.';

  @override
  String get statsMetricPlT07Formula =>
      'Maintenant − fin prévue, par tranches 1 / 7 / 14 / 30+ jours.';

  @override
  String get statsMetricPlT07Title => 'Ancienneté du retard';

  @override
  String get statsMetricPlX01Desc =>
      'Part de ce qui était prévu en début de période que vous avez réalisé.';

  @override
  String get statsMetricPlX01Formula =>
      'Prévus et faits dans la période ÷ prévus au début de la période ; les ajouts ultérieurs sont exclus.';

  @override
  String get statsMetricPlX01Title => 'Réalisation du plan';

  @override
  String get statsMetricPlX02Desc => 'Tâches prévues et réalisées chaque jour.';

  @override
  String get statsMetricPlX02Formula =>
      'Par jour : nombre prévu (plan initial) et fait.';

  @override
  String get statsMetricPlX02Title => 'Faits vs prévus par jour';

  @override
  String get statsMetricPlX03Desc =>
      'Tâches ajoutées après le début de la période et tâches déplacées hors ou dans la période.';

  @override
  String get statsMetricPlX03Formula =>
      'Nombre d’ajouts imprévus, d’occurrences sorties et entrées.';

  @override
  String get statsMetricPlX03Title => 'Imprévus et déplacés';

  @override
  String get statsMetricPlX04Desc =>
      'Tâches créées vs réalisées chaque semaine, et backlog ouvert.';

  @override
  String get statsMetricPlX04Formula =>
      'Créées et réalisées par semaine ; backlog = tâches non planifiées + occurrences en retard.';

  @override
  String get statsMetricPlX04Title => 'Flux du backlog';

  @override
  String get statsMetricPlX05Desc =>
      'Part des tâches réalisées avant leur fin prévue.';

  @override
  String get statsMetricPlX05Formula =>
      'Faites à l’heure ÷ faites (marge de tolérance incluse).';

  @override
  String get statsMetricPlX05Title => 'Réalisation à l’heure';

  @override
  String get statsMetricPlX06Desc =>
      'Tâches non terminées dont la fin prévue est dépassée, par ancienneté.';

  @override
  String get statsMetricPlX06Formula =>
      'Occurrences ouvertes en retard, par tranches 1 / 7 / 14 / 30+ jours.';

  @override
  String get statsMetricPlX06Title => 'En retard maintenant';

  @override
  String get statsMetricPlX07Desc =>
      'Temps disponible pour le travail planifié sur la période.';

  @override
  String get statsMetricPlX07Formula =>
      'Heures de travail par jour moins les blocs indisponibles, sur la période.';

  @override
  String get statsMetricPlX07Title => 'Capacité';

  @override
  String get statsMetricPlX08Desc =>
      'Part de votre capacité occupée par des tâches prévues.';

  @override
  String get statsMetricPlX08Formula =>
      'Minutes prévues dans les heures de travail ÷ capacité (peut dépasser 100 %).';

  @override
  String get statsMetricPlX08Title => 'Taux de charge prévu';

  @override
  String get statsMetricPlX09Desc =>
      'Part de votre capacité consacrée au travail suivi.';

  @override
  String get statsMetricPlX09Formula =>
      'Minutes suivies dans les heures de travail ÷ capacité ; requiert 60 % de suivi.';

  @override
  String get statsMetricPlX09Title => 'Taux de charge réel';

  @override
  String get statsMetricPlX10Desc =>
      'Jours où plus est prévu que le temps disponible.';

  @override
  String get statsMetricPlX10Formula =>
      'Jours où la charge prévue > capacité ; dépassement = charge − capacité.';

  @override
  String get statsMetricPlX10Title => 'Jours surchargés';

  @override
  String get statsMetricPlX11Desc =>
      'Capacité restante d’ici la fin de la période.';

  @override
  String get statsMetricPlX11Formula =>
      'Capacité restante − temps prévu restant (à partir de maintenant).';

  @override
  String get statsMetricPlX11Title => 'Temps libre restant';

  @override
  String get statsMetricPlX12Desc =>
      'Temps prévu et suivi par jour et par catégorie.';

  @override
  String get statsMetricPlX12Formula =>
      'Somme des minutes prévues vs somme des minutes suivies.';

  @override
  String get statsMetricPlX12Title => 'Heures prévues vs réelles';

  @override
  String get statsMetricPlX13Desc => 'Où va votre temps, par catégorie.';

  @override
  String get statsMetricPlX13Formula =>
      'Minutes suivies par catégorie (prévues si le suivi couvre < 60 %) ; part du total.';

  @override
  String get statsMetricPlX13Title => 'Temps par catégorie';

  @override
  String get statsMetricPlX14Desc => 'Temps hebdomadaire par catégorie.';

  @override
  String get statsMetricPlX14Formula => 'Minutes par catégorie et par semaine.';

  @override
  String get statsMetricPlX14Title => 'Tendance par catégorie';

  @override
  String get statsMetricPlX15Desc =>
      'Part du temps prévu occupée par des événements plutôt que des tâches.';

  @override
  String get statsMetricPlX15Formula =>
      'Minutes d’événements ÷ (minutes d’événements + de tâches).';

  @override
  String get statsMetricPlX15Title => 'Événements vs tâches';

  @override
  String get statsMetricQt01Desc => 'Temps écoulé depuis votre date d’arrêt.';

  @override
  String get statsMetricQt01Formula => 'Maintenant − date d’arrêt (en direct).';

  @override
  String get statsMetricQt01Title => 'Depuis l’arrêt';

  @override
  String get statsMetricQt02Desc =>
      'Temps depuis la dernière consommation (ou l’arrêt).';

  @override
  String get statsMetricQt02Formula =>
      'Maintenant − max(date d’arrêt, dernière consommation) (en direct).';

  @override
  String get statsMetricQt02Title => 'Abstinence actuelle';

  @override
  String get statsMetricQt03Desc => 'Votre plus longue période sans consommer.';

  @override
  String get statsMetricQt03Formula =>
      'Plus long écart entre l’arrêt, les consommations et maintenant.';

  @override
  String get statsMetricQt03Title => 'Plus longue abstinence';

  @override
  String get statsMetricQt04Desc =>
      'Jours depuis l’arrêt sans aucune consommation.';

  @override
  String get statsMetricQt04Formula =>
      'Nombre de jours clos sans consommation.';

  @override
  String get statsMetricQt04Title => 'Jours d’abstinence';

  @override
  String get statsMetricQt05Desc =>
      'Part des jours sans consommation depuis l’arrêt.';

  @override
  String get statsMetricQt05Formula =>
      'Jours d’abstinence ÷ jours clos depuis l’arrêt.';

  @override
  String get statsMetricQt05Title => 'Part de jours d’abstinence';

  @override
  String get statsMetricQt06Desc => 'Unités non consommées grâce à l’arrêt.';

  @override
  String get statsMetricQt06Formula =>
      'Référence par jour × jours − unités consommées (minimum 0).';

  @override
  String get statsMetricQt06Title => 'Unités évitées';

  @override
  String get statsMetricQt07Desc => 'Argent non dépensé grâce à l’arrêt.';

  @override
  String get statsMetricQt07Formula =>
      'Unités évitées chaque jour × coût unitaire en vigueur ce jour-là.';

  @override
  String get statsMetricQt07Title => 'Argent économisé';

  @override
  String get statsMetricQt08Desc =>
      'Argent dépensé en consommations depuis l’arrêt.';

  @override
  String get statsMetricQt08Formula =>
      'Unités consommées × coût unitaire du moment.';

  @override
  String get statsMetricQt08Title => 'Dépensé lors des écarts';

  @override
  String get statsMetricQt09Desc => 'Ce que vous économiserez en continuant.';

  @override
  String get statsMetricQt09Formula =>
      'Référence actuelle × coût unitaire sur 1 mois, 1 an et 5 ans.';

  @override
  String get statsMetricQt09Title => 'Projection d’économies';

  @override
  String get statsMetricQt10Desc =>
      'Estimation populationnelle de l’espérance de vie regagnée — pas une prédiction personnelle.';

  @override
  String get statsMetricQt10Formula =>
      'Unités évitées × minutes de vie par unité (≈ 20 min par cigarette, Jackson et al. 2025).';

  @override
  String get statsMetricQt10Title => 'Vie regagnée';

  @override
  String get statsMetricQt11Desc =>
      'Étapes de récupération typiques après la dernière cigarette.';

  @override
  String get statsMetricQt11Formula =>
      'Progression = abstinence actuelle ÷ délai de l’étape ; le compteur redémarre après un écart.';

  @override
  String get statsMetricQt11Title => 'Étapes santé';

  @override
  String get statsMetricQt12Desc =>
      'À quelle fréquence vous êtes resté sous la limite, et combien vous avez réduit.';

  @override
  String get statsMetricQt12Formula =>
      'Jours sous la limite ÷ jours ; réduction = 1 − consommation moyenne ÷ référence.';

  @override
  String get statsMetricQt12Title => 'Progrès de réduction';

  @override
  String get statsMetricQt13Desc => 'Fréquence et intensité des envies.';

  @override
  String get statsMetricQt13Formula =>
      'Envies par jour sur la période ; intensité moyenne et maximale ; moyenne glissante 7 jours.';

  @override
  String get statsMetricQt13Title => 'Charge d’envies';

  @override
  String get statsMetricQt14Desc => 'Ce qui déclenche les envies, où et quand.';

  @override
  String get statsMetricQt14Formula =>
      'Pareto par déclencheur, lieu et humeur ; matrice jour × heure.';

  @override
  String get statsMetricQt14Title => 'Contexte des envies';

  @override
  String get statsNoteAbstainMode =>
      'Uniquement pour les suivis en mode réduction.';

  @override
  String get statsNoteAllDay => 'Les tâches sur la journée n’ont pas de durée.';

  @override
  String get statsNoteClosed => 'Cet élément est clos.';

  @override
  String get statsNoteError => 'Calcul impossible';

  @override
  String get statsNoteLimitHabit =>
      'Les habitudes à limite affichent plutôt les jours sous la limite.';

  @override
  String get statsNoteLowCoverage =>
      'Suivez le temps d’au moins 60 % des tâches faites pour voir ceci.';

  @override
  String get statsNoteNew => 'Nouveau';

  @override
  String get statsNoteNoData => 'Pas encore de données';

  @override
  String get statsNoteNoGoal => 'Aucun objectif défini';

  @override
  String get statsNoteNoHabit => 'Habitude introuvable.';

  @override
  String get statsNoteNoItem => 'Élément introuvable.';

  @override
  String get statsNoteNoLifeEstimate =>
      'Indiquez les minutes de vie par unité pour voir cette estimation.';

  @override
  String get statsNoteNoOccurrence => 'Occurrence introuvable.';

  @override
  String get statsNoteNoQuitTrackers => 'Aucun suivi d’arrêt pour l’instant.';

  @override
  String get statsNoteNoTracker => 'Suivi d’arrêt introuvable.';

  @override
  String get statsNoteNoUnitCost =>
      'Indiquez un coût unitaire pour voir les économies.';

  @override
  String get statsNoteNotApplicable => 'Sans objet';

  @override
  String get statsNoteNotDone => 'Pas encore fait';

  @override
  String get statsNoteNotOverdue => 'Pas en retard';

  @override
  String get statsNoteNotScheduled => 'Non planifié';

  @override
  String get statsNoteNotSmoking =>
      'Les étapes santé ne concernent que l’arrêt du tabac.';

  @override
  String get statsNoteNotStarted => 'Pas démarré';

  @override
  String get statsNoteNotTracked => 'Temps réel non suivi';

  @override
  String get statsNotePastPeriod =>
      'Uniquement pour les périodes en cours ou à venir.';

  @override
  String get statsNotePopulationEstimate => 'Estimation populationnelle';

  @override
  String get statsNoteUsedPlanned =>
      'Temps prévu affiché : le temps réel est suivi sur moins de 60 % des tâches faites.';

  @override
  String get statsNoteYesNoHabit => 'Indisponible pour les habitudes oui/non.';

  @override
  String get statsNoteZeroDenominator =>
      'Rien n’était prévu sur cette période.';

  @override
  String statsOpenInsights(String section) {
    return 'Ouvrir $section';
  }

  @override
  String statsOverviewNextUp(String title, String time) {
    return 'À suivre : $title à $time';
  }

  @override
  String get statsOverviewOpenReview => 'Bilan hebdomadaire';

  @override
  String get statsPeriodAll => 'Tout';

  @override
  String get statsPeriodCustom => 'Personnalisé';

  @override
  String statsPeriodCustomRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get statsPeriodLastMonth => 'Mois dernier';

  @override
  String get statsPeriodLastQuarter => 'Trimestre dernier';

  @override
  String get statsPeriodLastWeek => 'Semaine dernière';

  @override
  String get statsPeriodLastYear => 'Année dernière';

  @override
  String get statsPeriodMonth => 'Mois';

  @override
  String get statsPeriodQuarter => 'Trimestre';

  @override
  String statsPeriodRolling(String days) {
    return '$days derniers jours';
  }

  @override
  String get statsPeriodRollingMenu => 'Glissant';

  @override
  String statsPeriodSelected(String period) {
    return 'Période : $period';
  }

  @override
  String get statsPeriodToday => 'Aujourd’hui';

  @override
  String get statsPeriodWeek => 'Semaine';

  @override
  String get statsPeriodYear => 'Année';

  @override
  String get statsPeriodYesterday => 'Hier';

  @override
  String get statsQuitMilestoneBreathing72h =>
      'La respiration devient plus facile ; l’énergie augmente';

  @override
  String get statsQuitMilestoneCancers20y =>
      'Risque de cancers bouche, gorge, larynx et pancréas proche d’un non-fumeur';

  @override
  String get statsQuitMilestoneChd15y =>
      'Risque coronarien proche de celui d’un non-fumeur';

  @override
  String get statsQuitMilestoneChdAdded =>
      'Le risque coronarien supplémentaire est divisé par deux';

  @override
  String get statsQuitMilestoneCirculation =>
      'La circulation et la fonction pulmonaire s’améliorent';

  @override
  String get statsQuitMilestoneCo12h =>
      'Monoxyde de carbone sanguin revenu à la normale';

  @override
  String get statsQuitMilestoneCo8h =>
      'Le monoxyde de carbone sanguin est divisé par deux ; l’oxygène remonte';

  @override
  String get statsQuitMilestoneCravings =>
      'Les envies s’atténuent généralement (une envie dure environ 3 à 5 min)';

  @override
  String get statsQuitMilestoneHeart20m =>
      'La fréquence cardiaque et la tension baissent ; le pouls redevient normal';

  @override
  String get statsQuitMilestoneHeartAttack =>
      'Le risque d’infarctus chute fortement';

  @override
  String get statsQuitMilestoneHeartHalf1y =>
      'Risque coronarien environ moitié de celui d’un fumeur';

  @override
  String get statsQuitMilestoneLifeExpectancy =>
      'Arrêter à 30 / 40 / 50 / 60 ans fait gagner environ 10 / 9 / 6 / 3 ans d’espérance de vie';

  @override
  String get statsQuitMilestoneLungCancer10y =>
      'Risque de cancer du poumon environ moitié de celui d’un fumeur';

  @override
  String get statsQuitMilestoneLungs =>
      'Toux et essoufflement diminuent ; fonction pulmonaire jusqu’à ~10 % meilleure';

  @override
  String get statsQuitMilestoneMouthCancer =>
      'Le risque de cancers de la bouche, de la gorge et du larynx diminue de moitié ; le risque d’AVC baisse';

  @override
  String get statsQuitMilestoneNicotine24h => 'La nicotine disparaît du sang';

  @override
  String get statsQuitMilestoneTaste48h =>
      'Les poumons évacuent le mucus ; le goût et l’odorat s’améliorent';

  @override
  String statsReviewAtRisk(String title) {
    return 'À risque : $title';
  }

  @override
  String statsReviewBlocked(String title) {
    return 'Bloqué ou en attente : $title';
  }

  @override
  String statsReviewFollowUp(String title) {
    return 'Relance en retard : $title';
  }

  @override
  String get statsReviewHeadline => 'Chiffres clés';

  @override
  String statsReviewHealth(String title) {
    return 'Étape santé atteinte : $title';
  }

  @override
  String get statsReviewLastWeek => 'Semaine dernière';

  @override
  String statsReviewLoad(String planned, String capacity) {
    return '$planned prévus sur $capacity';
  }

  @override
  String get statsReviewNextWeek => 'Semaine prochaine';

  @override
  String get statsReviewNothing => 'Rien cette semaine.';

  @override
  String statsReviewOverbooked(String date, String time) {
    return '$date est surchargé de $time';
  }

  @override
  String statsReviewOverdue(String title) {
    return 'En retard : $title';
  }

  @override
  String statsReviewPerfectDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count journées parfaites',
      one: '1 journée parfaite',
    );
    return '$_temp0';
  }

  @override
  String statsReviewRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String statsReviewRecord(String title) {
    return 'Nouveau record : $title';
  }

  @override
  String statsReviewStale(String title) {
    return 'Aucune activité récente : $title';
  }

  @override
  String statsReviewStreak(String title, String count) {
    return '$title : série de $count jours';
  }

  @override
  String get statsReviewThisWeek => 'Cette semaine jusqu’ici';

  @override
  String get statsReviewTime => 'Où est passé le temps';

  @override
  String get statsScopeChecklist => 'Statistiques de la liste';

  @override
  String get statsScopeChecklists => 'Statistiques des listes';

  @override
  String get statsScopeGlobal => 'Vue d’ensemble';

  @override
  String get statsScopeHabit => 'Statistiques de l’habitude';

  @override
  String get statsScopeHabits => 'Statistiques des habitudes';

  @override
  String get statsScopeItem => 'Statistiques de l’élément';

  @override
  String get statsScopePlanner => 'Statistiques du plan';

  @override
  String get statsScopeQuit => 'Statistiques de l’arrêt';

  @override
  String get statsScopeReview => 'Bilan hebdomadaire';

  @override
  String get statsScopeSeries => 'Statistiques de la série';

  @override
  String get statsScopeTask => 'Statistiques de la tâche';

  @override
  String get statsScopeYear => 'L’année en revue';

  @override
  String get statsSectionAbstinence => 'Abstinence';

  @override
  String get statsSectionAdvanced => 'Avancé';

  @override
  String get statsSectionAllocation => 'Répartition du temps';

  @override
  String get statsSectionCalendar => 'Calendrier';

  @override
  String get statsSectionCapacity => 'Capacité';

  @override
  String statsSectionCollapse(String section) {
    return 'Replier $section';
  }

  @override
  String get statsSectionCravings => 'Envies';

  @override
  String get statsSectionExecution => 'Exécution';

  @override
  String statsSectionExpand(String section) {
    return 'Déplier $section';
  }

  @override
  String get statsSectionFlow => 'Flux';

  @override
  String get statsSectionFocus => 'Concentration et équilibre';

  @override
  String get statsSectionHabitTable => 'Vos habitudes';

  @override
  String get statsSectionHistory => 'Historique';

  @override
  String get statsSectionItem => 'Cet élément';

  @override
  String get statsSectionLists => 'Listes';

  @override
  String get statsSectionMilestones => 'Étapes santé';

  @override
  String get statsSectionMoney => 'Argent et unités';

  @override
  String get statsSectionOccurrence => 'Cette occurrence';

  @override
  String get statsSectionOutcomes => 'Résultats';

  @override
  String get statsSectionPatterns => 'Tendances';

  @override
  String get statsSectionPinned => 'Épinglées';

  @override
  String get statsSectionPlanning => 'Planification';

  @override
  String get statsSectionPlanningQuality => 'Qualité de planification';

  @override
  String get statsSectionQuality => 'Qualité';

  @override
  String get statsSectionQuitTrackers => 'Suivis d’arrêt';

  @override
  String get statsSectionReduction => 'Réduction';

  @override
  String get statsSectionReview => 'Bilan hebdomadaire';

  @override
  String get statsSectionSeries => 'Exécution';

  @override
  String get statsSectionShortcuts => 'Sections';

  @override
  String get statsSectionStale => 'Éléments inactifs';

  @override
  String get statsSectionStatus => 'Statut';

  @override
  String get statsSectionStreaks => 'Séries';

  @override
  String get statsSectionStrength => 'Force';

  @override
  String get statsSectionTargetVolume => 'Objectif et volume';

  @override
  String get statsSectionTiming => 'Horaires et habitudes';

  @override
  String get statsSectionToday => 'Aujourd’hui';

  @override
  String get statsSectionTrend => 'Tendance';

  @override
  String get statsSectionWeek => 'La semaine en bref';

  @override
  String get statsSeeAll => 'Voir toutes les statistiques';

  @override
  String get statsSeeSeries => 'Voir les statistiques de la série';

  @override
  String get statsSegmentHabits => 'Habitudes';

  @override
  String get statsSegmentLists => 'Listes';

  @override
  String get statsSegmentOverview => 'Vue d’ensemble';

  @override
  String get statsSegmentPlan => 'Plan';

  @override
  String get statsSegmentQuit => 'Arrêts';

  @override
  String get statsSourceAcs => 'American Cancer Society';

  @override
  String get statsSourceBmj2000 => 'Shaw et al., BMJ 2000';

  @override
  String get statsSourceCdc => 'CDC';

  @override
  String get statsSourceHse => 'HSE';

  @override
  String get statsSourceJackson2025 => 'Jackson et al., Addiction 2025';

  @override
  String get statsSourceNci => 'National Cancer Institute';

  @override
  String get statsSourceNhs => 'NHS';

  @override
  String get statsSourceWho => 'OMS';

  @override
  String get statsUnknownScope => 'Cette statistique n’existe pas.';

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
  String get tagAdd => 'Ajouter une étiquette';

  @override
  String tagChipSemantics(String name) {
    return 'Étiquette $name';
  }

  @override
  String tagCreateNamed(String name) {
    return 'Créer l’étiquette « $name »';
  }

  @override
  String tagDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Elle sera retirée de $count éléments.',
      one: 'Elle sera retirée d’1 élément.',
      zero: 'Cette étiquette n’est pas encore utilisée.',
    );
    return '$_temp0';
  }

  @override
  String get tagEdit => 'Modifier l’étiquette';

  @override
  String get tagErrorDuplicate => 'Une étiquette porte déjà ce nom.';

  @override
  String get tagErrorInvalid => 'Utilisez de 1 à 40 caractères.';

  @override
  String get tagMerge => 'Fusionner dans…';

  @override
  String get tagMergeAction => 'Fusionner';

  @override
  String tagMergeConfirmBody(String source, String target) {
    return 'Tout ce qui est étiqueté « $source » sera étiqueté « $target », puis « $source » sera supprimée.';
  }

  @override
  String get tagMergeConfirmTitle => 'Fusionner les étiquettes ?';

  @override
  String tagMergeTitle(String name) {
    return 'Fusionner « $name » dans';
  }

  @override
  String tagMergedSnack(String name) {
    return 'Fusionnée dans « $name »';
  }

  @override
  String get tagName => 'Nom de l’étiquette';

  @override
  String get tagNew => 'Nouvelle étiquette';

  @override
  String get tagNoColor => 'Sans couleur';

  @override
  String get tagPickerSearch => 'Rechercher ou créer une étiquette';

  @override
  String get tagPickerTitle => 'Étiquettes';

  @override
  String tagRemoveSemantics(String name) {
    return 'Retirer l’étiquette $name';
  }

  @override
  String tagUsage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
      zero: 'Non utilisée',
    );
    return '$_temp0';
  }

  @override
  String get tagsEmpty => 'Aucune étiquette';

  @override
  String get tagsEmptyHint =>
      'Les étiquettes traversent les sections — utilisez-les pour des contextes comme courses ou en attente d’autrui.';

  @override
  String get tagsTitle => 'Étiquettes';

  @override
  String get tagsUpdatedSnack => 'Étiquettes mises à jour';

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
