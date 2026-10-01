# Section 2.2 — Attachments (Images & Files)

> Milestones: M0/M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.2 (storage bucket), 1.3, 1.4
> Architecture: arch §6.7 (pipeline), §7.3 `attachments`, §7.4 (storage policies), §6.17 (privacy)

## Goal

A reusable, offline-first attachment system: pick or capture images and files, process them on device
(compress, strip location, thumbnail), show them instantly from local storage, upload them reliably in the
background (resumable for large files), download lazily on other devices, and view them beautifully.
Used first by checklist items ([4.4]), then tasks, habit logs and checklists.

## Scope

**In:** `attachments` table (server + Drift), picking & permissions, processing, upload queue, download
cache, viewers, the reusable attachment strip widget, limits/validation, deletion & quota, tests.
**Out:** Where attachments appear in each feature ([4.4], [3.1], [5.2]); share-into-app ([8.2]);
storage purge job wiring ([1.4] T1.4.16 purge + cron in arch §7.7).

## Progress

- [x] T2.2.01 — Attachments table (server migration + Drift) & domain model
- [x] T2.2.02 — Picking: camera, photo picker, files (+ permissions & platform config)
- [x] T2.2.03 — Processing pipeline (copy, orientation, GPS strip, compress, thumbnail, hash)
- [x] T2.2.04 — Upload queue (standard + resumable), retries & Wi-Fi-only option
- [x] T2.2.05 — Download & local cache (thumbnails eager, originals on demand, LRU)
- [x] T2.2.06 — Viewers: image gallery, PDF, open-with
- [x] T2.2.07 — Attachment strip component (reusable)
- [x] T2.2.08 — Limits & validation (size, type, count)
- [x] T2.2.09 — Upload/download status & offline UX
- [x] T2.2.10 — Integration tests against local Supabase Storage
- [x] T2.2.11 — Deletion, reference-counted purge & storage quota display
- [ ] T2.2.12 — Video attachments (short clips) with poster frames
- [ ] T2.2.13 — Audio notes (record & play)
- [ ] T2.2.14 — Document scanner (camera → cropped PDF)

## Tasks

### T2.2.01 — Attachments table (server migration + Drift) & domain model
**Priority:** P0 · **Size:** M · **Depends on:** [1.2], [1.4]
**Description:** Create `app.attachments` exactly as arch §7.3 (polymorphic `owner_type/owner_id`,
storage paths, metadata, `sort_key`, `uploaded_at`) with `app.enable_sync`, the Drift mirror, local-only
`attachment_cache` (`attachment_id`, local original path, local thumb path, bytes, last_access_at,
download_state), and the `Attachment` entity + repository (`watchFor(ownerType, ownerId)`, add, reorder,
caption, soft delete).
**Implementation notes:** `owner_type` check constraint; index `(user_id, owner_type, owner_id)`; server
trigger rejects `storage_path` not starting with `{user_id}/{id}/`.
**Acceptance criteria:** pgTAP: user isolation + path-prefix check; repository streams attachments sorted by
`sort_key` and excludes tombstones.
**Tests:** pgTAP; Drift DAO tests.
**Notes:** The server table, path-prefix trigger (DL007) and pgTAP come from the foundation migrations; repository, cache store and domain model here.

### T2.2.02 — Picking: camera, photo picker, files (+ permissions & platform config)
**Priority:** P0 · **Size:** M · **Depends on:** T2.2.01
**Description:** `AttachmentPicker` service: *Take photo*, *Choose photos* (multi-select), *Choose files*
(any type in the allow-list). Android uses the system **photo picker** (no broad `READ_MEDIA_*`
permissions); iOS uses PHPicker. Camera permission primer before the OS prompt.
**Implementation notes:** `image_picker` (camera + gallery multi), `file_picker` (documents); localized
`NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription`; handle cancel, denied, restricted,
"limited photos" (iOS) states with recovery (open settings).
**Acceptance criteria:** picking 10 photos returns 10 items without blocking UI; denied permission shows a
helpful sheet; no media permissions declared in the Android manifest.
**Tests:** unit tests with fake platform pickers; manual QA matrix (iOS/Android, grant/deny).

