# Section 4.4 — Item & Checklist Attachments

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 2.2, 4.1, 4.2
> Architecture: §6.7 (attachments pipeline, duplicate/purge rule), §7.3 (`attachments`), §9.3 (trash)

## Goal

Let every checklist row carry images and files, as the user asked: *"each row is text and I can
assign images or files."* The capture, compression, upload queue, caching and viewers already exist
in [2.2]. This section plugs them into items and checklists and defines what happens to attachments
when trees are edited, duplicated, moved, deleted or restored.

## Scope

**In:** attaching from camera/gallery/files to items; the attachment strip on rows and in previews;
upload status and offline behaviour; attachment semantics for tree operations; checklist-level
attachments (P1); captions, reorder, remove (P1); a per-checklist attachments gallery (P1);
attachments in export/import (P2); paste/scan into an item (P2).
**Out:** the pipeline itself (processing, queue, storage policies, viewers → [2.2]); covers on
board cards ([4.1] T4.1.17); the gallery *view* of items ([4.5]).

## Progress

- [ ] T4.4.01 — Attach images & files to an item
- [ ] T4.4.02 — Attachment strip on item rows
- [ ] T4.4.03 — Upload status & offline behaviour
- [x] T4.4.04 — Attachment semantics for tree operations
- [x] T4.4.05 — Checklist-level attachments
- [ ] T4.4.06 — Captions, reorder & remove with undo
- [ ] T4.4.07 — Checklist attachments gallery
- [ ] T4.4.08 — Attachments in export & import bundles
- [ ] T4.4.09 — Paste image & scan document into an item

## Tasks

### T4.4.01 — Attach images & files to an item
**Priority:** P0 · **Size:** M · **Depends on:** [2.2], [4.2]
**Description:** Add one or many attachments to any item, at any depth, from the three sources.
**Implementation notes:**
- Entry points:
  - the 📎 button on the soft-keyboard toolbar ([4.2] T4.2.09);
  - the row menu;
  - the item details sheet ([4.2] T4.2.15).
- Sources:
  - camera photo;
  - gallery (multi-select via the system photo picker, no broad media permission);
  - files (any MIME type on the [2.2] allow-list).
- Each attachment creates an `attachments` row:
  - `owner_type = 'checklist_item'`, `owner_id` = the item id;
  - `sort_key` appended after existing attachments;
  - processing and upload go through the [2.2] queue;
  - an `attachment_added` activity event is written in the same transaction.
- [2.2] limits (size, count per item) apply, with friendly localized errors.
**Acceptance criteria:**
- Attaching 5 photos while offline shows 5 thumbnails instantly from local files.
- They upload automatically when the device comes online.
- The other device sees them after sync.
**Tests:** widget test with a fake picker; repository test (row + event in one transaction).

### T4.4.02 — Attachment strip on item rows
**Priority:** P0 · **Size:** M · **Depends on:** T4.4.01, [2.2] (shared strip component & viewers)
**Description:** Show attachments under the item text.
**Implementation notes:**
- Uses the shared strip component: image thumbnails, and file chips (icon by MIME type + name + size).
- At most 4 are visible, then "+N".
- Tapping opens the [2.2] viewer, which swipes across all of the item's attachments.
- Display rules:
  - collapsed rows show only a paperclip count;
  - preview mode shows the strip by default (configurable in checklist settings);
  - edit mode uses a compact strip.
- Thumbnails load lazily for visible rows only.
**Acceptance criteria:** scrolling a list with 200 image items stays at 60 fps; memory is bounded by
the [2.2] thumbnail cache.
**Tests:** goldens (images, files, mixed, RTL); widget test for viewer navigation.

### T4.4.03 — Upload status & offline behaviour
**Priority:** P0 · **Size:** S · **Depends on:** T4.4.02
**Description:** Make the state of each attachment visible without getting in the way.
**Implementation notes:**
- Badges on each thumbnail/chip:
  - *pending*;
  - *uploading* (progress ring);
  - *failed* (tap → retry, or show the error);
  - *not downloaded* (cloud icon on other devices; tap to fetch).
