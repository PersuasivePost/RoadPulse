# RoadPulse: Product Requirements

## Problem
Mumbai roads develop potholes every monsoon. Commuters have no quick way to record them, and nobody can see where the worst stretches are. RoadPulse turns a phone photo into a verified, mapped hazard report, entirely on-device.

## Users
- **Commuter**: reports hazards on the way, checks the worst roads near them.
- **Evaluator (faculty)**: needs to see every syllabus topic used meaningfully.

## Non-goals (do not build)
Backend/server, user accounts, cloud sync, push notifications, sharing reports to BMC, Android, iPad-specific layouts, object-detection bounding boxes.

---

## F0: Setup & CI
- XcodeGen `project.yml`: targets `RoadPulse` (app) and `RoadPulseTests`; bundle id `com.persuasivepost.roadpulse`; Info.plist keys `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSMotionUsageDescription`.
- `.github/workflows/ios.yml` on `macos-15`: install xcodegen → generate → `xcodebuild build` + `test` on a dynamically chosen iPhone simulator; upload `.xcresult` on failure.
- Folder structure per ARCHITECTURE.md; placeholder app; one passing test.
- **Done when:** Actions run is green on `main`.

## F1: ML model (Linux)
- Dataset: Kaggle pothole dataset (e.g. `atulyakumar98/pothole-detection-dataset`; verify, else best alternative). Classes `pothole`, `normal` (+ `crack` if a good dataset exists).
- `ml/train.py`: MobileNetV3-Small fine-tune, augmentation, 80/10/10 split, AMP, best checkpoint, metrics + confusion matrix → `ml/REPORT.md`.
- `ml/convert.py`: coremltools conversion, `ImageType` 224×224 with ImageNet normalisation in scale/bias, `ClassifierConfig` labels, metadata (author persuasivepost). Output to `Resources/RoadClassifier.mlpackage`.
- **Done when:** test accuracy ≥ 88%, REPORT.md written, CI compiles the model.

## F2: Persistence (Core Data)
- Entities and relationships per ARCHITECTURE.md.
- `PersistenceController` (viewContext, background contexts with auto-merge, lightweight migration, in-memory mode).
- `HazardRepository`: CRUD + NSPredicate queries (severity range, status, area, date range, text search).
- Demo seed: ~25 hazards across Kalyan, Dombivli, Thane, Ghatkopar, Vidyavihar.
- **Done when:** XCTests cover CRUD, predicates, cascade delete and background save merging.

## F3: App shell, state, onboarding, settings
- `@main` App + `WindowGroup`; inject persistence + `AppState` (`.environmentObject`).
- TabView: Map · Report · Hazards · Insights · Settings; selected tab via `@SceneStorage`.
- Correct, commented use of `@State`, `@Binding`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `@AppStorage`, `@SceneStorage`.
- Settings (`@AppStorage`): map style, default severity filter, haptics, drive sensitivity (Slider), units; Toggle/Picker/Stepper; Load demo data; Delete all (confirmationDialog).
- Onboarding (first launch, `fullScreenCover`): 3 pages, animated road illustration (Path + gradient, moving lane dashes, pulsing pothole), asymmetric transitions; last page requests permissions.
- **Done when:** onboarding shows once; settings persist across relaunch.

## F4: Map
- `LocationManager` (CLLocationManager wrapper, all auth states, denied-state view with Open Settings).
- iOS 17 `Map` + `MapCameraPosition`, `UserAnnotation`, `MapControls`, style toggle.
- Custom `Annotation` pins coloured by severity; severity ≥ 4 pulse; fixed = grey.
- Selection → spring scale-up → bottom sheet (`presentationDetents`) with photo, severity, address, rain-risk badge, actions (mark fixed, directions via `MKMapItem.openInMaps`, delete).
- Search: forward geocoding (`CLGeocoder.geocodeAddressString`) with Combine debounce, camera animates to result.
- Filter chips bound to AppState → NSPredicate.
- `Resources/MumbaiCommute.gpx` (Kalyan → Thane → Ghatkopar).
- **Done when:** demo pins render; search flies the camera; GPX simulation moves the user dot.

## F5: AI Report flow (core feature)
- `NavigationStack` + `NavigationPath`: Capture → Analyze → Details → Confirm.
- Capture: `PhotosPicker` + camera (`UIImagePickerController` representable, hidden when unavailable).
- Analyze: `ClassifierService` → `VNCoreMLRequest` off the main thread (async/await); scanning-line animation; animated confidence ring (custom Shape, animatable trim + counting number). "normal" → "No hazard detected" + manual override.
- Details: severity Slider (pre-filled from confidence), type Picker, notes TextField with `@FocusState`, already-fixed Toggle, location auto-filled + reverse geocoded (`CLGeocoder.reverseGeocodeLocation`) → address + Area (create if new). "Scan signboard" → `VNRecognizeTextRequest` OCR → landmark field.
- Confirm: summary card → save on background context → checkmark draw-on animation + haptic → pop to root.
- Custom nav bar/toolbar, Cancel with dismissal.
- **Done when:** a pothole photo yields "Pothole ≥ 80%", saves, and appears on the map; ClassifierService XCTests pass with bundled sample images.

## F6: Hazards list & gallery
- Sectioned list by Area (`SectionedFetchRequest`), `.searchable` → NSPredicate.
- List ↔ `LazyVGrid` gallery toggle with `matchedGeometryEffect`.
- Swipe actions (resolve / delete with confirm), long-press `contextMenu` with preview, pull-to-refresh (refetch rainfall).
- `ScrollViewReader`: jump-to-top FAB + severity index strip.
- Detail: hero image (matched geometry), pinch-zoom + double-tap reset, edit fields (Update), `ShareLink`.
- Custom gesture: swipe-to-resolve slider (`DragGesture`, threshold, spring snap-back).
- Animated empty state.
- **Done when:** all gestures work; list/grid morph is smooth; filters are instant.

## F7: Weather API (networking)
- `WeatherService` → Open-Meteo (no key), last 7 days' precipitation at the hazard's coordinates.
- Codable models; async/await version AND Combine `dataTaskPublisher` version (used by a ViewModel).
- Store `rainfallMM`; compute Monsoon Risk (low/medium/high) from rainfall × severity; show in detail + map sheet.
- Loading / error / retry states; cancellation on disappear.
- **Done when:** XCTest with `URLProtocol` mock + JSON fixture passes.

## F8: Insights & Drive Mode
- Insights (hand-drawn): animated bar chart of hazards per Area (staggered springs); severity donut of arc Shapes with `animatableData` (tap to highlight); "Worst roads near me" (distance-weighted severity); stat cards with counting numbers.
- Drive Mode (sheet from Map): start via hold-to-start long-press with progress ring; `MotionService` (CoreMotion 50 Hz, rolling vertical RMS); live waveform Path; spikes above the threshold → `RoughSegment` with GPS into the current `Trip`; trips drawn as `MapPolyline` coloured by intensity.
- Simulator fallback: "Replay sample drive" plays a bundled accelerometer CSV along the GPX route.
- **Done when:** replay draws the waveform and leaves a coloured trail on the map.

## F9: Polish & docs
- App icon, accent colour, dark mode, Dynamic Type, VoiceOver labels on custom controls, haptics respect settings, tab/button animations.
- Syllabus audit → fill gaps naturally → complete `docs/SYLLABUS_MAP.md`.
- README: features, Mermaid architecture, ML results, screenshots, GPX instructions.
- **Done when:** every syllabus row in SYLLABUS_MAP.md points to real code.