### T2.2.03 — Processing pipeline (copy, orientation, GPS strip, compress, thumbnail, hash)
**Priority:** P0 · **Size:** M · **Depends on:** T2.2.02
**Description:** In a background isolate: copy into `app_documents/attachments/<id>/<safe_name>`, apply
EXIF orientation, strip GPS/EXIF, compress images (long edge ≤ 2560 px, JPEG/WebP q≈85, keep PNG for
screenshots with transparency, HEIC → JPEG), generate a 512-px thumbnail (WebP), compute SHA-256, width,
height, MIME (`mime` sniffing), size. Non-image files are copied as-is (thumbnail = type icon; first-page
render for PDFs when cheap).
**Implementation notes:** `flutter_image_compress`; safe file names (unicode-normalized, no path chars);
duplicate detection by SHA-256 within the same owner (offer "already attached").
**Acceptance criteria:** a 12-MP photo becomes ≤ 1.5 MB with correct orientation and no GPS tags; processing
10 photos keeps the UI at 60 fps.
**Tests:** unit tests on sample images (orientation 1–8, HEIC, PNG with alpha); EXIF-stripping assertion.
**Notes:** HEIC is re-encoded to JPEG by the native codec; EXIF/GPS stripping is verified on JPEG; PDFs get a type icon (no first-page render).

### T2.2.04 — Upload queue (standard + resumable), retries & Wi-Fi-only option
**Priority:** P0 · **Size:** L · **Depends on:** T2.2.03, [1.4]
**Description:** Persistent queue (local table) uploading original + thumbnail to
`attachments/{user_id}/{attachment_id}/…`; files > 6 MB use Supabase resumable (TUS) uploads via `tusc`
(6 MB chunks, upload URL valid 24 h, `<project-ref>.storage.supabase.co` host); retries with
exponential backoff + jitter; pauses when offline; optional "upload on Wi-Fi only"; on success sets
`uploaded_at` and enqueues the row for sync (other devices then see it).
**Implementation notes:** single-flight worker with concurrency 2; survives app restarts; resumes TUS
uploads after kill; progress stream per attachment; integrates with background work ([1.4] background sync).
**Acceptance criteria:** airplane mode during a 20 MB upload → resumes from the last chunk when back online;
no duplicate objects after retries; the row syncs only after both files are uploaded.
**Tests:** state-machine unit tests; integration test (T2.2.10) with forced network failures.
**Notes:** Local-only mode (no Supabase client or local session) keeps jobs `pending` and never touches the network; files > 6 MB use TUS via `tusc`.

### T2.2.05 — Download & local cache (thumbnails eager, originals on demand, LRU)
**Priority:** P0 · **Size:** M · **Depends on:** T2.2.01
**Description:** On other devices, thumbnails download automatically when their owner is visible; originals
download on open (or "download all for offline" per checklist, P1). Local cache with LRU eviction and a
configurable cap (default 1 GB), never evicting files that are not yet uploaded.
**Implementation notes:** authenticated downloads via the Storage SDK (or short-lived signed URLs); write to
temp then atomic rename; `attachment_cache.last_access_at` updated on view.
**Acceptance criteria:** scrolling a checklist with 200 image items downloads thumbnails progressively
without jank; cache cap respected; offline shows cached files and placeholders for the rest.
**Tests:** unit tests for LRU policy; integration test for download-on-open.

### T2.2.06 — Viewers: image gallery, PDF, open-with
**Priority:** P0 · **Size:** M · **Depends on:** T2.2.05
**Description:** Full-screen gallery (swipe between an owner's images, pinch/double-tap zoom via
`InteractiveViewer`, captions, share, delete), PDF viewer (`pdfrx`), other types → share sheet /
platform "open in" (`share_plus`), avoiding ageing packages (`photo_view`, `open_filex`).
**Acceptance criteria:** gallery opens at the tapped image, supports RTL swipe direction, hero animation
(disabled with reduce motion); unsupported types never crash.
**Tests:** widget tests for gallery navigation; manual QA with PDF/DOCX/ZIP.
**Notes:** Gallery (PageView, InteractiveViewer, RTL, hero off with reduce motion), PDF via `pdfrx`, other types → share/open-with; gallery navigation widget test. Manual QA with real PDF/DOCX/ZIP files on devices still to do.

