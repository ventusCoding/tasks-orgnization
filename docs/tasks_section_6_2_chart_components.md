# Section 6.2 — Chart Kit

> Milestones: M1 (P0) · M2 (P1) · M3 (P2) · Depends on: 1.3, 6.1
> Architecture: §6.12 (stats engine), §6.14 (design system, RTL, accessibility), ADR-012 (`fl_chart` + custom painters)

## Goal

One consistent, accessible and themeable chart library that covers every visualization in the stats
catalog, built on `fl_chart` plus `CustomPainter`s behind our own widget API. It includes tooltips,
drill-down, RTL, dark mode, color-blind safety, a tabular alternative for every chart, and
share-as-image. Metric screens ([6.3]–[6.7]) compose these widgets and never talk to `fl_chart` directly.

## Scope

**In:** chart theme and frame, KPI tiles, line/area, bars, donut, Pareto, calendar heatmap/year grid,
progress visuals (rings, bullet chart, milestone bars, live counter), streak bars and timeline, punch
card, Gantt, histogram, box plot, scatter variants, stacked area/CFD, burn-down/up, radar, rose/clock,
treemap, matrix heatmap, Kaplan–Meier curve, forecast visuals, interactions, accessibility, share
image, goldens, performance, dev gallery.
**Out:** Metric computation ([6.1]); screen layouts ([6.3]–[6.7]); planner-grid overlays drawn by the
time-grid painter ([3.3], specified in [6.3]).

## Progress

- [x] T6.2.01 — Chart foundations: theme tokens, frame, axes & RTL
- [x] T6.2.02 — KPI tile with delta, interval & sparkline
- [x] T6.2.03 — Line & area chart
- [x] T6.2.04 — Bar charts (vertical, horizontal, stacked, grouped, 100 %)
- [x] T6.2.05 — Donut & Pareto
- [x] T6.2.06 — Calendar heatmap & year grid
- [x] T6.2.07 — Progress visuals: rings, bullet chart, milestone bars, live counter
- [x] T6.2.08 — Streak bars & streak timeline
- [x] T6.2.09 — Punch card (7 × 24)
- [x] T6.2.10 — Basic interactions: tooltips & drill-down payloads
- [x] T6.2.11 — Chart accessibility: semantic summaries & "view as table"
- [x] T6.2.12 — Chart goldens & rendering performance
- [x] T6.2.13 — Gantt: planned vs actual & move timeline
- [x] T6.2.14 — Histogram & box plot
- [x] T6.2.15 — Scatter plots (y = x, percentile lines, aging WIP)
- [x] T6.2.16 — Stacked area & cumulative flow diagram
- [x] T6.2.17 — Burn-down / burn-up
- [x] T6.2.18 — Radar chart
- [x] T6.2.19 — Rose / 24-hour clock chart
- [x] T6.2.20 — Treemap
- [x] T6.2.21 — Matrix heatmap
- [x] T6.2.22 — Advanced interactions: scrubbing, pan & zoom, range brush
- [x] T6.2.23 — Share chart as image
- [x] T6.2.24 — Chart gallery (dev flavor)
- [x] T6.2.25 — Kaplan–Meier curve
- [x] T6.2.26 — Forecast visuals: probability histogram & forecast cone

## Tasks

### T6.2.01 — Chart foundations: theme tokens, frame, axes & RTL
**Priority:** P0 · **Size:** M · **Depends on:** [1.3] (design tokens, l10n), [6.1] (formatters T6.1.07, result states T6.1.14)
**Description:** Shared building blocks for every chart: theme, frame, axes, legends and RTL behavior,
plus an adapter layer that isolates `fl_chart`.
**Implementation notes:**
- **`ChartTheme` (`ThemeExtension`):**
  - an 8-color series palette derived from Okabe–Ito, with light and dark variants
  - status colors from design tokens: done, partial, failed, missed, skipped, excused, paused, frozen,
    pending, not-due
  - category colors (16-color palette, arch §6.14)
  - grid, axis and label colors; stroke widths
  - pattern fills (diagonal, dots, cross-hatch) so series stay distinguishable without color
- **`ChartFrame`:**
  - title, and a subtitle showing the period
  - legend with series toggles
  - ⓘ button (opens the explain sheet from [6.1])
  - "View as table" toggle
  - overlays for loading, empty, insufficient ("Needs 4 more check-ins") and error
