# Progress

Update at the end of every task: tick items, add a dated line to the log, note blockers.

## Plan
| Task | Spec | Target date | Status |
|---|---|---|---|
| F0 Setup & CI | PRD#F0 | 29 Oct | ✅ |
| F1 ML model | PRD#F1 | 29 Oct | ◐ trained + converted (96.7% test); awaiting CI to compile model |
| F2 Core Data | PRD#F2 | 30 Oct | ☐ |
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

- 1 Nov: F1 done locally. Data from Hugging Face (no Kaggle key): taroii/pothole-detection, Arpitraj01/Pothole_classification, rupesh002/pothole-detection-dataset, kauevestena/deep_pavements_surface_patches (`ml/download_data.py`). MobileNetV3-Small fine-tune, grouped 80/10/10 split, **test accuracy 96.7%** (`ml/REPORT.md`). `RoadPulse/Resources/RoadClassifier.mlpackage` (3.1 MB; outputs `classLabel` / `classLabel_probs`). Tick F1 once CI compiles the model.

## Blockers / notes
<!-- e.g. lab Mac Xcode version, simulator issues -->
- F1: no `crack` class (no suitable close-up dataset). Dataset sources are skewed (see REPORT caveats): re-test with real phone photos on Mac visit 2. Vision must use `imageCropAndScaleOption = .scaleFill`. Model can't be run on Linux; first real prediction check is the F5 XCTests on CI.