### T2.2.07 — Attachment strip component (reusable)
**Priority:** P0 · **Size:** M · **Depends on:** T2.2.04, T2.2.06
**Description:** `AttachmentStrip(ownerType, ownerId, editable)` — horizontal thumbnails with type icons,
"+ add" button (opens picker menu), drag to reorder (fractional `sort_key`), long-press menu (caption,
share, remove with undo), upload/download status badges.
**Acceptance criteria:** used unchanged by checklist items, tasks and habit logs; accessible labels
("Photo 2 of 5, uploading 40 %").
**Tests:** widget tests (reorder, remove + undo, badges); goldens LTR/RTL.
**Notes:** Reorder is offered as long-press menu "Move earlier / later" (accessible; an in-strip drag would fight the long-press menu). Goldens: light/dark × LTR/RTL × text scale 1.0/2.0; file chips drop lines / widen at large text so 2.0 never overflows.

### T2.2.08 — Limits & validation (size, type, count)
**Priority:** P0 · **Size:** S · **Depends on:** T2.2.02
**Description:** Enforce max file size (default 25 MB), allowed MIME allow-list (images, PDF, Office docs,
text, audio/video when enabled, archives), max attachments per owner (default 50) with friendly localized
errors; mirrored by Storage bucket limits (`file_size_limit`, `allowed_mime_types`).
**Tests:** unit tests for validator; storage rejects oversized uploads in integration test.

### T2.2.09 — Upload/download status & offline UX
**Priority:** P0 · **Size:** S · **Depends on:** T2.2.04, T2.2.05
**Description:** Visible states: *processing*, *waiting for network*, *uploading n %*, *failed — retry*,
*not downloaded*, *downloading*; a global "N uploads pending" indicator in Settings › Sync.
**Tests:** widget tests per state.
**Notes:** `PendingUploadsIndicator` and `AttachmentSettingsSection` are ready for Settings › Sync — TODO(integration): the settings feature embeds them.

### T2.2.10 — Integration tests against local Supabase Storage
**Priority:** P0 · **Size:** M · **Depends on:** T2.2.04, T2.2.05
**Description:** Tests against the local stack: upload (standard + TUS), cross-user access denied (policy),
download by another device session of the same user, interrupted upload resume, path-prefix enforcement.
**Tests:** this task is the suite (`@Tags(['storage'])`).
**Notes:** `app/test_storage/attachment_storage_test.dart` (`@Tags(['storage'])`, own directory so plain `flutter test` never needs the stack): standard upload + second-device download + retry overwrite, cross-user read/write denied, path prefix (Storage policy and the DL007 row trigger via PostgREST), bucket MIME allow-list, TUS for > 6 MB with an interrupted upload resumed from its offset, and the queue + downloader end to end (offline → pending, online → row marked uploaded, other device downloads). Throwaway users via the admin API, removed afterwards. CI: `backend.yml` › storage job; local run in `docs/guide.md` §3.

### T2.2.11 — Deletion, reference-counted purge & storage quota display
**Priority:** P1 · **Size:** S · **Depends on:** T2.2.01, [1.4] (purge job)
**Description:** Soft delete removes the attachment from UI (restorable from Trash [8.3]); the nightly purge
deletes storage objects only when no remaining row references the path (duplicated items share objects —
arch §6.7). Settings shows total storage used (sum of `byte_size`, deduplicated by path) and local cache size
with "Clear cache".
**Tests:** pgTAP for the reference check; unit test for quota computation.
**Notes:** Soft delete with undo and the storage / cache usage section are here; the reference-counted purge job is server-side (foundation `100_purge_ops`).

### T2.2.12 — Video attachments (short clips) with poster frames
**Priority:** P2 · **Size:** M · **Depends on:** T2.2.03
**Description:** Short videos (≤ 60 s / 50 MB) with poster frame thumbnail, inline player in the viewer,
transcoding left to the OS picker settings.
**Notes:** Not started: needs native plugins for playback and poster frames (e.g. `video_player` + a thumbnail plugin) — new dependencies and platform setup, outside this pass.

### T2.2.13 — Audio notes (record & play)
**Priority:** P2 · **Size:** M · **Depends on:** T2.2.07
**Description:** Record voice notes (AAC), waveform preview, playback in the strip; microphone permission
primer; optional on-device transcription later ([9.3]).
**Notes:** Not started: needs recording/playback plugins (e.g. `record` + an audio player) with microphone permissions — new native dependencies, outside this pass.

### T2.2.14 — Document scanner (camera → cropped PDF)
**Priority:** P2 · **Size:** M · **Depends on:** T2.2.03
**Description:** Scan paper documents with edge detection and perspective correction (platform document
scanners where available) into a multi-page PDF attachment.
**Notes:** Not started: needs a native document-scanner plugin (VisionKit / ML Kit) — new native dependency, outside this pass.
