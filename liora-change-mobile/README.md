# Liora Change Mobile

Flutter app for the Liora Change hackathon MVP.

## Issue #6 — Check-in flow

This branch adds the daily check-in bottom sheet (complete / skip) with:

- `POST /challenges/{id}/check-ins` via `ChallengeRepository.submitCheckIn`
- Celebration view on complete (animated streak + XP)
- Calm acknowledgment on skip (no shame copy)
- Provider invalidation for dashboard + challenge detail
- Entry points on Home and Challenge Detail screens

## Setup

```bash
cd liora-change-mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

API base URL (default Android emulator):

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

## Merge note

If your teammate already merged Issues #1–#4 in another folder, copy `lib/features/checkins/` and the `submitCheckIn` method from this branch into that project, then wire the sheet from Home/Detail.