- **Axes:**
  - "nice" ticks (1-2-5 steps), at most 6 per axis on phones
  - date labels per bucket granularity, localized
  - duration, percent and currency labels via T6.1.07
  - counts and rates always start at 0
- **RTL:** time axes are mirrored (time flows right-to-left, matching the mirrored week table, arch
  §6.14); the value axis sits on the *start* side; legends and labels use directional layout.
- **Motion:** 250 ms ease-out, disabled under reduce-motion.
- **Adapter layer:** `lib/features/stats/presentation/charts/` exposes our own widgets; `fl_chart`
  types never leak into screens.
**Acceptance criteria:** switching theme or locale restyles every chart without rebuilding data; RTL
mirrors the time axes; every chart state (loading, empty, insufficient, error, data) renders correctly.
**Tests:** widget tests for the frame states; goldens for axes in LTR/RTL.
**Notes:** Chart kit under `features/stats/presentation/charts/`, public barrel `features/stats/charts.dart` (no `fl_chart` types leak). `ChartTheme` is a `ThemeExtension` that falls back to the ambient theme, so no design-system registration is needed; `ChartPrefs` (inherited widget) passes 12/24 h, digits, week start, day start and haptics without Riverpod. Axes use 1-2-5 ticks (`niceScale`); RTL mirrors time axes with the value axis on the start side; goldens cover LTR/RTL (T6.2.12).

