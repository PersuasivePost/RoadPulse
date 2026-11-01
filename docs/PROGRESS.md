# Progress

Update at the end of every task: tick items, add a dated line to the log, note blockers.

## Plan
| Task | Spec | Target date | Status |
|---|---|---|---|
| F0 Setup & CI | PRD#F0 | 29 Oct | ✅ |
| F1 ML model | PRD#F1 | 29 Oct | ✅ |
| F2 Core Data | PRD#F2 | 30 Oct | ◐ code + tests written, awaiting CI |
| F3 Shell, state, onboarding, settings | PRD#F3 | 30 Oct | ☐ |
| F4 Map | PRD#F4 | 31 Oct | ☐ |
| 🖥 Mac visit 1: run on simulator, test map + GPX | | 31 Oct | ☐ |
| F5 AI report flow | PRD#F5 | 1 Nov | ☐ |
| F6 Hazards list & gallery | PRD#F6 | 2 Nov | ☐ |
| F7 Weather API | PRD#F7 | 2 Nov | ☐ |
| 🖥 Mac visit 2: test report flow, gestures, API | | 2 Nov | ☐ |
| F8 Insights & Drive Mode | PRD#F8 | 3 Nov | ☐ |
| F9 Polish & docs | PRD#F9 | 3 Nov | ☐ |
| 🖥 Mac visit 3: full run-through, screenshots, demo video | | 3 Nov | ☐ |
| Buffer + submission | | 4 Nov | ☐ |

## Log
- 1 Nov: F0 written: `project.yml`, `.github/workflows/ios.yml`, folder skeleton, placeholder app (`RootTabView`), `Color+Tokens` + 12 colour sets + AccentColor, `Motion` tokens, `DesignTokenTests`. CI green on main (run 41291206532) after adding placeholder AppIcon set.

- 1 Nov: F1 done locally. Data from Hugging Face (no Kaggle key): taroii/pothole-detection, Arpitraj01/Pothole_classification, rupesh002/pothole-detection-dataset, kauevestena/deep_pavements_surface_patches (`ml/download_data.py`). MobileNetV3-Small fine-tune, grouped 80/10/10 split, **test accuracy 96.7%** (`ml/REPORT.md`). `RoadPulse/Resources/RoadClassifier.mlpackage` (3.1 MB; outputs `classLabel` / `classLabel_probs`). CI compiled the model (run 41294204339).

- 1 Nov: F2 written: programmatic model (`ModelBuilder`, 4 entities, cascade/nullify), `PersistenceController` (view + background contexts, auto-merge, lightweight-migration flags, `/dev/null` in-memory, `preview`), `HazardRepository` + `HazardQuery` (severity/status/type/area/date/text predicates, sort), `DemoSeeder` (25 hazards, 5 areas). Tests: repository CRUD, query predicates, cascade deletes, background merge, seeder, severity. Not yet compiled. `TripRepository` deferred to F8 (Drive Mode).

## Blockers / notes
<!-- e.g. lab Mac Xcode version, simulator issues -->
- F1: no `crack` class (no suitable close-up dataset). Dataset sources are skewed (see REPORT caveats): re-test with real phone photos on Mac visit 2. Vision must use `imageCropAndScaleOption = .scaleFill`. Model can't be run on Linux; first real prediction check is the F5 XCTests on CI.
- F2: a v2 model can't be migrated by the flags alone, because there's no .momd for Core Data to find v1 in. `ModelBuilder` documents the `NSStagedMigrationManager` route (iOS 17).
