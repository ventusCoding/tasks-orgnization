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
  String get attachmentsChecklistLevel => 'Sur la liste';

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
  String get attachmentsFilterAll => 'Tout';

  @override
  String get attachmentsFilterImages => 'Images';

  @override
  String get attachmentsFilterOther => 'Autres';

  @override
  String get attachmentsFilterPdfs => 'PDF';

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
  String get checklistAddItem => 'Ajouter un élément';

  @override
  String get checklistAddSubItem => 'Ajouter un sous-élément';

  @override
  String get checklistAllAttachments => 'Toutes les pièces jointes';

  @override
  String get checklistAllLists => 'Toutes les listes';

  @override
  String get checklistAttach => 'Joindre';

  @override
  String checklistBelowBadges(int blocked, int waiting) {
    return '$blocked bloqué(s) · $waiting en attente dessous';
  }

  @override
  String get checklistBodyHint => 'Note';

  @override
  String checklistCarrying(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Déplacement de $count éléments',
      one: 'Déplacement de 1 élément',
    );
    return '$_temp0';
  }

  @override
  String get checklistCollapse => 'Replier';

  @override
  String get checklistCollapseAll => 'Tout replier';

  @override
  String get checklistCollapsedState => 'replié';

  @override
  String get checklistCompleted => 'Liste terminée !';

  @override
  String get checklistCompletedArchive => 'Archiver';

  @override
  String get checklistCompletedKeep => 'Garder';

  @override
  String get checklistCompletedReset => 'Réinitialiser';

  @override
  String get checklistCopied => 'Copié';

  @override
  String get checklistCopy => 'Copier';

  @override
  String get checklistCopyText => 'Copier en texte';

  @override
  String get checklistCut => 'Couper';

  @override
  String get checklistDelete => 'Supprimer la liste';

  @override
  String get checklistDeleteCompleted => 'Supprimer les éléments terminés';

  @override
  String get checklistDeleteItem => 'Supprimer';

  @override
  String checklistDepthBadge(int level) {
    return 'N$level';
  }

  @override
  String get checklistDetails => 'Détails';

  @override
  String get checklistDragHandle => 'Glisser pour déplacer';

  @override
  String get checklistDue => 'Échéance';

  @override
  String get checklistDuplicate => 'Dupliquer la liste';

  @override
  String get checklistDuplicateItem => 'Dupliquer';

  @override
  String get checklistEmptyFocus => 'Aucun sous-élément';

  @override
  String get checklistExpand => 'Déplier';

  @override
  String get checklistExpandAll => 'Tout déplier';

  @override
  String checklistExpandToLevel(int level) {
    return 'Déplier jusqu\'au niveau $level';
  }

  @override
  String get checklistFilterAll => 'Tous';

  @override
  String get checklistFilterDueSoon => 'Échéance proche';

  @override
  String get checklistFilterHasAttachments => 'Avec pièces jointes';

  @override
  String get checklistFilterOpen => 'Ouverts';

  @override
  String get checklistFilterText => 'Rechercher dans la liste';

  @override
  String get checklistFiltered => 'Vue filtrée';

  @override
  String get checklistFocus => 'Zoomer';

  @override
  String get checklistHideCheckboxes => 'Masquer les cases';

  @override
  String get checklistHideCompleted => 'Masquer les terminés';

  @override
  String get checklistHideKeyboard => 'Masquer le clavier';

  @override
  String get checklistImport => 'Importer des éléments…';

  @override
  String get checklistInTrash => 'Cette liste est dans la corbeille';

  @override
  String get checklistIndent => 'Augmenter le retrait';

  @override
  String get checklistInsights => 'Statistiques';

  @override
  String get checklistInsightsPlaceholder =>
      'Les statistiques de liste arrivent avec la section Statistiques.';

  @override
  String get checklistItemHint => 'Élément';

  @override
  String checklistItemsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments supprimés',
      one: '1 élément supprimé',
    );
    return '$_temp0';
  }

  @override
  String get checklistItemsMoved => 'Déplacé';

  @override
  String get checklistLabelName => 'Nom du libellé';

  @override
  String get checklistLabels => 'Libellés';

  @override
  String get checklistLineBreak => 'Saut de ligne';

  @override
  String get checklistLinkedTask => 'Tâche liée';

  @override
  String get checklistModeEdit => 'Modifier';

  @override
  String get checklistModePreview => 'Aperçu';

  @override
  String get checklistMoveConflict =>
      'Un déplacement était en conflit avec une modification sur un autre appareil et a été annulé.';

  @override
  String get checklistMoveDown => 'Descendre';

  @override
  String get checklistMoveTo => 'Déplacer vers…';

  @override
  String get checklistMoveUp => 'Monter';

  @override
  String get checklistNewLabel => 'Nouveau libellé';

  @override
  String get checklistNextOpen => 'Élément ouvert suivant';

  @override
  String get checklistNoItems => 'Aucun élément';

  @override
  String get checklistNoLabels => 'Aucun libellé';

  @override
  String get checklistNotFound => 'Cette liste n\'existe pas';

  @override
  String get checklistOpenTrash => 'Ouvrir la corbeille';

  @override
  String get checklistOutdent => 'Diminuer le retrait';

  @override
  String get checklistPaste => 'Coller';

  @override
  String get checklistPasteHere => 'Coller ici';

  @override
  String get checklistPendingUploads => 'Envois en attente';

  @override
  String checklistProgress(int done, int total) {
    return '$done sur $total terminés';
  }

  @override
  String get checklistPromote => 'Transformer en liste';

  @override
  String get checklistPromoted => 'Nouvelle liste créée';

  @override
  String get checklistRecovered => 'Récupéré';

  @override
  String get checklistRepeat => 'Répétition…';

  @override
  String get checklistResetConfirm =>
      'Tous les éléments reviennent à faire et les notes de raison sont effacées.';

  @override
  String get checklistResetDone => 'Liste réinitialisée';

  @override
  String get checklistResetNow => 'Réinitialiser maintenant';

  @override
  String get checklistResetStatuses => 'Réinitialiser tous les statuts';

  @override
  String get checklistResetView => 'Réinitialiser';

  @override
  String checklistRowSemantics(String text, int level, int index, int count) {
    return '$text, niveau $level, élément $index sur $count';
  }

  @override
  String get checklistSaveAsTemplate => 'Enregistrer comme modèle';

  @override
  String get checklistScheduleTask => 'Planifier comme tâche';

  @override
  String get checklistSelect => 'Sélectionner';

  @override
  String get checklistSelectAll => 'Tout sélectionner';

  @override
  String get checklistSelectSubtree => 'Sélectionner les sous-éléments';

  @override
  String checklistSelected(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get checklistSettings => 'Réglages de la liste';

  @override
  String get checklistShare => 'Partager / exporter';

  @override
  String get checklistShowCheckboxes => 'Afficher les cases';

  @override
  String get checklistSortAlpha => 'Alphabétique';

  @override
  String get checklistSortChildren => 'Trier les sous-éléments';

  @override
  String get checklistSortCompletedBottom => 'Terminés en bas';

  @override
  String get checklistSortDescending => 'Décroissant';

  @override
  String get checklistSortDue => 'Échéance';

  @override
  String get checklistSortFilter => 'Trier et filtrer';

  @override
  String get checklistSortManual => 'Manuel';

  @override
  String get checklistSortPriority => 'Priorité';

  @override
  String get checklistSortRecent => 'Modifiés récemment';

  @override
  String get checklistSortStatus => 'Statut';

  @override
  String checklistSortedBy(String criterion) {
    return 'Trié par $criterion';
  }

  @override
  String get checklistStatusChanged => 'Statut modifié';

  @override
  String checklistSubItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sous-éléments',
      one: '1 sous-élément',
    );
    return '$_temp0';
  }

  @override
  String get checklistTaskPlaceholder =>
      'Le lien avec les tâches arrive avec le planificateur.';

  @override
  String get checklistTemplateSaved => 'Enregistré comme modèle';

  @override
  String get checklistTitleHint => 'Titre';

  @override
  String get checklistUncheckAll => 'Tout décocher';

  @override
  String checklistUncheckConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Décocher $count éléments ?',
      one: 'Décocher 1 élément ?',
    );
    return '$_temp0';
  }

  @override
  String get checklistViewGallery => 'Galerie';

  @override
  String get checklistViewKanban => 'Kanban';

  @override
  String get checklistViewOutline => 'Plan';

  @override
  String get checklistZoomOut => 'Dézoomer';

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
  String get exportBranchOnly => 'Seulement cette branche';

  @override
  String get exportCopied => 'Copié dans le presse-papiers';

  @override
  String get exportCopy => 'Copier dans le presse-papiers';

  @override
  String get exportMarkdown => 'Markdown';

  @override
  String get exportOpml => 'OPML';

  @override
  String get exportPlain => 'Texte brut';

  @override
  String get exportShare => 'Partager…';

  @override
  String get exportTitle => 'Partager / exporter';

  @override
  String get galleryEmpty => 'Aucun élément avec image';

  @override
  String get galleryOnlyImages => 'Seulement avec images';

  @override
  String get importAction => 'Importer';

  @override
  String get importChooseFile => 'Choisir un fichier';

  @override
  String get importConvertBody => 'Convertir la note en éléments';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments importés',
      one: '1 élément importé',
    );
    return '$_temp0';
  }

  @override
  String importItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
    );
    return '$_temp0';
  }

  @override
  String get importKeepOne => 'Garder en un seul élément';

  @override
  String get importPasteHint =>
      'Collez du texte indenté, du Markdown ou de l\'OPML';

  @override
  String get importSplit => 'Découper en éléments (garder l\'imbrication)';

  @override
  String get importTitle => 'Importer';

  @override
  String get importWarningAttachments =>
      'Les références de pièces jointes ont été ignorées';

  @override
  String get importWarningEmpty => 'Rien à importer';

  @override
  String get importWarningMalformed => 'Impossible de lire ce fichier';

  @override
  String get importWarningTooMany =>
      'Seules les 10 000 premières lignes ont été importées';

  @override
  String get itemAddReminder => 'Ajouter un rappel';

  @override
  String get itemAddTime => 'Ajouter une heure';

  @override
  String get itemAttachments => 'Pièces jointes';

  @override
  String get itemClearDue => 'Supprimer l\'échéance';

  @override
  String itemCompletedOn(String date) {
    return 'Terminé $date';
  }

  @override
  String itemCreated(String date) {
    return 'Créé $date';
  }

  @override
  String get itemDetailsTitle => 'Détails de l\'élément';

  @override
  String get itemDue => 'Échéance';

  @override
  String get itemDueOverdue => 'En retard';

  @override
  String get itemDueToday => 'Aujourd\'hui';

  @override
  String get itemDueTomorrow => 'Demain';

  @override
  String itemEdited(String date) {
    return 'Modifié $date';
  }

  @override
  String get itemHistory => 'Historique';

  @override
  String get itemHistoryCause => 'automatique';

  @override
  String itemHistoryDevice(String device) {
    return 'sur $device';
  }

  @override
  String get itemHistoryEmpty => 'Aucun changement de statut';

  @override
  String itemHistoryTransition(String from, String to) {
    return '$from → $to';
  }

  @override
  String get itemInsights => 'Statistiques';

  @override
  String get itemNoDue => 'Pas d\'échéance';

  @override
  String get itemNote => 'Note';

  @override
  String get itemOtherDevice => 'un autre appareil';

  @override
  String get itemPriority => 'Priorité';

  @override
  String get itemReminders => 'Rappels';

  @override
  String get itemRemindersPlaceholder =>
      'Les rappels de cet élément se régleront ici.';

  @override
  String get itemText => 'Texte';

  @override
  String get itemThisDevice => 'cet appareil';

  @override
  String get itemTimeInStatus => 'Temps par statut';

  @override
  String get kanbanAll => 'Tous les éléments';

  @override
  String get kanbanChildren => 'Sous-éléments directs';

  @override
  String get kanbanEmptyColumn => 'Déposer des éléments ici';

  @override
  String get kanbanLeaves => 'Feuilles seulement';

  @override
  String get kanbanScope => 'Afficher';

  @override
  String get kanbanShowCancelled => 'Afficher les annulés';

  @override
  String get listsArchive => 'Archives';

  @override
  String get listsArchiveAction => 'Archiver';

  @override
  String get listsArchiveEmpty => 'Aucune liste archivée';

  @override
  String get listsArchived => 'Liste archivée';

  @override
  String listsBadgeBlocked(int count) {
    return '$count bloqué(s)';
  }

  @override
  String listsBadgeStale(int count) {
    return '$count en sommeil';
  }

  @override
  String listsBadgeWaiting(int count) {
    return '$count en attente';
  }

  @override
  String get listsBoardSort => 'Trier les cartes';

  @override
  String get listsBoardSortManual => 'Manuel';

  @override
  String get listsBoardSortRecent => 'Modifiées récemment';

  @override
  String get listsBoardSortTitle => 'Titre';

  @override
  String get listsCardActions => 'Actions de la liste';

  @override
  String listsCardMore(int count) {
    return '+$count de plus';
  }

  @override
  String listsCardProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String listsCardSemantics(String title, String progress) {
    return '$title, $progress';
  }

  @override
  String get listsColor => 'Couleur';

  @override
  String listsCopyOf(String title) {
    return 'Copie de $title';
  }

  @override
  String get listsDelete => 'Supprimer';

  @override
  String get listsDeleted => 'Liste supprimée';

  @override
  String get listsDragHint => 'Appui long puis glisser pour réorganiser';

  @override
  String get listsDuplicate => 'Dupliquer';

  @override
  String get listsDuplicated => 'Liste dupliquée';

  @override
  String get listsEmptyAction => 'Créer votre première liste';

  @override
  String get listsEmptyMessage =>
      'Listes, notes et routines — imbriquées aussi profondément que nécessaire.';

  @override
  String get listsEmptyTitle => 'Aucune liste pour l\'instant';

  @override
  String get listsFilterColor => 'Couleur';

  @override
  String get listsFilterHasAttachments => 'Avec pièces jointes';

  @override
  String get listsFilterHasBlocked => 'En attente ou bloqué';

  @override
  String get listsFilterPinned => 'Épinglées';

  @override
  String get listsFilterRepeating => 'Récurrentes';

  @override
  String get listsFromTemplate => 'Depuis un modèle';

  @override
  String get listsGridView => 'Vue grille';

  @override
  String get listsImportFile => 'Importer un fichier…';

  @override
  String get listsListView => 'Vue liste';

  @override
  String get listsMoveItems => 'Déplacer des éléments…';

  @override
  String get listsNewChecklist => 'Nouvelle liste';

  @override
  String get listsNewNote => 'Nouvelle note';

  @override
  String get listsOthers => 'Autres';

  @override
  String get listsPin => 'Épingler';

  @override
  String get listsPinned => 'Épinglées';

  @override
  String get listsPreferences => 'Réglages des listes';

  @override
  String get listsRepeats => 'Répétition';

  @override
  String get listsResetStatusesOption => 'Remettre tous les statuts à faire';

  @override
  String get listsSearchHint => 'Rechercher dans les listes';

  @override
  String get listsSearchItems => 'Éléments';

  @override
  String get listsSearchNoResults =>
      'Aucune liste ni aucun élément correspondant';

  @override
  String get listsShowBody => 'Afficher le texte des notes sur les cartes';

  @override
  String get listsShowSmartChips => 'Afficher les puces En attente / Bloqué';

  @override
  String get listsTemplates => 'Modèles';

  @override
  String get listsTrash => 'Corbeille';

  @override
  String get listsUnarchive => 'Désarchiver';

  @override
  String get listsUnarchived => 'Liste désarchivée';

  @override
  String get listsUnpin => 'Désépingler';

  @override
  String get listsUntitled => 'Sans titre';

  @override
  String get localOnlyBanner =>
      'La synchronisation cloud n\'est pas configurée — vos données restent sur cet appareil.';

  @override
  String get moveChooseParent => 'Choisir l\'emplacement';

  @override
  String moveDone(String title) {
    return 'Déplacé vers $title';
  }

  @override
  String get moveToList => 'Déplacer vers une liste';

  @override
  String get moveToTop => 'Niveau supérieur';

  @override
  String get notFoundTitle => 'Page introuvable';

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
  String repeatChip(String rule, String when) {
    return 'Réinit. $rule · prochaine $when';
  }

  @override
  String get repeatCustom => 'Règle personnalisée';

  @override
  String get repeatDaily => 'Tous les jours';

  @override
  String get repeatModeAll => 'Tout remettre à faire';

  @override
  String get repeatModeCompleted => 'Décocher seulement les terminés';

  @override
  String get repeatMonthly => 'Tous les mois';

  @override
  String get repeatNoRuns => 'Aucun cycle terminé';

  @override
  String get repeatNone => 'Ne se répète pas';

  @override
  String get repeatResetTime => 'Heure de réinitialisation';

  @override
  String repeatRunSummary(int done, int total) {
    return '$done/$total terminés';
  }

  @override
  String get repeatRuns => 'Historique des cycles';

  @override
  String get repeatTitle => 'Répétition';

  @override
  String get repeatWeekdays => 'Tous les jours ouvrés';

  @override
  String get repeatWeekly => 'Toutes les semaines';

  @override
  String get savedSnack => 'Enregistré';

  @override
  String get settingsAutoComplete => 'Terminer les parents automatiquement';

  @override
  String get settingsCascadeAlways => 'Terminer aussi les sous-éléments';

  @override
  String get settingsCascadeAsk => 'Demander';

  @override
  String get settingsCascadeNever => 'Laisser les sous-éléments';

  @override
  String get settingsCategory => 'Catégorie';

  @override
  String get settingsCompleteChildren => 'En terminant un parent';

  @override
  String get settingsDefaultOpen => 'Ouvrir en';

  @override
  String get settingsHideCheckboxes => 'Masquer les cases (puces)';

  @override
  String get settingsProgressChildren => 'Seulement les sous-éléments directs';

  @override
  String get settingsProgressLeaves => 'Tous les sous-éléments';

  @override
  String get settingsProgressMode => 'La progression compte';

  @override
  String get settingsRequireReason => 'Exiger une raison pour';

  @override
  String get settingsShowAttachments => 'Afficher les pièces jointes en aperçu';

  @override
  String get settingsShowNotes => 'Afficher les notes en aperçu';

  @override
  String get settingsSortCompleted => 'Terminés en bas';

  @override
  String settingsStaleDays(int days) {
    return 'En sommeil après $days jours';
  }

  @override
  String get settingsSwipeComplete => 'Terminer';

  @override
  String get settingsSwipeEditLeft => 'Mode édition · balayer à gauche';

  @override
  String get settingsSwipeEditRight => 'Mode édition · balayer à droite';

  @override
  String get settingsSwipeIndent => 'Retrait';

  @override
  String get settingsSwipeMenu => 'Menu d\'actions';

  @override
  String get settingsSwipeNone => 'Rien';

  @override
  String get settingsSwipeOutdent => 'Retrait arrière';

  @override
  String get settingsSwipePreviewLeft => 'Aperçu · balayer à gauche';

  @override
  String get settingsSwipePreviewRight => 'Aperçu · balayer à droite';

  @override
  String get settingsSwipeTitle => 'Actions de balayage';

  @override
  String get smartBlocked => 'Bloqué';

  @override
  String smartChip(String label, int count) {
    return '$label · $count';
  }

  @override
  String get smartClearFollowUp => 'Supprimer la relance';

  @override
  String get smartEmpty => 'Rien ici — parfait.';

  @override
  String get smartFollowUps => 'Relances';

  @override
  String get smartGroupByList => 'Grouper par liste';

  @override
  String get smartOngoing => 'En cours';

  @override
  String get smartOpenInList => 'Ouvrir dans la liste';

  @override
  String get smartSetFollowUp => 'Définir une relance';

  @override
  String get smartSortAge => 'Ancienneté';

  @override
  String get smartSortFollowUp => 'Relance';

  @override
  String get smartSortList => 'Liste';

  @override
  String get smartUnknown => 'Liste intelligente inconnue';

  @override
  String get smartWaiting => 'En attente';

  @override
  String get stateEmpty => 'Rien pour l\'instant';

  @override
  String get stateErrorBody => 'Veuillez réessayer.';

  @override
  String get stateErrorTitle => 'Un problème est survenu';

  @override
  String get stateLoading => 'Chargement…';

  @override
  String get statusAddNote => 'Ajouter une note…';

  @override
  String statusAgeDays(int n) {
    return '$n j';
  }

  @override
  String statusAgeHours(int n) {
    return '$n h';
  }

  @override
  String statusAgeMinutes(int n) {
    return '$n min';
  }

  @override
  String get statusBlocked => 'Bloqué';

  @override
  String get statusCancelled => 'Annulé';

  @override
  String get statusCascadeAll => 'Tout terminer';

  @override
  String get statusCascadeOnlyThis => 'Seulement celui-ci';

  @override
  String statusCascadeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Terminer aussi $count sous-éléments ouverts ?',
      one: 'Terminer aussi 1 sous-élément ouvert ?',
    );
    return '$_temp0';
  }

  @override
  String get statusChange => 'Changer le statut';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get statusFollowUp => 'Relancer';

  @override
  String statusFollowUpChip(String when) {
    return 'Relancer $when';
  }

  @override
  String get statusFollowUpCustom => 'Personnalisé…';

  @override
  String get statusFollowUpIn3Days => 'Dans 3 jours';

  @override
  String get statusFollowUpLaterToday => 'Plus tard aujourd\'hui';

  @override
  String get statusFollowUpNextWeek => 'La semaine prochaine';

  @override
  String get statusFollowUpNone => 'Pas de relance';

  @override
  String get statusFollowUpOverdue => 'À relancer';

  @override
  String get statusFollowUpTomorrow => 'Demain 09:00';

  @override
  String get statusKeepFollowUp => 'Garder la relance';

  @override
  String statusMarked(String status) {
    return 'Marqué $status';
  }

  @override
  String get statusOngoing => 'En cours';

  @override
  String get statusReasonBlocked => 'Qu\'est-ce qui bloque ?';

  @override
  String get statusReasonOther => 'Ajouter une note (facultatif)';

  @override
  String get statusReasonRequired => 'Une raison est requise';

  @override
  String get statusReasonWaiting => 'En attente de qui / quoi ?';

  @override
  String get statusRecentReasons => 'Récents';

  @override
  String get statusSheetTitle => 'Statut';

  @override
  String get statusStale => 'En sommeil';

  @override
  String get statusTodo => 'À faire';

  @override
  String get statusWaiting => 'En attente';

  @override
  String statusWithAge(String status, String age) {
    return '$status · $age';
  }

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
  String get templatesBuiltin => 'Intégrés';

  @override
  String get templatesCreated => 'Liste créée depuis le modèle';

  @override
  String get templatesEdit => 'Modifier le modèle';

  @override
  String get templatesEmpty =>
      'Enregistrez n\'importe quelle liste comme modèle depuis son menu.';

  @override
  String get templatesMine => 'Mes modèles';

  @override
  String get templatesRename => 'Renommer';

  @override
  String get templatesUse => 'Utiliser le modèle';
}
