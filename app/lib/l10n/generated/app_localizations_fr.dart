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
  String get activityArchived => 'Archivé';

  @override
  String activityAttachmentAdded(String name) {
    return 'Pièce jointe ajoutée : $name';
  }

  @override
  String activityAttachmentRemoved(String name) {
    return 'Pièce jointe retirée : $name';
  }

  @override
  String get activityCauseAutomatic => 'Automatique';

  @override
  String get activityCauseBulk => 'Modification groupée';

  @override
  String get activityCauseImport => 'Importé';

  @override
  String activityChangedFields(String fields) {
    return 'Modifié : $fields';
  }

  @override
  String get activityCompleted => 'Terminé';

  @override
  String get activityCreated => 'Créé';

  @override
  String get activityCreatedCopy => 'Créé par duplication';

  @override
  String get activityCreatedFromTemplate => 'Créé à partir d’un modèle';

  @override
  String get activityDeleted => 'Supprimé';

  @override
  String activityDeletedWithItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimé avec $count éléments',
      one: 'Supprimé avec 1 élément',
    );
    return '$_temp0';
  }

  @override
  String activityDurationChanged(String from, String to) {
    return 'Durée modifiée de $from à $to';
  }

  @override
  String get activityEdited => 'Modifié';

  @override
  String get activityEmpty => 'Aucun historique pour l’instant';

  @override
  String get activityFieldCategory => 'catégorie';

  @override
  String get activityFieldColor => 'couleur';

  @override
  String get activityFieldDue => 'échéance';

  @override
  String get activityFieldDuration => 'durée';

  @override
  String get activityFieldIcon => 'icône';

  @override
  String get activityFieldName => 'nom';

  @override
  String get activityFieldNotes => 'notes';

  @override
  String get activityFieldPriority => 'priorité';

  @override
  String get activityFieldRepeat => 'répétition';

  @override
  String get activityFieldTags => 'étiquettes';

  @override
  String get activityFieldText => 'texte';

  @override
  String get activityFieldTime => 'horaire';

  @override
  String get activityFieldTitle => 'titre';

  @override
  String get activityFile => 'fichier';

  @override
  String activityItemsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments ajoutés',
      one: '1 élément ajouté',
    );
    return '$_temp0';
  }

  @override
  String get activityListSeparator => ', ';

  @override
  String get activityMerged => 'Fusionné';

  @override
  String get activityMoved => 'Déplacé';

  @override
  String get activityMovedToList => 'Déplacé vers une autre liste';

  @override
  String get activityOther => 'Modifié';

  @override
  String get activityPaused => 'Mis en pause';

  @override
  String activityQuoted(String text) {
    return '« $text »';
  }

  @override
  String get activityRelapse => 'Rechute enregistrée';

  @override
  String get activityReopened => 'Rouvert';

  @override
  String activityRescheduled(String from, String to) {
    return 'Déplacé de $from à $to';
  }

  @override
  String get activityReset => 'Réinitialisé';

  @override
  String get activityRestored => 'Restauré';

  @override
  String get activityResumed => 'Repris';

  @override
  String get activityRollover => 'Reporté';

  @override
  String get activityScheduled => 'Planifié';

  @override
  String get activityScopeFollowing => 'Cette occurrence et les suivantes';

  @override
  String get activityScopeSeries => 'Toutes les occurrences';

  @override
  String get activitySeriesSplit => 'Série scindée';

  @override
  String get activitySkipped => 'Ignoré';

  @override
  String activitySkippedReason(String reason) {
    return 'Ignoré : $reason';
  }

  @override
  String get activitySorted => 'Éléments triés';

  @override
  String get activityStarted => 'Démarré';

  @override
  String activityStatusChanged(String from, String to) {
    return 'Statut changé de $from à $to';
  }

  @override
  String get activityStatusNoteChanged => 'Motif modifié';

  @override
  String activityStatusSet(String to) {
    return 'Statut défini sur $to';
  }

  @override
  String get activityStopped => 'Arrêté';

  @override
  String get activityTagsChanged => 'Étiquettes modifiées';

  @override
  String get activityTimeLogged => 'Temps enregistré';

  @override
  String get activityTitle => 'Historique';

  @override
  String get activityUnarchived => 'Désarchivé';

  @override
  String get activityUnscheduled => 'Replacé dans les tâches à planifier';

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
  String get attachmentsClipboardNoImage => 'Aucune image dans le presse-papiers';

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
  String get attachmentsDownloadWhenOnline => 'Ce fichier sera téléchargé lorsque vous serez en ligne.';

  @override
  String attachmentsDuration(String duration) {
    return 'Durée $duration';
  }

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
  String get attachmentsPause => 'Pause';

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
  String get attachmentsPlay => 'Lire';

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
  String attachmentsRejectedTooLong(String name, int seconds) {
    return '$name dure plus de $seconds secondes';
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
  String get attachmentsSourcePaste => 'Coller une image';

  @override
  String get attachmentsSourcePhotos => 'Choisir des photos';

  @override
  String get attachmentsSourceRecordVideo => 'Filmer une vidéo';

  @override
  String get attachmentsSourceScan => 'Numériser un document';

  @override
  String get attachmentsSourceVideos => 'Choisir une vidéo';

  @override
  String get attachmentsSourceVoiceNote => 'Note vocale';

  @override
  String get attachmentsStatusDownloading => 'Téléchargement';

  @override
  String get attachmentsStatusFailed => 'Échec de l\'envoi — touchez pour réessayer';

  @override
  String get attachmentsStatusNotDownloaded => 'Non téléchargé — touchez pour récupérer';

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
  String get attachmentsWifiOnly => 'Envoyer les pièces jointes en Wi-Fi uniquement';

  @override
  String get authAvatarChange => 'Changer la photo';

  @override
  String get authAvatarRemove => 'Retirer la photo';

  @override
  String get authBrowserFlowStarted => 'Terminez la connexion dans votre navigateur, puis revenez dans Everslot.';

  @override
  String get authChangeEmail => 'Utiliser une autre adresse';

  @override
  String authCodeBody(String email) {
    return 'Saisissez le code à 6 chiffres envoyé à $email, ou touchez le lien contenu dans cet e-mail.';
  }

  @override
  String get authCodeLabel => 'Code à 6 chiffres';

  @override
  String get authCodeResent => 'Un nouveau code est en route.';

  @override
  String get authCodeTitle => 'Consultez votre boîte de réception';

  @override
  String get authContinueApple => 'Continuer avec Apple';

  @override
  String get authContinueGoogle => 'Continuer avec Google';

  @override
  String get authContinueGuest => 'Continuer sans compte';

  @override
  String get authCurrentZone => 'Fuseau horaire actuel';

  @override
  String get authDeleteAccount => 'Supprimer le compte';

  @override
  String get authDeleteBody =>
      'Votre compte et toutes vos données (plannings, listes, habitudes et pièces jointes) seront définitivement supprimés sur tous vos appareils. Cette action est irréversible.';

  @override
  String get authDeleteConfirm => 'Supprimer définitivement';

  @override
  String get authDeleteExportFirst => 'Exporter mes données d\'abord';

  @override
  String authDeleteReauthBody(String email) {
    return 'Pour confirmer qu\'il s\'agit bien de vous, saisissez le code envoyé à $email.';
  }

  @override
  String get authDeleteTitle => 'Supprimer votre compte ?';

  @override
  String get authDeleteUnderstand => 'Je comprends que cette action est irréversible';

  @override
  String authDeleteWeb(String url) {
    return 'Vous pouvez aussi demander la suppression sur le web : $url';
  }

  @override
  String get authDeleted => 'Votre compte a été supprimé.';

  @override
  String get authDeleting => 'Suppression de votre compte…';

  @override
  String get authDeviceRevokedBody =>
      'Cet appareil a été retiré de votre compte depuis un autre appareil. Exportez d\'abord vos données si vous souhaitez en garder une copie, puis déconnectez-vous.';

  @override
  String get authDeviceRevokedTitle => 'Cet appareil a été retiré';

  @override
  String get authDisplayName => 'Nom affiché';

  @override
  String get authDisplayNameHint => 'Comment souhaitez-vous être appelé ?';

  @override
  String get authEmailHint => 'vous@exemple.com';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authErrorCaptcha => 'La vérification de sécurité a échoué. Veuillez réessayer.';

  @override
  String get authErrorEmailInUse => 'Cette adresse appartient déjà à un autre compte.';

  @override
  String get authErrorGuestDisabled => 'Le mode invité est désactivé sur ce serveur.';

  @override
  String get authErrorIdentityInUse => 'Ce moyen de connexion est déjà associé à un autre compte.';

  @override
  String get authErrorInvalidCode => 'Ce code est invalide ou a expiré.';

  @override
  String get authErrorInvalidEmail => 'Veuillez saisir une adresse e-mail valide.';

  @override
  String get authErrorLastIdentity => 'Vous ne pouvez pas retirer votre unique moyen de connexion.';

  @override
  String get authErrorMfaRequired => 'Saisissez le code de votre application d\'authentification pour continuer.';

  @override
  String get authErrorNotConfigured => 'La synchronisation n\'est pas configurée dans cette version (voir guide.md).';

  @override
  String get authErrorOffline => 'Vous êtes hors ligne. Vérifiez votre connexion et réessayez.';

  @override
  String get authErrorProviderNotConfigured => 'Ce moyen de connexion n\'est pas encore configuré (voir guide.md).';

  @override
  String get authErrorRateLimited => 'Trop de tentatives. Patientez un instant puis réessayez.';

  @override
  String get authErrorSessionExpired => 'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get authErrorUnknown => 'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get authExportFirst => 'Exporter les données';

  @override
  String get authGuestAccount => 'Compte invité';

  @override
  String get authGuestBanner =>
      'Vous utilisez un compte invité. Ajoutez un e-mail pour que vos données survivent si vous supprimez l\'app.';

  @override
  String get authGuestBannerAction => 'Sécuriser mes données';

  @override
  String get authGuestHint =>
      'Essayez Everslot tout de suite et ajoutez un e-mail plus tard pour conserver vos données.';

  @override
  String get authHomeZone => 'Fuseau horaire de référence';

  @override
  String get authLegalNote =>
      'En continuant, vous acceptez les Conditions d\'utilisation et la Politique de confidentialité.';

  @override
  String get authLink => 'Associer';

  @override
  String authLinked(String provider) {
    return '$provider associé';
  }

  @override
  String get authLinkedAccounts => 'Moyens de connexion';

  @override
  String get authLocalOnlyAccount => 'Données conservées sur cet appareil';

  @override
  String get authLocalOnlyAccountBody =>
      'Vous n\'êtes pas connecté. Connectez-vous pour synchroniser vos appareils : vos données suivront.';

  @override
  String get authMfaBody =>
      'Demander un code d\'une application d\'authentification à la connexion et avant de supprimer le compte.';

  @override
  String get authMfaCopySecret => 'Copier la clé';

  @override
  String get authMfaDisable => 'Désactiver';

  @override
  String get authMfaDisableBody =>
      'Saisissez un code de votre application d\'authentification pour désactiver la validation en deux étapes.';

  @override
  String get authMfaDisabled => 'La validation en deux étapes est désactivée.';

  @override
  String get authMfaEnabled => 'La validation en deux étapes est activée.';

  @override
  String get authMfaEnroll => 'Configurer';

  @override
  String get authMfaEnrollBody =>
      'Ajoutez cette clé à votre application d\'authentification, puis saisissez le code à 6 chiffres affiché.';

  @override
  String get authMfaOpenApp => 'Ouvrir dans l\'application d\'authentification';

  @override
  String get authMfaSecret => 'Clé de configuration';

  @override
  String get authMfaSecretCopied => 'Clé de configuration copiée.';

  @override
  String get authMfaTitle => 'Validation en deux étapes';

  @override
  String get authMfaVerifyBody =>
      'Ouvrez votre application d\'authentification et saisissez le code à 6 chiffres d\'Everslot.';

  @override
  String get authMfaVerifyTitle => 'Saisissez le code de votre application d\'authentification';

  @override
  String get authNotConfiguredBody =>
      'Cette version n\'est pas encore reliée à un projet Supabase (voir guide.md). En attendant, Everslot fonctionne entièrement sur cet appareil.';

  @override
  String get authNotConfiguredTitle => 'La synchronisation n\'est pas configurée';

  @override
  String get authOr => 'ou';

  @override
  String get authProfileTitle => 'Compte';

  @override
  String get authProviderApple => 'Apple';

  @override
  String get authProviderEmail => 'E-mail';

  @override
  String get authProviderGoogle => 'Google';

  @override
  String get authReauthBody =>
      'Votre session a expiré. Reconnectez-vous pour reprendre la synchronisation : tout ce que vous avez fait hors ligne est conservé.';

  @override
  String get authReauthTitle => 'Reconnectez-vous';

  @override
  String get authRegionalSettings => 'Paramètres régionaux';

  @override
  String get authResend => 'Renvoyer le code';

  @override
  String authResendIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Renvoyer le code dans $seconds secondes',
      one: 'Renvoyer le code dans $seconds seconde',
    );
    return '$_temp0';
  }

  @override
  String get authSendCode => 'Recevoir un code';

  @override
  String get authSessionExpiredBanner =>
      'Votre session a expiré. Vos modifications sont enregistrées sur cet appareil et seront synchronisées dès que vous vous reconnecterez.';

  @override
  String get authSignInAgain => 'Me reconnecter';

  @override
  String get authSignInToSync => 'Se connecter pour synchroniser';

  @override
  String get authSignOut => 'Se déconnecter';

  @override
  String get authSignOutAnyway => 'Me déconnecter quand même';

  @override
  String get authSignOutBody =>
      'Vos données seront retirées de cet appareil. Elles restent en sécurité dans votre compte.';

  @override
  String get authSignOutGuestBody =>
      'Ce compte invité n’existe que sur cet appareil. Vous déconnecter le supprimera définitivement avec toutes ses données : ajoutez d’abord un e-mail pour le conserver.';

  @override
  String authSignOutPendingBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications ne sont pas encore synchronisées et seront perdues.',
      one: '$count modification n\'est pas encore synchronisée et sera perdue.',
    );
    return '$_temp0 Exportez d\'abord vos données, ou déconnectez-vous quand même.';
  }

  @override
  String get authSignOutSyncing => 'Synchronisation de vos dernières modifications…';

  @override
  String get authSignOutTitle => 'Se déconnecter ?';

  @override
  String authSignedInAs(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String get authSignedOut => 'Déconnecté';

  @override
  String get authUnlink => 'Dissocier';

  @override
  String authUnlinkConfirm(String provider) {
    return 'Dissocier $provider ?';
  }

  @override
  String get authUpdateRequired =>
      'Mettez Everslot à jour pour continuer la synchronisation. Vos modifications restent sur cet appareil.';

  @override
  String get authUpgradeBody =>
      'Ajoutez un moyen de connexion à votre compte invité. Vos données restent exactement telles qu\'elles sont.';

  @override
  String get authUpgradeDone => 'Votre compte est sécurisé.';

  @override
  String get authUpgradeEmail => 'Ajouter un e-mail';

  @override
  String authUpgradeEmailInUseBody(String email) {
    return '$email possède déjà un compte Everslot. Utilisez une autre adresse, ou exportez vos données d\'invité, déconnectez-vous, connectez-vous à ce compte puis importez le fichier.';
  }

  @override
  String get authUpgradeEmailInUseTitle => 'Adresse déjà utilisée';

  @override
  String get authUpgradeTitle => 'Conservez vos données';

  @override
  String get authUseLocalOnly => 'Utiliser sur cet appareil uniquement';

  @override
  String get authUseLocalOnlyHint => 'Ni compte ni synchronisation. Connectez-vous plus tard : vos données suivront.';

  @override
  String get authVerify => 'Valider';

  @override
  String get authWelcomeBody =>
      'Connectez-vous pour synchroniser vos plannings, listes et habitudes sur tous vos appareils.';

  @override
  String get authWelcomeTitle => 'Bienvenue dans Everslot';

  @override
  String authZoneChangedBody(String zone) {
    return 'Vous êtes maintenant sur $zone. Les tâches à heure fixe gardent leur heure exacte et les tâches flottantes vous suivent. Faire de $zone votre fuseau de référence ?';
  }

  @override
  String get authZoneChangedTitle => 'Nouveau fuseau horaire';

  @override
  String get authZoneDetected => 'Détecté sur cet appareil';

  @override
  String authZoneKeepHome(String zone) {
    return 'Garder $zone';
  }

  @override
  String get authZoneMakeHome => 'En faire la référence';

  @override
  String get authZoneNoMatch => 'Aucun fuseau horaire ne correspond à votre recherche';

  @override
  String get authZoneSearch => 'Rechercher un fuseau horaire';

  @override
  String get bootstrapErrorBody =>
      'Un problème est survenu à l\'ouverture de l\'application. Vos données restent en sécurité sur cet appareil. Réessayez, et redémarrez votre téléphone si cela continue.';

  @override
  String get bootstrapErrorCopy => 'Copier les détails';

  @override
  String get bootstrapErrorDetails => 'Détails (pour les développeurs)';

  @override
  String get bootstrapErrorTitle => 'Everslot n\'a pas pu démarrer';

  @override
  String get categoriesEmpty => 'Aucune catégorie';

  @override
  String get categoriesTitle => 'Catégories';

  @override
  String get categoryArchived => 'Archivée';

  @override
  String get categoryClearAction => 'Leur retirer la catégorie';

  @override
  String categoryCreateNamed(String name) {
    return 'Créer la catégorie « $name »';
  }

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
  String get categoryDeleteBody => 'Les éléments de cette catégorie resteront, sans catégorie.';

  @override
  String categoryDeleteUsedBody(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments utilisent « $name ».',
      one: '1 élément utilise « $name ».',
    );
    return '$_temp0 Que faire de ces éléments ?';
  }

  @override
  String get categoryEdit => 'Modifier la catégorie';

  @override
  String get categoryErrorDuplicate => 'Une catégorie porte déjà ce nom.';

  @override
  String get categoryErrorInvalid => 'Utilisez 1 à 60 caractères.';

  @override
  String get categoryName => 'Nom';

  @override
  String get categoryNew => 'Nouvelle catégorie';

  @override
  String get categoryNone => 'Sans catégorie';

  @override
  String get categoryPick => 'Catégorie';

  @override
  String get categoryReassignAction => 'Les déplacer vers une autre catégorie';

  @override
  String get categoryReassignTitle => 'Déplacer les éléments vers';

  @override
  String get categoryReorderHint => 'Faites glisser pour réorganiser';

  @override
  String get categorySearch => 'Rechercher ou créer une catégorie';

  @override
  String get categoryUnavailable => 'Compte comme temps indisponible';

  @override
  String get categoryUnavailableHint => 'Exclu des statistiques de capacité (sommeil, congés…).';

  @override
  String categoryUsage(int count) {
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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count jours', one: '1 jour');
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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count gelés', one: '1 gelé');
    return '$_temp0';
  }

  @override
  String get chartsGalleryDark => 'Thème sombre';

  @override
  String get chartsGalleryEmptyState => 'État vide';

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
  String get chartsLabelArrivalsPerDeparture => 'Arrivées ÷ départs';

  @override
  String get chartsLabelAttempt => 'Tentative';

  @override
  String get chartsLabelAttention => 'À surveiller';

  @override
  String get chartsLabelBackfillShare => 'Saisies tardives';

  @override
  String get chartsLabelBaseline => 'Référence';

  @override
  String get chartsLabelBest => 'Record';

  @override
  String get chartsLabelBias => 'Biais';

  @override
  String get chartsLabelBlocked => 'Bloqué';

  @override
  String get chartsLabelBranching => 'Enfants par parent';

  @override
  String get chartsLabelCancelled => 'Annulé';

  @override
  String get chartsLabelCapacity => 'Capacité';

  @override
  String get chartsLabelCheckIns => 'Validations';

  @override
  String get chartsLabelCompleted => 'Terminé';

  @override
  String get chartsLabelContextSwitches => 'Changements';

  @override
  String get chartsLabelCount => 'Nombre';

  @override
  String get chartsLabelCravings => 'Envies';

  @override
  String get chartsLabelCreated => 'Créés';

  @override
  String get chartsLabelCurrent => 'Actuel';

  @override
  String get chartsLabelCycleTime => 'Temps de cycle';

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
  String get chartsLabelFollowUpOverdue => 'Relance en retard';

  @override
  String get chartsLabelFragmentation => 'Fragmentation';

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
  String get chartsLabelIntegrityMissingReason => 'Motif manquant';

  @override
  String get chartsLabelIntegrityOpenChildren => 'Terminé, mais sous-éléments ouverts';

  @override
  String get chartsLabelIntegrityParentOpen => 'Sous-éléments faits, encore ouvert';

  @override
  String get chartsLabelIntensity => 'Intensité';

  @override
  String get chartsLabelItems => 'Éléments';

  @override
  String get chartsLabelLapse => 'Écart';

  @override
  String get chartsLabelLargestBranch => 'Plus grande branche';

  @override
  String get chartsLabelLate => 'En retard';

  @override
  String get chartsLabelLeafDepth => 'Profondeur moyenne des feuilles';

  @override
  String get chartsLabelLeaves => 'Feuilles';

  @override
  String get chartsLabelLifeRegained => 'Vie regagnée';

  @override
  String get chartsLabelLimit => 'Limite';

  @override
  String get chartsLabelLists => 'Listes';

  @override
  String get chartsLabelLittleRatio => 'Ratio de Little';

  @override
  String get chartsLabelLoggedRatio => 'Saisies';

  @override
  String get chartsLabelLongestBlock => 'Plus long bloc';

  @override
  String get chartsLabelLoops => 'Boucles en cours ↔ attente';

  @override
  String get chartsLabelLowPriority => 'Priorité basse';

  @override
  String get chartsLabelMape => 'Erreur';

  @override
  String get chartsLabelMaxDepth => 'Profondeur max';

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
  String get chartsLabelMostActive => 'Les plus actives';

  @override
  String get chartsLabelMostBlocked => 'Les plus bloquées';

  @override
  String get chartsLabelMoved => 'Déplacé';

  @override
  String get chartsLabelMovedIn => 'Arrivés';

  @override
  String get chartsLabelMovedOut => 'Sortis';

  @override
  String get chartsLabelMovedShare => 'Déplacées';

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
  String get chartsLabelPauses => 'Pauses';

  @override
  String get chartsLabelPdfs => 'PDF';

  @override
  String get chartsLabelPending => 'En attente';

  @override
  String get chartsLabelPendingSync => 'En attente de synchro';

  @override
  String get chartsLabelPerDay => 'Par jour';

  @override
  String get chartsLabelPerfectDay => 'Journée parfaite';

  @override
  String get chartsLabelPlaces => 'Lieux';

  @override
  String get chartsLabelPlanned => 'Prévu';

  @override
  String get chartsLabelPostponed => 'Reporté';

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
  String get chartsLabelRating => 'Note';

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
  String get chartsLabelRuleChanged => 'Règle modifiée';

  @override
  String get chartsLabelSaved => 'Économisé';

  @override
  String get chartsLabelScope => 'Périmètre';

  @override
  String get chartsLabelScore => 'Score';

  @override
  String get chartsLabelSessions => 'Sessions';

  @override
  String get chartsLabelShortcut => 'Fait sans démarrage';

  @override
  String get chartsLabelSkipped => 'Passé';

  @override
  String get chartsLabelSnowballing => 'Boule de neige — déplacée 3 fois ou plus';

  @override
  String get chartsLabelSpent => 'Dépensé';

  @override
  String get chartsLabelStale => 'Inactives';

  @override
  String get chartsLabelStalest => 'Les plus inactives';

  @override
  String get chartsLabelStatusChanges => 'Changements d’état';

  @override
  String get chartsLabelStreak => 'Série';

  @override
  String get chartsLabelSuccess => 'Réussi';

  @override
  String get chartsLabelSummary => 'Résumé';

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
  String get chartsLabelTrackedTime => 'Temps suivi';

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
  String get chartsLabelUnknownUnits => 'Non saisies';

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
  String get chartsLabelWidestLevel => 'Niveau le plus large';

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
  String chartsRangeBrush(String from, String to) {
    return 'Plage visible $from–$to. Faites glisser pour la déplacer, tirez un bord pour la redimensionner.';
  }

  @override
  String chartsRatio(String value) {
    return '$value×';
  }

  @override
  String chartsScopeAdded(String date, String count, String items) {
    return '$date : +$count — $items';
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
  String get chartsShareAction => 'Partager';

  @override
  String get chartsShareFailed => 'L’image du graphique n’a pas pu être créée';

  @override
  String get chartsShareHideNames => 'Masquer les noms';

  @override
  String get chartsShareMark => 'Créé avec Everslot';

  @override
  String get chartsStreakBest => 'Record';

  @override
  String get chartsStreakCurrent => 'En cours';

  @override
  String chartsSummaryBars(String title, String count, String label, String value) {
    return '$title : $count barres, la plus haute $label avec $value.';
  }

  @override
  String chartsSummaryCalendar(String title, String count) {
    return '$title : $count jours affichés.';
  }

  @override
  String chartsSummaryLine(String title, String range, String first, String last, String trend) {
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
  String get chartsZoomReset => 'Réinitialiser le zoom';

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
  String get checklistCover => 'Image de couverture…';

  @override
  String get checklistCoverAuto => 'Automatique (première image)';

  @override
  String get checklistCoverNoImages => 'Ajoutez d’abord une image à la liste ou à ses éléments';

  @override
  String get checklistCoverUpdated => 'Couverture mise à jour';

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
  String checklistDoneThisWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terminés cette semaine',
      one: '1 terminé cette semaine',
    );
    return '$_temp0';
  }

  @override
  String get checklistDragHandle => 'Glisser pour déplacer';

  @override
  String get checklistDue => 'Échéance';

  @override
  String get checklistDuplicate => 'Dupliquer la liste';

  @override
  String get checklistDuplicateItem => 'Dupliquer';

  @override
  String checklistDurationDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n jours', one: '1 jour');
    return '$_temp0';
  }

  @override
  String checklistDurationHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n heures', one: '1 heure');
    return '$_temp0';
  }

  @override
  String checklistDurationMinutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n minutes', one: '1 minute');
    return '$_temp0';
  }

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
  String get checklistExpandToLevelMenu => 'Déplier jusqu’au niveau…';

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
  String get checklistHasReminders => 'Rappels définis';

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
  String checklistItemsDuplicated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments dupliqués',
      one: '1 élément dupliqué',
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
  String get checklistLinkTask => 'Lier à une tâche existante…';

  @override
  String get checklistLinkTaskTitle => 'Lier une tâche';

  @override
  String get checklistLinkedTask => 'Tâche liée';

  @override
  String get checklistMdBold => 'Gras';

  @override
  String get checklistMdBullet => 'Liste à puces';

  @override
  String get checklistMdCode => 'Code';

  @override
  String get checklistMdHeading => 'Titre';

  @override
  String get checklistMdItalic => 'Italique';

  @override
  String get checklistMdLink => 'Lien';

  @override
  String get checklistMdStrike => 'Barré';

  @override
  String get checklistMirror => 'Miroir';

  @override
  String checklistMirrorDone(String list) {
    return 'Miroir créé dans $list';
  }

  @override
  String get checklistMirrorMore => 'Suite dans l’original…';

  @override
  String get checklistMirrorNotAllowed => 'Un miroir ne peut pas aller dans son original';

  @override
  String checklistMirrorOf(String list) {
    return 'Miroir · $list';
  }

  @override
  String get checklistMirrorTo => 'Créer un miroir dans…';

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
  String get checklistNoOtherLists => 'Aucune autre liste à afficher';

  @override
  String get checklistNoTasksToLink => 'Aucune tâche à lier pour l’instant';

  @override
  String get checklistNotFound => 'Cette liste n\'existe pas';

  @override
  String get checklistNotifItemGone => 'Cet élément n’existe plus';

  @override
  String get checklistOpenOriginal => 'Ouvrir l’original';

  @override
  String get checklistOpenSideBySide => 'Ouvrir côte à côte…';

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
  String get checklistPickSecondList => 'Afficher à côté de cette liste';

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
  String get checklistResetConfirm => 'Tous les éléments reviennent à faire et les notes de raison sont effacées.';

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
  String checklistStatusSpoken(String status, String age) {
    return '$status depuis $age';
  }

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
  String checklistTaskLinked(String task) {
    return 'Liée à $task';
  }

  @override
  String get checklistTaskPlaceholder => 'Le lien avec les tâches arrive avec le planificateur.';

  @override
  String get checklistTaskScheduled => 'Tâche créée — choisissez son horaire';

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
  String get checklistUnlinkMirror => 'Délier le miroir (garder une copie)';

  @override
  String get checklistViewGallery => 'Galerie';

  @override
  String get checklistViewKanban => 'Kanban';

  @override
  String get checklistViewMindMap => 'Carte mentale';

  @override
  String get checklistViewOutline => 'Plan';

  @override
  String get checklistZoomOut => 'Dézoomer';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get confirmDeleteBody => 'Vous pourrez le restaurer depuis la corbeille pendant 30 jours.';

  @override
  String confirmDeleteTitle(String item) {
    return 'Supprimer $item ?';
  }

  @override
  String deletedSnack(String item) {
    return '$item supprimé';
  }

  @override
  String get devComponentGallery => 'Galerie de composants';

  @override
  String get devConfigured => 'Configuré';

  @override
  String get devCopied => 'Copié';

  @override
  String get devDangerZone => 'Zone sensible';

  @override
  String get devDatabase => 'Base de données locale';

  @override
  String get devDatabaseEmpty => 'Aucune ligne.';

  @override
  String devDatabaseRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lignes',
      one: '1 ligne',
      zero: 'vide',
    );
    return '$_temp0';
  }

  @override
  String get devEnvironment => 'Environnement';

  @override
  String get devFirebase => 'Firebase';

  @override
  String get devFlags => 'Fonctionnalités expérimentales';

  @override
  String get devFlagsHint => 'Réglages valables pour cette session uniquement (versions de développement).';

  @override
  String devFlavor(String flavor) {
    return 'Variante : $flavor';
  }

  @override
  String get devLogs => 'Journaux';

  @override
  String get devLogsAll => 'Tous';

  @override
  String get devLogsCopy => 'Copier les journaux';

  @override
  String get devLogsEmpty => 'Aucune entrée de journal pour l’instant.';

  @override
  String get devMenu => 'Menu développeur';

  @override
  String get devNoWarnings => 'Aucun avertissement de configuration';

  @override
  String get devNotConfigured => 'Non configuré';

  @override
  String get devResetData => 'Réinitialiser les données locales';

  @override
  String get devResetDataBody =>
      'Supprime tous les éléments, réglages et fichiers enregistrés sur cet appareil. Un compte cloud est déconnecté (ses données restent sur le serveur). Action irréversible.';

  @override
  String get devResetDone => 'Données locales réinitialisées';

  @override
  String get devSampleData => 'Données d’exemple';

  @override
  String get devSampleDataBody =>
      'Ajoute environ six mois de tâches, listes, habitudes et un suivi d’arrêt réalistes pour les démos et les captures d’écran.';

  @override
  String devSampleDataDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments ajoutés',
      one: '1 élément ajouté',
    );
    return '$_temp0';
  }

  @override
  String get devSampleDataGenerate => 'Générer des données d’exemple';

  @override
  String get devSampleDataRemove => 'Supprimer les données d’exemple';

  @override
  String get devSampleDataRemoved => 'Données d’exemple supprimées';

  @override
  String devSession(String mode) {
    return 'Session : $mode';
  }

  @override
  String get devSupabase => 'Supabase';

  @override
  String devSyncAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tentatives',
      one: '1 tentative',
      zero: 'pas encore envoyé',
    );
    return '$_temp0';
  }

  @override
  String devSyncBatch(int size) {
    return 'Taille des lots d’envoi : $size';
  }

  @override
  String get devSyncClear => 'Effacer';

  @override
  String get devSyncConflicts => 'Journal des conflits';

  @override
  String get devSyncConflictsEmpty => 'Aucun conflit enregistré.';

  @override
  String devSyncCursor(int cursor, int watermark) {
    return 'Curseur $cursor · seuil de purge $watermark';
  }

  @override
  String get devSyncDiagnostics => 'Diagnostic de synchronisation';

  @override
  String devSyncGroup(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications',
      one: '1 modification',
    );
    return '$_temp0 · $when';
  }

  @override
  String devSyncLastPull(String when) {
    return 'Dernière réception : $when';
  }

  @override
  String devSyncLastPush(String when) {
    return 'Dernier envoi : $when';
  }

  @override
  String get devSyncNever => 'jamais';

  @override
  String get devSyncNoPulls => 'Aucune réception pendant cette session.';

  @override
  String get devSyncOff =>
      'La synchronisation est désactivée sur cet appareil (mode local). La file d’envoi garde les modifications pour une connexion ultérieure.';

  @override
  String get devSyncOutbox => 'File d’envoi';

  @override
  String get devSyncOutboxEmpty => 'La file d’envoi est vide.';

  @override
  String devSyncPullPage(int since, int next, int changes) {
    String _temp0 = intl.Intl.pluralLogic(
      changes,
      locale: localeName,
      other: '$changes modifications',
      one: '1 modification',
    );
    return '$since → $next · $_temp0';
  }

  @override
  String get devSyncPulls => 'Dernières pages reçues';

  @override
  String get devSyncSimulateOffline => 'Simuler l’absence de réseau';

  @override
  String get devSyncSimulateOfflineHint => 'Chaque synchronisation échoue comme si le réseau était coupé.';

  @override
  String get devTestCrash => 'Envoyer un crash de test';

  @override
  String get devTestCrashBody => 'Lève une erreur non interceptée ; les builds release la signalent à Crashlytics.';

  @override
  String get devTimeTravel => 'Voyage dans le temps';

  @override
  String devTimeTravelNow(String time) {
    return 'Heure de l’app : $time';
  }

  @override
  String get devTimeTravelOff => 'Heure réelle';

  @override
  String devTimeTravelOffset(String relative) {
    return 'Décalage : $relative';
  }

  @override
  String get devTimeTravelPick => 'Choisir une date et une heure';

  @override
  String get devTimeTravelReset => 'Revenir à l’heure réelle';

  @override
  String get devTools => 'Outils';

  @override
  String get devZone => 'Fuseau horaire';

  @override
  String devZoneDevice(String zone) {
    return 'Fuseau de l’appareil : $zone';
  }

  @override
  String get devZoneOverridden => 'Remplacé jusqu’à réinitialisation';

  @override
  String get devZoneOverride => 'Remplacer le fuseau de l’appareil';

  @override
  String get devZoneReset => 'Utiliser le vrai fuseau de l’appareil';

  @override
  String durationDaysShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days jours', one: '1 jour');
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
  String get entityStatusActive => 'Actif';

  @override
  String get entityStatusArchived => 'Archivé';

  @override
  String get entityStatusBlocked => 'Bloqué';

  @override
  String get entityStatusCancelled => 'Annulé';

  @override
  String get entityStatusCompleted => 'Terminé';

  @override
  String get entityStatusDone => 'Fait';

  @override
  String get entityStatusInProgress => 'En cours';

  @override
  String get entityStatusMissed => 'Manqué';

  @override
  String get entityStatusOngoing => 'En cours';

  @override
  String get entityStatusPaused => 'En pause';

  @override
  String get entityStatusScheduled => 'Planifié';

  @override
  String get entityStatusSkipped => 'Ignoré';

  @override
  String get entityStatusTodo => 'À faire';

  @override
  String get entityStatusWaiting => 'En attente';

  @override
  String get errorAuth => 'Veuillez vous reconnecter.';

  @override
  String get errorConflict => 'Cet élément a été modifié ailleurs. Rechargez puis réessayez.';

  @override
  String get errorNetwork => 'Serveur injoignable. Vérifiez votre connexion.';

  @override
  String get errorNotConfigured => 'Cette fonction nécessite la configuration cloud (voir guide.md).';

  @override
  String get errorNotFound => 'Cet élément n\'existe plus.';

  @override
  String get errorPermission => 'Une autorisation est nécessaire.';

  @override
  String get errorStorage =>
      'Impossible de lire ou d\'écrire les données sur cet appareil. Libérez de l\'espace puis réessayez.';

  @override
  String get errorUnknown => 'Erreur inattendue.';

  @override
  String get errorUnsupportedVersion => 'Mettez à jour Everslot pour continuer la synchronisation.';

  @override
  String get errorValidation => 'Veuillez vérifier les champs indiqués.';

  @override
  String get errorWidgetFallback => 'Cette partie n\'a pas pu s\'afficher.';

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
  String get exportPdf => 'PDF';

  @override
  String get exportPdfFailed => 'Impossible de créer le PDF';

  @override
  String get exportPdfImages => 'Inclure les miniatures d’images';

  @override
  String get exportPdfNotes => 'Inclure les notes';

  @override
  String exportPdfPageOf(int page, int total) {
    return 'Page $page sur $total';
  }

  @override
  String get exportPlain => 'Texte brut';

  @override
  String get exportPrint => 'Imprimer…';

  @override
  String get exportShare => 'Partager…';

  @override
  String get exportTitle => 'Partager / exporter';

  @override
  String get exportZipBundle => 'Partager en zip (avec les fichiers)';

  @override
  String filterActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtres actifs',
      one: '1 filtre actif',
      zero: 'Aucun filtre',
    );
    return '$_temp0';
  }

  @override
  String get filterAny => 'Tous';

  @override
  String get filterAttachments => 'Pièces jointes';

  @override
  String get filterCategory => 'Catégorie';

  @override
  String filterChipCount(String field, int count) {
    return '$field · $count';
  }

  @override
  String filterChipValue(String field, String value) {
    return '$field : $value';
  }

  @override
  String filterClear(String filter) {
    return 'Retirer le filtre $filter';
  }

  @override
  String get filterClearAll => 'Tout effacer';

  @override
  String get filterDate => 'Date';

  @override
  String get filterNoCategory => 'Sans catégorie';

  @override
  String get filterOneOffOnly => 'Ponctuel';

  @override
  String get filterPriority => 'Priorité';

  @override
  String get filterRecurring => 'Répétition';

  @override
  String get filterRecurringOnly => 'Récurrent';

  @override
  String get filterStatus => 'Statut';

  @override
  String get filterTag => 'Étiquette';

  @override
  String get filterText => 'Texte';

  @override
  String get filterTextPrompt => 'Contient le texte';

  @override
  String get filterWithAttachments => 'Avec pièces jointes';

  @override
  String get filterWithoutAttachments => 'Sans pièces jointes';

  @override
  String get galleryButtons => 'Boutons';

  @override
  String get galleryChips => 'Puces et étiquettes';

  @override
  String get galleryColors => 'Couleurs des catégories';

  @override
  String get galleryConfirm => 'Confirmation';

  @override
  String get galleryContainer => 'Ouvrir un élément';

  @override
  String get galleryDarkTheme => 'Thème sombre';

  @override
  String get galleryDialogs => 'Dialogues, feuilles et sélecteurs';

  @override
  String get galleryDisabled => 'Désactivé';

  @override
  String get galleryEmpty => 'Aucun élément avec image';

  @override
  String get galleryFadeThrough => 'Fondu enchaîné';

  @override
  String get galleryFilters => 'Filtres';

  @override
  String get galleryIcons => 'Icônes';

  @override
  String get galleryInputs => 'Champs de saisie';

  @override
  String get galleryLargeText => 'Grand texte (200 %)';

  @override
  String get galleryLayout => 'Mise en page adaptative';

  @override
  String get galleryMotion => 'Animations';

  @override
  String get galleryOnlyImages => 'Seulement avec images';

  @override
  String galleryPicked(String value) {
    return 'Choisi : $value';
  }

  @override
  String get galleryPriorities => 'Priorités';

  @override
  String get galleryProgress => 'Progression';

  @override
  String get galleryPrompt => 'Saisie de texte';

  @override
  String get galleryReduceMotion => 'Réduire les animations';

  @override
  String get galleryRows => 'Lignes et avatars';

  @override
  String get galleryRtl => 'De droite à gauche';

  @override
  String get gallerySampleText => 'Exemple de texte';

  @override
  String get gallerySharedAxis => 'Axe partagé';

  @override
  String get gallerySheet => 'Feuille modale';

  @override
  String get gallerySheetActions => 'Feuille avec actions';

  @override
  String get gallerySheetBody => 'Une feuille modale au style Everslot.';

  @override
  String get galleryStates => 'États vide, erreur et chargement';

  @override
  String get galleryStatuses => 'Statuts';

  @override
  String get gallerySwipeHint => 'Balayez pour les actions';

  @override
  String get galleryTitle => 'Galerie de composants';

  @override
  String get galleryUndoSnack => 'Barre d’annulation';

  @override
  String get galleryWindowCompact => 'compacte';

  @override
  String get galleryWindowExpanded => 'étendue';

  @override
  String get galleryWindowMedium => 'moyenne';

  @override
  String galleryWindowSize(String size) {
    return 'Fenêtre : $size';
  }

  @override
  String get goalsAchieved => 'Atteints';

  @override
  String goalsAchievedOn(String date) {
    return 'Atteint le $date';
  }

  @override
  String get goalsActive => 'En cours';

  @override
  String get goalsAdd => 'Ajouter un objectif';

  @override
  String get goalsBadgeBackfillFreeMonth => 'Un mois noté à temps';

  @override
  String get goalsBadgeChallenge => 'Défi réussi';

  @override
  String goalsBadgeCravings(int count) {
    return '$count envies surmontées';
  }

  @override
  String goalsBadgeEarnedOn(String date) {
    return 'Obtenu le $date';
  }

  @override
  String get goalsBadgeFirstCheckIn => 'Premier pointage';

  @override
  String get goalsBadgeFirstPerfectDay => 'Première journée parfaite';

  @override
  String get goalsBadgePerfectWeek => 'Semaine parfaite';

  @override
  String goalsBadgeProgress(String value, String target) {
    return '$value sur $target';
  }

  @override
  String get goalsBadgeShare => 'Partager';

  @override
  String get goalsBadgeShareDate => 'Inclure la date';

  @override
  String get goalsBadgeShareHabit => 'Inclure le nom de l\'habitude';

  @override
  String goalsBadgeShareText(String name) {
    return 'J\'ai obtenu le badge « $name » dans Everslot.';
  }

  @override
  String get goalsBadgeShareTitle => 'Partager un badge';

  @override
  String goalsBadgeStreak(int count) {
    return 'Série de $count jours';
  }

  @override
  String goalsBadgeTotal(String value) {
    return '$value enregistrés';
  }

  @override
  String goalsBadgeUnlocked(String name) {
    return 'Badge débloqué : $name';
  }

  @override
  String get goalsBadgesEarned => 'Obtenus';

  @override
  String get goalsBadgesEmpty => 'Pointez une habitude pour obtenir votre premier badge.';

  @override
  String get goalsBadgesLocked => 'À obtenir';

  @override
  String get goalsBadgesTitle => 'Badges';

  @override
  String goalsCelebrate(String title) {
    return 'Objectif atteint : $title !';
  }

  @override
  String get goalsDelete => 'Supprimer l\'objectif';

  @override
  String get goalsDeleted => 'Objectif supprimé';

  @override
  String get goalsEdit => 'Modifier l\'objectif';

  @override
  String get goalsEmpty => 'Aucun objectif pour l\'instant';

  @override
  String get goalsEmptyBody => 'Fixez une cible pour une habitude — par exemple 10 000 pompes cette année.';

  @override
  String get goalsEnded => 'Terminés';

  @override
  String get goalsErrDates => 'Choisissez une date de début et une date de fin.';

  @override
  String get goalsErrEnd => 'La fin doit être après le début.';

  @override
  String get goalsErrMetric => 'Cette mesure ne convient pas à cette habitude.';

  @override
  String get goalsErrScope => 'Choisissez sur quoi porte l\'objectif.';

  @override
  String get goalsErrTarget => 'Saisissez une cible supérieure à zéro.';

  @override
  String get goalsErrTitle => '80 caractères maximum.';

  @override
  String goalsEta(String date) {
    return 'Prévu le $date';
  }

  @override
  String get goalsFrom => 'Du';

  @override
  String get goalsHabit => 'Habitude';

  @override
  String get goalsMetric => 'Mesure';

  @override
  String get goalsMetricCleanDays => 'Jours d\'abstinence';

  @override
  String get goalsMetricCompletions => 'Jours réussis';

  @override
  String get goalsMetricItemsCompleted => 'Éléments terminés';

  @override
  String get goalsMetricMoneySaved => 'Argent économisé';

  @override
  String get goalsMetricStreakDays => 'Série (jours)';

  @override
  String get goalsMetricTotalValue => 'Total enregistré';

  @override
  String get goalsMetricTrackedMinutes => 'Minutes suivies';

  @override
  String get goalsMetricUnitsAvoided => 'Unités évitées';

  @override
  String goalsNeedPerDay(String value) {
    return '$value par jour pour finir à temps';
  }

  @override
  String get goalsNew => 'Nouvel objectif';

  @override
  String get goalsPaceMarker => 'Là où vous devriez être aujourd\'hui';

  @override
  String get goalsPeriod => 'Période';

  @override
  String get goalsPeriodAllTime => 'Sans limite de temps';

  @override
  String get goalsPeriodCustom => 'Dates personnalisées';

  @override
  String get goalsPeriodMonth => 'Ce mois-ci';

  @override
  String get goalsPeriodQuarter => 'Ce trimestre';

  @override
  String get goalsPeriodWeek => 'Cette semaine';

  @override
  String get goalsPeriodYear => 'Cette année';

  @override
  String goalsProgressOf(String actual, String target) {
    return '$actual sur $target';
  }

  @override
  String get goalsSaved => 'Objectif enregistré';

  @override
  String get goalsStatusAchieved => 'Atteint';

  @override
  String get goalsStatusAtRisk => 'Compromis';

  @override
  String get goalsStatusBehind => 'En retard';

  @override
  String get goalsStatusOnTrack => 'En bonne voie';

  @override
  String goalsSuggestion(String value, String target) {
    return 'À ce rythme, vous atteindriez $value — visez $target ?';
  }

  @override
  String get goalsTarget => 'Cible';

  @override
  String get goalsTitle => 'Objectifs';

  @override
  String get goalsTitleField => 'Titre (facultatif)';

  @override
  String get goalsTo => 'Au';

  @override
  String goalsUseSuggestion(String target) {
    return 'Viser $target';
  }

  @override
  String get habitsActionAddValue => 'Ajouter une valeur';

  @override
  String get habitsActionBackfill => 'Saisir un autre jour';

  @override
  String get habitsActionCheckNow => 'Cocher maintenant';

  @override
  String get habitsActionClear => 'Effacer';

  @override
  String get habitsActionDetails => 'Détails';

  @override
  String get habitsActionDone => 'Fait';

  @override
  String get habitsActionEdit => 'Modifier';

  @override
  String get habitsActionEditEntries => 'Modifier les saisies';

  @override
  String get habitsActionExcuse => 'Excuser';

  @override
  String get habitsActionNotDone => 'Pas fait';

  @override
  String get habitsActionNoteMood => 'Note et humeur';

  @override
  String get habitsActionPause => 'Mettre en pause';

  @override
  String get habitsActionPauseTimer => 'Mettre le minuteur en pause';

  @override
  String get habitsActionSkip => 'Sauter';

  @override
  String get habitsActionStartTimer => 'Démarrer le minuteur';

  @override
  String get habitsActionStopTimer => 'Arrêter et enregistrer';

  @override
  String get habitsActionUndoDone => 'Décocher';

  @override
  String get habitsAdd => 'Ajouter';

  @override
  String get habitsAddEntry => 'Ajouter';

  @override
  String get habitsAddTime => 'Ajouter une heure';

  @override
  String get habitsAdvancedTitle => 'Avancé';

  @override
  String get habitsAfterCompletionDueAfter => 'À refaire après';

  @override
  String get habitsAfterUnitDays => 'Jours';

  @override
  String get habitsAfterUnitMonths => 'Mois';

  @override
  String get habitsAfterUnitWeeks => 'Semaines';

  @override
  String get habitsAllDone => 'Tout est fait 🎉';

  @override
  String get habitsAllHabits => 'Toutes les habitudes';

  @override
  String get habitsAllStats => 'Toutes les statistiques';

  @override
  String get habitsApplyAll => 'Tout l\'historique';

  @override
  String get habitsApplyAllWarn => 'Les statistiques passées vont changer.';

  @override
  String get habitsApplyDate => 'Une date choisie…';

  @override
  String get habitsApplyTitle => 'Appliquer la nouvelle fréquence ou le nouvel objectif à partir de';

  @override
  String get habitsApplyToday => 'Aujourd\'hui';

  @override
  String get habitsArchived => 'Archivées';

  @override
  String get habitsArchivedSnack => 'Habitude archivée';

  @override
  String get habitsAskNote => 'Demander une note et l’humeur après validation';

  @override
  String get habitsAtRisk => 'En danger';

  @override
  String get habitsBestStreak => 'Meilleure série';

  @override
  String get habitsCalendar => 'Calendrier';

  @override
  String get habitsCelebratePerfectDay => 'Journée parfaite — tout est fait !';

  @override
  String habitsCelebrateStreak(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours d\'affilée',
      one: '1 jour d\'affilée',
    );
    return '$name : $_temp0 !';
  }

  @override
  String get habitsCelebrationDismiss => 'Fermer';

  @override
  String habitsCellSemantics(String habit, String date, String status) {
    return '$habit, $date : $status';
  }

  @override
  String habitsChallengeBestStreak(String streak) {
    return 'Meilleure série : $streak';
  }

  @override
  String get habitsChallengeClose => 'Fermer';

  @override
  String get habitsChallengeContinued => 'C\'est maintenant une habitude durable';

  @override
  String habitsChallengeDay(int day, int total) {
    return 'Jour $day sur $total';
  }

  @override
  String habitsChallengeDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours restants',
      one: '1 jour restant',
      zero: 'Dernier jour',
    );
    return '$_temp0';
  }

  @override
  String get habitsChallengeEveryDay => 'Chaque jour prévu';

  @override
  String get habitsChallengeKeepGoing => 'Continuer';

  @override
  String get habitsChallengeKeepGoingHint => 'En faire une habitude durable — votre historique est conservé.';

  @override
  String habitsChallengeMinRatio(String percent) {
    return 'Au moins $percent des jours';
  }

  @override
  String get habitsChallengeMissedBody =>
      'Tout ne s\'est pas passé comme prévu — mais vous avez été là. Recommencez ou continuez.';

  @override
  String get habitsChallengeMissedTitle => 'Défi terminé';

  @override
  String habitsChallengeProgress(int done, int due) {
    return '$done jours réussis sur $due';
  }

  @override
  String get habitsChallengeRuleTitle => 'Pour réussir';

  @override
  String get habitsChallengeSuccessTitle => 'Défi réussi !';

  @override
  String get habitsChallengeTitle => 'Défi';

  @override
  String habitsChallengeVolume(String value) {
    return 'Total : $value';
  }

  @override
  String get habitsCompactRows => 'Lignes compactes';

  @override
  String habitsCounts(int done, int notDone, int missed, int skipped) {
    return 'Faites $done · Pas faites $notDone · Manquées $missed · Sautées $skipped';
  }

  @override
  String get habitsCreateQuitInstead => 'Créer un suivi d\'arrêt';

  @override
  String get habitsCurrentStreak => 'Série actuelle';

  @override
  String get habitsDatesTitle => 'Dates';

  @override
  String get habitsDayStateLabel => 'Statut';

  @override
  String habitsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
      zero: '0 jour',
    );
    return '$_temp0';
  }

  @override
  String habitsDecrease(String step) {
    return 'Retirer $step';
  }

  @override
  String get habitsDeleteBody =>
      'Son historique part avec elle dans la corbeille. Vous pouvez la restaurer pendant 30 jours.';

  @override
  String get habitsDeleteEntry => 'Supprimer la saisie';

  @override
  String habitsDeleteTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get habitsDeletedSnack => 'Habitude supprimée';

  @override
  String habitsDragHandle(String name) {
    return 'Déplacer $name';
  }

  @override
  String get habitsEditCustom => 'Modifier la fréquence';

  @override
  String get habitsEditEntry => 'Modifier la saisie';

  @override
  String get habitsEditorEditTitle => 'Modifier l\'habitude';

  @override
  String get habitsEditorNewTitle => 'Nouvelle habitude';

  @override
  String get habitsEmptyAction => 'Créer une habitude';

  @override
  String get habitsEmptyBody =>
      'Créez une habitude — comme 15 pompes par jour — et indiquez chaque jour si vous l’avez faite.';

  @override
  String get habitsEmptyTitle => 'Pas encore d\'habitude';

  @override
  String get habitsEndNever => 'Jamais';

  @override
  String get habitsEntries => 'Saisies';

  @override
  String get habitsEntryDeleted => 'Saisie supprimée';

  @override
  String get habitsErrDuration => 'Une durée doit être comprise entre 1 min et 24 h';

  @override
  String get habitsErrEnd => 'La date de fin précède la date de début';

  @override
  String get habitsErrFreezes => 'Entre 0 et 31 gels par mois';

  @override
  String get habitsErrLimitNeedsMeasurable => '« Au plus » nécessite un nombre, une durée ou une valeur';

  @override
  String get habitsErrNameEmpty => 'Saisissez un nom';

  @override
  String get habitsErrNameTooLong => 'Le nom est trop long (80 caractères max.)';

  @override
  String get habitsErrSchedule => 'Cette fréquence n\'est pas valide';

  @override
  String get habitsErrSectionName => 'Le nom doit comporter 1 à 40 caractères';

  @override
  String get habitsErrTarget => 'Saisissez un objectif supérieur à 0';

  @override
  String get habitsErrUnit => 'L\'unité doit comporter 1 à 20 caractères';

  @override
  String get habitsErrorArchived => 'Cette habitude est archivée.';

  @override
  String get habitsErrorFuture => 'Impossible de valider avant le début — vous pouvez la sauter ou l’excuser.';

  @override
  String habitsEveryNDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: 'Tous les $n jours', two: 'Un jour sur deux');
    return '$_temp0';
  }

  @override
  String get habitsFieldCategory => 'Catégorie';

  @override
  String get habitsFieldColor => 'Couleur';

  @override
  String get habitsFieldDescription => 'Description';

  @override
  String get habitsFieldEnd => 'Fin';

  @override
  String get habitsFieldIcon => 'Icône';

  @override
  String get habitsFieldName => 'Nom';

  @override
  String get habitsFieldNameHint => 'ex. 15 pompes';

  @override
  String get habitsFieldSection => 'Section';

  @override
  String get habitsFieldStart => 'Début';

  @override
  String get habitsFieldTarget => 'Objectif';

  @override
  String get habitsFieldUnit => 'Unité';

  @override
  String get habitsFilterAll => 'Toutes';

  @override
  String get habitsFilterDue => 'À faire';

  @override
  String get habitsFor30Days => 'Pendant 30 jours';

  @override
  String get habitsFreezes => 'Gels de série par mois';

  @override
  String get habitsFromTemplate => 'À partir d\'un modèle';

  @override
  String get habitsFutureOnlyPlanned => 'Seuls les sauts et les excuses peuvent être planifiés pour les jours à venir.';

  @override
  String get habitsGoalExampleCheck => 'Fait ou pas';

  @override
  String get habitsGoalExampleCount => '15 pompes';

  @override
  String get habitsGoalExampleDuration => 'Lire 20 min';

  @override
  String get habitsGoalExampleNumeric => 'Courir 5 km';

  @override
  String habitsGoalSentence(String op, String amount) {
    return '$op $amount';
  }

  @override
  String get habitsGoalTitle => 'Objectif';

  @override
  String get habitsGoalTypeCheck => 'Oui / Non';

  @override
  String get habitsGoalTypeCount => 'Nombre';

  @override
  String get habitsGoalTypeDuration => 'Durée';

  @override
  String get habitsGoalTypeNumeric => 'Valeur';

  @override
  String get habitsGroupByCategory => 'Catégorie';

  @override
  String get habitsGroupByNone => 'Aucun';

  @override
  String get habitsGroupBySection => 'Moment';

  @override
  String get habitsGroupByTitle => 'Regrouper par';

  @override
  String habitsGroupNotDue(int count) {
    return 'Pas prévues aujourd\'hui ($count)';
  }

  @override
  String get habitsHideNotDue => 'Masquer les habitudes non prévues';

  @override
  String get habitsHoldRingHint => 'Maintenir appuyé pour marquer comme fait';

  @override
  String get habitsHoldToComplete => 'Maintenir pour valider';

  @override
  String get habitsHoldToCompleteHint =>
      'Maintenez l\'anneau appuyé pour cocher une habitude et éviter les appuis accidentels.';

  @override
  String habitsIncrease(String step) {
    return 'Ajouter $step';
  }

  @override
  String get habitsIncrementStep => 'Pas';

  @override
  String get habitsJournal => 'Journal des notes';

  @override
  String get habitsJournalEmpty => 'Aucune note pour le moment';

  @override
  String get habitsJournalEmptyBody => 'Les notes et humeurs ajoutées à vos validations s\'affichent ici.';

  @override
  String get habitsLast90 => '90 derniers jours';

  @override
  String get habitsLastDay => 'Dernier jour';

  @override
  String habitsLeftOfLimit(String left, String limit) {
    return 'Encore $left sur $limit';
  }

  @override
  String get habitsLimitZeroHint => 'Une limite de 0 revient à arrêter complètement.';

  @override
  String get habitsManage => 'Gérer les habitudes';

  @override
  String get habitsMatrixTapTitle => 'Appui sur un jour dans la vue semaine';

  @override
  String get habitsMinPerDay => 'Minimum par jour';

  @override
  String habitsMinutesValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get habitsMood1 => 'Terrible';

  @override
  String get habitsMood2 => 'Mauvais';

  @override
  String get habitsMood3 => 'Correct';

  @override
  String get habitsMood4 => 'Bien';

  @override
  String get habitsMood5 => 'Excellent';

  @override
  String get habitsMoodLabel => 'Humeur';

  @override
  String get habitsMoodTrend => 'Tendance de l\'humeur';

  @override
  String get habitsMoveToSection => 'Déplacer vers une section…';

  @override
  String get habitsNewHabit => 'Nouvelle habitude';

  @override
  String get habitsNewQuit => 'Nouveau suivi d\'arrêt';

  @override
  String get habitsNewer => 'Jours suivants';

  @override
  String get habitsNextDay => 'Jour suivant';

  @override
  String get habitsNextMonth => 'Mois suivant';

  @override
  String get habitsNextYear => 'Année suivante';

  @override
  String get habitsNoBuildHabits => 'Aucune habitude à cocher pour le moment';

  @override
  String get habitsNoCategory => 'Sans catégorie';

  @override
  String get habitsNoEntries => 'Aucune saisie pour le moment';

  @override
  String get habitsNone => 'Aucune';

  @override
  String get habitsNotActiveThatDay => 'Cette habitude n\'était pas active ce jour-là.';

  @override
  String get habitsNotEnoughData => 'Pas encore assez de données';

  @override
  String get habitsNoteHint => 'Comment ça s\'est passé ?';

  @override
  String get habitsNoteMoodTitle => 'Note et humeur';

  @override
  String get habitsNothingThisDay => 'Rien de prévu ce jour-là';

  @override
  String get habitsNothingThisDayBody => 'Les habitudes apparaissent ici les jours où elles sont prévues.';

  @override
  String get habitsNotifGone => 'Cette habitude n\'existe plus.';

  @override
  String habitsNotifInvalidValue(String input) {
    return '« $input » n\'est pas un nombre — ouvrez l\'app pour l\'enregistrer.';
  }

  @override
  String get habitsOlder => 'Jours précédents';

  @override
  String get habitsOnlyOn => 'Seulement le (facultatif)';

  @override
  String get habitsOpAtLeast => 'Au moins';

  @override
  String get habitsOpAtMost => 'Au plus';

  @override
  String get habitsOpExactly => 'Exactement';

  @override
  String habitsOrdinal(String which) {
    String _temp0 = intl.Intl.selectLogic(which, {
      'first': 'Premier',
      'second': 'Deuxième',
      'third': 'Troisième',
      'fourth': 'Quatrième',
      'other': 'Dernier',
    });
    return '$_temp0';
  }

  @override
  String get habitsOverLimit => 'Limite dépassée';

  @override
  String get habitsOverdue => 'En retard';

  @override
  String get habitsPauseAction => 'Mettre en pause';

  @override
  String habitsPauseDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count jours', one: '1 jour');
    return '$_temp0';
  }

  @override
  String get habitsPauseHint => 'Les jours en pause sont neutres : jamais manqués et ils ne cassent jamais une série.';

  @override
  String get habitsPauseIndefinitely => 'Indéfiniment';

  @override
  String get habitsPauseTitle => 'Mettre l\'habitude en pause';

  @override
  String get habitsPauseToday => 'Aujourd\'hui';

  @override
  String get habitsPauseUntil => 'Jusqu\'à une date…';

  @override
  String habitsPauseUntilDate(String date) {
    return 'Jusqu\'au $date';
  }

  @override
  String get habitsPauseWeek => '1 semaine';

  @override
  String get habitsPausedIndefinitely => 'En pause';

  @override
  String get habitsPausedSnack => 'En pause';

  @override
  String habitsPausedUntil(String date) {
    return 'En pause jusqu\'au $date';
  }

  @override
  String habitsPerfectDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours parfaits',
      one: '1 jour parfait',
      zero: 'Aucun jour parfait pour le moment',
    );
    return '$_temp0';
  }

  @override
  String get habitsPickDuration => 'Choisir une durée';

  @override
  String get habitsPresetAfterCompletion => 'Après chaque réalisation';

  @override
  String get habitsPresetCustom => 'Personnalisé…';

  @override
  String get habitsPresetDaily => 'Tous les jours';

  @override
  String get habitsPresetEveryNDays => 'Tous les N jours';

  @override
  String get habitsPresetInterval => 'Toutes les N heures';

  @override
  String get habitsPresetMonthlyDay => 'Chaque mois, un jour donné';

  @override
  String get habitsPresetMonthlyWeekday => 'Chaque mois, un jour de semaine';

  @override
  String get habitsPresetSpecificDays => 'Certains jours';

  @override
  String get habitsPresetSpecificTimes => 'À heures fixes';

  @override
  String get habitsPresetTimesPerDay => 'N fois par jour';

  @override
  String get habitsPresetTimesPerMonth => 'N× par mois';

  @override
  String get habitsPresetTimesPerWeek => 'N× par semaine';

  @override
  String get habitsPresetWeekdays => 'En semaine';

  @override
  String get habitsPresetWeekends => 'Le week-end';

  @override
  String get habitsPrevDay => 'Jour précédent';

  @override
  String get habitsPreviewNext => 'Prochaines';

  @override
  String get habitsPreviewTitle => 'Aperçu';

  @override
  String get habitsPreviousMonth => 'Mois précédent';

  @override
  String get habitsPreviousYear => 'Année précédente';

  @override
  String get habitsProgressionEvery => 'Tous les';

  @override
  String get habitsProgressionHint => 'Commence à la cible et ajoute un palier régulièrement pendant le défi.';

  @override
  String get habitsProgressionMax => 'Jusqu\'à (0 = sans limite)';

  @override
  String get habitsProgressionStep => 'Ajouter à chaque fois';

  @override
  String get habitsProgressionTitle => 'Augmenter la cible';

  @override
  String habitsProgressionToday(String value) {
    return 'Cible du jour : $value';
  }

  @override
  String get habitsQuickValues => 'Valeurs rapides';

  @override
  String get habitsQuickValuesHint => 'ex. 5 10 15';

  @override
  String habitsQuotaMonth(int done, int times) {
    return '$done sur $times ce mois-ci';
  }

  @override
  String habitsQuotaWeek(int done, int times) {
    return '$done sur $times cette semaine';
  }

  @override
  String get habitsRate30 => 'Taux sur 30 jours';

  @override
  String get habitsReasonOptional => 'Raison (facultatif)';

  @override
  String get habitsRecentEntries => 'Saisies récentes';

  @override
  String habitsRecordAbstinence(String value) {
    return 'Plus longue période sans consommer : $value';
  }

  @override
  String habitsRecordBestDay(String value) {
    return 'Meilleure journée : $value';
  }

  @override
  String habitsRecordBestWeek(String value) {
    return 'Meilleure semaine : $value';
  }

  @override
  String habitsRecordCravings(int count) {
    return 'Le plus d\'envies surmontées en un jour : $count';
  }

  @override
  String get habitsRecordNew => 'Nouveau record !';

  @override
  String habitsRecordStreak(String value) {
    return 'Plus longue série : $value';
  }

  @override
  String get habitsReorder => 'Réorganiser';

  @override
  String get habitsReorderDone => 'Terminé';

  @override
  String get habitsReorderHint => 'Faites glisser les poignées pour changer l\'ordre.';

  @override
  String get habitsReordered => 'Ordre enregistré';

  @override
  String get habitsRequireExplicit => 'Une journée vide compte comme manquée';

  @override
  String get habitsResume => 'Reprendre';

  @override
  String get habitsResumedSnack => 'Reprise';

  @override
  String get habitsRollupAll => 'Toutes les validations sont nécessaires';

  @override
  String habitsRollupMin(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Au moins $n validations',
      one: 'Au moins 1 validation',
    );
    return '$_temp0';
  }

  @override
  String get habitsRollupMinCount => 'Validations nécessaires';

  @override
  String get habitsRollupMinTitle => 'Une journée compte avec une partie des validations';

  @override
  String get habitsSavedSnack => 'Enregistré';

  @override
  String get habitsScheduleTitle => 'Fréquence';

  @override
  String get habitsSectionAfternoon => 'Après-midi';

  @override
  String get habitsSectionAnytime => 'N\'importe quand';

  @override
  String get habitsSectionDeleteBody => 'Ses habitudes passent dans « N\'importe quand ».';

  @override
  String get habitsSectionDeleteTitle => 'Supprimer cette section ?';

  @override
  String get habitsSectionDeleted => 'Section supprimée';

  @override
  String get habitsSectionEdit => 'Modifier la section';

  @override
  String get habitsSectionEvening => 'Soir';

  @override
  String get habitsSectionMorning => 'Matin';

  @override
  String get habitsSectionNew => 'Nouvelle section';

  @override
  String get habitsSectionNone => 'Autres';

  @override
  String habitsSectionProgress(int done, int total) {
    return '$done / $total faites';
  }

  @override
  String get habitsSectionWindow => 'Plage horaire';

  @override
  String get habitsSections => 'Sections';

  @override
  String get habitsShowStreaks => 'Afficher les séries';

  @override
  String get habitsSkipBreaks => 'Cassent la série';

  @override
  String get habitsSkipNeutral => 'Ne cassent pas la série';

  @override
  String get habitsSkipPolicy => 'Jours sautés';

  @override
  String habitsSlotsProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String habitsSnackCleared(String name) {
    return '« $name » effacée';
  }

  @override
  String habitsSnackDone(String name) {
    return '« $name » fait';
  }

  @override
  String habitsSnackExcused(String name) {
    return '« $name » excusée';
  }

  @override
  String habitsSnackLogged(String amount, String name) {
    return '$amount enregistré · $name';
  }

  @override
  String habitsSnackNotDone(String name) {
    return '« $name » marqué comme non fait';
  }

  @override
  String habitsSnackSkipped(String name) {
    return '« $name » sautée';
  }

  @override
  String get habitsStatusDone => 'Fait';

  @override
  String get habitsStatusExcused => 'Excusée';

  @override
  String get habitsStatusFailed => 'Pas fait';

  @override
  String get habitsStatusFrozen => 'Gelée';

  @override
  String get habitsStatusMissed => 'Manqué';

  @override
  String get habitsStatusNotDue => 'Non prévue';

  @override
  String get habitsStatusPartial => 'Partiellement';

  @override
  String get habitsStatusPaused => 'En pause';

  @override
  String get habitsStatusPending => 'À faire';

  @override
  String get habitsStatusSkipped => 'Sautée';

  @override
  String habitsStreakSemantics(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Série de $days jours',
      one: 'Série de 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get habitsStrength => 'Solidité';

  @override
  String get habitsTapCycleDoneFail => 'Fait → Pas fait → Effacer';

  @override
  String get habitsTapCycleDoneOnly => 'Fait → Effacer';

  @override
  String get habitsTapCycleDoneSkip => 'Fait → Sauté → Effacer';

  @override
  String get habitsTemplatesChallenges => 'Défis';

  @override
  String get habitsTemplatesHabits => 'Habitudes';

  @override
  String get habitsTemplatesQuit => 'Arrêter';

  @override
  String get habitsTemplatesTitle => 'Modèles';

  @override
  String habitsTimerElapsed(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(minutes, locale: localeName, other: '$minutes minutes', one: '1 minute');
    return 'Minuteur : $_temp0';
  }

  @override
  String habitsTimesPerDay(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n fois par jour', one: 'Une fois par jour');
    return '$_temp0';
  }

  @override
  String habitsTimesPerMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n fois par mois', one: 'Une fois par mois');
    return '$_temp0';
  }

  @override
  String habitsTimesPerWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n fois par semaine',
      one: 'Une fois par semaine',
    );
    return '$_temp0';
  }

  @override
  String get habitsToday => 'Aujourd\'hui';

  @override
  String get habitsToggleShortPress => 'Basculer par un appui court';

  @override
  String get habitsToggleShortPressHint => 'Désactivé : un appui long bascule, un appui court ouvre le jour.';

  @override
  String get habitsTolerance => 'Validation anticipée';

  @override
  String habitsTotalOfTarget(String total, String target) {
    return 'Total $total sur $target';
  }

  @override
  String get habitsTplChallengeMeditate => '14 jours de méditation';

  @override
  String get habitsTplChallengeMeditateDesc => '10 minutes par jour pendant 14 jours';

  @override
  String get habitsTplChallengeNoSugar => '21 jours sans sucre';

  @override
  String get habitsTplChallengeNoSugarDesc => 'Chaque jour pendant 21 jours';

  @override
  String get habitsTplChallengePushUps => '30 jours de pompes';

  @override
  String get habitsTplChallengePushUpsDesc => '20 répétitions par jour pendant 30 jours';

  @override
  String get habitsTplCoffeeLimit => 'Au plus 2 cafés';

  @override
  String get habitsTplCoffeeLimitDesc => 'Une limite quotidienne';

  @override
  String get habitsTplGym => 'Salle de sport';

  @override
  String get habitsTplGymDesc => '3 fois par semaine, n’importe quels jours';

  @override
  String get habitsTplJournal => 'Tenir un journal';

  @override
  String get habitsTplJournalDesc => 'Oui / non, chaque soir';

  @override
  String get habitsTplMeditate => 'Méditer';

  @override
  String get habitsTplMeditateDesc => '10 minutes par jour';

  @override
  String get habitsTplPushUps => '15 pompes';

  @override
  String get habitsTplPushUpsDesc => 'Nombre ≥ 15 répétitions, chaque jour';

  @override
  String get habitsTplRead => 'Lire';

  @override
  String get habitsTplReadDesc => '20 minutes par jour';

  @override
  String get habitsTplSleepEarly => 'Dormir avant 23 h';

  @override
  String get habitsTplSleepEarlyDesc => 'Oui / non, chaque jour';

  @override
  String get habitsTplStretch => 'S\'étirer';

  @override
  String get habitsTplStretchDesc => 'Toutes les heures de 9 h à 18 h (6 sur 10)';

  @override
  String get habitsTplWalk => 'Marcher';

  @override
  String get habitsTplWalkDesc => '5 km par jour';

  @override
  String get habitsTplWater => 'Boire de l\'eau';

  @override
  String get habitsTplWaterDesc => '8 verres par jour';

  @override
  String get habitsTypeBuild => 'Prendre une habitude';

  @override
  String get habitsTypeQuit => 'Arrêter quelque chose';

  @override
  String get habitsUnarchive => 'Désarchiver';

  @override
  String get habitsUnarchivedSnack => 'Habitude restaurée';

  @override
  String habitsUnitCigarettes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'cigarettes', one: 'cigarette');
    return '$_temp0';
  }

  @override
  String habitsUnitCups(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'tasses', one: 'tasse');
    return '$_temp0';
  }

  @override
  String get habitsUnitCustom => 'Autre…';

  @override
  String habitsUnitDrinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'verres', one: 'verre');
    return '$_temp0';
  }

  @override
  String habitsUnitGlasses(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'verres', one: 'verre');
    return '$_temp0';
  }

  @override
  String get habitsUnitH => 'h';

  @override
  String habitsUnitJoints(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'joints', one: 'joint');
    return '$_temp0';
  }

  @override
  String get habitsUnitKcal => 'kcal';

  @override
  String get habitsUnitKm => 'km';

  @override
  String get habitsUnitL => 'L';

  @override
  String get habitsUnitMi => 'mi';

  @override
  String get habitsUnitMin => 'min';

  @override
  String get habitsUnitMl => 'ml';

  @override
  String habitsUnitPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'pages', one: 'page');
    return '$_temp0';
  }

  @override
  String habitsUnitReps(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'répétitions', one: 'répétition');
    return '$_temp0';
  }

  @override
  String habitsUnitServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'portions', one: 'portion');
    return '$_temp0';
  }

  @override
  String habitsUnitSessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'sessions', one: 'session');
    return '$_temp0';
  }

  @override
  String habitsUnitSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'pas', one: 'pas');
    return '$_temp0';
  }

  @override
  String habitsUnitTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'fois', one: 'fois');
    return '$_temp0';
  }

  @override
  String get habitsVacationIndefinitely => 'Le mode vacances est activé';

  @override
  String get habitsVacationTitle => 'Mode vacances';

  @override
  String habitsVacationUntil(String date) {
    return 'Mode vacances jusqu\'au $date';
  }

  @override
  String get habitsValueHint => 'Quantité';

  @override
  String get habitsValueInvalid => 'Saisissez un nombre supérieur à 0';

  @override
  String get habitsValueTitle => 'Saisir une valeur';

  @override
  String get habitsViewMonth => 'Mois';

  @override
  String get habitsViewOptions => 'Options d\'affichage';

  @override
  String get habitsViewToday => 'Aujourd\'hui';

  @override
  String get habitsViewWeek => 'Semaine';

  @override
  String get habitsViewYear => 'Année';

  @override
  String habitsWarnManySlots(int count) {
    return '$count validations par jour — c’est beaucoup.';
  }

  @override
  String get habitsWarnNeverDue => 'Cette fréquence ne tombe sur aucun jour à venir.';

  @override
  String habitsWeekOf(String date) {
    return 'Semaine du $date';
  }

  @override
  String get habitsWindowFrom => 'De';

  @override
  String get habitsWindowTo => 'À';

  @override
  String get habitsYear => 'Année';

  @override
  String habitsYearSummary(int done, int scheduled, String year) {
    return 'Faite $done jours sur $scheduled prévus en $year';
  }

  @override
  String habitsZoneFixed(String zone) {
    return 'Toujours utiliser $zone';
  }

  @override
  String habitsZoneFixedHint(String zone) {
    return 'Les jours suivent $zone où que vous soyez';
  }

  @override
  String get habitsZoneFloating => 'Les jours suivent votre fuseau horaire actuel';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count éléments', one: '1 élément');
    return '$_temp0';
  }

  @override
  String get importKeepOne => 'Garder en un seul élément';

  @override
  String importMoreLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '…et $count éléments de plus',
      one: '…et 1 élément de plus',
    );
    return '$_temp0';
  }

  @override
  String get importPasteHint => 'Collez du texte indenté, du Markdown ou de l\'OPML';

  @override
  String get importSplit => 'Découper en éléments (garder l\'imbrication)';

  @override
  String importSplitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Scinder en $count éléments (garder l’imbrication)',
      one: 'Scinder en 1 élément (garder l’imbrication)',
    );
    return '$_temp0';
  }

  @override
  String get importTitle => 'Importer';

  @override
  String get importWarningAttachments => 'Les références de pièces jointes ont été ignorées';

  @override
  String get importWarningEmpty => 'Rien à importer';

  @override
  String get importWarningMalformed => 'Impossible de lire ce fichier';

  @override
  String get importWarningTooMany => 'Seules les 10 000 premières lignes ont été importées';

  @override
  String get integrationsActionFailed => 'Cette action n\'a pas pu être effectuée.';

  @override
  String integrationsHabitLogged(String habit) {
    return 'Enregistré : $habit';
  }

  @override
  String integrationsHabitNotFound(String name) {
    return 'Aucune habitude ne correspond à « $name ».';
  }

  @override
  String get integrationsLinkInTrash => 'Cet élément est dans la corbeille.';

  @override
  String get integrationsLinkNotFound => 'Ce lien ne peut pas être ouvert dans Everslot.';

  @override
  String get integrationsNothingNext => 'Plus rien n\'est prévu aujourd\'hui.';

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
  String get itemNoStepDuration => 'Partage le temps de la tâche';

  @override
  String get itemNote => 'Note';

  @override
  String get itemOtherDevice => 'un autre appareil';

  @override
  String get itemPriority => 'Priorité';

  @override
  String itemScheduledAs(String title) {
    return 'Planifié : $title';
  }

  @override
  String get itemScheduledBadge => 'Planifié comme tâche';

  @override
  String get itemStepDuration => 'Durée de l’étape (routines)';

  @override
  String get itemText => 'Texte';

  @override
  String get itemThisDevice => 'cet appareil';

  @override
  String get itemTimeInStatus => 'Temps par statut';

  @override
  String get itemsColAge => 'Âge';

  @override
  String get itemsColAttachments => 'Fichiers';

  @override
  String get itemsColChecklist => 'Liste';

  @override
  String get itemsColDue => 'Échéance';

  @override
  String get itemsColFollowUp => 'Relance';

  @override
  String get itemsColPath => 'Chemin';

  @override
  String get itemsColPriority => 'Priorité';

  @override
  String get itemsColStatus => 'Statut';

  @override
  String get itemsColText => 'Élément';

  @override
  String get itemsTableEmpty => 'Aucun élément ne correspond';

  @override
  String get itemsTableFilterHint => 'Filtrer par texte, liste ou chemin';

  @override
  String get itemsTableOpen => 'Tous les éléments (tableau)';

  @override
  String get itemsTableSelectAll => 'Sélectionner tous les éléments affichés';

  @override
  String itemsTableSelectRow(String item) {
    return 'Sélectionner $item';
  }

  @override
  String itemsTableSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnés',
      one: '1 sélectionné',
    );
    return '$_temp0';
  }

  @override
  String itemsTableSortBy(String column) {
    return 'Trier par $column';
  }

  @override
  String itemsTableStatusChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments mis à jour',
      one: '1 élément mis à jour',
    );
    return '$_temp0';
  }

  @override
  String get itemsTableTitle => 'Tous les éléments';

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
  String get linkKindChecklist => 'Liste';

  @override
  String get linkKindChecklistItem => 'Élément de liste';

  @override
  String get linkKindHabit => 'Habitude';

  @override
  String get linkKindHabitLog => 'Note d’habitude';

  @override
  String get linkKindTask => 'Tâche';

  @override
  String get linkedCompleteAction => 'Terminer';

  @override
  String linkedCompleteItemBody(String item) {
    return '« $item » est planifié par cette tâche.';
  }

  @override
  String get linkedCompleteItemTitle => 'Terminer aussi l’élément de liste ?';

  @override
  String linkedCompleteTaskBody(String task) {
    return '« $task » planifie cet élément.';
  }

  @override
  String get linkedCompleteTaskTitle => 'Marquer aussi la tâche comme faite ?';

  @override
  String get linkedEntityMissing => 'Supprimé';

  @override
  String linkedEntitySemantics(String kind, String title, String status) {
    return '$kind : $title, $status. L’ouvre';
  }

  @override
  String get linkedEntityUntitled => 'Sans titre';

  @override
  String get listsAllLists => 'Toutes les listes';

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
  String get listsEditLabels => 'Modifier les libellés';

  @override
  String get listsEmptyAction => 'Créer votre première liste';

  @override
  String get listsEmptyMessage => 'Listes, notes et routines — imbriquées aussi profondément que nécessaire.';

  @override
  String get listsEmptyTitle => 'Aucune liste pour l\'instant';

  @override
  String get listsFilterAnyLabel => 'Tous les libellés';

  @override
  String get listsFilterColor => 'Couleur';

  @override
  String get listsFilterHasAttachments => 'Avec pièces jointes';

  @override
  String get listsFilterHasBlocked => 'En attente ou bloqué';

  @override
  String get listsFilterHasDue => 'Avec échéances';

  @override
  String get listsFilterLabel => 'Libellé';

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
  String listsLabelFilterActive(String label) {
    return 'Listes avec le libellé $label';
  }

  @override
  String listsLabelSemantics(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listes',
      one: '1 liste',
      zero: 'aucune liste',
    );
    return '$label, $_temp0';
  }

  @override
  String get listsListView => 'Vue liste';

  @override
  String get listsMoveConflicted =>
      'Un déplacement est entré en conflit avec une modification faite sur un autre appareil et a été annulé.';

  @override
  String get listsMoveConflictedUndo => 'Déplacement annulé après un conflit de synchronisation';

  @override
  String get listsMoveItems => 'Déplacer des éléments…';

  @override
  String get listsNewChecklist => 'Nouvelle liste';

  @override
  String get listsNewNote => 'Nouvelle note';

  @override
  String get listsNoLabels => 'Aucun libellé pour l’instant';

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
  String get listsSearchNoResults => 'Aucune liste ni aucun élément correspondant';

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
  String get mindMapExport => 'Exporter en image';

  @override
  String mindMapHidden(int count) {
    return '+$count';
  }

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
  String get notifBodyChildrenComplete => 'Tous les sous-éléments sont faits — le terminer ?';

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
  String get notifChannelBlocked => 'Certaines catégories de notifications sont bloquées';

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
  String get notifChipChangeTime => 'Modifier l’heure';

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
  String notifChipLastDayAt(String time) {
    return 'Le dernier jour à $time';
  }

  @override
  String get notifChipMilestones => 'Étapes';

  @override
  String notifChipOnDayAt(String time) {
    return 'Le jour même à $time';
  }

  @override
  String get notifChipRepeat => 'Répéter…';

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
  String notifCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rappels copiés',
      one: '1 rappel copié',
    );
    return '$_temp0';
  }

  @override
  String get notifCopyFrom => 'Copier les rappels de…';

  @override
  String get notifCopyNothing => 'Cet élément n’a pas de rappels propres';

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
  String get notifDiagPushOff => 'Push non configuré — rappels locaux uniquement';

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
  String get notifExactOff => 'Les rappels peuvent arriver jusqu’à une heure en retard';

  @override
  String get notifExactOffBody => 'Autorisez les rappels précis pour qu’ils sonnent à la minute près.';

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
  String get notifFieldRepeats => 'Répétition';

  @override
  String get notifFieldStatuses => 'Statuts';

  @override
  String get notifFieldThresholds => 'Seuils (séparés par des virgules, vide = auto)';

  @override
  String get notifFieldToStatus => 'Nouveau statut';

  @override
  String get notifFieldUntil => 'Jusqu’à';

  @override
  String get notifFreqDaily => 'Tous les jours';

  @override
  String get notifFreqMonthly => 'Tous les mois';

  @override
  String get notifFreqWeekly => 'Toutes les semaines';

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
  String get notifIssueAnchorUnavailable => 'Ce repère n’est pas disponible pour cet élément';

  @override
  String get notifIssueEmptyContent => 'Le titre ne peut pas être vide';

  @override
  String get notifIssueLateness => 'Le retard doit être d’au moins 1 minute';

  @override
  String get notifIssueNoChannel => 'Choisissez au moins un mode de notification';

  @override
  String get notifIssueOffsetOutOfRange => 'Le décalage doit rester sous 30 jours';

  @override
  String get notifIssueRepeatDoze =>
      'Sur Android, des répétitions espacées de moins de 10 minutes peuvent arriver en retard quand le téléphone est en veille';

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
  String get notifIssueTooManyActions => 'Android n’affiche que les 3 premières actions';

  @override
  String get notifIssueUnknownTrigger => 'Ce type de règle n’est pas pris en charge';

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
  String get notifModeOffHint => 'Aucune notification pour cet élément';

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
  String get notifNoiseBlocked => 'Trop de notifications (plus de 1 440 par jour)';

  @override
  String get notifNoiseCluster => 'Plusieurs rappels à la même minute — un seul son sera joué';

  @override
  String notifNoiseConfirm(int perDay) {
    return 'Ce rappel envoie environ $perDay notifications par jour. Enregistrer quand même ?';
  }

  @override
  String notifNoiseWarn(int perDay) {
    return 'Environ $perDay notifications par jour';
  }

  @override
  String get notifNoticeChannelBody => 'Ouvrez les réglages du système pour les autoriser de nouveau.';

  @override
  String get notifNoticeRevokedBody => 'Reconnectez-vous pour continuer la synchronisation.';

  @override
  String get notifNoticeRevokedTitle => 'Cet appareil a été retiré de votre compte';

  @override
  String get notifNoticeSaturatedBody =>
      'iOS ne garde que les 64 prochains rappels. Ouvrez Everslot régulièrement (ou activez le push) pour que les suivants soient programmés.';

  @override
  String get notifNoticeSaturatedTitle => 'Tous les rappels ne tiennent pas sur cet appareil';

  @override
  String get notifNoticeSyncBody =>
      'Vos modifications sont en sécurité sur cet appareil. Vérifiez votre connexion ou reconnectez-vous.';

  @override
  String get notifNoticeSyncTitle => 'La synchronisation échoue depuis plus d’un jour';

  @override
  String get notifNoticeUpdateBody =>
      'Cette version ne peut plus se synchroniser. Installez la dernière version pour garder vos données synchronisées.';

  @override
  String get notifNoticeUpdateTitle => 'Mettez à jour Everslot';

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
  String get notifPausedShort => 'Notifications en pause';

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
  String get notifSaturationBody => 'Ouvrez Everslot pour garder vos rappels à jour';

  @override
  String get notifSaturationTitle => 'Ouvrez Everslot';

  @override
  String get notifSectionChecklists => 'Listes';

  @override
  String get notifSectionDigests => 'Récapitulatifs';

  @override
  String get notifSectionHabits => 'Habitudes';

  @override
  String notifSectionOffHint(String section) {
    return 'Les notifications « $section » sont désactivées dans les réglages';
  }

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
  String get notifStatusBlocked => 'bloqué';

  @override
  String get notifStatusCancelled => 'annulé';

  @override
  String get notifStatusCompleted => 'terminé';

  @override
  String get notifStatusDone => 'fait';

  @override
  String get notifStatusInProgress => 'en cours';

  @override
  String get notifStatusMissed => 'manqué';

  @override
  String get notifStatusOngoing => 'en cours';

  @override
  String get notifStatusScheduled => 'planifié';

  @override
  String get notifStatusSkipped => 'passé';

  @override
  String get notifStatusTodo => 'à faire';

  @override
  String get notifStatusWaiting => 'en attente';

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
  String get notifSumChildrenComplete => 'Quand tous les sous-éléments sont faits';

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
  String get notifThisDeviceIsPrimary => 'Cet appareil est l’appareil principal';

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
  String get onboardingClock => 'Horloge';

  @override
  String get onboardingClock12 => '12 heures';

  @override
  String get onboardingClock24 => '24 heures';

  @override
  String get onboardingEssentialsBody =>
      'Nous avons repris ces réglages de votre appareil. Corrigez ce qui ne va pas : vous pourrez les modifier plus tard dans Paramètres › Région.';

  @override
  String get onboardingEssentialsTitle => 'Votre semaine, votre horloge';

  @override
  String get onboardingGetStarted => 'Commencer';

  @override
  String get onboardingLanguage => 'Langue';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get onboardingTimeZone => 'Fuseau horaire de référence';

  @override
  String get onboardingTitle => 'Configurer Everslot';

  @override
  String get onboardingWeekStart => 'La semaine commence le';

  @override
  String get pickerColor => 'Couleur';

  @override
  String get pickerCustomColor => 'Couleur personnalisée';

  @override
  String get pickerDate => 'Date';

  @override
  String get pickerDays => 'Jours';

  @override
  String get pickerDuration => 'Durée';

  @override
  String get pickerEnd => 'Fin';

  @override
  String get pickerHex => 'Code hexadécimal';

  @override
  String get pickerHexInvalid => 'Utilisez 6 chiffres hexadécimaux, par ex. 3B82F6';

  @override
  String get pickerHours => 'Heures';

  @override
  String get pickerIcon => 'Icône';

  @override
  String get pickerLowContrast => 'Contraste faible : cette couleur se voit mal sur le fond.';

  @override
  String get pickerMinutes => 'Minutes';

  @override
  String get pickerNextMonth => 'Mois suivant';

  @override
  String get pickerNextWeek => 'Semaine prochaine';

  @override
  String get pickerNoColor => 'Sans couleur';

  @override
  String get pickerPreviousMonth => 'Mois précédent';

  @override
  String get pickerSearchIcons => 'Rechercher une icône';

  @override
  String get pickerStart => 'Début';

  @override
  String get pickerTime => 'Heure';

  @override
  String get pickerTimeInvalid => 'Saisissez une heure comme 07:03';

  @override
  String get pickerTimeRange => 'Plage horaire';

  @override
  String get pickerTomorrow => 'Demain';

  @override
  String get pickerTypeTime => 'Saisir une heure';

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
  String get pvActualColumn => 'Réel';

  @override
  String get pvAddCountdown => 'Ajouter un compte à rebours';

  @override
  String get pvAddTask => 'Ajouter une tâche';

  @override
  String get pvAddToBacklog => 'Ajouter au backlog';

  @override
  String get pvAddZone => 'Ajouter un fuseau horaire';

  @override
  String get pvAllDay => 'Toute la journée';

  @override
  String get pvAllDaySection => 'Toute la journée et sans heure';

  @override
  String get pvApplyToView => 'Appliquer à cette vue';

  @override
  String get pvAutoAdvance => 'Avance automatique';

  @override
  String get pvAutoScrollNow => 'Aller à l’heure actuelle à l’ouverture';

  @override
  String get pvBacklogEmpty => 'Aucune tâche à planifier';

  @override
  String get pvCancelOccurrence => 'Annuler cette occurrence';

  @override
  String get pvCannotUnschedule => 'Les occurrences récurrentes ne peuvent pas retourner dans les tâches à planifier';

  @override
  String get pvCapacity => 'Capacité';

  @override
  String get pvCategories => 'Catégories';

  @override
  String get pvChecklistDue => 'Éléments de liste avec échéance';

  @override
  String get pvClearFilters => 'Effacer';

  @override
  String get pvClearPlace => 'Retirer l’épingle';

  @override
  String get pvClearSelection => 'Effacer la sélection';

  @override
  String get pvClocksForward => 'Passage à l’heure d’été';

  @override
  String get pvColCategory => 'Catégorie';

  @override
  String get pvColDate => 'Date';

  @override
  String get pvColDuration => 'Durée';

  @override
  String get pvColEnd => 'Fin';

  @override
  String get pvColLocation => 'Lieu';

  @override
  String get pvColPriority => 'Priorité';

  @override
  String get pvColRecurrence => 'Répétition';

  @override
  String get pvColStart => 'Début';

  @override
  String get pvColStatus => 'Statut';

  @override
  String get pvColTitle => 'Titre';

  @override
  String get pvColTracking => 'Suivi';

  @override
  String get pvCollapse => 'Réduire';

  @override
  String get pvColorBy => 'Couleur selon';

  @override
  String get pvColorByCategory => 'Catégorie';

  @override
  String get pvColorByPriority => 'Priorité';

  @override
  String get pvColorByStatus => 'Statut';

  @override
  String get pvColorByTask => 'Tâche';

  @override
  String get pvColumns => 'Colonnes';

  @override
  String get pvCompletion => 'Réalisation';

  @override
  String get pvContinues => 'suite';

  @override
  String pvCopied(String title) {
    return '« $title » copiée';
  }

  @override
  String get pvCopy => 'Copier';

  @override
  String pvCopySuffix(String name) {
    return '$name (copie)';
  }

  @override
  String get pvCountdownSince => 'Compter depuis';

  @override
  String get pvCountdownUntil => 'Décompter jusqu’à';

  @override
  String pvCounterParts(int days, int hours, int minutes) {
    return '$days j $hours h $minutes min';
  }

  @override
  String get pvCreate => 'Créer';

  @override
  String get pvCreateHere => 'Créer ici';

  @override
  String get pvCreatedSnack => 'Tâche créée';

  @override
  String pvCurrentSize(String size) {
    return 'Actuel : $size';
  }

  @override
  String pvDayHeaderSemantics(String day, String items) {
    return '$day, $items';
  }

  @override
  String pvDayOverbooked(String duration) {
    return 'Surchargé de $duration';
  }

  @override
  String get pvDayRibbon => 'Jour';

  @override
  String pvDayStats(String done, String total, String planned) {
    return '$done/$total · $planned';
  }

  @override
  String get pvDaySummary => 'Bilan de la journée';

  @override
  String get pvDayTicker => 'Bandeau des journées';

  @override
  String pvDayUtilizationExplain(String planned, String capacity) {
    return '$planned prévus pour $capacity d’heures de travail';
  }

  @override
  String pvDaysSince(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
      zero: 'aujourd’hui',
    );
    return '$_temp0';
  }

  @override
  String pvDaysUntil(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dans $count jours',
      one: 'dans 1 jour',
      zero: 'aujourd’hui',
    );
    return '$_temp0';
  }

  @override
  String get pvDaysVisible => 'Jours visibles';

  @override
  String get pvDaysVisibleLandscape => 'Jours en mode paysage';

  @override
  String get pvDefaultBadge => 'Par défaut';

  @override
  String get pvDeleteView => 'Supprimer la vue';

  @override
  String get pvDemoData => 'Données de démonstration (développeur)';

  @override
  String get pvDensity => 'Densité';

  @override
  String get pvDensityComfortable => 'Confortable';

  @override
  String get pvDensityCompact => 'Compacte';

  @override
  String get pvDimPast => 'Estomper le passé';

  @override
  String get pvDisplay => 'Affichage';

  @override
  String get pvDoneTotal => 'Faites';

  @override
  String get pvDragToSchedule => 'Faites glisser sur la grille pour planifier';

  @override
  String get pvDropNotSupported => 'Ce regroupement ne peut pas encore être modifié par glisser-déposer';

  @override
  String get pvDroppedPin => 'Épingle';

  @override
  String get pvDuplicateView => 'Dupliquer la vue';

  @override
  String pvElapsed(String duration) {
    return 'Écoulé : $duration';
  }

  @override
  String get pvEmptyDay => 'Rien de prévu';

  @override
  String get pvEmptyRange => 'Rien sur cette période';

  @override
  String pvEmptySlotSemantics(String day, String time) {
    return '$day $time, libre, touchez deux fois pour créer';
  }

  @override
  String get pvEmptyWeekTitle => 'Rien de prévu cette semaine';

  @override
  String get pvExpand => 'Développer';

  @override
  String get pvExpandInline => 'Déplier la journée sur place';

  @override
  String get pvExtend => 'Prolonger';

  @override
  String pvExtendBy(int minutes) {
    return '+$minutes min';
  }

  @override
  String pvExtendedSnack(int minutes) {
    return 'Prolongé de $minutes min';
  }

  @override
  String get pvExtraZones => 'Fuseaux horaires supplémentaires';

  @override
  String get pvFillFromBacklog => 'Remplir avec une tâche à planifier';

  @override
  String get pvFillGap => 'Remplir ce créneau';

  @override
  String get pvFilter => 'Filtrer';

  @override
  String get pvFilters => 'Filtres';

  @override
  String get pvFinish => 'Terminer';

  @override
  String get pvFollowWorkHours => 'Utiliser mes heures de travail';

  @override
  String pvFreeGap(String duration) {
    return 'libre $duration';
  }

  @override
  String get pvFreeInWorkHours => 'Libre pendant les heures de travail';

  @override
  String pvFreeRun(String from, String to, String duration) {
    return 'Libre $from–$to · $duration';
  }

  @override
  String get pvFrom => 'De';

  @override
  String get pvGoalLinked => 'Lié à un objectif';

  @override
  String get pvGotIt => 'Compris';

  @override
  String get pvGroupBy => 'Regrouper par';

  @override
  String get pvGroupCalendar => 'Vues calendrier';

  @override
  String get pvGroupCategory => 'Catégorie';

  @override
  String get pvGroupDay => 'Jour';

  @override
  String get pvGroupDeadline => 'Échéance';

  @override
  String get pvGroupNone => 'Aucun';

  @override
  String get pvGroupPriority => 'Priorité';

  @override
  String get pvGroupProductivity => 'Concentration et productivité';

  @override
  String get pvGroupStatus => 'Statut';

  @override
  String get pvGroupTask => 'Tâche';

  @override
  String get pvHeatMetric => 'Mesure';

  @override
  String pvHiddenRange(String from, String to) {
    return 'Masqué $from–$to';
  }

  @override
  String get pvHideEmptySlots => 'Regrouper les créneaux vides';

  @override
  String get pvHintLongPress => 'Appuyez longuement sur un espace vide pour créer une tâche';

  @override
  String get pvHintPinch => 'Pincez pour zoomer ; pincez horizontalement pour changer le nombre de jours';

  @override
  String pvHintSlotSize(String size) {
    return 'Touchez $size pour changer la taille des lignes';
  }

  @override
  String get pvHorizonDay => 'Aujourd’hui';

  @override
  String get pvHorizonMonth => 'Ce mois-ci';

  @override
  String get pvHorizonQuarter => 'Ce trimestre';

  @override
  String get pvHorizonWeek => 'Cette semaine';

  @override
  String get pvHorizonYear => 'Cette année';

  @override
  String get pvHorizonsHint =>
      'Intentions non planifiées par horizon — glissez-les vers un autre horizon ou sur un jour.';

  @override
  String get pvIgnoreLowPriority => 'Ignorer les tâches peu prioritaires';

  @override
  String pvImportanceRule(String priority) {
    return 'Importante à partir de la priorité $priority';
  }

  @override
  String pvItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
      zero: 'Aucun élément',
    );
    return '$_temp0';
  }

  @override
  String get pvJumpToDate => 'Aller à une date';

  @override
  String get pvKeepScreenOn => 'Garder l’écran allumé';

  @override
  String get pvLaneCap => 'Colonnes côte à côte';

  @override
  String get pvLaneOther => 'Autres';

  @override
  String get pvLanes => 'Couloirs';

  @override
  String get pvLanesHint => 'Choisissez les catégories affichées côte à côte et leur ordre.';

  @override
  String pvLastRowShort(String duration) {
    return 'la dernière de $duration';
  }

  @override
  String get pvLayout => 'Disposition';

  @override
  String get pvLess => 'Moins';

  @override
  String get pvListBelow => 'Liste en dessous';

  @override
  String get pvListMode => 'Liste accessible';

  @override
  String get pvLoadThresholds => 'Teinte de charge (chargé · dépassé)';

  @override
  String get pvMakeGoal => 'En faire un objectif';

  @override
  String get pvMapAttribution => '© les contributeurs d’OpenStreetMap';

  @override
  String get pvMapPlaceholder => 'Donnez un lieu à une tâche (éditeur → trouver un lieu) pour la voir sur la carte.';

  @override
  String get pvMarkDone => 'Marquer comme faite';

  @override
  String get pvMarkNotDone => 'Marquer comme non faite';

  @override
  String get pvMetricCompletion => 'Taux de réalisation';

  @override
  String get pvMetricCount => 'Nombre d’éléments';

  @override
  String get pvMetricPlanned => 'Heures prévues';

  @override
  String get pvMinGap => 'Durée minimale';

  @override
  String get pvMonthBars => 'Barres';

  @override
  String get pvMonthDots => 'Points';

  @override
  String get pvMonthTitles => 'Titres';

  @override
  String get pvMonthTitlesTimes => 'Titres et heures';

  @override
  String pvMore(String count) {
    return '+$count';
  }

  @override
  String pvMoreItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments de plus',
      one: '1 élément de plus',
    );
    return '$_temp0';
  }

  @override
  String get pvMoreLegend => 'Plus';

  @override
  String get pvMoreOptions => 'Plus d’options';

  @override
  String get pvMove => 'Déplacer';

  @override
  String get pvMoveDoneBody => 'Elle est déjà faite : la déplacer modifie son historique.';

  @override
  String get pvMoveDoneTitle => 'Déplacer une tâche faite ?';

  @override
  String get pvMoveDown => 'Descendre';

  @override
  String pvMoveEarlier(int minutes) {
    return 'Avancer de $minutes min';
  }

  @override
  String pvMoveLater(int minutes) {
    return 'Retarder de $minutes min';
  }

  @override
  String get pvMoveNextDay => 'Déplacer au jour suivant';

  @override
  String get pvMovePreviousDay => 'Déplacer au jour précédent';

  @override
  String get pvMoveTo => 'Déplacer vers…';

  @override
  String get pvMoveUnfinishedTomorrow => 'Reporter les tâches non faites à demain';

  @override
  String get pvMoveUp => 'Monter';

  @override
  String pvMovedSnack(String when) {
    return 'Déplacée à $when';
  }

  @override
  String get pvNext => 'Suivant';

  @override
  String get pvNextDay => 'Jour suivant';

  @override
  String pvNextDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Les $count prochains jours',
      one: 'Le jour suivant',
    );
    return '$_temp0';
  }

  @override
  String get pvNextUp => 'Ensuite';

  @override
  String get pvNextWeek => 'Semaine suivante';

  @override
  String get pvNoCategory => 'Sans catégorie';

  @override
  String get pvNoCountdowns => 'Aucun compte à rebours';

  @override
  String get pvNoDeadline => 'Sans échéance';

  @override
  String get pvNoEstimate => 'Sans estimation';

  @override
  String get pvNoOpenings => 'Aucun temps libre trouvé';

  @override
  String pvNoRoom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments n’ont pas trouvé de place',
      one: '1 élément n’a pas trouvé de place',
    );
    return '$_temp0';
  }

  @override
  String get pvNoRoutine => 'Aucun bloc de routine aujourd’hui';

  @override
  String get pvNoSavedViews => 'Aucune vue enregistrée pour l’instant';

  @override
  String get pvNoTasks => 'Aucune tâche';

  @override
  String get pvNothingNext => 'Rien d’autre de prévu aujourd’hui';

  @override
  String get pvNothingNow => 'Rien de prévu en ce moment';

  @override
  String get pvNothingToPaste => 'Copiez d’abord une tâche';

  @override
  String get pvNow => 'Maintenant';

  @override
  String get pvOneOff => 'Ponctuelle';

  @override
  String get pvOpenDay => 'Ouvrir la journée';

  @override
  String get pvOpenPlannerInsights => 'Ouvrir les statistiques du planning';

  @override
  String get pvOpenings => 'Disponibilités';

  @override
  String get pvOverdue => 'En retard';

  @override
  String get pvOverlapCascade => 'Cascade';

  @override
  String get pvOverlapColumns => 'Colonnes';

  @override
  String get pvOverlapStyle => 'Style des chevauchements';

  @override
  String get pvOverlayChecklistDue => 'Éléments de liste à échéance';

  @override
  String get pvOverlayDeviceCalendars => 'Calendriers de l’appareil';

  @override
  String get pvOverlayFreeSlots => 'Temps libre';

  @override
  String get pvOverlayHabits => 'Habitudes prévues';

  @override
  String get pvOverlayHeat => 'Intensité des heures chargées';

  @override
  String get pvOverlayOccupancy => 'Occupation des créneaux (4 dernières semaines)';

  @override
  String get pvOverlayUtilization => 'Charge du jour';

  @override
  String get pvOverlays => 'Superpositions';

  @override
  String get pvPagingDay => 'Un jour';

  @override
  String get pvPagingFree => 'Défilement libre';

  @override
  String get pvPagingMode => 'Un balayage avance de';

  @override
  String get pvPagingWeek => 'Une semaine';

  @override
  String pvPasted(String time) {
    return 'Collée à $time';
  }

  @override
  String get pvPause => 'Pause';

  @override
  String get pvPickDate => 'Choisir une date';

  @override
  String get pvPickPlace => 'Trouver un lieu';

  @override
  String get pvPin => 'Épingler';

  @override
  String get pvPinned => 'Épinglés';

  @override
  String pvPixels(String value) {
    return '$value px';
  }

  @override
  String get pvPlaceNoResults => 'Aucun lieu trouvé';

  @override
  String get pvPlaceSearchHint => 'Adresse ou nom du lieu';

  @override
  String get pvPlaceTapHint => 'Ou touchez la carte pour placer une épingle.';

  @override
  String get pvPlanColumn => 'Prévu';

  @override
  String get pvPlanFirstTask => 'Planifiez votre première tâche';

  @override
  String get pvPlanned => 'Prévu';

  @override
  String get pvPostpone => 'Reporter';

  @override
  String pvPostponeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(minutes, locale: localeName, other: '$minutes minutes', one: '1 minute');
    return '$_temp0';
  }

  @override
  String get pvPostponeNextWeek => 'La semaine prochaine';

  @override
  String get pvPostponeTomorrow => 'Demain';

  @override
  String get pvPrevious => 'Précédent';

  @override
  String get pvPreviousDay => 'Jour précédent';

  @override
  String get pvPreviousWeek => 'Semaine précédente';

  @override
  String get pvPriorities => 'Priorités';

  @override
  String get pvQuadDelegate => 'Déléguer';

  @override
  String get pvQuadDo => 'Faire';

  @override
  String get pvQuadEliminate => 'Éliminer';

  @override
  String get pvQuadSchedule => 'Planifier';

  @override
  String get pvQuickCreateHint => 'Qu’avez-vous prévu ?';

  @override
  String get pvQuickCreateTitle => 'Nouvelle tâche';

  @override
  String pvQuotaProgress(String title, int done, int total) {
    return '$title · $done/$total cette période';
  }

  @override
  String get pvQuotaSlots => 'Objectifs à placer';

  @override
  String get pvRadial12 => '12 h';

  @override
  String get pvRadial24 => '24 h';

  @override
  String get pvRadialHours => 'Cadran';

  @override
  String get pvRecurring => 'Récurrente';

  @override
  String get pvRemoveCountdown => 'Retirer des comptes à rebours';

  @override
  String get pvRenameView => 'Renommer la vue';

  @override
  String get pvRenderAuto => 'Auto';

  @override
  String get pvRenderMode => 'Affichage';

  @override
  String get pvRenderTable => 'Tableau';

  @override
  String get pvRenderTimeline => 'Chronologie';

  @override
  String pvRepeatedHour(String time, String offset) {
    return '$time ($offset)';
  }

  @override
  String get pvRepeats => 'se répète';

  @override
  String get pvResetView => 'Réinitialiser les réglages de la vue';

  @override
  String pvResizedSnack(String duration) {
    return 'Durée : $duration';
  }

  @override
  String get pvRibbonStyle => 'Ruban';

  @override
  String get pvRoutineComplete => 'Routine terminée';

  @override
  String get pvRoutineStart => 'Lancer la routine';

  @override
  String pvRoutineSummary(int done, int total) {
    return 'Étapes faites : $done sur $total';
  }

  @override
  String get pvRowHeight => 'Hauteur des lignes';

  @override
  String get pvRowsOccurrences => 'Occurrences';

  @override
  String pvRowsPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lignes par jour',
      one: '1 ligne par jour',
    );
    return '$_temp0';
  }

  @override
  String get pvRowsTasks => 'Tâches';

  @override
  String get pvRules => 'Règles';

  @override
  String get pvSaveAsNewView => 'Enregistrer comme nouvelle vue';

  @override
  String get pvSaveViewAs => 'Enregistrer la vue sous…';

  @override
  String get pvSavedViews => 'Vues enregistrées';

  @override
  String get pvScale => 'Échelle';

  @override
  String get pvScaleDays => 'Jours';

  @override
  String get pvScaleHours => 'Heures';

  @override
  String get pvScaleMonths => 'Mois';

  @override
  String get pvScaleWeeks => 'Semaines';

  @override
  String get pvScheduleOn => 'Planifier le…';

  @override
  String pvScheduledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments planifiés',
      one: '1 élément planifié',
    );
    return '$_temp0';
  }

  @override
  String get pvScheduledSnack => 'Planifiée';

  @override
  String get pvScopeAll => 'Toutes les occurrences';

  @override
  String get pvScopeFollowing => 'Celle-ci et les suivantes';

  @override
  String get pvScopeThis => 'Cette occurrence';

  @override
  String get pvScopeTitle => 'Modifier une tâche récurrente';

  @override
  String get pvSelect => 'Sélectionner';

  @override
  String pvSelected(int count) {
    return 'Sélection : $count';
  }

  @override
  String get pvSelectionActions => 'Actions';

  @override
  String pvSeriesPreview(String adherence, String streak) {
    return '$adherence réalisées · série $streak';
  }

  @override
  String get pvSetAsPlanDefault => 'Ouvrir l’onglet Plan sur cette vue';

  @override
  String get pvSetDefaultView => 'Définir par défaut';

  @override
  String get pvShareAvailability => 'Partager mes disponibilités';

  @override
  String get pvShowAsTimeline => 'Afficher en lignes de chronologie';

  @override
  String get pvShowCancelled => 'Afficher les tâches annulées';

  @override
  String get pvShowCompleted => 'Afficher les tâches faites';

  @override
  String get pvShowEmptyDays => 'Afficher les jours vides';

  @override
  String get pvShowNotes => 'Afficher les notes';

  @override
  String get pvShowWeekends => 'Afficher les week-ends';

  @override
  String get pvSinceGroup => 'Depuis';

  @override
  String get pvSkip => 'Passer';

  @override
  String get pvSkipRemaining => 'Passer les tâches restantes';

  @override
  String get pvSkipStep => 'Passer l’étape';

  @override
  String get pvSlotCustom => 'Taille personnalisée';

  @override
  String get pvSlotCustomHint => 'Minutes ou h:mm (1 min – 24 h)';

  @override
  String get pvSlotInvalid => 'Saisissez une taille comprise entre 1 minute et 24 heures';

  @override
  String get pvSlotPresets => 'Préréglages';

  @override
  String get pvSlotSize => 'Taille des créneaux';

  @override
  String get pvSlotsStyle => 'Créneaux';

  @override
  String get pvSnap => 'Aimantation';

  @override
  String get pvSortBy => 'Trier par';

  @override
  String get pvStart => 'Démarrer';

  @override
  String pvStartsAt(String time) {
    return 'Commence à $time';
  }

  @override
  String get pvStatusCancelled => 'Annulée';

  @override
  String get pvStatusDone => 'Faite';

  @override
  String get pvStatusInProgress => 'En cours';

  @override
  String get pvStatusMissed => 'Manquée';

  @override
  String get pvStatusScheduled => 'Planifiée';

  @override
  String get pvStatusSkipped => 'Passée';

  @override
  String pvStatusSnack(String status) {
    return 'Statut : $status';
  }

  @override
  String get pvStatuses => 'Statuts';

  @override
  String pvStep(int n, int total) {
    return 'Étape $n sur $total';
  }

  @override
  String get pvStop => 'Arrêter';

  @override
  String get pvSwipeVertical => 'Balayer verticalement';

  @override
  String pvTableThreshold(String size) {
    return 'Tableau à partir de $size';
  }

  @override
  String get pvTags => 'Étiquettes';

  @override
  String get pvTextFilterHint => 'Rechercher dans les titres et les notes';

  @override
  String pvTileSemantics(String title, String day, String start, String end, String status) {
    return '$title, $day, de $start à $end, $status';
  }

  @override
  String pvTimeLeft(String duration) {
    return 'Reste : $duration';
  }

  @override
  String get pvTo => 'À';

  @override
  String get pvToggleBacklog => 'Tiroir du backlog';

  @override
  String get pvTopCategories => 'Catégories principales';

  @override
  String get pvTracked => 'Mesuré';

  @override
  String get pvTrackingCheck => 'Case à cocher';

  @override
  String get pvTrackingEvent => 'Événement';

  @override
  String get pvTrackingModes => 'Suivi';

  @override
  String get pvTrackingTimer => 'Minuteur';

  @override
  String get pvUnpin => 'Désépingler';

  @override
  String get pvUnscheduleUnsupported => 'Le retour d’une tâche vers les tâches à planifier n’est pas encore disponible';

  @override
  String get pvUnscheduled => 'Non planifiées';

  @override
  String get pvUnscheduledSnack => 'Déplacé dans le backlog';

  @override
  String get pvUntimed => 'Sans heure';

  @override
  String get pvUpcoming => 'À venir';

  @override
  String pvUrgencyRule(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Urgente sous $days jours',
      one: 'Urgente sous 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get pvUsePlace => 'Utiliser ce lieu';

  @override
  String get pvVarianceLate => 'Commencée en retard';

  @override
  String get pvVarianceNotDone => 'Non faite';

  @override
  String get pvVarianceOnPlan => 'Conforme au plan';

  @override
  String get pvVarianceOverran => 'Dépassement';

  @override
  String get pvVarianceUnplanned => 'Imprévue';

  @override
  String get pvViewAgenda => 'Agenda';

  @override
  String get pvViewBacklog => 'À planifier';

  @override
  String get pvViewCountdown => 'Comptes à rebours';

  @override
  String get pvViewDayList => 'Liste du jour';

  @override
  String get pvViewFocus => 'Concentration';

  @override
  String get pvViewFreeSlots => 'Créneaux libres';

  @override
  String get pvViewHorizons => 'Horizons';

  @override
  String get pvViewKanban => 'Kanban';

  @override
  String get pvViewLoadHeatmap => 'Carte de charge';

  @override
  String get pvViewMap => 'Carte';

  @override
  String get pvViewMatrix => 'Matrice d’Eisenhower';

  @override
  String get pvViewMonth => 'Mois';

  @override
  String get pvViewMultiWeek => 'Plusieurs semaines';

  @override
  String get pvViewNDay => 'N jours';

  @override
  String get pvViewName => 'Nom de la vue';

  @override
  String get pvViewPlanVsActual => 'Prévu ou réel';

  @override
  String get pvViewQuarter => 'Trimestre';

  @override
  String get pvViewRadial => 'Horloge de 24 h';

  @override
  String get pvViewRibbon => 'Ruban';

  @override
  String get pvViewRoutine => 'Lecteur de routine';

  @override
  String get pvViewSaved => 'Vue enregistrée';

  @override
  String get pvViewSettings => 'Réglages de la vue';

  @override
  String get pvViewSwimlanes => 'Couloirs';

  @override
  String get pvViewSwitcher => 'Changer de vue';

  @override
  String get pvViewTable => 'Tableau';

  @override
  String get pvViewTimeline => 'Chronologie';

  @override
  String get pvViewWeekList => 'Liste de la semaine';

  @override
  String get pvViewWeekTable => 'Tableau de la semaine';

  @override
  String get pvViewWorkWeek => 'Semaine de travail';

  @override
  String get pvViewYear => 'Année';

  @override
  String get pvVisibleHours => 'Heures visibles';

  @override
  String get pvVisibleHoursAll => 'Les 24 heures';

  @override
  String pvWeekNumber(int week) {
    return 'S$week';
  }

  @override
  String get pvWeekNumbers => 'Numéros de semaine';

  @override
  String get pvWeekRibbon => 'Semaine';

  @override
  String get pvWeekSummary => 'Bilan de la semaine';

  @override
  String pvWeeksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count semaines', one: '1 semaine');
    return '$_temp0';
  }

  @override
  String get pvWithPlace => 'Tâches avec un lieu';

  @override
  String get pvWorkDaysOnly => 'Jours ouvrés uniquement';

  @override
  String get pvWorkHours => 'Heures de travail';

  @override
  String get pvZoneHint => 'p. ex. Asia/Tokyo';

  @override
  String get pvZoomAroundNow => 'Zoomer autour de maintenant';

  @override
  String get pvZoomFixed => 'Créneau fixe';

  @override
  String get pvZoomMode => 'Zoom';

  @override
  String get pvZoomSemantic => 'Sémantique';

  @override
  String get quitAddUse => '+1';

  @override
  String get quitAllClocks => 'Tous les compteurs';

  @override
  String get quitAmount => 'Quantité';

  @override
  String get quitAutoSuccess => 'Les jours sans rechute comptent comme réussis';

  @override
  String get quitAutoSuccessHint => 'Désactivé : confirmez chaque jour réussi dans le bilan du soir.';

  @override
  String get quitBaseline => 'Avant d\'arrêter, par jour';

  @override
  String quitBreathCycle(int cycle) {
    return 'Cycle $cycle';
  }

  @override
  String get quitBreathHold => 'Retenez';

  @override
  String get quitBreathIn => 'Inspirez';

  @override
  String get quitBreathOut => 'Expirez';

  @override
  String quitBreathPhase(String phase, int seconds) {
    return '$phase · $seconds';
  }

  @override
  String get quitBreathing478 => '4-7-8';

  @override
  String get quitBreathingBox => 'Carrée 4-4-4-4';

  @override
  String get quitBreathingStart => 'Démarrer';

  @override
  String get quitBreathingStop => 'Arrêter';

  @override
  String get quitBreathingTitle => 'Respiration';

  @override
  String quitCleanDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours sans',
      one: '1 jour sans',
      zero: '0 jour sans',
    );
    return '$_temp0';
  }

  @override
  String get quitCleanDaysTitle => 'Jours sans';

  @override
  String get quitCleanSaved => 'Journée marquée comme réussie';

  @override
  String get quitCoping => 'Ce qui m\'a aidé';

  @override
  String get quitCopingBreathing => 'Respiration profonde';

  @override
  String get quitCopingCallFriend => 'Appeler un ami';

  @override
  String get quitCopingDelay10 => 'Attendre 10 minutes';

  @override
  String get quitCopingGum => 'Chewing-gum';

  @override
  String get quitCopingWalk => 'Une marche';

  @override
  String get quitCopingWater => 'Un verre d\'eau';

  @override
  String quitCostPerUnit(String price) {
    return '= $price par unité';
  }

  @override
  String get quitCostTitle => 'Coût';

  @override
  String quitCounterSemantics(int days, int hours, int minutes) {
    return '$days jours $hours heures $minutes minutes';
  }

  @override
  String get quitCravingDetails => 'Ajouter des détails';

  @override
  String get quitCravingLogged => 'Envie notée — bravo de l\'avoir remarquée.';

  @override
  String get quitCravingTitle => 'Envie';

  @override
  String get quitCurrency => 'Devise';

  @override
  String get quitDailyLimit => 'Limite quotidienne';

  @override
  String get quitDayMilestonesTitle => 'Temps d\'abstinence';

  @override
  String quitDaysHours(int days, int hours) {
    return '$days j $hours h';
  }

  @override
  String get quitDistractionExercise => 'De l\'exercice';

  @override
  String get quitDistractionGame => 'Un petit jeu';

  @override
  String get quitDistractionMusic => 'Musique';

  @override
  String get quitDistractionRead => 'Lire';

  @override
  String get quitDistractionShower => 'Une douche';

  @override
  String get quitDistractionSnack => 'Un en-cas sain';

  @override
  String get quitDistractionsEmpty => 'Ajoutez les distractions qui vous aident dans les bibliothèques.';

  @override
  String get quitDistractionsTitle => 'Distractions';

  @override
  String get quitDuration => 'Durée';

  @override
  String get quitEditorEditTitle => 'Modifier le suivi d\'arrêt';

  @override
  String get quitEditorNewTitle => 'Nouveau suivi d\'arrêt';

  @override
  String get quitErrCurrency => 'Utilisez un code devise à 3 lettres (ex. EUR)';

  @override
  String get quitErrDailyLimit => 'Indiquez une limite quotidienne de 0 ou plus';

  @override
  String get quitErrNegative => 'Les valeurs ne peuvent pas être négatives';

  @override
  String get quitErrStartInFuture => 'La date d\'arrêt ne peut pas être dans le futur';

  @override
  String get quitEstimatesNote => 'Toutes les valeurs par défaut sont des estimations — adaptez-les à votre situation.';

  @override
  String quitEventCraving(int intensity) {
    return 'Envie · intensité $intensity';
  }

  @override
  String get quitEventPledge => 'Engagement du jour';

  @override
  String get quitEventRelapse => 'Rechute';

  @override
  String get quitEventRestart => 'Nouvelle tentative d\'arrêt';

  @override
  String get quitHealthTitle => 'Récupération de la santé';

  @override
  String quitIntensity(int value) {
    return 'Intensité : $value/10';
  }

  @override
  String get quitLifePerUnit => 'Espérance de vie par unité';

  @override
  String get quitLifeRegained => 'Vie regagnée';

  @override
  String get quitLogCraving => 'Noter une envie';

  @override
  String get quitLogRelapse => 'Noter une rechute';

  @override
  String get quitLogUse => 'Noter une consommation';

  @override
  String get quitLongest => 'Plus longue série';

  @override
  String get quitManualReset => 'remise à zéro manuelle';

  @override
  String quitMilestoneDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours d\'abstinence',
      one: '1 jour d\'abstinence',
    );
    return '$_temp0';
  }

  @override
  String quitMilestoneElapsed(String percent) {
    return '$percent du temps écoulé';
  }

  @override
  String quitMilestoneEta(String date) {
    return 'Prévue le $date';
  }

  @override
  String quitMilestoneInWindow(String date) {
    return 'En cours · jusqu\'à environ $date';
  }

  @override
  String quitMilestoneReachedOn(String date) {
    return 'Atteinte le $date';
  }

  @override
  String get quitMilestoneSources => 'Sources';

  @override
  String get quitMilestonesClockNote =>
      'Les étapes se comptent depuis votre dernier écart : l\'horloge repart à zéro après un écart.';

  @override
  String get quitMilestonesOpen => 'Toutes les étapes';

  @override
  String get quitMilestonesReached => 'Atteintes';

  @override
  String get quitMilestonesTitle => 'Étapes';

  @override
  String get quitMilestonesUpcoming => 'À venir';

  @override
  String get quitModeAbstain => 'Arrêter complètement';

  @override
  String get quitModeReduce => 'Réduire';

  @override
  String get quitModeTitle => 'Objectif';

  @override
  String get quitMoneySaved => 'Argent économisé';

  @override
  String get quitMotivation => 'Pourquoi j\'arrête';

  @override
  String get quitMotivationCard => 'Mes raisons';

  @override
  String get quitMotivationHint => 'Mes raisons…';

  @override
  String get quitNameAlcohol => 'Arrêter l\'alcool';

  @override
  String get quitNameCaffeine => 'Moins de caféine';

  @override
  String get quitNameCannabis => 'Arrêter le cannabis';

  @override
  String get quitNameCigarettes => 'Arrêter de fumer';

  @override
  String get quitNameGaming => 'Moins de jeux vidéo';

  @override
  String get quitNameOther => 'Arrêter une habitude';

  @override
  String get quitNameSocialMedia => 'Moins de réseaux sociaux';

  @override
  String get quitNameSugar => 'Arrêter le sucre';

  @override
  String get quitNameVape => 'Arrêter de vapoter';

  @override
  String get quitNextMilestone => 'Prochaine étape';

  @override
  String get quitNo => 'Non';

  @override
  String get quitNoEvents => 'Rien de noté pour le moment — continuez !';

  @override
  String get quitNoTrackers => 'Pas encore de suivi d\'arrêt';

  @override
  String get quitNoTrackersBody => 'Suivez depuis combien de temps vous avez arrêté de fumer, de boire ou autre chose.';

  @override
  String get quitNotSure => 'Je ne sais pas';

  @override
  String get quitNote => 'Note';

  @override
  String get quitNotifInvalidIntensity => 'L\'intensité est un nombre de 1 à 10.';

  @override
  String quitNotifMoneyMilestone(String amount) {
    return '$amount économisés';
  }

  @override
  String quitOffsetMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count mois', one: '1 mois');
    return '$_temp0';
  }

  @override
  String quitOffsetRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String quitOffsetWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count semaines', one: '1 semaine');
    return '$_temp0';
  }

  @override
  String quitOffsetYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count ans', one: '1 an');
    return '$_temp0';
  }

  @override
  String get quitOther => 'Autre…';

  @override
  String get quitOverLimit => 'Au-delà de la limite d\'aujourd\'hui';

  @override
  String get quitPackPrice => 'Prix du paquet';

  @override
  String get quitPhotoAfterSave => 'Vous pourrez ajouter une photo motivante après l’enregistrement.';

  @override
  String get quitPlace => 'Lieu';

  @override
  String get quitPlaceBar => 'Bar';

  @override
  String get quitPlaceCar => 'Voiture';

  @override
  String get quitPlaceFriends => 'Chez des amis';

  @override
  String get quitPlaceHome => 'Maison';

  @override
  String get quitPlaceOutside => 'Dehors';

  @override
  String get quitPlaceWork => 'Travail';

  @override
  String get quitPledgeAction => 'Prendre l\'engagement du jour';

  @override
  String get quitPledgeMorning => 'Engagement du matin';

  @override
  String get quitPledgeSaved => 'Engagement enregistré';

  @override
  String quitPledgeStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours d\'engagement d\'affilée',
      one: '1 jour d\'engagement d\'affilée',
    );
    return '$_temp0';
  }

  @override
  String get quitPledgeText => 'Aujourd\'hui, je choisis de tenir bon.';

  @override
  String get quitPledged => 'Engagement pris pour aujourd\'hui';

  @override
  String get quitPopulationEstimate => 'estimation populationnelle';

  @override
  String get quitPopulationEstimateHelp =>
      'Estimation populationnelle : environ 20 min par cigarette (Jackson et al. 2025 ; BMJ 2000 : 11 min). Les effets varient selon les personnes.';

  @override
  String get quitPresetAlcohol => 'Alcool';

  @override
  String get quitPresetCaffeine => 'Caféine';

  @override
  String get quitPresetCannabis => 'Cannabis';

  @override
  String get quitPresetCigarettes => 'Tabac';

  @override
  String get quitPresetGaming => 'Jeux vidéo';

  @override
  String get quitPresetOther => 'Autre chose';

  @override
  String get quitPresetSocialMedia => 'Réseaux sociaux';

  @override
  String get quitPresetSugar => 'Sucre';

  @override
  String get quitPresetTitle => 'Que voulez-vous arrêter ?';

  @override
  String get quitPresetVape => 'Vapotage';

  @override
  String get quitRecentEvents => 'Événements récents';

  @override
  String get quitRelapseAmount => 'Combien ? (facultatif)';

  @override
  String get quitRelapseKindTitle => 'Comment la compter ?';

  @override
  String quitRelapseNewAttempt(String time) {
    return 'Commencer une nouvelle tentative d\'arrêt à partir du $time';
  }

  @override
  String get quitRelapseSaved =>
      'C\'est noté. Soyez indulgent avec vous-même : chaque tentative vous apprend quelque chose.';

  @override
  String get quitRelapseSlip => 'Comme un écart — je garde ma date d\'arrêt ; la série repart de maintenant';

  @override
  String quitRelapseSupport(String duration) {
    return 'Vous avez tenu $duration — cela compte toujours.';
  }

  @override
  String get quitRelapseTitle => 'Noter une rechute';

  @override
  String get quitResetBody => 'Cela note une rechute maintenant. Votre date d\'arrêt reste la même.';

  @override
  String get quitResetCounter => 'Remettre à zéro';

  @override
  String get quitResisted => 'Avez-vous résisté ?';

  @override
  String get quitReviewEvening => 'Bilan du soir';

  @override
  String get quitReviewQuestion => 'Avez-vous tenu bon aujourd\'hui ?';

  @override
  String get quitReviewYesterdayQuestion => 'Avez-vous tenu bon hier ?';

  @override
  String get quitReviewedClean => 'Journée sans consommation — bravo !';

  @override
  String get quitRewardAdd => 'Ajouter une récompense';

  @override
  String get quitRewardClaim => 'Utiliser';

  @override
  String quitRewardClaimed(String date) {
    return 'Obtenue le $date';
  }

  @override
  String get quitRewardClaimedSnack => 'Profitez-en — vous l\'avez mérité.';

  @override
  String quitRewardEta(String date) {
    return 'À portée vers le $date';
  }

  @override
  String get quitRewardName => 'Récompense';

  @override
  String get quitRewardNeedsCost =>
      'Indiquez un prix par unité dans le suivi pour voir ce que vos économies permettent.';

  @override
  String get quitRewardPrice => 'Prix';

  @override
  String get quitRewardReady => 'Vous pouvez vous l\'offrir !';

  @override
  String get quitRewardSaved => 'Récompense enregistrée';

  @override
  String get quitRewardsEmpty => 'Choisissez ce que vos économies vont payer.';

  @override
  String get quitRewardsTitle => 'Ce que mes économies m\'offrent';

  @override
  String get quitRitualEnable => 'Engagement du matin et bilan du soir';

  @override
  String get quitRitualEnableHint =>
      'Un engagement le matin et un bilan le soir. Ajoutez des rappels à ces heures dans la section Rappels.';

  @override
  String get quitRitualTitle => 'Rituel quotidien';

  @override
  String get quitSinceFirstQuit => 'Depuis votre premier arrêt';

  @override
  String get quitSinceLastRelapse => 'Abstinent depuis';

  @override
  String get quitSinceLastUse => 'Depuis la dernière consommation';

  @override
  String get quitStartedAt => 'J\'ai arrêté le';

  @override
  String get quitTimePerUnit => 'Temps passé par unité';

  @override
  String get quitTimeWonBack => 'Temps regagné';

  @override
  String quitTodayUse(String used, String limit) {
    return '$used sur $limit aujourd\'hui';
  }

  @override
  String get quitToolboxDone => 'Trois minutes écoulées — avez-vous résisté ?';

  @override
  String get quitToolboxLogged => 'Envie enregistrée avec sa durée.';

  @override
  String get quitToolboxOpen => 'Ouvrir la boîte à outils';

  @override
  String quitToolboxRemaining(String time) {
    return 'Encore $time';
  }

  @override
  String get quitToolboxStart => 'Lancer le minuteur de 3 minutes';

  @override
  String get quitToolboxThrough => 'C\'est passé';

  @override
  String get quitToolboxTimerHint => 'La plupart des envies passent en 3 à 5 minutes. Tenez bon.';

  @override
  String get quitToolboxTimerTitle => 'Laisser passer l\'envie';

  @override
  String get quitToolboxTitle => 'Boîte à outils';

  @override
  String get quitTrigger => 'Déclencheur';

  @override
  String get quitTriggerAfterMeals => 'Après les repas';

  @override
  String get quitTriggerAlcohol => 'Alcool';

  @override
  String get quitTriggerBoredom => 'Ennui';

  @override
  String get quitTriggerCoffee => 'Café';

  @override
  String get quitTriggerDriving => 'Conduite';

  @override
  String get quitTriggerPhone => 'Téléphone';

  @override
  String get quitTriggerSocial => 'Situations sociales';

  @override
  String get quitTriggerStress => 'Stress';

  @override
  String get quitTriggerWakingUp => 'Réveil';

  @override
  String get quitTriggerWorkBreak => 'Pause au travail';

  @override
  String get quitUnitCost => 'Prix par unité';

  @override
  String get quitUnitDays => 'j';

  @override
  String get quitUnitHours => 'h';

  @override
  String get quitUnitMinutes => 'min';

  @override
  String get quitUnitSeconds => 's';

  @override
  String get quitUnitsAvoided => 'Évités';

  @override
  String get quitUnitsPerPack => 'Unités par paquet';

  @override
  String get quitUseLogged => 'Consommation notée';

  @override
  String get quitVocabAdd => 'Ajouter une entrée';

  @override
  String get quitVocabCoping => 'Stratégies';

  @override
  String get quitVocabDistractions => 'Distractions';

  @override
  String get quitVocabEmpty => 'Rien pour l\'instant — ajoutez les vôtres.';

  @override
  String get quitVocabName => 'Nom';

  @override
  String get quitVocabPlaces => 'Lieux';

  @override
  String get quitVocabRename => 'Renommer';

  @override
  String get quitVocabSaved => 'Bibliothèque mise à jour';

  @override
  String get quitVocabTitle => 'Déclencheurs, lieux et stratégies';

  @override
  String get quitVocabTriggers => 'Déclencheurs';

  @override
  String quitVocabUses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Utilisé $count fois',
      one: 'Utilisé une fois',
      zero: 'Pas encore utilisé',
    );
    return '$_temp0';
  }

  @override
  String get quitWhen => 'Quand';

  @override
  String get quitWithdrawalNow => 'Là où vous en êtes';

  @override
  String get quitWithdrawalTitle => 'Sevrage';

  @override
  String get quitWithinLimitStreakTitle => 'Jours dans la limite';

  @override
  String get quitYes => 'Oui';

  @override
  String get recurAddDate => 'Ajouter';

  @override
  String get recurAddOrdinal => 'Ajouter un jour comme « 2e mardi »';

  @override
  String get recurAddTime => 'Ajouter une heure';

  @override
  String get recurAdvancedTitle => 'Répétition personnalisée';

  @override
  String get recurAfterHint => 'La suivante arrive ce délai après l’achèvement de la précédente.';

  @override
  String get recurAfterPreview => 'Les suivantes dépendent du moment où vous le terminez';

  @override
  String recurAnchorMoved(String date) {
    return 'Première occurrence : $date';
  }

  @override
  String recurCalendarSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours avec des occurrences',
      one: '1 jour avec des occurrences',
      zero: 'aucun jour avec des occurrences',
    );
    return '$_temp0';
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
  String get recurCustomValue => 'Autre valeur…';

  @override
  String get recurEnds => 'Fin';

  @override
  String get recurEndsAfter => 'Après un nombre de fois';

  @override
  String recurEndsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count fois', one: '1 fois');
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
  String get recurExceptionExcluded => 'Exclue';

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
  String recurExceptionRestoreAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Restaurer $count occurrences ?',
      one: 'Restaurer 1 occurrence ?',
    );
    return '$_temp0';
  }

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
  String get recurIssueCountAndUntil => 'Choisissez une date de fin ou un nombre de fois';

  @override
  String get recurIssueDate => 'Date non valide';

  @override
  String get recurIssueEmptyWeekdays => 'Sélectionnez au moins un jour';

  @override
  String get recurIssueInterval => 'L’intervalle doit être d’au moins 1';

  @override
  String get recurIssueMissing => 'La règle est incomplète';

  @override
  String get recurIssueOrdinal => '« 1er », « dernier »… ne fonctionnent qu’avec une répétition mensuelle ou annuelle';

  @override
  String recurIssueQuota(int max) {
    return 'Ce quota est impossible avec cet écart ($max max.)';
  }

  @override
  String recurIssueTooFrequent(int count) {
    return 'Trop fréquent : $count par jour (1440 max.)';
  }

  @override
  String get recurIssueUnsupported => 'Ces options ne peuvent pas être combinées';

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
  String get recurNumbersHint => 'Nombres séparés par des virgules (négatif = depuis la fin)';

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
  String get recurOrdinalPick => 'Quel jour ?';

  @override
  String get recurOrdinalSecondLast => 'Avant-dernier';

  @override
  String recurOrdinalWeekday(String ordinal, String weekday) {
    return '$ordinal $weekday';
  }

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
  String recurPeriodWeek(String date) {
    return 'Semaine du $date';
  }

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
  String recurRemove(String item) {
    return 'Retirer $item';
  }

  @override
  String recurRemoveTime(String time) {
    return 'Retirer $time';
  }

  @override
  String get recurSetPos => 'Ne garder que les positions';

  @override
  String get recurSetPosHint => '1 = première, −1 = dernière date correspondante de chaque période';

  @override
  String get recurSummary => 'Résumé';

  @override
  String get recurTimes => 'Heures de la journée';

  @override
  String recurTimesDefault(String time) {
    return 'À l’heure de début ($time)';
  }

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
  String get recurWarnAllDaySubDaily => 'Un élément sur la journée ne peut pas se répéter dans la journée';

  @override
  String get recurWarnDst => 'Certaines heures tombent lors d’un changement d’heure et sont décalées';

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
  String get recurWeekNumbers => 'Numéros de semaine';

  @override
  String get recurWeekStart => 'La semaine commence le';

  @override
  String get recurWeekdayOrdinal => 'Lequel dans la période';

  @override
  String get recurWeekdays => 'Jours de la semaine';

  @override
  String get recurWindow => 'Plage horaire';

  @override
  String get recurWindowAnchorSeries => 'Continuer la chaîne depuis la première occurrence';

  @override
  String get recurWindowAnchorWindow => 'Recommencer chaque jour au début de la plage';

  @override
  String get recurWindowEnd => 'Jusqu’à';

  @override
  String get recurWindowNone => 'Toute la journée';

  @override
  String get recurWindowStart => 'De';

  @override
  String get recurYearDays => 'Jours de l’année';

  @override
  String recurZoneNote(String zone) {
    return 'Heures de $zone';
  }

  @override
  String redoDoneSnack(String action) {
    return 'Rétabli : $action';
  }

  @override
  String get redoNothing => 'Rien à rétablir';

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'il y a $count jours', one: 'hier');
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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'dans $count jours', one: 'demain');
    return '$_temp0';
  }

  @override
  String relativeInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'dans $count heures', one: 'dans 1 heure');
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
  String get repeatModeAll => 'Tout remettre à faire';

  @override
  String get repeatModeCompleted => 'Décocher seulement les terminés';

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
  String get savedSnack => 'Enregistré';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsAboutSubtitle => 'Version, licences, aide';

  @override
  String get settingsAccessibility => 'Accessibilité';

  @override
  String get settingsAccessibilitySubtitle => 'Animations, vibrations, contraste, libellés';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsAccountLocalOnly => 'Sur cet appareil uniquement';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsAppearanceSubtitle => 'Thème, densité, langue';

  @override
  String get settingsArabicDigits => 'Chiffres arabes orientaux';

  @override
  String get settingsArabicDigitsSubtitle => 'Afficher ٠١٢٣ au lieu de 0123 lorsque l\'app est en arabe';

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
  String get settingsClock => 'Horloge';

  @override
  String get settingsClock12 => '12 heures';

  @override
  String get settingsClock24 => '24 heures';

  @override
  String get settingsCompleteChildren => 'En terminant un parent';

  @override
  String get settingsCurrency => 'Devise des économies (sevrage)';

  @override
  String get settingsCurrentZone => 'Fuseau horaire actuel (cet appareil)';

  @override
  String get settingsDataSubtitle => 'Sauvegarder, restaurer ou transférer vos données';

  @override
  String get settingsDataTitle => 'Export et import';

  @override
  String get settingsDayStart => 'La journée des habitudes commence à';

  @override
  String get settingsDayStartSubtitle =>
      'Les validations avant cette heure comptent pour la veille. S\'applique uniquement aux nouvelles validations.';

  @override
  String get settingsDefaultOpen => 'Ouvrir en';

  @override
  String get settingsDefaultsHint =>
      'Valeurs par défaut des nouveaux éléments. Les éléments existants gardent leurs propres réglages.';

  @override
  String get settingsDensity => 'Densité';

  @override
  String get settingsDensityComfortable => 'Confortable';

  @override
  String get settingsDensityCompact => 'Compacte';

  @override
  String settingsDeviceLastSeen(String when) {
    return 'Vu pour la dernière fois $when';
  }

  @override
  String get settingsDevicePushOff => 'Notifications push désactivées';

  @override
  String get settingsDevicePushOn => 'Notifications push activées';

  @override
  String get settingsDeviceRevoke => 'Retirer l\'appareil';

  @override
  String get settingsDeviceRevokeBody =>
      'Il ne recevra plus de notifications et sera déconnecté à sa prochaine connexion.';

  @override
  String settingsDeviceRevokeTitle(String name) {
    return 'Retirer $name ?';
  }

  @override
  String get settingsDeviceRevoked => 'Appareil retiré';

  @override
  String get settingsDeviceThis => 'Cet appareil';

  @override
  String get settingsDeviceUnknown => 'Appareil inconnu';

  @override
  String get settingsDevices => 'Appareils';

  @override
  String get settingsDevicesEmpty => 'Aucun appareil enregistré pour l\'instant.';

  @override
  String get settingsDevicesOffline => 'Connectez-vous à Internet pour voir vos appareils.';

  @override
  String get settingsDynamicColor => 'Couleurs du fond d\'écran';

  @override
  String get settingsDynamicColorSubtitle =>
      'Utiliser les couleurs Material You de l\'appareil. Les couleurs des catégories ne changent pas.';

  @override
  String get settingsExportAttachments => 'Inclure les pièces jointes';

  @override
  String get settingsExportAttachmentsHint => 'Uniquement les fichiers déjà présents sur cet appareil.';

  @override
  String get settingsExportBody => 'Une copie de toutes vos données sur cet appareil. Fonctionne hors ligne.';

  @override
  String get settingsExportButton => 'Exporter';

  @override
  String get settingsExportCsv => 'Tableurs (CSV)';

  @override
  String get settingsExportCsvHint => 'Un fichier par table pour Excel, Numbers ou Sheets.';

  @override
  String settingsExportDone(String file) {
    return 'Export prêt : $file';
  }

  @override
  String get settingsExportFailed => 'L’export a échoué. Veuillez réessayer.';

  @override
  String get settingsExportJson => 'Sauvegarde Everslot (JSON)';

  @override
  String get settingsExportJsonHint => 'Une copie complète que vous pourrez réimporter.';

  @override
  String settingsExportProgress(int percent) {
    return 'Export en cours… $percent %';
  }

  @override
  String get settingsExportShareSubject => 'Export Everslot';

  @override
  String get settingsExportTitle => 'Exporter';

  @override
  String get settingsFewer => 'Un de moins';

  @override
  String get settingsGroupData => 'Données et confidentialité';

  @override
  String get settingsGroupGeneral => 'Général';

  @override
  String get settingsGroupHelp => 'Aide';

  @override
  String get settingsGroupSections => 'Sections';

  @override
  String get settingsHabits => 'Habitudes';

  @override
  String settingsHabitsDayStartLink(String time) {
    return 'La journée commence à $time';
  }

  @override
  String get settingsHabitsFreezes => 'Jokers de série par mois';

  @override
  String get settingsHabitsFreezesHint => 'Jours manqués pardonnés chaque mois pour les nouvelles habitudes.';

  @override
  String get settingsHabitsSkipBreaks => 'Interrompent la série';

  @override
  String get settingsHabitsSkipNeutral => 'Sans effet sur la série';

  @override
  String get settingsHabitsSkipPolicy => 'Jours sautés';

  @override
  String get settingsHabitsSubtitle => 'Jours sautés, gels de série';

  @override
  String get settingsHideCheckboxes => 'Masquer les cases (puces)';

  @override
  String get settingsHomeZone => 'Fuseau horaire de référence';

  @override
  String get settingsHomeZoneAuto => 'Suivre cet appareil';

  @override
  String get settingsHomeZoneAutoSubtitle => 'Mettre à jour le fuseau de référence automatiquement en voyage';

  @override
  String get settingsHomeZoneSubtitle => 'Les tâches et habitudes à heure fixe utilisent ce fuseau';

  @override
  String get settingsInsights => 'Statistiques';

  @override
  String get settingsInsightsCompare => 'Comparer avec la période précédente';

  @override
  String get settingsInsightsPeriod => 'Période par défaut';

  @override
  String get settingsInsightsSubtitle => 'Période par défaut, comparaisons';

  @override
  String get settingsInsightsWeekStart => 'Début de semaine (statistiques)';

  @override
  String settingsInsightsWeekStartProfile(String day) {
    return 'Comme l’app ($day)';
  }

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get settingsLanguageSystem => 'Langue du système';

  @override
  String get settingsLists => 'Listes';

  @override
  String get settingsListsAutoComplete => 'Terminer les parents automatiquement';

  @override
  String get settingsListsAutoCompleteHint => 'Un parent est terminé quand tous ses sous-éléments le sont.';

  @override
  String get settingsListsCompletedBottom => 'Déplacer les éléments terminés en bas';

  @override
  String get settingsListsProgress => 'La progression compte';

  @override
  String get settingsListsProgressChildren => 'Les sous-éléments directs';

  @override
  String get settingsListsProgressLeaves => 'Chaque élément';

  @override
  String get settingsListsRequireReason => 'Demander une raison quand un élément est';

  @override
  String get settingsListsShowCompleted => 'Afficher les éléments terminés';

  @override
  String get settingsListsSubtitle => 'Statuts, progression, éléments terminés';

  @override
  String get settingsMore => 'Un de plus';

  @override
  String get settingsNotificationsSubtitle => 'Rappels, heures calmes, boîte de réception';

  @override
  String get settingsOrganizationSubtitle => 'Catégories et étiquettes utilisées dans l\'app';

  @override
  String get settingsPeriodLastMonth => 'Le mois dernier';

  @override
  String get settingsPeriodLastWeek => 'La semaine dernière';

  @override
  String settingsPeriodRolling(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days derniers jours', one: 'Dernier jour');
    return '$_temp0';
  }

  @override
  String get settingsPeriodThisMonth => 'Ce mois-ci';

  @override
  String get settingsPeriodThisQuarter => 'Ce trimestre';

  @override
  String get settingsPeriodThisWeek => 'Cette semaine';

  @override
  String get settingsPeriodThisYear => 'Cette année';

  @override
  String get settingsPlan => 'Planning';

  @override
  String get settingsPlanActualAlways => 'Toujours';

  @override
  String get settingsPlanActualNever => 'Jamais';

  @override
  String get settingsPlanActualOffSchedule => 'En cas d’écart';

  @override
  String get settingsPlanActualTime => 'Demander l’heure réelle à la fin';

  @override
  String get settingsPlanDefaultDuration => 'Durée par défaut des tâches';

  @override
  String get settingsPlanDefaultView => 'Vue par défaut';

  @override
  String get settingsPlanDefaultViewNone => 'Tableau de la semaine';

  @override
  String get settingsPlanGrace => 'Manquée après';

  @override
  String settingsPlanGraceValue(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes après la fin',
      one: '1 minute après la fin',
      zero: 'Dès la fin',
    );
    return '$_temp0';
  }

  @override
  String get settingsPlanRollOver => 'Tâches non terminées';

  @override
  String get settingsPlanRollOverAsk => 'Me demander';

  @override
  String get settingsPlanRollOverAuto => 'Les reporter à aujourd’hui';

  @override
  String get settingsPlanRollOverOff => 'Les laisser';

  @override
  String get settingsPlanSubtitle => 'Vue par défaut, durées, heures de travail';

  @override
  String get settingsPlanTracking => 'Suivi par défaut';

  @override
  String get settingsPlanTrackingCheck => 'À cocher';

  @override
  String get settingsPlanTrackingEvent => 'Événement';

  @override
  String get settingsPlanTrackingTimer => 'Minuteur';

  @override
  String get settingsPlanWorkDays => 'Jours travaillés';

  @override
  String get settingsPlanWorkEnd => 'Fin';

  @override
  String get settingsPlanWorkHours => 'Heures de travail';

  @override
  String get settingsPlanWorkStart => 'Début';

  @override
  String get settingsPreview => 'Aperçu';

  @override
  String get settingsPrivacy => 'Confidentialité et sécurité';

  @override
  String get settingsPrivacySubtitle => 'Verrouillage, contenu des notifications masqué';

  @override
  String get settingsProgressChildren => 'Seulement les sous-éléments directs';

  @override
  String get settingsProgressLeaves => 'Tous les sous-éléments';

  @override
  String get settingsProgressMode => 'La progression compte';

  @override
  String get settingsRegional => 'Région';

  @override
  String get settingsRegionalSubtitle => 'Fuseau horaire, début de semaine, horloge, devise';

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
  String get settingsSyncData => 'Synchronisation et données';

  @override
  String get settingsSyncDataSubtitle => 'Appareils, export, import, corbeille';

  @override
  String get settingsSyncDiagnostics => 'Diagnostic de synchronisation';

  @override
  String get settingsSyncDiscardBody => 'La version du serveur de ces éléments est rétablie sur cet appareil.';

  @override
  String get settingsSyncDiscardFailed => 'Abandonner les modifications refusées';

  @override
  String get settingsSyncDiscardTitle => 'Abandonner les modifications refusées ?';

  @override
  String settingsSyncFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications ont été refusées par le serveur',
      one: '$count modification a été refusée par le serveur',
    );
    return '$_temp0';
  }

  @override
  String settingsSyncInitialProgress(int percent) {
    return 'Téléchargement de vos données… $percent %';
  }

  @override
  String get settingsSyncLastError => 'Dernière erreur';

  @override
  String settingsSyncLastSuccess(String when) {
    return 'Dernière synchronisation $when';
  }

  @override
  String get settingsSyncNever => 'Pas encore synchronisé';

  @override
  String get settingsSyncNow => 'Synchroniser maintenant';

  @override
  String get settingsSyncOffBody => 'Vos données sont stockées uniquement sur cet appareil.';

  @override
  String get settingsSyncOffTitle => 'La synchronisation est désactivée';

  @override
  String get settingsSyncRefreshLocalOnly => 'Tout est enregistré sur cet appareil.';

  @override
  String get settingsSyncResync => 'Forcer une resynchronisation complète';

  @override
  String get settingsSyncResyncBody =>
      'Everslot télécharge à nouveau toutes vos données. Les modifications pas encore synchronisées sont conservées.';

  @override
  String get settingsSyncResyncTitle => 'Tout resynchroniser ?';

  @override
  String get settingsSyncRetryFailed => 'Renvoyer les modifications refusées';

  @override
  String get settingsSyncStatus => 'État';

  @override
  String get settingsSyncTitle => 'Synchronisation et appareils';

  @override
  String get settingsSyncTooltip => 'État de la synchronisation';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsTrash => 'Corbeille';

  @override
  String get settingsTrashDeleteForever => 'Supprimer définitivement';

  @override
  String get settingsTrashDeleteForeverBody =>
      'Il sera effacé de tous vos appareils, avec tout ce qui a été supprimé avec lui. Action irréversible.';

  @override
  String settingsTrashDeleteForeverTitle(String title) {
    return 'Supprimer « $title » définitivement ?';
  }

  @override
  String get settingsTrashDeleted => 'Supprimé définitivement';

  @override
  String settingsTrashDeletedWhen(String when) {
    return 'Supprimé $when';
  }

  @override
  String get settingsTrashEmptyAll => 'Vider la corbeille';

  @override
  String settingsTrashEmptyAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments seront supprimés définitivement de tous vos appareils.',
      one: '1 élément sera supprimé définitivement de tous vos appareils.',
    );
    return '$_temp0 Action irréversible.';
  }

  @override
  String get settingsTrashEmptyState => 'La corbeille est vide';

  @override
  String get settingsTrashHint =>
      'Les éléments supprimés restent ici 30 jours. En restaurer un rétablit tout ce qui a été supprimé avec lui.';

  @override
  String get settingsTrashKindAttachment => 'Pièce jointe';

  @override
  String get settingsTrashKindChecklist => 'Liste';

  @override
  String get settingsTrashKindHabit => 'Habitude';

  @override
  String get settingsTrashKindItem => 'Élément de liste';

  @override
  String get settingsTrashKindTask => 'Tâche';

  @override
  String get settingsTrashNotSynced => 'Cette suppression n’est pas encore synchronisée. Réessayez une fois en ligne.';

  @override
  String get settingsTrashOffline => 'Connectez-vous à Internet pour supprimer définitivement.';

  @override
  String get settingsTrashRestore => 'Restaurer';

  @override
  String get settingsTrashRestored => 'Restauré';

  @override
  String get settingsTrashUntitled => 'Sans titre';

  @override
  String settingsTrashWith(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count éléments liés',
      one: '+1 élément lié',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnknownPage => 'Cette page de paramètres n\'existe pas.';

  @override
  String get settingsWeekStart => 'La semaine commence le';

  @override
  String get shellCreate => 'Créer';

  @override
  String shellDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count à faire', one: '1 à faire');
    return '$_temp0';
  }

  @override
  String get shellQuickAdd => 'Ajout rapide';

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
  String get statsCardError => 'Cette carte n’a pas pu être calculée.';

  @override
  String statsClustersEpisodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count fois', one: '1 fois');
    return '$_temp0';
  }

  @override
  String get statsClustersHint =>
      'Choisissez les motifs qui veulent dire la même chose et nommez le groupe. Les groupes s’appliquent à toutes les listes.';

  @override
  String statsClustersIn(String name) {
    return 'dans « $name »';
  }

  @override
  String get statsClustersMerge => 'Fusionner';

  @override
  String get statsClustersName => 'Nom du groupe';

  @override
  String get statsClustersOpen => 'Fusionner les motifs';

  @override
  String get statsClustersTitle => 'Groupes de blocages';

  @override
  String get statsClustersUnmerge => 'Retirer des groupes';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count périodes', one: '1 période');
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
  String get statsEmptyHabits => 'Ajoutez une habitude pour suivre votre régularité.';

  @override
  String get statsEmptyLists => 'Créez une liste pour voir comment le travail avance.';

  @override
  String get statsEmptyPlanner => 'Planifiez quelques tâches et revenez voir vos statistiques.';

  @override
  String get statsEmptyQuit => 'Aucun suivi d’arrêt pour l’instant';

  @override
  String get statsEmptyQuitBody => 'Créez-en un dans Habitudes pour voir vos progrès ici.';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count filtres', one: '1 filtre');
    return '$_temp0';
  }

  @override
  String statsGlossaryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count indicateurs', one: '1 indicateur');
    return '$_temp0';
  }

  @override
  String statsGlossaryEmpty(String query) {
    return 'Aucun indicateur ne correspond à « $query ».';
  }

  @override
  String get statsGlossaryFormula => 'Formule';

  @override
  String get statsGlossarySearch => 'Rechercher un indicateur';

  @override
  String get statsGlossaryTitle => 'Glossaire des indicateurs';

  @override
  String get statsGuidanceLogFromNotifications =>
      'Saisissez depuis les notifications de rappel pour plus de précision.';

  @override
  String get statsGuidanceLogSameDay =>
      'Essayez de saisir le jour même — les saisies tardives sont sujettes aux oublis.';

  @override
  String get statsGuidanceSyncPending =>
      'Certaines modifications d’autres appareils peuvent manquer tant que la synchronisation n’est pas terminée.';

  @override
  String get statsGuidanceTrackTime => 'Lancez le minuteur sur vos tâches pour voir vos heures réelles.';

  @override
  String get statsHealthClockNote =>
      'Les étapes suivent votre temps actuel sans tabac : le compteur redémarre après un écart.';

  @override
  String get statsHealthDisclaimer =>
      'Estimations éducatives fondées sur des moyennes de population de l’OMS, du NHS, des CDC et de l’American Cancer Society ; les résultats individuels varient. Ceci n’est pas un avis médical. Consultez un professionnel de santé.';

  @override
  String get statsHealthElapsedNote => 'Les pourcentages indiquent le temps écoulé, pas des mesures physiologiques.';

  @override
  String statsHealthRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get statsLayoutDone => 'Terminé';

  @override
  String get statsLayoutEdit => 'Personnaliser les cartes';

  @override
  String get statsLayoutHiddenTag => 'Masquée';

  @override
  String statsLayoutHide(String card) {
    return 'Masquer $card';
  }

  @override
  String get statsLayoutHint =>
      'Faites glisser pour réordonner. Épinglez une carte pour la garder en haut ou masquez celles dont vous n’avez pas besoin.';

  @override
  String statsLayoutPin(String card) {
    return 'Épingler $card';
  }

  @override
  String statsLayoutReorder(String card) {
    return 'Réordonner $card';
  }

  @override
  String get statsLayoutReset => 'Rétablir par défaut';

  @override
  String statsLayoutShow(String card) {
    return 'Afficher $card';
  }

  @override
  String statsLayoutUnpin(String card) {
    return 'Désépingler $card';
  }

  @override
  String get statsLoading => 'Mise à jour des statistiques…';

  @override
  String get statsMetricClI01Desc => 'Temps passé par cet élément dans chaque statut.';

  @override
  String get statsMetricClI01Formula => 'Somme des intervalles par statut jusqu’à maintenant (ou suppression).';

  @override
  String get statsMetricClI01Title => 'Temps par statut';

  @override
  String get statsMetricClI02Desc => 'Temps entre le début du travail et l’achèvement.';

  @override
  String get statsMetricClI02Formula => 'Terminé − démarré (première sortie de « à faire »).';

  @override
  String get statsMetricClI02Title => 'Temps de cycle';

  @override
  String get statsMetricClI03Desc => 'Temps entre la création et l’achèvement.';

  @override
  String get statsMetricClI03Formula => 'Terminé − créé.';

  @override
  String get statsMetricClI03Title => 'Délai total';

  @override
  String get statsMetricClI04Desc => 'Depuis combien de temps un élément ouvert est en cours ou attend.';

  @override
  String get statsMetricClI04Formula => 'Démarré : maintenant − début ; non démarré : maintenant − création.';

  @override
  String get statsMetricClI04Title => 'Âge';

  @override
  String get statsMetricClI05Desc => 'Temps écoulé depuis la dernière activité sur cet élément.';

  @override
  String get statsMetricClI05Formula =>
      'Maintenant − dernière activité (statut, modification, pièce jointe ou enfant).';

  @override
  String get statsMetricClI05Title => 'Inactivité';

  @override
  String get statsMetricClI06Desc => 'Achèvement des éléments imbriqués.';

  @override
  String get statsMetricClI06Formula => 'Feuilles terminées ÷ feuilles comptables (annulées exclues).';

  @override
  String get statsMetricClI06Title => 'Avancement du sous-arbre';

  @override
  String get statsMetricClI07Desc => 'L’historique de l’élément en segments colorés avec notes.';

  @override
  String get statsMetricClI07Formula => 'Chaque intervalle de statut de la création à maintenant.';

  @override
  String get statsMetricClI07Title => 'Chronologie des statuts';

  @override
  String get statsMetricClI08Desc => 'Combien de fois et combien de temps cet élément a été bloqué, et pourquoi.';

  @override
  String get statsMetricClI08Formula =>
      'Nombre d’intervalles bloqués, temps bloqué total et sa part du temps de cycle.';

  @override
  String get statsMetricClI08Title => 'Épisodes bloqués';

  @override
  String get statsMetricClI09Desc =>
      'Combien de temps cet élément a attendu quelqu’un ou quelque chose, avec l’état du suivi.';

  @override
  String get statsMetricClI09Formula =>
      'Nombre d’attentes, attente totale, attente en cours ; relance en retard si la date est passée pendant l’attente.';

  @override
  String get statsMetricClI09Title => 'Épisodes d’attente';

  @override
  String get statsMetricClI10Desc => 'Part du temps de cycle passée à travailler activement.';

  @override
  String get statsMetricClI10Formula => 'Temps en cours ÷ temps de cycle.';

  @override
  String get statsMetricClI10Title => 'Efficacité du flux';

  @override
  String get statsMetricClI11Desc => 'À quel point cet élément a changé d’état.';

  @override
  String get statsMetricClI11Formula =>
      'Changements d’état ; réouvertures (terminé → autre) ; boucles en cours ↔ en attente.';

  @override
  String get statsMetricClI11Title => 'Agitation';

  @override
  String get statsMetricClI12Desc => 'Temps d’attente de l’élément avant le début du travail.';

  @override
  String get statsMetricClI12Formula => 'Début − création (temps de file).';

  @override
  String get statsMetricClI12Title => 'Délai avant action';

  @override
  String get statsMetricClI13Desc => 'Fichiers joints à cet élément.';

  @override
  String get statsMetricClI13Formula => 'Nombre, taille totale et répartition par type (images, PDF, autres).';

  @override
  String get statsMetricClI13Title => 'Pièces jointes de l’élément';

  @override
  String get statsMetricClI14Desc => 'Fréquence de modification du texte de l’élément.';

  @override
  String get statsMetricClI14Formula => 'Nombre de modifications du texte ; dernière modification.';

  @override
  String get statsMetricClI14Title => 'Modifications';

  @override
  String get statsMetricClL01Desc => 'Répartition des éléments de la liste par statut.';

  @override
  String get statsMetricClL01Formula => 'Éléments par statut ; % terminé sur les feuilles et sur tous les nœuds.';

  @override
  String get statsMetricClL01Title => 'Répartition des statuts';

  @override
  String get statsMetricClL02Desc => 'Achèvement quotidien de la liste.';

  @override
  String get statsMetricClL02Formula => 'Terminés ÷ (éléments − annulés) à la fin de chaque jour.';

  @override
  String get statsMetricClL02Title => 'Avancement dans le temps';

  @override
  String get statsMetricClL03Desc => 'Éléments terminés par semaine, avec moyenne glissante sur 4 semaines.';

  @override
  String get statsMetricClL03Formula => 'Achèvements par tranche (un élément rouvert compte une fois).';

  @override
  String get statsMetricClL03Title => 'Débit';

  @override
  String get statsMetricClL04Desc => 'Éléments en cours, en attente ou bloqués à la fin de chaque jour.';

  @override
  String get statsMetricClL04Formula => 'Nombre d’éléments en cours + en attente + bloqués.';

  @override
  String get statsMetricClL04Title => 'Travail en cours';

  @override
  String get statsMetricClL05Desc => 'Éléments ajoutés vs terminés chaque semaine.';

  @override
  String get statsMetricClL05Formula => 'Créés (ou déplacés ici) vs terminés par semaine ; flux net = différence.';

  @override
  String get statsMetricClL05Title => 'Arrivées vs sorties';

  @override
  String get statsMetricClL06Desc => 'Éléments ouverts sans activité depuis un moment, et les plus anciens.';

  @override
  String get statsMetricClL06Formula => 'Éléments ouverts inactifs ≥ au seuil ; les 10 plus anciens.';

  @override
  String get statsMetricClL06Title => 'Éléments inactifs';

  @override
  String get statsMetricClL07Desc => 'Nombre d’éléments dans chaque état à la fin de chaque jour.';

  @override
  String get statsMetricClL07Formula =>
      'Comptes de fin de journée par état depuis l’historique ; en cours, temps de cycle approximatif et débit à une date.';

  @override
  String get statsMetricClL07Title => 'Flux cumulé';

  @override
  String get statsMetricClL08Desc => 'Durée des éléments entre le début et la fin.';

  @override
  String get statsMetricClL08Formula =>
      'Histogramme des temps de cycle ; nuage par date de fin avec les lignes P50/P70/P85/P95.';

  @override
  String get statsMetricClL08Title => 'Distribution du temps de cycle';

  @override
  String get statsMetricClL09Desc => '« 85 % des éléments sont terminés en moins de X ».';

  @override
  String get statsMetricClL09Formula => 'P85 du temps de cycle sur les 90 derniers jours.';

  @override
  String get statsMetricClL09Title => 'Niveau de service';

  @override
  String get statsMetricClL10Desc =>
      'Éléments démarrés ouverts par état et par âge ; plus vieux que le temps de cycle habituel = à risque.';

  @override
  String get statsMetricClL10Formula => 'Âge = maintenant − début ; à risque au-delà du P85 du temps de cycle.';

  @override
  String get statsMetricClL10Title => 'Âge du travail en cours';

  @override
  String get statsMetricClL11Desc => 'Éléments restants chaque jour, avec une ligne idéale jusqu’à l’échéance.';

  @override
  String get statsMetricClL11Formula =>
      'Restants = arrivés − terminés − annulés ; cône de prévision si l’historique suffit.';

  @override
  String get statsMetricClL11Title => 'Burn-down';

  @override
  String get statsMetricClL12Desc => 'De combien la liste a grossi après le début du travail.';

  @override
  String get statsMetricClL12Formula =>
      'Éléments ajoutés après la référence ÷ éléments à la référence (premier changement d’état).';

  @override
  String get statsMetricClL12Title => 'Dérive du périmètre';

  @override
  String get statsMetricClL13Desc => 'Part des éléments annulés, et de ceux terminés sans avoir été démarrés.';

  @override
  String get statsMetricClL13Formula => 'Annulés ÷ créés ; terminés sans début ÷ terminés.';

  @override
  String get statsMetricClL13Title => 'Annulés et raccourcis';

  @override
  String get statsMetricClL14Desc => 'Éléments coincés en ce moment, et depuis combien de temps.';

  @override
  String get statsMetricClL14Formula =>
      'Nombres actuels de bloqués et en attente avec leur âge ; temps bloqué sur la période ; motifs principaux.';

  @override
  String get statsMetricClL14Title => 'Bloqués et en attente';

  @override
  String get statsMetricClL15Desc => 'Agissez-vous sur les éléments à leur date de relance ?';

  @override
  String get statsMetricClL15Formula =>
      'Épisodes traités dans les 24 h de la relance ÷ épisodes avec relance ; relances en retard listées.';

  @override
  String get statsMetricClL15Title => 'Discipline de relance';

  @override
  String get statsMetricClL16Desc => 'Profondeur et largeur de la liste.';

  @override
  String get statsMetricClL16Formula =>
      'Profondeur max, profondeur moyenne des feuilles, enfants par parent, feuilles, niveau le plus large et plus grande branche.';

  @override
  String get statsMetricClL16Title => 'Forme de l’arbre';

  @override
  String get statsMetricClL17Desc => 'Éléments dont l’état contredit leurs enfants ou auxquels manque un motif requis.';

  @override
  String get statsMetricClL17Formula =>
      'Parents terminés avec enfants ouverts ; parents ouverts dont tous les enfants sont faits ; motifs manquants.';

  @override
  String get statsMetricClL17Title => 'Contrôles de cohérence';

  @override
  String get statsMetricClL18Desc => 'Avancement, débit et temps bloqué de chaque branche principale.';

  @override
  String get statsMetricClL18Formula =>
      'Avancement par feuilles par branche ; réalisations et temps bloqué sur la période.';

  @override
  String get statsMetricClL18Title => 'Contribution des branches';

  @override
  String get statsMetricClL19Desc =>
      'Fréquence à laquelle les éléments datés sont faits à temps, et ce qui est en retard.';

  @override
  String get statsMetricClL19Formula =>
      'Faits avant l’échéance ÷ terminés avec échéance ; éléments ouverts en retard et retard moyen.';

  @override
  String get statsMetricClL19Title => 'Respect des échéances';

  @override
  String get statsMetricClL20Desc =>
      'Niveau de réalisation de chaque tour de cette liste au moment de la réinitialisation.';

  @override
  String get statsMetricClL20Formula => 'Terminés ÷ éléments par tour ; moyenne et tendance.';

  @override
  String get statsMetricClL20Title => 'Réalisation des tours';

  @override
  String get statsMetricClL21Desc => 'Tours consécutifs terminés à 100 %.';

  @override
  String get statsMetricClL21Formula => 'Série de tours entièrement terminés.';

  @override
  String get statsMetricClL21Title => 'Série de tours parfaits';

  @override
  String get statsMetricClL22Desc => 'Temps nécessaire pour terminer un tour complet.';

  @override
  String get statsMetricClL22Formula => 'Dernière réalisation − début du tour pour les tours à 100 % ; médiane et P85.';

  @override
  String get statsMetricClL22Title => 'Durée d’un tour';

  @override
  String get statsMetricClL23Desc => 'Éléments le plus souvent laissés non faits à la réinitialisation.';

  @override
  String get statsMetricClL23Formula => 'Nombre de fois non terminés et part des tours.';

  @override
  String get statsMetricClL23Title => 'Éléments les plus sautés';

  @override
  String get statsMetricClL24Desc => 'Réalisation moyenne des tours par jour de semaine.';

  @override
  String get statsMetricClL24Formula => '% moyen de réalisation par jour de semaine.';

  @override
  String get statsMetricClL24Title => 'Tours par jour';

  @override
  String get statsMetricClL25Desc => 'Éléments terminés chaque jour dans cette liste, avec la série actuelle.';

  @override
  String get statsMetricClL25Formula => 'Réalisations par jour ; série de jours avec au moins une.';

  @override
  String get statsMetricClL25Title => 'Calendrier des réalisations';

  @override
  String get statsMetricClL26Desc => 'Motifs de blocage similaires regroupés, classés par impact.';

  @override
  String get statsMetricClL26Formula =>
      'Motifs normalisés ; rang = épisodes × heures bloquées ; les groupes se fusionnent dans les réglages.';

  @override
  String get statsMetricClL26Title => 'Groupes de blocages';

  @override
  String get statsMetricClL27Desc =>
      'La fluidité de la liste est-elle assez stable pour s’y fier ? Jamais une prévision.';

  @override
  String get statsMetricClL27Formula =>
      'temps de cycle moyen ÷ (en cours moyen ÷ débit moyen) ; instable hors 0,7–1,3 ou si arrivées ÷ départs sort de 0,8–1,2.';

  @override
  String get statsMetricClL27Title => 'Vérification de la loi de Little';

  @override
  String get statsMetricClL28Desc => 'Quand les éléments restants seront probablement terminés.';

  @override
  String get statsMetricClL28Formula =>
      '10 000 simulations à partir des réalisations quotidiennes récentes ; dates à 50 %, 85 % et 95 % de chances.';

  @override
  String get statsMetricClL28Title => 'Prévision de fin';

  @override
  String get statsMetricClL29Desc => 'Avancement de chaque niveau de l’arbre.';

  @override
  String get statsMetricClL29Formula => 'Terminés ÷ éléments comptables par niveau.';

  @override
  String get statsMetricClL29Title => 'Avancement par niveau';

  @override
  String get statsMetricClL30Desc => 'Fichiers joints dans cette liste.';

  @override
  String get statsMetricClL30Formula => 'Nombre, taille totale et répartition par type.';

  @override
  String get statsMetricClL30Title => 'Pièces jointes de la liste';

  @override
  String get statsMetricClX01Desc => 'Vos listes : actives, archivées, modèles et inactives.';

  @override
  String get statsMetricClX01Formula =>
      'Nombre de listes ; inactive = aucune activité depuis N jours avec des éléments ouverts.';

  @override
  String get statsMetricClX01Title => 'Vue des listes';

  @override
  String get statsMetricClX02Desc => 'Éléments ajoutés vs terminés chaque semaine, toutes listes.';

  @override
  String get statsMetricClX02Formula => 'Créés vs terminés par semaine ; flux net = différence.';

  @override
  String get statsMetricClX02Title => 'Arrivées vs sorties (toutes les listes)';

  @override
  String get statsMetricClX03Desc => 'Éléments en cours, en attente ou bloqués, et les plus anciens.';

  @override
  String get statsMetricClX03Formula => 'Nombres sur les listes actives (archivées exclues).';

  @override
  String get statsMetricClX03Title => 'Travail en cours (toutes les listes)';

  @override
  String get statsMetricClX04Desc => 'Éléments terminés sur la période.';

  @override
  String get statsMetricClX04Formula => 'Achèvements finaux sur la période, comparés à la précédente.';

  @override
  String get statsMetricClX04Title => 'Éléments terminés';

  @override
  String get statsMetricClX05Desc => 'Éléments par statut dans toutes les listes.';

  @override
  String get statsMetricClX05Formula => 'Nombre d’éléments par statut.';

  @override
  String get statsMetricClX05Title => 'Répartition par statut';

  @override
  String get statsMetricClX06Desc => 'Motifs de blocage et d’attente les plus fréquents dans toutes vos listes.';

  @override
  String get statsMetricClX06Formula => 'Pareto des motifs normalisés : épisodes et temps total.';

  @override
  String get statsMetricClX06Title => 'Motifs toutes listes';

  @override
  String get statsMetricClX07Desc => 'Qui ou quoi vos éléments attendent.';

  @override
  String get statsMetricClX07Formula =>
      'Attentes regroupées par personne ou chose : ouvertes, attente moyenne, plus longue attente, relances en retard.';

  @override
  String get statsMetricClX07Title => 'Registre des attentes';

  @override
  String get statsMetricClX08Desc => 'Listes ayant perdu le plus de temps en blocages.';

  @override
  String get statsMetricClX08Formula => 'Listes classées par temps bloqué total sur la période.';

  @override
  String get statsMetricClX08Title => 'Listes les plus bloquées';

  @override
  String get statsMetricClX09Desc => 'Temps de cycle habituel sur toutes les listes et tendance du débit.';

  @override
  String get statsMetricClX09Formula => 'P50/P85 du temps de cycle global ; pente hebdomadaire du débit.';

  @override
  String get statsMetricClX09Title => 'Repères de flux';

  @override
  String get statsMetricClX10Desc => 'Éléments terminés chaque jour dans vos listes, avec la série actuelle.';

  @override
  String get statsMetricClX10Formula => 'Réalisations par jour ; série de jours avec au moins une.';

  @override
  String get statsMetricClX10Title => 'Calendrier des réalisations';

  @override
  String get statsMetricClX11Desc => 'Espace utilisé par les pièces jointes de vos listes.';

  @override
  String get statsMetricClX11Formula => 'Σ des tailles ; nombre et répartition par type.';

  @override
  String get statsMetricClX11Title => 'Stockage des pièces jointes';

  @override
  String get statsMetricClX12Desc => 'Combien de listes vous créez et archivez chaque mois.';

  @override
  String get statsMetricClX12Formula => 'Listes créées et archivées par mois.';

  @override
  String get statsMetricClX12Title => 'Listes créées et archivées';

  @override
  String get statsMetricGl01Desc => 'Votre journée, toutes sections : agenda, habitudes, listes et arrêts.';

  @override
  String get statsMetricGl01Formula => 'Mêmes chiffres que les indicateurs de chaque section pour aujourd’hui.';

  @override
  String get statsMetricGl01Title => 'Aujourd’hui';

  @override
  String get statsMetricGl02Desc => 'Cette semaine jusqu’ici vs les mêmes jours la semaine dernière.';

  @override
  String get statsMetricGl02Formula => 'Indicateurs des sections à date et leur évolution vs la semaine précédente.';

  @override
  String get statsMetricGl02Title => 'La semaine en bref';

  @override
  String get statsMetricGl03Desc =>
      'Votre semaine : chiffres clés, victoires, points d’attention et charge de la semaine suivante.';

  @override
  String get statsMetricGl03Formula => 'Indicateurs des sections et leur évolution vs la semaine précédente.';

  @override
  String get statsMetricGl03Title => 'Bilan hebdomadaire';

  @override
  String get statsMetricGl10Desc =>
      'La fiabilité de vos statistiques : saisie des habitudes, saisies tardives, temps suivi sur les tâches et modifications en attente de synchronisation — chacune avec un conseil pour l’améliorer.';

  @override
  String get statsMetricGl10Formula =>
      'Taux de saisie des habitudes et unités inconnues (30 derniers jours) ; part des saisies tardives (> 24 h) ; couverture du temps réel = occurrences faites avec temps suivi ÷ occurrences faites ; modifications en attente de synchronisation.';

  @override
  String get statsMetricGl10Title => 'Qualité des données';

  @override
  String get statsMetricHbH01Desc => 'À quel point l’habitude est ancrée — les jours récents comptent plus.';

  @override
  String get statsMetricHbH01Formula => 'Score Loop : score = précédent × m + crédit × (1 − m), m = 0,5^(√f ÷ 13).';

  @override
  String get statsMetricHbH01Title => 'Force de l’habitude';

  @override
  String get statsMetricHbH02Desc => 'Unités réussies d’affilée jusqu’à maintenant ; aujourd’hui reste ouvert.';

  @override
  String get statsMetricHbH02Formula => 'Moteur de séries : passages, excuses, pauses et gels sont neutres.';

  @override
  String get statsMetricHbH02Title => 'Série actuelle';

  @override
  String get statsMetricHbH03Desc => 'Votre plus longue suite d’unités réussies.';

  @override
  String get statsMetricHbH03Formula => 'Longueur maximale de série, avec ses dates.';

  @override
  String get statsMetricHbH03Title => 'Meilleure série';

  @override
  String get statsMetricHbH04Desc => 'Vos dix plus longues séries.';

  @override
  String get statsMetricHbH04Formula => 'Séries triées par longueur puis par récence.';

  @override
  String get statsMetricHbH04Title => 'Meilleures séries';

  @override
  String get statsMetricHbH05Desc => 'Part des unités prévues que vous avez réussies.';

  @override
  String get statsMetricHbH05Formula =>
      'Réussies ÷ (unités prévues closes − excusées) ; intervalle de Wilson sous 20 unités.';

  @override
  String get statsMetricHbH05Title => 'Taux de réussite';

  @override
  String get statsMetricHbH06Desc => 'Comment chaque unité prévue s’est terminée.';

  @override
  String get statsMetricHbH06Formula =>
      'Nombre d’unités réussies, partielles, non faites, manquées, passées et excusées.';

  @override
  String get statsMetricHbH06Title => 'Bilan des résultats';

  @override
  String get statsMetricHbH07Desc => 'Réussites (et volume) par semaine, mois ou année.';

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
  String get statsMetricHbH09Desc => 'Chaque validation est un vote pour la personne que vous voulez être.';

  @override
  String get statsMetricHbH09Formula => 'Nombre total de validations manuelles (faites et progression).';

  @override
  String get statsMetricHbH09Title => 'Répétitions totales';

  @override
  String get statsMetricHbH10Desc => 'Part de l’objectif de la période atteinte.';

  @override
  String get statsMetricHbH10Formula => 'Réalisé ÷ (objectif quotidien × jours prévus − jours passés).';

  @override
  String get statsMetricHbH10Title => 'Progression vers l’objectif';

  @override
  String get statsMetricHbH11Desc => 'Tout ce que vous avez enregistré, dans l’unité de l’habitude.';

  @override
  String get statsMetricHbH11Formula => 'Somme des valeurs enregistrées sur la période et au total.';

  @override
  String get statsMetricHbH11Title => 'Volume total';

  @override
  String get statsMetricHbH25Desc =>
      'La part de l’historique de cette habitude réellement enregistrée. Un jour non saisi est inconnu, pas un échec : il compte comme manqué uniquement parce que rien n’a été enregistré.';

  @override
  String get statsMetricHbH25Formula =>
      'Taux de saisie = unités avec au moins une saisie ÷ unités planifiées closes · unités inconnues = unités manquées sans aucune saisie · part des saisies tardives = saisies créées plus de 24 h après la fin de leur unité ÷ toutes les saisies.';

  @override
  String get statsMetricHbH25Title => 'Complétude des données';

  @override
  String get statsMetricHbX01Desc => 'Habitudes prévues réalisées aujourd’hui.';

  @override
  String get statsMetricHbX01Formula => 'Faites ÷ prévues aujourd’hui (habitudes à construire).';

  @override
  String get statsMetricHbX01Title => 'Progression du jour';

  @override
  String get statsMetricHbX02Desc => 'Jours où toutes les habitudes prévues ont été faites.';

  @override
  String get statsMetricHbX02Formula => 'Jours où toutes les unités dues sont faites ; série de journées parfaites.';

  @override
  String get statsMetricHbX02Title => 'Journées parfaites';

  @override
  String get statsMetricHbX03Desc => 'Part des habitudes de chaque jour réalisée.';

  @override
  String get statsMetricHbX03Formula => 'Par jour : faites ÷ prévues, toutes habitudes.';

  @override
  String get statsMetricHbX03Title => 'Réalisation quotidienne';

  @override
  String get statsMetricHbX04Desc => 'Taux de réussite hebdomadaire de toutes les habitudes.';

  @override
  String get statsMetricHbX04Formula =>
      'Faites ÷ prévues par semaine, moyenne glissante 4 semaines ; Δ vs semaine précédente.';

  @override
  String get statsMetricHbX04Title => 'Tendance d’assiduité';

  @override
  String get statsMetricHbX05Desc => 'Argent économisé, unités évitées et vie regagnée, tous arrêts confondus.';

  @override
  String get statsMetricHbX05Formula => 'Sommes sur les suivis d’arrêt actifs (la vie regagnée est une estimation).';

  @override
  String get statsMetricHbX05Title => 'Bilan des arrêts';

  @override
  String get statsMetricHbX12Desc =>
      'Les mêmes mesures de complétude pour toutes les habitudes : taux de saisie, unités non saisies (inconnues) et saisies tardives.';

  @override
  String get statsMetricHbX12Formula =>
      'Σ unités avec saisie ÷ Σ unités planifiées closes de toutes les habitudes ; Σ unités inconnues ; Σ saisies tardives ÷ Σ saisies.';

  @override
  String get statsMetricHbX12Title => 'Complétude des données (toutes les habitudes)';

  @override
  String get statsMetricPlS01Desc => 'Nombre d’échéances de la série sur la période.';

  @override
  String get statsMetricPlS01Formula => 'Occurrences de la règle dans la fenêtre ; closes et ouvertes comptées à part.';

  @override
  String get statsMetricPlS01Title => 'Occurrences attendues';

  @override
  String get statsMetricPlS02Desc => 'Répartition des occurrences de la série par résultat.';

  @override
  String get statsMetricPlS02Formula => 'Nombre d’occurrences faites (D), manquées (M), passées (K) et excusées (X).';

  @override
  String get statsMetricPlS02Title => 'Faits, manqués, passés';

  @override
  String get statsMetricPlS03Desc => 'Part des occurrences dues que vous avez réalisées.';

  @override
  String get statsMetricPlS03Formula =>
      'Faits ÷ (attendus − excusés), avec moyenne glissante sur 4 semaines et tendance hebdomadaire.';

  @override
  String get statsMetricPlS03Title => 'Assiduité';

  @override
  String get statsMetricPlS04Desc => 'Part des occurrences dues manquées ou non faites.';

  @override
  String get statsMetricPlS04Formula => '(Manqués + non faits) ÷ (attendus − excusés).';

  @override
  String get statsMetricPlS04Title => 'Taux d’oubli';

  @override
  String get statsMetricPlS05Desc => 'Occurrences réalisées d’affilée ; les passages sont neutres par défaut.';

  @override
  String get statsMetricPlS05Formula => 'Moteur de séries, une unité par occurrence.';

  @override
  String get statsMetricPlS05Title => 'Série actuelle et record';

  @override
  String get statsMetricPlS06Desc => 'Temps suivi et prévu cumulé depuis le début de la série.';

  @override
  String get statsMetricPlS06Formula => 'Totaux cumulés des minutes réelles et prévues.';

  @override
  String get statsMetricPlS06Title => 'Temps investi';

  @override
  String get statsMetricPlS07Desc => 'Nombre total d’occurrences réalisées.';

  @override
  String get statsMetricPlS07Formula => 'Nombre d’occurrences faites.';

  @override
  String get statsMetricPlS07Title => 'Total réalisé';

  @override
  String get statsMetricPlS08Desc => 'Jours depuis la dernière occurrence réalisée.';

  @override
  String get statsMetricPlS08Formula => 'Aujourd’hui − date de la dernière réalisation.';

  @override
  String get statsMetricPlS08Title => 'Dernière réalisation';

  @override
  String get statsMetricPlS09Desc => 'Résultat de chaque jour pour la série.';

  @override
  String get statsMetricPlS09Formula => 'Pire résultat du jour : manqué > partiel > en retard > passé > fait > excusé.';

  @override
  String get statsMetricPlS09Title => 'Calendrier des résultats';

  @override
  String get statsMetricPlS10Desc => 'Part des occurrences prévues que vous avez sautées, et pourquoi.';

  @override
  String get statsMetricPlS10Formula => 'Sautées ÷ prévues ; motifs classés par nombre.';

  @override
  String get statsMetricPlS10Title => 'Taux et motifs d’annulation';

  @override
  String get statsMetricPlS11Desc => 'Part des démarrages dans le délai de grâce, avec les retards par mois.';

  @override
  String get statsMetricPlS11Formula => 'Démarrages à l’heure ÷ occurrences démarrées ; boîte à moustaches du retard.';

  @override
  String get statsMetricPlS11Title => 'Ponctualité au démarrage';

  @override
  String get statsMetricPlS12Desc => 'Part des occurrences réalisées terminées à l’heure.';

  @override
  String get statsMetricPlS12Formula => 'Réalisées à temps ÷ réalisées.';

  @override
  String get statsMetricPlS12Title => 'Réalisation à temps';

  @override
  String get statsMetricPlS13Desc => 'Vos dix plus longues séries pour cette tâche récurrente.';

  @override
  String get statsMetricPlS13Formula => 'Séries classées par longueur, puis par date.';

  @override
  String get statsMetricPlS13Title => 'Meilleures séries';

  @override
  String get statsMetricPlS14Desc => 'Solidité de l’habitude (score de type Loop).';

  @override
  String get statsMetricPlS14Formula => 'score = score·m + fait·(1 − m), m = 0,5^(√f/13), f = occurrences par jour.';

  @override
  String get statsMetricPlS14Title => 'Force de la routine';

  @override
  String get statsMetricPlS15Desc => 'Régularité de la durée réelle et comparaison avec le plan.';

  @override
  String get statsMetricPlS15Formula =>
      'Médiane, moyenne, écart type et CV des minutes réelles ; médiane de réel ÷ prévu.';

  @override
  String get statsMetricPlS15Title => 'Stabilité de la durée';

  @override
  String get statsMetricPlS16Desc => 'Assiduité pour chaque jour de semaine prévu par la règle.';

  @override
  String get statsMetricPlS16Formula => 'Réalisées ÷ occurrences closes non excusées, par jour.';

  @override
  String get statsMetricPlS16Title => 'Profil par jour';

  @override
  String get statsMetricPlS17Desc => 'À quelle heure vous terminez habituellement cette tâche.';

  @override
  String get statsMetricPlS17Formula => 'Occurrences réalisées par heure de fin.';

  @override
  String get statsMetricPlS17Title => 'Heures de réalisation';

  @override
  String get statsMetricPlS18Desc => 'Fréquence et ampleur des déplacements des occurrences de cette série.';

  @override
  String get statsMetricPlS18Formula => 'Déplacées ≥ 1× ÷ occurrences ; déplacements moyens ; report moyen.';

  @override
  String get statsMetricPlS18Title => 'Reprogrammations de la série';

  @override
  String get statsMetricPlS19Desc => 'Assiduité avant et après chaque modification de la règle.';

  @override
  String get statsMetricPlS19Formula => 'Assiduité sur les 28 jours avant et après chaque modification.';

  @override
  String get statsMetricPlS19Title => 'Changements de règle';

  @override
  String get statsMetricPlS20Desc => 'À quelle heure vous commencez réellement, et avec quelle régularité.';

  @override
  String get statsMetricPlS20Formula => 'Moyenne et écart type circulaires des heures de début (ou de fin).';

  @override
  String get statsMetricPlS20Title => 'Régularité de l’horaire';

  @override
  String get statsMetricPlS21Desc => 'De combien vous commencez en général avant ou après l’heure prévue.';

  @override
  String get statsMetricPlS21Formula => 'Moyenne circulaire de (début réel − début prévu), dans ±12 h.';

  @override
  String get statsMetricPlS21Title => 'Décalage du début';

  @override
  String get statsMetricPlT01Desc => 'Durée prévue pour cette occurrence.';

  @override
  String get statsMetricPlT01Formula => 'Fin prévue − début prévu.';

  @override
  String get statsMetricPlT01Title => 'Durée prévue';

  @override
  String get statsMetricPlT02Desc => 'Temps réellement suivi sur cette occurrence, pauses exclues.';

  @override
  String get statsMetricPlT02Formula => 'Somme des sessions suivies ; inconnue si rien n’a été suivi.';

  @override
  String get statsMetricPlT02Title => 'Durée réelle';

  @override
  String get statsMetricPlT03Desc => 'Différence entre temps réel et prévu, et leur rapport.';

  @override
  String get statsMetricPlT03Formula => 'Réel − prévu ; rapport R = réel ÷ prévu (si prévu ≥ 5 min).';

  @override
  String get statsMetricPlT03Title => 'Écart de durée';

  @override
  String get statsMetricPlT04Desc => 'Avance ou retard du démarrage par rapport au plan.';

  @override
  String get statsMetricPlT04Formula => 'Début de la 1re session − début prévu ; à l’heure dans la marge de tolérance.';

  @override
  String get statsMetricPlT04Title => 'Retard au démarrage';

  @override
  String get statsMetricPlT05Desc => 'Avance ou retard de la fin de l’occurrence.';

  @override
  String get statsMetricPlT05Formula => 'Achèvement (ou fin de la dernière session) − fin prévue.';

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
  String get statsMetricPlT07Desc => 'Depuis combien de temps une occurrence non terminée est en retard.';

  @override
  String get statsMetricPlT07Formula => 'Maintenant − fin prévue, par tranches 1 / 7 / 14 / 30+ jours.';

  @override
  String get statsMetricPlT07Title => 'Ancienneté du retard';

  @override
  String get statsMetricPlT08Desc =>
      'Nombre de fois où cette occurrence a été déplacée. Les déplacements de toute la série comptent une fois par occurrence concernée.';

  @override
  String get statsMetricPlT08Formula => 'Nombre d’événements « reprogrammé » de cette occurrence.';

  @override
  String get statsMetricPlT08Title => 'Reprogrammations';

  @override
  String get statsMetricPlT09Desc => 'Temps total de déplacement de cette occurrence, dans les deux sens.';

  @override
  String get statsMetricPlT09Formula => 'Σ |nouveau début − ancien début| sur tous les déplacements.';

  @override
  String get statsMetricPlT09Title => 'Distance de reprogrammation';

  @override
  String get statsMetricPlT10Desc => 'Écart entre le début final et le premier début prévu.';

  @override
  String get statsMetricPlT10Formula => 'Début prévu final − premier début prévu.';

  @override
  String get statsMetricPlT10Title => 'Dérive nette';

  @override
  String get statsMetricPlT11Desc => 'Signale une occurrence sans cesse repoussée.';

  @override
  String get statsMetricPlT11Formula => 'Affiché quand l’occurrence a été déplacée 3 fois ou plus.';

  @override
  String get statsMetricPlT11Title => 'Effet boule de neige';

  @override
  String get statsMetricPlT12Desc => 'Temps entre la création de la tâche et sa réalisation.';

  @override
  String get statsMetricPlT12Formula => 'Heure de fin − heure de création de la tâche.';

  @override
  String get statsMetricPlT12Title => 'Délai total';

  @override
  String get statsMetricPlT13Desc => 'Temps entre la création de la tâche et le début du travail.';

  @override
  String get statsMetricPlT13Formula => 'Début de la première session − heure de création.';

  @override
  String get statsMetricPlT13Title => 'Latence de démarrage';

  @override
  String get statsMetricPlT14Desc => 'Avec combien d’avance l’occurrence a été planifiée.';

  @override
  String get statsMetricPlT14Formula => 'Premier début prévu − heure de création.';

  @override
  String get statsMetricPlT14Title => 'Horizon de planification';

  @override
  String get statsMetricPlT15Desc =>
      'Part du temps suivi passé dans le créneau prévu, avec les minutes débordant avant et après.';

  @override
  String get statsMetricPlT15Formula => 'Recouvrement(sessions, créneau prévu) ÷ minutes réelles.';

  @override
  String get statsMetricPlT15Title => 'Respect du créneau';

  @override
  String get statsMetricPlT16Desc =>
      'Sessions suivies de cette occurrence : nombre, total, durée moyenne, pauses et plus long bloc sans interruption.';

  @override
  String get statsMetricPlT16Formula =>
      'Pauses = écarts ≥ 2 min ; des sessions séparées de moins de 2 min forment un bloc.';

  @override
  String get statsMetricPlT16Title => 'Sessions de concentration';

  @override
  String get statsMetricPlT17Desc => 'Part de l’occurrence qui a été réalisée.';

  @override
  String get statsMetricPlT17Formula => 'Pourcentage d’avancement enregistré avec l’occurrence.';

  @override
  String get statsMetricPlT17Title => 'Réalisation partielle';

  @override
  String get statsMetricPlT18Desc => 'Votre note (1–5) et votre commentaire sur cette occurrence.';

  @override
  String get statsMetricPlT18Formula => 'Note et commentaire enregistrés à la fin.';

  @override
  String get statsMetricPlT18Title => 'Auto-évaluation';

  @override
  String get statsMetricPlX01Desc => 'Part de ce qui était prévu en début de période que vous avez réalisé.';

  @override
  String get statsMetricPlX01Formula =>
      'Prévus et faits dans la période ÷ prévus au début de la période ; les ajouts ultérieurs sont exclus.';

  @override
  String get statsMetricPlX01Title => 'Réalisation du plan';

  @override
  String get statsMetricPlX02Desc => 'Tâches prévues et réalisées chaque jour.';

  @override
  String get statsMetricPlX02Formula => 'Par jour : nombre prévu (plan initial) et fait.';

  @override
  String get statsMetricPlX02Title => 'Faits vs prévus par jour';

  @override
  String get statsMetricPlX03Desc =>
      'Tâches ajoutées après le début de la période et tâches déplacées hors ou dans la période.';

  @override
  String get statsMetricPlX03Formula => 'Nombre d’ajouts imprévus, d’occurrences sorties et entrées.';

  @override
  String get statsMetricPlX03Title => 'Imprévus et déplacés';

  @override
  String get statsMetricPlX04Desc => 'Tâches créées vs réalisées chaque semaine, et backlog ouvert.';

  @override
  String get statsMetricPlX04Formula =>
      'Créées et réalisées par semaine ; backlog = tâches non planifiées + occurrences en retard.';

  @override
  String get statsMetricPlX04Title => 'Flux du backlog';

  @override
  String get statsMetricPlX05Desc => 'Part des tâches réalisées avant leur fin prévue.';

  @override
  String get statsMetricPlX05Formula => 'Faites à l’heure ÷ faites (marge de tolérance incluse).';

  @override
  String get statsMetricPlX05Title => 'Réalisation à l’heure';

  @override
  String get statsMetricPlX06Desc => 'Tâches non terminées dont la fin prévue est dépassée, par ancienneté.';

  @override
  String get statsMetricPlX06Formula => 'Occurrences ouvertes en retard, par tranches 1 / 7 / 14 / 30+ jours.';

  @override
  String get statsMetricPlX06Title => 'En retard maintenant';

  @override
  String get statsMetricPlX07Desc => 'Temps disponible pour le travail planifié sur la période.';

  @override
  String get statsMetricPlX07Formula => 'Heures de travail par jour moins les blocs indisponibles, sur la période.';

  @override
  String get statsMetricPlX07Title => 'Capacité';

  @override
  String get statsMetricPlX08Desc => 'Part de votre capacité occupée par des tâches prévues.';

  @override
  String get statsMetricPlX08Formula => 'Minutes prévues dans les heures de travail ÷ capacité (peut dépasser 100 %).';

  @override
  String get statsMetricPlX08Title => 'Taux de charge prévu';

  @override
  String get statsMetricPlX09Desc => 'Part de votre capacité consacrée au travail suivi.';

  @override
  String get statsMetricPlX09Formula =>
      'Minutes suivies dans les heures de travail ÷ capacité ; requiert 60 % de suivi.';

  @override
  String get statsMetricPlX09Title => 'Taux de charge réel';

  @override
  String get statsMetricPlX10Desc => 'Jours où plus est prévu que le temps disponible.';

  @override
  String get statsMetricPlX10Formula => 'Jours où la charge prévue > capacité ; dépassement = charge − capacité.';

  @override
  String get statsMetricPlX10Title => 'Jours surchargés';

  @override
  String get statsMetricPlX11Desc => 'Capacité restante d’ici la fin de la période.';

  @override
  String get statsMetricPlX11Formula => 'Capacité restante − temps prévu restant (à partir de maintenant).';

  @override
  String get statsMetricPlX11Title => 'Temps libre restant';

  @override
  String get statsMetricPlX12Desc => 'Temps prévu et suivi par jour et par catégorie.';

  @override
  String get statsMetricPlX12Formula => 'Somme des minutes prévues vs somme des minutes suivies.';

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
  String get statsMetricPlX15Desc => 'Part du temps prévu occupée par des événements plutôt que des tâches.';

  @override
  String get statsMetricPlX15Formula => 'Minutes d’événements ÷ (minutes d’événements + de tâches).';

  @override
  String get statsMetricPlX15Title => 'Événements vs tâches';

  @override
  String get statsMetricPlX16Desc => 'Répartition de votre temps selon la priorité des tâches.';

  @override
  String get statsMetricPlX16Formula => 'Σ minutes par priorité 0–4 (réel si suivi, sinon prévu).';

  @override
  String get statsMetricPlX16Title => 'Temps par priorité';

  @override
  String get statsMetricPlX17Desc =>
      'Minutes par étiquette. Une tâche à plusieurs étiquettes compte entièrement pour chacune.';

  @override
  String get statsMetricPlX17Formula => 'Σ minutes par étiquette.';

  @override
  String get statsMetricPlX17Title => 'Temps par étiquette';

  @override
  String get statsMetricPlX18Desc => 'Votre temps et vos réalisations vont-ils aux tâches prioritaires ?';

  @override
  String get statsMetricPlX18Formula => 'Part du temps sur les priorités 3–4 ; taux de réalisation haute vs basse.';

  @override
  String get statsMetricPlX18Title => 'Alignement des priorités';

  @override
  String get statsMetricPlX19Desc => 'Votre temps par catégorie, puis par tâche.';

  @override
  String get statsMetricPlX19Formula => 'Surface ∝ minutes (catégorie → tâche).';

  @override
  String get statsMetricPlX19Title => 'Carte de l’allocation';

  @override
  String get statsMetricPlX20Desc =>
      'Part de votre temps consacrée aux séries récurrentes plutôt qu’aux tâches ponctuelles.';

  @override
  String get statsMetricPlX20Formula => 'Minutes récurrentes ÷ toutes les minutes ; réalisations de chaque type.';

  @override
  String get statsMetricPlX20Title => 'Récurrent vs ponctuel';

  @override
  String get statsMetricPlX21Desc => 'Vos tâches durent-elles en général plus ou moins que prévu ?';

  @override
  String get statsMetricPlX21Formula => 'exp(médiane ln(réel ÷ prévu)) − 1 ; nécessite 10 occurrences suivies.';

  @override
  String get statsMetricPlX21Title => 'Biais d’estimation';

  @override
  String get statsMetricPlX22Desc => 'Taille moyenne de l’écart entre durée prévue et réelle.';

  @override
  String get statsMetricPlX22Formula => 'moyenne(|réel − prévu| ÷ prévu) (MAPE).';

  @override
  String get statsMetricPlX22Title => 'Erreur d’estimation';

  @override
  String get statsMetricPlX23Desc => 'Temps à ajouter aux estimations pour que 8 tâches sur 10 tiennent.';

  @override
  String get statsMetricPlX23Formula => 'P80(réel ÷ prévu) − 1.';

  @override
  String get statsMetricPlX23Title => 'Marge conseillée';

  @override
  String get statsMetricPlX24Desc => 'Chaque occurrence suivie selon sa durée prévue et réelle.';

  @override
  String get statsMetricPlX24Formula => 'Points (prévu, réel) avec la droite y = x et une bande de ±20 %.';

  @override
  String get statsMetricPlX24Title => 'Prévu vs réel';

  @override
  String get statsMetricPlX25Desc => 'Durée habituelle des tâches que vous planifiez.';

  @override
  String get statsMetricPlX25Formula => 'Histogramme des minutes prévues ; médiane et moyenne.';

  @override
  String get statsMetricPlX25Title => 'Durées prévues';

  @override
  String get statsMetricPlX26Desc => 'Biais et erreur d’estimation par catégorie.';

  @override
  String get statsMetricPlX26Formula => 'Biais et MAPE calculés dans chaque catégorie.';

  @override
  String get statsMetricPlX26Title => 'Précision par catégorie';

  @override
  String get statsMetricPlX27Desc => 'Part des occurrences démarrées à l’heure.';

  @override
  String get statsMetricPlX27Formula => 'Démarrages à l’heure ÷ occurrences démarrées.';

  @override
  String get statsMetricPlX27Title => 'Ponctualité';

  @override
  String get statsMetricPlX28Desc => 'Retard habituel entre le début prévu et réel, par jour et heure.';

  @override
  String get statsMetricPlX28Formula => 'Médiane, moyenne et P85 de (début réel − début prévu).';

  @override
  String get statsMetricPlX28Title => 'Retard au démarrage';

  @override
  String get statsMetricPlX29Desc => 'Part des occurrences déplacées au moins une fois, dans un sens ou l’autre.';

  @override
  String get statsMetricPlX29Formula => 'Occurrences déplacées ≥ 1× ÷ occurrences de la période.';

  @override
  String get statsMetricPlX29Title => 'Part reprogrammée';

  @override
  String get statsMetricPlX30Desc => 'Quantité de travail repoussée et fréquence des déplacements.';

  @override
  String get statsMetricPlX30Formula =>
      'Σ des reports vers l’avant (heures) ; déplacements moyens par occurrence déplacée.';

  @override
  String get statsMetricPlX30Title => 'Heures reportées';

  @override
  String get statsMetricPlX31Desc => 'Part des occurrences finalement plus tardives que prévu au départ.';

  @override
  String get statsMetricPlX31Formula => 'Occurrences dont le début final > premier début prévu ÷ occurrences.';

  @override
  String get statsMetricPlX31Title => 'Indice de procrastination';

  @override
  String get statsMetricPlX32Desc => 'Part des occurrences prévues sautées, et les motifs les plus fréquents.';

  @override
  String get statsMetricPlX32Formula => 'Sautées ÷ prévues ; motifs classés par nombre.';

  @override
  String get statsMetricPlX32Title => 'Annulations et motifs';

  @override
  String get statsMetricPlX33Desc =>
      'À quels moments de la semaine se situent votre temps prévu, suivi ou vos réalisations.';

  @override
  String get statsMetricPlX33Formula => 'Minutes (ou réalisations) par jour × heure.';

  @override
  String get statsMetricPlX33Title => 'Heures chargées';

  @override
  String get statsMetricPlX34Desc => 'Taux de réalisation et heures travaillées par jour de semaine.';

  @override
  String get statsMetricPlX34Formula => 'Réalisées ÷ occurrences closes et heures suivies par jour.';

  @override
  String get statsMetricPlX34Title => 'Meilleurs jours';

  @override
  String get statsMetricPlX35Desc => 'Fréquence à laquelle chaque créneau de la semaine contient du travail prévu.';

  @override
  String get statsMetricPlX35Formula => 'Semaines avec une tâche prévue dans le créneau ÷ semaines de la période.';

  @override
  String get statsMetricPlX35Title => 'Occupation des créneaux';

  @override
  String get statsMetricPlX36Desc => 'Créneaux des heures de travail jamais occupés sur au moins 4 semaines.';

  @override
  String get statsMetricPlX36Formula => 'Créneaux des heures de travail occupés à 0 %.';

  @override
  String get statsMetricPlX36Title => 'Créneaux inutilisés';

  @override
  String get statsMetricPlX37Desc => 'Taux de réalisation selon l’heure de début prévue.';

  @override
  String get statsMetricPlX37Formula => 'Réalisées ÷ occurrences closes par heure de début prévue.';

  @override
  String get statsMetricPlX37Title => 'Heures les plus productives';

  @override
  String get statsMetricPlX38Desc => 'Heures passées en blocs ininterrompus d’au moins la durée de travail profond.';

  @override
  String get statsMetricPlX38Formula =>
      'Blocs ≥ 60 min (réglage) ; les sessions d’une même tâche séparées de < 2 min sont fusionnées.';

  @override
  String get statsMetricPlX38Title => 'Travail profond';

  @override
  String get statsMetricPlX39Desc => 'Temps suivi en dehors de vos heures de travail et le week-end.';

  @override
  String get statsMetricPlX39Formula => 'Σ minutes suivies hors heures de travail ; minutes du week-end.';

  @override
  String get statsMetricPlX39Title => 'Travail hors horaires';

  @override
  String get statsMetricPlX40Desc => 'Votre usage du minuteur.';

  @override
  String get statsMetricPlX40Formula => 'Sessions, durée moyenne, part des occurrences réalisées avec sessions.';

  @override
  String get statsMetricPlX40Title => 'Utilisation du minuteur';

  @override
  String get statsMetricPlX41Desc =>
      'Part des occurrences réalisées avec du temps suivi — la base des métriques de durée.';

  @override
  String get statsMetricPlX41Formula => 'Occurrences réalisées avec sessions ÷ occurrences réalisées.';

  @override
  String get statsMetricPlX41Title => 'Couverture du temps réel';

  @override
  String get statsMetricPlX42Desc =>
      'Jours (ou semaines) consécutifs atteignant votre objectif de réalisations. Les jours off ne la cassent pas.';

  @override
  String get statsMetricPlX42Formula => 'Jours d’affilée avec ≥ N réalisations ; les jours sans capacité sont neutres.';

  @override
  String get statsMetricPlX42Title => 'Série d’objectif';

  @override
  String get statsMetricPlX43Desc => 'À quel point votre temps libre pendant les heures de travail est morcelé.';

  @override
  String get statsMetricPlX43Formula => '1 − plus grand bloc libre ÷ temps libre total (0 = un seul bloc).';

  @override
  String get statsMetricPlX43Title => 'Fragmentation';

  @override
  String get statsMetricPlX44Desc => 'Fréquence des changements de catégorie entre sessions consécutives.';

  @override
  String get statsMetricPlX44Formula => 'Changements de catégorie entre sessions consécutives ÷ heures suivies.';

  @override
  String get statsMetricPlX44Title => 'Changements de contexte';

  @override
  String get statsMetricPlX45Desc => 'Score pondéré de votre temps selon vos poids de catégories (0–4).';

  @override
  String get statsMetricPlX45Formula => '100 · Σ(poids × minutes) ÷ (4 · Σ minutes) sur les catégories pondérées.';

  @override
  String get statsMetricPlX45Title => 'Score de productivité';

  @override
  String get statsMetricPlX46Desc => 'Avec combien d’avance vous planifiez habituellement vos tâches.';

  @override
  String get statsMetricPlX46Formula => 'Histogramme de (premier début prévu − création), en heures.';

  @override
  String get statsMetricPlX46Title => 'Anticipation';

  @override
  String get statsMetricQt01Desc => 'Temps écoulé depuis votre date d’arrêt.';

  @override
  String get statsMetricQt01Formula => 'Maintenant − date d’arrêt (en direct).';

  @override
  String get statsMetricQt01Title => 'Depuis l’arrêt';

  @override
  String get statsMetricQt02Desc => 'Temps depuis la dernière consommation (ou l’arrêt).';

  @override
  String get statsMetricQt02Formula => 'Maintenant − max(date d’arrêt, dernière consommation) (en direct).';

  @override
  String get statsMetricQt02Title => 'Abstinence actuelle';

  @override
  String get statsMetricQt03Desc => 'Votre plus longue période sans consommer.';

  @override
  String get statsMetricQt03Formula => 'Plus long écart entre l’arrêt, les consommations et maintenant.';

  @override
  String get statsMetricQt03Title => 'Plus longue abstinence';

  @override
  String get statsMetricQt04Desc => 'Jours depuis l’arrêt sans aucune consommation.';

  @override
  String get statsMetricQt04Formula => 'Nombre de jours clos sans consommation.';

  @override
  String get statsMetricQt04Title => 'Jours d’abstinence';

  @override
  String get statsMetricQt05Desc => 'Part des jours sans consommation depuis l’arrêt.';

  @override
  String get statsMetricQt05Formula => 'Jours d’abstinence ÷ jours clos depuis l’arrêt.';

  @override
  String get statsMetricQt05Title => 'Part de jours d’abstinence';

  @override
  String get statsMetricQt06Desc => 'Unités non consommées grâce à l’arrêt.';

  @override
  String get statsMetricQt06Formula => 'Référence par jour × jours − unités consommées (minimum 0).';

  @override
  String get statsMetricQt06Title => 'Unités évitées';

  @override
  String get statsMetricQt07Desc => 'Argent non dépensé grâce à l’arrêt.';

  @override
  String get statsMetricQt07Formula => 'Unités évitées chaque jour × coût unitaire en vigueur ce jour-là.';

  @override
  String get statsMetricQt07Title => 'Argent économisé';

  @override
  String get statsMetricQt08Desc => 'Argent dépensé en consommations depuis l’arrêt.';

  @override
  String get statsMetricQt08Formula => 'Unités consommées × coût unitaire du moment.';

  @override
  String get statsMetricQt08Title => 'Dépensé lors des écarts';

  @override
  String get statsMetricQt09Desc => 'Ce que vous économiserez en continuant.';

  @override
  String get statsMetricQt09Formula => 'Référence actuelle × coût unitaire sur 1 mois, 1 an et 5 ans.';

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
  String get statsMetricQt11Desc => 'Étapes de récupération typiques après la dernière cigarette.';

  @override
  String get statsMetricQt11Formula =>
      'Progression = abstinence actuelle ÷ délai de l’étape ; le compteur redémarre après un écart.';

  @override
  String get statsMetricQt11Title => 'Étapes santé';

  @override
  String get statsMetricQt12Desc => 'À quelle fréquence vous êtes resté sous la limite, et combien vous avez réduit.';

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
  String get statsMetricQt14Formula => 'Pareto par déclencheur, lieu et humeur ; matrice jour × heure.';

  @override
  String get statsMetricQt14Title => 'Contexte des envies';

  @override
  String get statsNoteAbstainMode => 'Uniquement pour les suivis en mode réduction.';

  @override
  String get statsNoteAllDay => 'Les tâches sur la journée n’ont pas de durée.';

  @override
  String get statsNoteClosed => 'Cet élément est clos.';

  @override
  String get statsNoteError => 'Calcul impossible';

  @override
  String get statsNoteLimitHabit => 'Les habitudes à limite affichent plutôt les jours sous la limite.';

  @override
  String get statsNoteLowCoverage => 'Suivez le temps d’au moins 60 % des tâches faites pour voir ceci.';

  @override
  String get statsNoteNeedsMoreData => 'Données insuffisantes';

  @override
  String get statsNoteNew => 'Nouveau';

  @override
  String get statsNoteNoCategoryWeights =>
      'Attribuez un poids (0–4) aux catégories dans les réglages pour voir ce score';

  @override
  String get statsNoteNoConsistentTime => 'Pas d’horaire régulier';

  @override
  String get statsNoteNoData => 'Pas encore de données';

  @override
  String get statsNoteNoFreeTime => 'Aucun temps libre pendant les heures de travail';

  @override
  String get statsNoteNoGoal => 'Aucun objectif défini';

  @override
  String get statsNoteNoHabit => 'Habitude introuvable.';

  @override
  String get statsNoteNoItem => 'Élément introuvable.';

  @override
  String get statsNoteNoLifeEstimate => 'Indiquez les minutes de vie par unité pour voir cette estimation.';

  @override
  String get statsNoteNoOccurrence => 'Occurrence introuvable.';

  @override
  String get statsNoteNoQuitTrackers => 'Aucun suivi d’arrêt pour l’instant.';

  @override
  String get statsNoteNoRating => 'Pas encore de note';

  @override
  String get statsNoteNoRuns =>
      'Cette liste n’a pas encore de tours (elle n’est pas réinitialisable ou n’a jamais été réinitialisée)';

  @override
  String get statsNoteNoTracker => 'Suivi d’arrêt introuvable.';

  @override
  String get statsNoteNoUnitCost => 'Indiquez un coût unitaire pour voir les économies.';

  @override
  String get statsNoteNotApplicable => 'Sans objet';

  @override
  String get statsNoteNotDone => 'Pas encore fait';

  @override
  String get statsNoteNotOverdue => 'Pas en retard';

  @override
  String get statsNoteNotScheduled => 'Non planifié';

  @override
  String get statsNoteNotSmoking => 'Les étapes santé ne concernent que l’arrêt du tabac.';

  @override
  String get statsNoteNotSnowballing => 'Déplacée moins de 3 fois';

  @override
  String get statsNoteNotStarted => 'Pas démarré';

  @override
  String get statsNoteNotTracked => 'Temps réel non suivi';

  @override
  String get statsNotePastPeriod => 'Uniquement pour les périodes en cours ou à venir.';

  @override
  String get statsNotePopulationEstimate => 'Estimation populationnelle';

  @override
  String get statsNoteTagsOverlap => 'Certaines tâches ont plusieurs étiquettes : les totaux se recoupent';

  @override
  String get statsNoteUnloggedNotFailed =>
      'Les jours non saisis sont inconnus, pas des échecs — ils comptent comme manqués uniquement faute de saisie.';

  @override
  String get statsNoteUnstableFlow => 'Flux instable : les moyennes peuvent tromper';

  @override
  String get statsNoteUsedPlanned =>
      'Temps prévu affiché : le temps réel est suivi sur moins de 60 % des tâches faites.';

  @override
  String get statsNoteYesNoHabit => 'Indisponible pour les habitudes oui/non.';

  @override
  String get statsNoteZeroDenominator => 'Rien n’était prévu sur cette période.';

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
  String get statsQuitMilestoneBreathing72h => 'La respiration devient plus facile ; l’énergie augmente';

  @override
  String get statsQuitMilestoneCancers20y =>
      'Risque de cancers bouche, gorge, larynx et pancréas proche d’un non-fumeur';

  @override
  String get statsQuitMilestoneChd15y => 'Risque coronarien proche de celui d’un non-fumeur';

  @override
  String get statsQuitMilestoneChdAdded => 'Le risque coronarien supplémentaire est divisé par deux';

  @override
  String get statsQuitMilestoneCirculation => 'La circulation et la fonction pulmonaire s’améliorent';

  @override
  String get statsQuitMilestoneCo12h => 'Monoxyde de carbone sanguin revenu à la normale';

  @override
  String get statsQuitMilestoneCo8h => 'Le monoxyde de carbone sanguin est divisé par deux ; l’oxygène remonte';

  @override
  String get statsQuitMilestoneCravings => 'Les envies s’atténuent généralement (une envie dure environ 3 à 5 min)';

  @override
  String get statsQuitMilestoneHeart20m => 'La fréquence cardiaque et la tension baissent ; le pouls redevient normal';

  @override
  String get statsQuitMilestoneHeartAttack => 'Le risque d’infarctus chute fortement';

  @override
  String get statsQuitMilestoneHeartHalf1y => 'Risque coronarien environ moitié de celui d’un fumeur';

  @override
  String get statsQuitMilestoneLifeExpectancy =>
      'Arrêter à 30 / 40 / 50 / 60 ans fait gagner environ 10 / 9 / 6 / 3 ans d’espérance de vie';

  @override
  String get statsQuitMilestoneLungCancer10y => 'Risque de cancer du poumon environ moitié de celui d’un fumeur';

  @override
  String get statsQuitMilestoneLungs => 'Toux et essoufflement diminuent ; fonction pulmonaire jusqu’à ~10 % meilleure';

  @override
  String get statsQuitMilestoneMouthCancer =>
      'Le risque de cancers de la bouche, de la gorge et du larynx diminue de moitié ; le risque d’AVC baisse';

  @override
  String get statsQuitMilestoneNicotine24h => 'La nicotine disparaît du sang';

  @override
  String get statsQuitMilestoneTaste48h => 'Les poumons évacuent le mucus ; le goût et l’odorat s’améliorent';

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
  String get statsSectionAttachments => 'Pièces jointes et modifications';

  @override
  String get statsSectionBlockers => 'Bloqués et en attente';

  @override
  String get statsSectionBurn => 'Burn-down et périmètre';

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
  String get statsSectionCycleTime => 'Temps de cycle';

  @override
  String get statsSectionDataQuality => 'Qualité des données';

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
  String get statsSectionRuns => 'Tours de routine';

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
  String get statsSectionTree => 'Arborescence';

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
  String get tasksAddTag => 'Ajouter une étiquette';

  @override
  String tasksAnchorMoved(String date) {
    return 'Début déplacé au $date pour correspondre à la répétition';
  }

  @override
  String get tasksAttachments => 'Pièces jointes';

  @override
  String get tasksAttachmentsPlaceholder => 'Les photos et fichiers seront bientôt disponibles ici';

  @override
  String get tasksBacklogLabel => 'Non planifiée';

  @override
  String get tasksBulkAddTags => 'Ajouter des étiquettes';

  @override
  String get tasksBulkDelete => 'Supprimer';

  @override
  String tasksBulkDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer $count éléments ?',
      one: 'Supprimer 1 élément ?',
    );
    return '$_temp0';
  }

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
  String get tasksChecklistNew => 'Nouvelle liste';

  @override
  String get tasksChecklistNewName => 'Nom de la liste';

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
  String get tasksDayDoneAll => 'Tout marquer comme fait';

  @override
  String tasksDayDoneAllSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tâches marquées comme faites',
      one: '1 tâche marquée comme faite',
      zero: 'Plus rien à marquer',
    );
    return '$_temp0';
  }

  @override
  String get tasksDayMoveTomorrow => 'Reporter l’inachevé à demain';

  @override
  String tasksDayMoveTomorrowSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tâches reportées à demain',
      one: '1 tâche reportée à demain',
      zero: 'Rien à reporter',
    );
    return '$_temp0';
  }

  @override
  String get tasksDaySkipRest => 'Ignorer le reste de la journée';

  @override
  String tasksDaySkipRestSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tâches ignorées',
      one: '1 tâche ignorée',
      zero: 'Plus rien à ignorer',
    );
    return '$_temp0';
  }

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
  String get tasksEntryFuture => 'Une session ne peut pas commencer dans le futur';

  @override
  String get tasksEntryNegative => 'La fin doit être après le début';

  @override
  String get tasksEntryOverlap => 'Chevauche une autre session';

  @override
  String get tasksEntryRunning => 'En cours';

  @override
  String get tasksErrAllDay => 'Les tâches sur la journée couvrent des jours entiers';

  @override
  String get tasksErrDuration => 'La durée doit être comprise entre 0 minute et 365 jours';

  @override
  String get tasksErrEstimate => 'L’estimation est hors limites';

  @override
  String get tasksErrPriority => 'Priorité non valide';

  @override
  String get tasksErrRecurrenceInvalid => 'La règle de répétition n’est pas valide';

  @override
  String get tasksErrRecurrenceNoDate => 'Une tâche répétée a besoin d’une date';

  @override
  String get tasksErrTitleEmpty => 'Saisissez un titre';

  @override
  String get tasksErrTitleTooLong => 'Le titre est trop long (300 caractères max.)';

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
  String get tasksFieldTags => 'Étiquettes';

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
  String get tasksNotifAlreadyClosed => 'Déjà faite ou ignorée';

  @override
  String get tasksNotifGone => 'Cette tâche n’existe plus';

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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'et $count autres', one: 'et 1 autre');
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
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '+$count jours', one: '+1 jour');
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
  String tasksQuotaIndicator(String title, int done, int total, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'aujourd’hui',
      'week': 'cette semaine',
      'month': 'ce mois-ci',
      'year': 'cette année',
      'other': 'sur la période',
    });
    return '$title · $done/$total $_temp0';
  }

  @override
  String tasksQuotaIndicatorDone(String title, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'fait pour aujourd’hui',
      'week': 'fait pour cette semaine',
      'month': 'fait pour ce mois-ci',
      'year': 'fait pour cette année',
      'other': 'fait pour la période',
    });
    return '$title · $_temp0';
  }

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
  String get tasksScopePastKept => 'Les occurrences passées gardent leurs horaires d’origine.';

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
  String get tasksTemplatesEmpty => 'Aucun modèle. Enregistrez une tâche comme modèle depuis son menu.';

  @override
  String get tasksTemplatesTitle => 'Modèles';

  @override
  String get tasksTimeEntries => 'Sessions';

  @override
  String get tasksTimeTracking => 'Suivi du temps';

  @override
  String get tasksTooManyOccurrences => 'Trop d’occurrences à afficher — zoomez';

  @override
  String tasksTracked(String duration) {
    return 'Suivi : $duration';
  }

  @override
  String get tasksTrackingCheck => 'Case à cocher';

  @override
  String get tasksTrackingCheckHint => 'À cocher ou à passer ; peut être manquée.';

  @override
  String get tasksTrackingEvent => 'Événement';

  @override
  String get tasksTrackingEventHint => 'Un bloc de temps (réunion, repas) : pas de case, jamais manqué.';

  @override
  String get tasksTrackingTimer => 'Minuteur';

  @override
  String get tasksTrackingTimerHint => 'Mesurez le temps passé ; terminée à l’arrêt du minuteur.';

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

  @override
  String get templatesBuiltin => 'Intégrés';

  @override
  String get templatesCreated => 'Liste créée depuis le modèle';

  @override
  String get templatesEdit => 'Modifier le modèle';

  @override
  String get templatesEmpty => 'Enregistrez n\'importe quelle liste comme modèle depuis son menu.';

  @override
  String get templatesMine => 'Mes modèles';

  @override
  String get templatesRename => 'Renommer';

  @override
  String get templatesUse => 'Utiliser le modèle';

  @override
  String undoDoneSnack(String action) {
    return 'Annulé : $action';
  }

  @override
  String get undoNothing => 'Rien à annuler';

  @override
  String get voiceNoteDiscard => 'Supprimer';

  @override
  String get voiceNoteHint => 'Touchez le micro et parlez.';

  @override
  String get voiceNoteMicPrimerBody =>
      'Everslot utilise le micro uniquement pendant l’enregistrement d’une note vocale. Les enregistrements restent sur votre appareil jusqu’à leur envoi sur votre compte.';

  @override
  String get voiceNoteMicPrimerTitle => 'Accès au micro';

  @override
  String get voiceNoteRecord => 'Démarrer l’enregistrement';

  @override
  String voiceNoteRecording(String duration) {
    return 'Enregistrement, $duration';
  }

  @override
  String get voiceNoteSave => 'Joindre';

  @override
  String get voiceNoteStop => 'Arrêter l’enregistrement';

  @override
  String get voiceNoteTitle => 'Note vocale';
}