### T6.2.02 — KPI tile with delta, interval & sparkline
**Priority:** P0 · **Size:** S · **Depends on:** T6.2.01
**Description:** The headline-number widget used on every Insights screen.
**Implementation notes:**
- Contents:
  - the formatted value and its unit
  - a delta chip (arrow, value, color from the metric's `direction`)
  - a "± x pp" Wilson half-width when n < 20
  - a sparkline of the last 12 buckets (line or mini-bars)
  - an optional target marker
- Two sizes (compact and regular). Tap opens drill-down; long-press opens the explain sheet.
- The insufficient state shows the missing count; the not-applicable state shows "—".
**Acceptance criteria:** readable at text scale 2.0 (the sparkline hides before text truncates); the
delta is announced by screen readers as "up 5 percentage points".
**Tests:** widget tests for each state; goldens.
**Notes:** `KpiTile` + `DeltaChip` + `Sparkline`; the ± half-width follows the metric's `MinSampleRule`; the sparkline hides at text scale ≥ 1.5 or below 120 dp.

### T6.2.03 — Line & area chart
**Priority:** P0 · **Size:** M · **Depends on:** T6.2.01, [6.1] (trend T6.1.04)
**Description:** Time series such as adherence over time, strength score, craving intensity, hours per week.
**Implementation notes:**
- **Series and overlays:**
  - up to 6 series
  - an optional dashed rolling-mean overlay
  - an optional trend line with a slope label ("+2.1 pp/week", from T6.1.04)
  - goal line, target band, and pace line (goals)
- **Data handling:**
  - `null` values leave gaps; the chart never interpolates across missing data
  - area fill and cumulative mode
  - vertical annotation markers with icons ("rule changed", "vacation", "quit date reset")
  - LTTB downsampling to at most about 2 points per pixel column once there are more than 500 points
**Acceptance criteria:** a 1 825-point series renders under the T6.2.12 budget; gaps stay visible;
annotations are tappable and announced.
**Tests:** unit tests for LTTB (keeps extrema); goldens with trend, goal and gap.
**Notes:** `TimeSeriesChart` on `fl_chart` `LineChart`; LTTB downsampling via `lttb()` (unit-tested: keeps extrema and gaps). Annotation markers are labeled vertical lines; tapping them is part of the P1 scrubbing work (T6.2.22).

### T6.2.04 — Bar charts (vertical, horizontal, stacked, grouped, 100 %)
**Priority:** P0 · **Size:** M · **Depends on:** T6.2.01
**Description:** Covers history by period, throughput, planned vs actual hours, created vs completed,
and weekday profiles.
**Implementation notes:**
- **Variants:** vertical, horizontal, stacked, grouped and 100 % stacked. Negative values (deltas)
  diverge from a zero baseline.
- **Overlays:** an optional line (capacity line, rolling mean, target).
- **Labels:** value labels auto-hide when crowded. Colors come from category or status.
- **Many bars:** beyond 60 bars, switch to horizontal scrolling or suggest a coarser bucket.
- **Tap:** returns a drill payload (T6.2.10).
**Acceptance criteria:** a stacked bar tooltip lists every segment with its share; capacity overlay
lines render above the bars; RTL mirrors the category order.
**Tests:** goldens per variant; widget test for the tap payload.
**Notes:** `BarsChart` is a `CustomPainter` (pattern fills for status tones, exact RTL mirroring, crowd-aware value labels); > 60 bars scroll horizontally.

### T6.2.05 — Donut & Pareto
**Priority:** P0 · **Size:** M · **Depends on:** T6.2.01
**Description:** Composition charts: status mix and time allocation (donut); skip reasons, craving
triggers and blocker reasons (Pareto).
**Implementation notes:**
- **Donut:** a center label (total or headline), at most 7 slices plus "Other", and a legend with values
  and percentages.
- **Pareto:** bars sorted in descending order, a cumulative-% line on a secondary axis, and an 80 %
  reference line. At most 12 bars plus "Other".
**Acceptance criteria:** slices under 2 % are merged into "Other"; Pareto cumulative values end at 100 %.
**Tests:** unit tests for the grouping logic; goldens.
**Notes:** Donut on `fl_chart` `PieChart`; Pareto is a custom painter. Grouping rules live in the domain models (`groupDonutSlices`, `ParetoData`).

### T6.2.06 — Calendar heatmap & year grid
**Priority:** P0 · **Size:** M · **Depends on:** T6.2.01
**Description:** Month calendars and GitHub-style year grids for habit days, occurrence outcomes,
completions per day, abstinent days and cravings.
**Implementation notes:**
- Implemented with a `CustomPainter`. The month grid has 7 columns in week-start order with day numbers;
  the year grid is 53 × 7 with month labels.
- **Discrete status mode:** one style per status (done, partial, failed, missed, skipped, excused,
  paused, frozen, pending, not due), each with its own color, pattern and legend.
- **Continuous intensity mode:** 5 quantile bins or fixed thresholds.
- Today gets an outline; future days are dimmed. Tapping a day returns a drill payload.
- Paging covers a single year or multiple years, with year paging.
**Acceptance criteria:** week start MO/SA/SU and RTL lay out correctly; 365 cells render in < 4 ms per
frame; statuses are distinguishable in grayscale.
**Tests:** goldens per mode, week start, RTL and dark theme; a performance test.
**Notes:** Month grids for ranges ≤ 45 days, year grid otherwise (scrolls when wider than the screen). The 365-cell frame budget is covered by the heavy-scene smoke test; profile-mode timing belongs to the [9.1] device suite.

### T6.2.07 — Progress visuals: rings, bullet chart, milestone bars, live counter
**Priority:** P0 · **Size:** M · **Depends on:** T6.2.01
**Description:** Progress and target widgets used by the Today/Habits/Quit summaries and target metrics.
**Implementation notes:**
- **Progress rings:** single or concentric, animated.
- **Bullet chart:** actual bar, target marker, a ghost bar for the previous period, and qualitative
  background bands.
- **Milestone list:** one progress bar per milestone with its label, an ETA ("in 3 d 4 h") and an
  achieved check. The "restarted after lapse" state gets a supportive label.
- **Live counter:** d/h/m/s from a shared 1 Hz ticker that runs only while visible. Screen-reader
  updates are throttled to once per minute.
**Acceptance criteria:** the counter stays accurate across background/foreground and DST (it uses
instants); rings never exceed 100 % visually but can show "+20 %" over-achievement text.
**Tests:** widget tests with a fake ticker; goldens.
**Notes:** `LiveCounter` uses the shared `CounterTicker` (one 1 Hz timer, only while `TickerMode` is enabled) and an injectable clock for tests.

### T6.2.08 — Streak bars & streak timeline
**Priority:** P0 · **Size:** S · **Depends on:** T6.2.01, [6.1] (streak engine T6.1.09)
**Description:** Loop-style horizontal bars of the top streaks, and a lane showing streak segments,
breaks and frozen units across the calendar.
**Implementation notes:** each bar shows its length and date range; the current streak is highlighted;
frozen units are drawn with a pattern.
**Acceptance criteria:** top-10 bars are ordered by length and then by recency; the timeline aligns with
the calendar heatmap's week boundaries.
**Tests:** goldens; a unit test for the ordering.

### T6.2.09 — Punch card (7 × 24)
**Priority:** P0 · **Size:** M · **Depends on:** T6.2.01
**Description:** A weekday × hour heatmap for busiest hours, check-in times, cravings, lapses and
punctuality.
**Implementation notes:**
- Rows are weekdays in week-start order; columns are hours with 12/24 h labels (a 30-minute resolution
  is optional).
- Each cell is either a bubble-size or a color-intensity encoding.
- Tapping a cell returns `(weekday, hour)` as a drill payload. Columns are mirrored in RTL.
**Acceptance criteria:** the column for 00:00 respects the day-start hour when configured; an empty
matrix shows the empty state, not a blank grid.
**Tests:** goldens (week starts, RTL, dark theme).
**Notes:** Punch card columns rotate to `ChartPrefs.dayStartMinutes`; taps return `weekday:<iso>:<hour>`.

### T6.2.10 — Basic interactions: tooltips & drill-down payloads
**Priority:** P0 · **Size:** S · **Depends on:** T6.2.01
**Description:** Consistent tap and long-press behavior across all charts.
**Implementation notes:**
- Tooltips show the value, label and delta.
- A typed `ChartTap<T>` payload (bucket range, series key, category id, status) is handed to the stats
  screen framework, which opens the filtered list ([6.1] T6.1.16).
- Selection gives a haptic tick, which respects the haptics setting.
**Acceptance criteria:** every P0 chart returns a meaningful payload; tooltips never overflow the
screen edges in RTL.
**Tests:** widget tests per chart type.
**Notes:** Typed `ChartTap` payloads (drill key, label, series, value) from line, bars, donut, Pareto, calendar, punch card and streak charts; bar tooltips list every segment with its share; selection haptics honour `appearance.haptics` via `ChartPrefs.haptics`.

### T6.2.11 — Chart accessibility: semantic summaries & "view as table"
**Priority:** P0 · **Size:** M · **Depends on:** T6.2.01
**Description:** Make every chart usable without sight or color vision.
**Implementation notes:**
- **Semantic summary:** each chart provides an auto-generated sentence covering the range, min and max,
  trend and latest value. Example: "Adherence, last 12 weeks: from 62 % to 71 %, rising 0.8 pp per week."
- **Data table:** "View as table" renders the exact same numbers as a sortable table.
- **Non-color cues:** patterns and direct labels, so color is never the only channel.
- **Contrast:** graphical objects reach at least 3:1 (WCAG 1.4.11).
- **Tablets:** points and bars can take keyboard focus.
- **Text scale 2.0:** labels wrap, rotate or abbreviate instead of clipping.
**Acceptance criteria:** automated `meetsGuideline(textContrastGuideline)` and labeled-tap-target checks
pass; TalkBack/VoiceOver read the summary and allow table navigation.
**Tests:** widget semantics tests per chart type; an a11y audit entry in [9.1].
**Notes:** Every chart in a `ChartFrame` is announced by `chartSummary` and has a sortable `ChartDataTable`. Keyboard focus is provided by the table rows; per-bar focus traversal is left to the [9.1] accessibility audit.

### T6.2.12 — Chart goldens & rendering performance
**Priority:** P0 · **Size:** M · **Depends on:** T6.2.02, T6.2.03, T6.2.04, T6.2.05, T6.2.06, T6.2.07, T6.2.08, T6.2.09
**Description:** Visual regression and frame-time budgets for the chart kit.
**Implementation notes:**
- Goldens use the [9.1] golden matrix (light/dark × LTR/RTL × text scale 1.0/2.0) with fixture data for
  every P0 chart.
- Performance scenario: a year heatmap + a 1 825-point line + 60 bars on one screen, measured in profile
  mode. Build plus raster must stay ≤ 8 ms per frame, using `RepaintBoundary` per chart and const
  painters. Charts must not rebuild on unrelated provider updates.
**Acceptance criteria:** CI goldens are stable across runs; the performance test passes on the reference
emulator.
**Tests:** this task is the suite.
**Notes:** Golden matrix `test/features/stats/charts/goldens/p0_charts_{light,dark}_{ltr,rtl}_{1x,2x}.png` (one gallery per variant, tagged `golden`); the 2.0 text-scale variant caught and fixed a ring-label overflow. The heavy scene (year heatmap + 1 825-point line + 60 bars) has a debug-mode smoke budget; profile-mode ≤ 8 ms frame budgets are measured by the [9.1] device suite.

### T6.2.13 — Gantt: planned vs actual & move timeline
**Priority:** P1 · **Size:** M · **Depends on:** T6.2.01, T6.2.10
**Description:** A per-day or per-task timeline comparing plan and reality, plus a timeline of
reschedules.
**Implementation notes:**
- **Planned vs actual:** rows per day (or per task). The planned bar is drawn as an outline and the
  actual sessions are overlaid as fills. Color encodes variance (early, late, overrun), with minute
  labels on demand.
- **Move timeline:** one dot per reschedule, with an arrow from the old date to the new one.
**Acceptance criteria:** overlapping sessions stack without hiding each other; RTL mirrors time.
**Tests:** goldens.
**Notes:** `GanttChart` / `MoveTimelineChart` (`charts/timeline_charts.dart`): planned outline + session fills toned by `sessionTone` (early/on time/late/overrun, 5-min grace, patterns), `assignLanes` stacks overlapping sessions in sub-lanes; row tap reads out planned/actual minutes and opens the row's entity; RTL mirrors time. Move timeline uses wall-clock minutes.

### T6.2.14 — Histogram & box plot
**Priority:** P1 · **Size:** M · **Depends on:** T6.2.04, [6.1] (T6.1.02 bins & box summary)
**Description:** Distributions of durations, cycle time, start delay, craving intensity and habit values.
**Implementation notes:**
- **Histogram:** bins come from [6.1], with P50/P85 markers and a count/density toggle.
- **Box plots:** grouped (by month or weekday), with outliers as dots and n under each box.
**Acceptance criteria:** the markers match the [6.1] percentile values exactly.
**Tests:** goldens.
**Notes:** `HistogramChart` (count/share toggle, dashed P50/P85 markers placed at the given [6.1] values, bin taps `bin:<i>`) and `BoxPlotChart` (whiskers, outliers, `n = …` under each box, `group:<i>` taps) in `charts/distribution_charts.dart`; test builds the markers with `percentile()` and bins with `histogramFixedWidth()`.

### T6.2.15 — Scatter plots (y = x, percentile lines, aging WIP)
**Priority:** P1 · **Size:** M · **Depends on:** T6.2.01, T6.2.10
**Description:** Three scatter variants:
- **Planned vs actual:** x = Dp, y = Da, with a y = x line and a shaded ±20 % band.
- **Cycle time by completion date:** horizontal lines at P50, P70, P85 and P95.
- **Aging WIP:** columns for the statuses ongoing, waiting and blocked; y = age; points are jittered,
  with background bands at the CT percentiles.
**Implementation notes:** each point is tappable and opens its item or occurrence. When points overlap,
they fade to translucent.
**Acceptance criteria:** 2 000 points stay responsive; percentile lines are labeled.
**Tests:** goldens; a widget test for tapping a point.
**Notes:** `ScatterChart` (`charts/scatter_chart.dart`): plan vs actual on one scale with y = x and ±20 % band, by-date with labeled percentile lines, aging WIP columns with deterministic jitter and CT-percentile background bands; nearest-point hit test (18 px) opens the point's `DrillRef`; > 150 points fade to translucent. 2 000-point pump + tap stays well under 2 s in debug.

### T6.2.16 — Stacked area & cumulative flow diagram
**Priority:** P1 · **Size:** M · **Depends on:** T6.2.03
**Description:** Ordered stacked bands for time allocation over time and for the checklist CFD.
**Implementation notes:**
- CFD band order from bottom to top: completed, then blocked, waiting and ongoing (together forming
  "in progress"), then todo.
- Scrubbing shows the per-band counts at a date.
- At a selected date, annotations show WIP (the vertical distance) and the approximate cycle time (the
  horizontal distance).
**Acceptance criteria:** bands never cross; reopens that lower the completed band render correctly.
**Tests:** goldens using the [6.4] CFD fixture.
**Notes:** `StackedAreaChart` + pure `StackedBands` (`charts/flow_charts.dart`): cumulative tops (never cross, reopens lower the completed band), tap/horizontal-drag scrub read-out of every band, and for a CFD (bottom band = completed) the WIP accent and the dashed ≈ cycle-time distance. Markers (e.g. reopens) as triangles.

### T6.2.17 — Burn-down / burn-up
**Priority:** P1 · **Size:** S · **Depends on:** T6.2.03
**Description:** Remaining-items line (with an optional ideal line to the due date); burn-up with a
total-scope line and a done line; scope-creep markers.
**Acceptance criteria:** scope increases show up as steps in the scope line, with a marker listing the
added items.
**Tests:** goldens.
**Notes:** Burn charts are `TimeSeriesData(step: true)`: `ChartAnnotation.details` (new) on `AnnotationKind.scopeChange` markers draws a "+N" marker and lists the added items under the chart (`chartsScopeAdded`); ideal line = a `pace` series (dashed).

### T6.2.18 — Radar chart
**Priority:** P1 · **Size:** S · **Depends on:** T6.2.01
**Description:** 3–12 axes (weekday profile, life areas), with 1–2 series (current vs previous) and value
labels.
**Acceptance criteria:** axes with no data are drawn dashed; the table alternative lists every axis.
**Tests:** goldens.
**Notes:** `RadarChart` (`charts/radial_charts.dart`): 3–12 axes clockwise from the top (counter-clockwise in RTL), rings at 25/50/75/100 %, filled current series with value labels, dashed previous outline, axes without data drawn dashed; table lists every axis.

### T6.2.19 — Rose / 24-hour clock chart
**Priority:** P1 · **Size:** S · **Depends on:** T6.2.01, [6.1] (circular statistics T6.1.18)
**Description:** A circular histogram of times of day (check-ins, task starts), with a circular-mean
arrow and a ±1 circular SD arc.
**Implementation notes:** 24 or 48 sectors; the ring rotates by the day-start hour; labels follow 12/24 h.
**Acceptance criteria:** a cluster around midnight renders as one lobe, not two.
**Tests:** goldens.
**Notes:** `RoseChart` / `RosePainter`: 24 or 48 area-true wedges (radius ∝ √count) rotated to `dayStartMinute`, mean arrow and ±1 SD arc, "No consistent time" when R̄ is low; wrap-around keeps a midnight cluster as one lobe (sector test). Clock faces stay clockwise in RTL.

### T6.2.20 — Treemap
**Priority:** P1 · **Size:** S · **Depends on:** T6.2.01
**Description:** A squarified treemap of time allocation (category → task), with labels where the area
allows and drill-down on tap.
**Acceptance criteria:** areas are proportional to minutes (±1 %).
**Tests:** a unit test for the layout algorithm; goldens.
**Notes:** `squarify()` (Bruls et al.) + `TreemapChart` (`charts/grid_charts.dart`): parents then children inside a header-inset parent rect, labels only where ≥ 40 × 16 px, innermost-node tap drill; unit test checks areas ±1 %, bounds and no overlap.

### T6.2.21 — Matrix heatmap
**Priority:** P1 · **Size:** S · **Depends on:** T6.2.01
**Description:** A generic N × M grid, used for slot occupancy by weekday × slot and for the habit
co-occurrence (phi) matrix.
**Implementation notes:** sequential or diverging (−1…1) color scales, optional cell labels, and axis
labels that truncate with a tooltip.
**Acceptance criteria:** diverging scales are symmetric around 0; the table alternative is present.
**Tests:** goldens.
**Notes:** `MatrixHeatmap` / `MatrixPainter`: sequential or diverging (bound = max |v|, symmetric around 0, positive/negative tones), cell labels from 30 px, significance dots, truncated axis labels with a tap read-out of the full `row × column`; horizontal scroll when wider than the screen.

### T6.2.22 — Advanced interactions: scrubbing, pan & zoom, range brush
**Priority:** P1 · **Size:** M · **Depends on:** T6.2.10
**Description:** Richer interaction for long ranges.
**Implementation notes:**
- Long-press scrub with a crosshair across all series.
- Pinch-zoom and pan on time axes, within range limits.
- A range brush under long series.
- A crosshair synchronized across the charts on one screen.
**Acceptance criteria:** gestures don't conflict with page scrolling (a vertical drag scrolls the page;
a horizontal drag scrubs); 60 fps while scrubbing.
**Tests:** widget gesture tests.
**Notes:** `TimeSeriesChart` is now stateful: fl_chart's pan/long-press scrub (vertical drags still scroll — the scrollable's vertical recognizer wins first), `ChartCrosshairScope` shares the scrubbed date across a screen's charts, two-finger pinch/pan via a raw `Listener` (zoom window clamped to the data, min 7 buckets, "Reset zoom"), and a range brush (`_RangeBrush`, > 90 buckets: drag to pan, drag an edge to resize; `DragStartBehavior.down`). Gesture tests in `charts/chart_interactions_test.dart`; 60 fps is for the [9.1] device suite.