- An item with pending uploads is fully editable. Attachment failures never block text or status edits.
- The checklist header shows "3 uploads pending" while the queue is busy.
**Tests:** widget tests driven by fake queue states.

### T4.4.04 — Attachment semantics for tree operations
**Priority:** P0 · **Size:** S · **Depends on:** [4.2] (subtree operations), [2.2]
**Description:** Define and implement what each tree operation does to attachment rows.
**Implementation notes:**

| Operation | Effect on attachments |
|---|---|
| Duplicate subtree / checklist | Copy rows (new ids) that reference the **same** storage objects (arch §6.7) |
| Move (within or across checklists) | Nothing: the owner is the item, whose id does not change |
| Merge row into previous | Attachments are re-owned by the target row (`owner_id` update) |
| Promote to checklist ([4.2] T4.2.04) | The item's attachments become checklist-level (`owner_type = 'checklist'`) |
| Delete subtree | Attachment rows tombstoned in the same op group |
| Restore (undo / Trash) | Attachment rows restored with their op group |
| Server purge | Storage object deleted only when no remaining row references its path |

**Acceptance criteria:** after duplicating a list, then deleting and purging the original, the
copy's files still load.
**Tests:** repository tests for each row of the table; purge-reference test in the [2.2] server suite.

### T4.4.05 — Checklist-level attachments
**Priority:** P1 · **Size:** S · **Depends on:** T4.4.01
**Description:** Attach files to the checklist itself (`owner_type = 'checklist'`), e.g. a photo of
a whiteboard for a note card.
**Implementation notes:**
- Shown in the checklist header.
- The board card uses the first image as a thumbnail when no cover is set ([4.1] T4.1.08).
**Tests:** widget test; board card thumbnail fallback test.
**Notes:** Checklist-level strip under the title; the card thumbnail falls back to the first checklist image, then to item images.

### T4.4.06 — Captions, reorder & remove with undo
**Priority:** P1 · **Size:** S · **Depends on:** T4.4.02
**Description:** Curate attachments.
**Implementation notes:**
- Edit captions in the viewer or the details sheet (`caption`).
- Drag to reorder within the strip (`sort_key`).
- Remove tombstones the row and shows an undo snackbar.
**Tests:** widget tests for caption editing, reorder and undo.

### T4.4.07 — Checklist attachments gallery
**Priority:** P1 · **Size:** M · **Depends on:** T4.4.02
**Description:** A grid of every attachment in a checklist: all items plus checklist-level ones.
**Implementation notes:**
- Grouped by item, with its breadcrumb path.
- Filter by type: images, PDFs, other.
- Tapping opens the viewer with a *Go to item* action (opens the item in focus mode).
- Query: attachments joined to the checklist's live items.
- The grid component is reused by the gallery view in [4.5].
**Tests:** DAO test (join, live items only); widget tests.

### T4.4.08 — Attachments in export & import bundles
**Priority:** P2 · **Size:** S · **Depends on:** [4.5] (export/import)
**Description:** Carry attachments through export and import.
**Implementation notes:**
- Markdown/OPML exports list attachment file names under their items.
- Optional *zip bundle* export: the text file plus a `files/` folder.
- Importing a bundle re-attaches the files through the [2.2] pipeline.
**Tests:** round-trip test (export bundle → import → same files per item).

### T4.4.09 — Paste image & scan document into an item
**Priority:** P2 · **Size:** S · **Depends on:** T4.4.01, [2.2] (scan document)
**Description:** Faster capture into an item.
**Implementation notes:**
- Paste an image from the clipboard where the platform supports it.
- *Scan document*: camera → cropped PDF from [2.2].
- Sharing files into a specific item is handled by [8.2].
**Tests:** widget test with a fake clipboard.
