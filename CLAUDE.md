# RoadPulse – AI Road Hazard Mapper

SwiftUI iOS app for the Honours course **iOS Application Development using SwiftUI (216H05C701)**.
Users photograph road hazards → on-device Core ML classifies them → hazards are geotagged, stored in Core Data, and mapped in MapKit. Optional Drive Mode maps rough roads via CoreMotion.

Deadline: **4 Nov 2026**. Scope is fixed in `docs/PRD.md`. Do not add features outside it.

## Read before every task
1. `docs/PROGRESS.md`: what's done and what's next. Update it at the end of every task.
2. `docs/PRD.md`: feature specs + acceptance criteria (F0–F9).
3. `docs/ARCHITECTURE.md`: folders, layers, data model, naming.
4. `docs/DESIGN.md`: colours, type, spacing, motion, components. All UI must follow it.
5. `docs/SYLLABUS_MAP.md`: keep it updated whenever you use a syllabus concept.


# ALWAYS REMEMBER DO NOT COMMIT ANYTHING!! ALWAYS ASHVATTH WILL DO ALL THE COMMITS YOU NEVER TOUCH COMMITING STAGING AND PUSHING!!

## Hard constraints
- **The developer is on Linux with no Mac.** You cannot run Xcode, the simulator or `swift build` for iOS locally. **GitHub Actions (macOS runner) is the only compiler.**
- Never commit `.xcodeproj`. `project.yml` (XcodeGen) is the source of truth for targets, resources, Info.plist keys and build settings.
- iOS deployment target **17.0**. Swift 5.9+. SwiftUI-first; UIKit only through `UIViewRepresentable`/`UIViewControllerRepresentable` when unavoidable (camera picker).
- State: use **`ObservableObject` + `@Published`** (the syllabus teaches these). Do **not** use the `@Observable` macro.
- Core Data model is built **programmatically** (`NSManagedObjectModel` in code). No `.xcdatamodeld`.
- No third-party Swift packages. Apple frameworks only: SwiftUI, MapKit, CoreLocation, CoreData, CoreML, Vision, CoreMotion, Combine, PhotosUI.
- Charts are hand-drawn with `Path`/`Shape` (no Swift Charts); this demonstrates custom geometry.
- ML training lives in `ml/` (Python, PyTorch → coremltools). Datasets, checkpoints and venvs are git-ignored.

## Workflow (every task)
1. Read the files above, then state a short plan.
2. Implement. Keep files small (≤ ~250 lines); one view per file.
3. Add or extend XCTests for any logic (repositories, services, view models).
4. Write code you're confident compiles. Double-check iOS 17 API signatures, since you can't build locally.
5. Run `/ship` (commit → push → `gh run watch` → fix from logs → repeat until green).
6. Update `docs/PROGRESS.md` and `docs/SYLLABUS_MAP.md`.

## Git
- Author: `persuasivepost <joshi.ashvatth@gmail.com>`. Never use another name.
- Conventional commits: `feat(map): custom severity pins`, `fix(ci): ...`, `chore: ...`.
- Small commits, one feature slice each.

## Commands
```bash
gh run watch                       # watch latest CI run
gh run view --log-failed           # read failing step logs
python ml/train.py && python ml/convert.py   # retrain + reconvert model (Linux, GPU)
# On a Mac only:
xcodegen generate && open RoadPulse.xcodeproj
```

## Code style
- `// MARK: -` sections; views split into small subviews; previews for every view using the in-memory store + demo data.
- Comment each property wrapper choice briefly (`// @StateObject: this view owns the lifecycle`). It's a teaching project, so the viva will ask.
- No force unwraps outside tests. Errors surface to UI as user-friendly messages.
- Respect `@Environment(\.accessibilityReduceMotion)` in every custom animation.