### T6.2.23 — Share chart as image
**Priority:** P1 · **Size:** S · **Depends on:** T6.2.01
**Description:** Capture a `ChartFrame` as a PNG (3× pixel ratio) that includes the title, period and a
small Everslot mark. The user can hide entity names, and the image is shared via the share sheet. It
never uploads anything.
**Acceptance criteria:** the exported image matches the on-screen chart (pixel-compare in a test);
names are replaced by "Habit 1…" when hiding is on.
**Tests:** widget test of the export pipeline.
**Notes:** `charts/chart_share.dart`: `MetricCard` frames get a share button → `ChartShareSheet` preview (title, period, chart, "Made with Everslot" mark, "Hide names" switch) → `captureChartPng` (3×) → `ChartImageSharer` (temp file + share sheet; nothing uploaded). Hidden names use `StatFormat.hideNames` + `anonymousNamesOf(data)` ("Item 1…" numbered by order of appearance). Test decodes the exported PNG and compares it pixel for pixel with the on-screen boundary at 3×. Screen goldens regenerated for the share button.

### T6.2.24 — Chart gallery (dev flavor)
**Priority:** P1 · **Size:** S · **Depends on:** T6.2.12
**Description:** A debug screen showing every chart type with fixture data. Toggles cover theme, RTL, text
scale and color-vision-deficiency simulation (protanopia, deuteranopia and tritanopia color matrices).
**Acceptance criteria:** the gallery lists every chart in the kit; it is excluded from the prod flavor.
**Tests:** a smoke widget test.
**Notes:** `ChartGalleryScreen` (debug menu › Chart gallery, dev builds only — the `/dev` route is compiled out of prod): every sample of `charts/chart_samples.dart` plus empty/insufficient states, with dark, RTL, text scale 2.0 and protanopia/deuteranopia/tritanopia (Machado 2009) color-matrix toggles. Smoke test scrolls through every sample.

