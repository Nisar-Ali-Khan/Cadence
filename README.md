# Cadence — PCOS Care Companion (Flutter)

A cycle-aware PCOS symptom tracker: daily logging, a 28-day "cycle ring"
visualization, non-diagnostic pattern insights, doctor-ready reports, and
reminders. Same design system as the earlier web prototype: deep plum, sage,
dusty rose and amber, with Fraunces + Public Sans + IBM Plex Mono type.

## Setup

1. Install the Flutter SDK if you haven't already (`flutter doctor` to check).
2. From this folder, run:
   ```bash
   flutter pub get
   flutter run
   ```
3. First run needs internet access once, to fetch the Google Fonts
   (Fraunces, Public Sans, IBM Plex Mono). If you need fully offline builds,
   bundle the font files locally and swap `google_fonts` calls for
   `fontFamily` references instead.

## Project structure

```
lib/
  theme/        Color palette (AppColors) and typography (AppText)
  widgets/      Cycle ring painter, symptom slider, section card, bottom nav
  screens/      Today, Trends, Reports, Profile + the HomeShell tab switcher
  models/       ReportItem
```

## Notes for going further

- State currently lives in-memory inside `HomeShell` — no backend or local
  persistence yet. Swap in your API/database layer (or `shared_preferences`
  for local-only storage) when ready.
- The "Patterns in your logs" card and the high-pain alert are written as
  non-diagnostic observations on purpose ("noticed", not "diagnosed") —
  keep that framing if you extend the insight logic, since anything that
  reads as a diagnosis pushes the app toward medical-device territory.
- The 28-day cycle data and 16-day trend chart are hardcoded sample data —
  wire them up to real logged entries once you have storage in place.
