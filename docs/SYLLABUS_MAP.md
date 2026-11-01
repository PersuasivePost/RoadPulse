# Syllabus → Code Map (216H05C701)

Fill the "Where" column with `File.swift → type/function` as each concept is implemented. This is the viva cheat sheet.

| Module | Concept | Where in RoadPulse | Status |
|---|---|---|---|
| 1.1 | `@main`, App & Scene protocols, `body` | App/RoadPulseApp.swift → `RoadPulseApp` (`WindowGroup`, `.environmentObject`, `init` registers defaults) | ✅ |
| 1.2 | HStack / VStack / ZStack | Onboarding/OnboardingView.swift → `body` (ZStack + VStack), `PrimaryButton` (HStack) | ✅ |
| 1.2 | Lists & navigation | Settings/SettingsScreen.swift → `NavigationStack` + `Form`; Hazards/HazardsContent.swift → sectioned `List` with `Section` headers, `swipeActions`, `refreshable` | ✅ |
| 1.2 | View modifiers (custom ViewModifier) | Components/CardStyle.swift → `CardStyle`, `View.cardStyle()` | ✅ |
| 1.2 | Layout priority & alignment guides | Hazards/HazardRow.swift → `.layoutPriority(1)` on the title; Insights/WorstRoadsList.swift → `.alignmentGuide(.leading)` aligns the bar under the road name | ✅ |
| 2.1 | `@State` / `@Binding` | OnboardingView.swift → `@State pageIndex`, `@Binding hasCompleted`; RoadIllustration.swift → `@State dashPhase` | ✅ |
| 2.1 | `@StateObject` / `@EnvironmentObject` | RoadPulseApp.swift → `@StateObject appState`; Map/MapScreen.swift, Map/FilterChips.swift → `@EnvironmentObject appState`; SettingsScreen.swift, Report/ReportFlow.swift → `@StateObject viewModel`; Report/*Step.swift → `@EnvironmentObject viewModel` | ✅ |
| 2.2 | `ObservableObject` / `@ObservedObject` | App/AppState.swift, ViewModels/SettingsViewModel.swift, Services/LocationManager.swift (`ObservableObject`); Onboarding/PermissionStatusView.swift → `@ObservedObject location` | ✅ |
| 2.2 | `@AppStorage` / `@SceneStorage` | Settings/SettingsScreen.swift → 6 `@AppStorage`; RootTabView.swift → `@SceneStorage selectedTab` | ✅ |
| 3.1 | List & LazyVGrid / LazyHGrid | Hazards/HazardsContent.swift → `list` (`List`, `Section`), `grid` (`LazyVGrid`, adaptive `GridItem`, pinned section headers); HazardsScreen.swift → segmented layout toggle | ✅ |
| 3.1 | ScrollViewReader | Hazards/HazardsContent.swift → `ScrollViewReader`, `proxy.scrollTo` (jump-to-top button, `SeverityIndexStrip` jumps) | ✅ |
| 3.1 | TextField / Slider / Toggle / Picker / Stepper | SettingsScreen.swift → Picker, Stepper, Toggle, Slider; Report/DetailsStep.swift → `TextField` (+ `@FocusState`), severity `Slider`, type `Picker`, fixed `Toggle`; Map/SearchBar.swift → `TextField` | ✅ |
| 3.1 | Tap / swipe / long-press gestures | OnboardingView.swift → `swipe` (`DragGesture`); Map/HazardMapView.swift → tap-to-select pins; Hazards/HazardsContent.swift → `contextMenu` with preview (long-press), `swipeActions`; Hazards/ZoomableImage.swift → `MagnifyGesture`, `DragGesture`, double-tap; Drive/HoldToStartButton.swift → `onLongPressGesture(minimumDuration:onPressingChanged:)`; Insights/SeverityDonut.swift → `SpatialTapGesture` | ✅ |
| 3.1 | Custom gesture recogniser | Components/ResolveSlider.swift → `DragGesture` with 80% threshold + spring snap-back (maths in Models/ResolveGesture.swift), Hazards/SeverityIndexStrip.swift → `DragGesture` + `@GestureState`; Drive/HoldToStartButton.swift → long-press with progress ring and early-release drain | ✅ |
| 3.2 | NavigationStack + NavigationPath, passing data | Report/ReportFlow.swift → `NavigationStack(path:)`, `navigationDestination(for: ReportStep.self)`; ViewModels/ReportViewModel.swift → `path`, shared state passed via `.environmentObject` | ✅ |
| 3.2 | Custom nav bars & toolbars | Report/ReportStepChrome.swift → hidden back button, custom `ToolbarItem`s, Cancel with `confirmationDialog`, `safeAreaInset` progress; DetailsStep.swift → keyboard toolbar | ✅ |
| 3.2 | Transitions & modal presentation/dismissal | RootTabView.swift → `fullScreenCover`; OnboardingView.swift → `slide` (`.asymmetric`); Map/MapScreen.swift → `.sheet`; Map/HazardSheet.swift → `presentationDetents`, `confirmationDialog` | ✅ |
| 3.3 | Paths, gradients, custom geometry | Onboarding/RoadShape.swift, LaneDashesShape.swift (`animatableData`), RoadGeometry.swift; RoadIllustration.swift → `LinearGradient`; Components/RingShape.swift (animatable arc), AnimatedCheckmark.swift (`CheckmarkShape`) | ✅ |
| 3.3 | Implicit / explicit animations, transitions | RoadIllustration.swift → `withAnimation` repeatForever; LanePageIndicator.swift, PrimaryButton.swift → `.animation(_, value:)`; OnboardingView.swift → `.transition`; Components/ConfidenceRing.swift → animated ring + counting number (`Animatable`); Report/AnalyzeStep.swift → scan line; Report/ConfirmStep.swift → checkmark draw-on | ✅ |
| 3.3 | Hand-drawn charts (Path/Shape, `animatableData`) | Insights/BarChart.swift → `BarShape`; Insights/SeverityDonut.swift → `DonutSliceShape` (`AnimatablePair`); Drive/WaveformShape.swift; Components/CountingNumber.swift (`Animatable`) | ✅ |
| 3.3 | `matchedGeometryEffect`, share sheet | Hazards/HazardThumbnail.swift, HazardDetail.swift → one `@Namespace` id per hazard (list ↔ grid ↔ hero); HazardDetail.swift, HazardsContent.swift → `ShareLink` | ✅ |
| 4.1 | URLSession, JSON → Codable | Services/WeatherService.swift → `session.data(from:)`, `parse`; Models/WeatherResponse.swift → `Codable` + `convertFromSnakeCase`; Models/WeatherError.swift; Views/Components/RainfallRow.swift (loading / error / retry); tests use a `URLProtocol` stub | ✅ |
| 4.1 | Async fetching with Combine | ViewModels/MapViewModel.swift → `$searchText` pipeline (`debounce`, `removeDuplicates`, `sink`); Services/WeatherService.swift → `dataTaskPublisher`, `tryMap`, `mapError`; ViewModels/RainfallViewModel.swift → `receive(on:)`, `sink`, `AnyCancellable` cancelled on disappear | ✅ |
| 4.2 | Core Data model, entity relationships, context | Persistence/ModelBuilder.swift → `makeModel()`, `link(...)` (Area↔Hazard, Trip↔RoughSegment); PersistenceController.swift → `viewContext` | ✅ |
| 4.2 | `@FetchRequest` + `NSPredicate` | Map/HazardMapView.swift → `@FetchRequest(fetchRequest:)` rebuilt per filter; Repositories/HazardQuery.swift → `predicate` (NSCompoundPredicate); Settings/SettingsScreen.swift → live count. Hazards/HazardsContent.swift → `SectionedFetchRequest` (`sectionIdentifier: \.areaSectionName`) via `HazardQuery.groupedByAreaRequest()` | ✅ |
| 4.2 | CRUD | Repositories/HazardRepository.swift → `create`, `fetch`, `update`, `delete` | ✅ |
| 4.2 | Migration & concurrency | PersistenceController.swift → lightweight-migration flags, `performBackgroundTask`, `automaticallyMergesChangesFromParent`; HazardRepository.swift → `createInBackground` | ✅ |
| 5.1 | Map view in SwiftUI | Map/MapScreen.swift, Map/HazardMapView.swift → `Map(position:selection:)`, `MapCameraPosition`, `UserAnnotation`, `.mapControls`, `.mapStyle` | ✅ |
| 5.1 | CLLocationManager & privacy permissions | Services/LocationManager.swift → all authorization states, `start()`/`stop()`, delegate; Onboarding last page; Map/LocationDeniedView.swift (Open Settings) | ✅ |
| 5.2 | Custom annotations / pins | Map/HazardPin.swift → custom `Annotation` content; Map/HazardMapView.swift → `Annotation(...).tag(id)` | ✅ |
| 5.2 | MapPolyline / MapCircle overlays | Map/HazardMapView.swift → `MapPolyline(...).stroke(...)`, `MapCircle` for rough segments, coloured by intensity | ✅ |
| 5.2 | Map selection & interaction | Map/HazardMapView.swift → `selection:`; Map/MapScreen.swift → sheet binding, camera fly-to (`flyTo`) | ✅ |
| 5.2 | Forward & reverse geocoding (CLGeocoder) | Services/GeocodingService.swift → `geocodeAddressString` (forward, map search), `reverseGeocodeLocation` (report address + Area) | ✅ |
| 5.3 | Core ML model integration in SwiftUI lifecycle | Services/ClassifierService.swift (loads `RoadClassifier.mlmodelc` once); ViewModels/ReportViewModel.swift → `analyze()` called from `AnalyzeStep`'s `.task` | ✅ |
| 5.3 | `VNCoreMLRequest` image classification | Services/ClassifierService.swift → `classify(_:)` (`VNCoreMLRequest`, `.scaleFill`, `Task.detached`) | ✅ |
| 5.3 | Text recognition (OCR) with Vision | Services/TextRecognitionService.swift → `VNRecognizeTextRequest`; Models/LandmarkPicker.swift; Report/DetailsStep.swift → "Scan signboard" | ✅ |
| Extra | CoreMotion sensor processing | Services/MotionService.swift → `CMMotionManager.startDeviceMotionUpdates` at 50 Hz; Models/SpikeDetector.swift → rolling RMS; ViewModels/DriveViewModel.swift; replay fallback `ReplayMotionService` | ✅ |
| Extra | Accessibility: Dynamic Type, VoiceOver, Reduce Motion | Hazards/HazardRow.swift → `@ScaledMetric`; Components/ResolveSlider.swift, Drive/HoldToStartButton.swift, Hazards/SeverityIndexStrip.swift → `accessibilityAction` / `accessibilityAdjustableAction`; every custom animation checks `accessibilityReduceMotion` (e.g. Report/ConfirmStep.swift) | ✅ |