### T6.2.25 — Kaplan–Meier curve
**Priority:** P2 · **Size:** S · **Depends on:** T6.2.03, [6.1] (T6.1.25)
**Description:** A step-function survival curve with censor tick marks, a median line and label, and an
optional confidence band.
**Acceptance criteria:** "median not reached" is shown explicitly when S never drops to 0.5.
**Tests:** goldens.
**Notes:** `KmChart`: step curve from S(0) = 1, Greenwood band as a step area, censor ticks, dashed median guides and an explicit "Median not reached" / "Median …" caption.

### T6.2.26 — Forecast visuals: probability histogram & forecast cone
**Priority:** P2 · **Size:** S · **Depends on:** T6.2.14, T6.2.17, [6.1] (T6.1.26)
**Description:** Two forecast displays: a histogram of finish dates with P50/P85/P95 markers, and a
shaded cone (P50–P85–P95) overlaid on burn-down and goal charts.
**Acceptance criteria:** the cone starts at the last actual data point; the percentiles are labeled with dates.
**Tests:** goldens.
**Notes:** `ForecastChart` (finish-day histogram toned by P50/P85/P95, dashed markers, dated captions) and the cone on `TimeSeriesChart` (`TimeSeriesData.cone`: P50/P85/P95 lines from the last actual point with between-band fills, x axis extended over the forecast dates, finish dates labeled under the chart). Goldens for every P1/P2 chart: `charts/goldens/advanced_charts_{light,dark}_{ltr,rtl}_{1x,2x}.png`.
