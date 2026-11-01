# RoadPulse: Architecture

## Pattern
MVVM + repository. Views are dumb; ViewModels (`ObservableObject`) own screen logic; Services wrap Apple frameworks; Repositories own Core Data access.

```
Views ──▶ ViewModels ──▶ Services (Classifier, OCR, Location, Geocoding, Weather, Motion)
   │            └──────▶ Repositories ──▶ PersistenceController (Core Data)
   └── @FetchRequest (read-only lists bind directly to Core Data)
AppState (EnvironmentObject): selected tab-level state, filters, selected hazard, drive status
```

## Folders
```
RoadPulse/
  App/            RoadPulseApp.swift, AppState.swift, RootTabView.swift
  Models/         Core Data NSManagedObject subclasses, enums (HazardType, HazardStatus, Severity, RiskLevel)
  Persistence/    PersistenceController.swift, ModelBuilder.swift (programmatic model), DemoSeeder.swift
  Repositories/   HazardRepository.swift, TripRepository.swift
  Services/       ClassifierService, TextRecognitionService, LocationManager, GeocodingService, DirectionsLauncher, ImageProcessing, SampleImages, WeatherService, MotionService, Haptics
  ViewModels/     ReportViewModel, MapViewModel, HazardDetailViewModel, InsightsViewModel, DriveViewModel
  Views/
    Map/          MapScreen, HazardMapView, HazardPin, HazardSheet, SearchBar, FilterChips, LocationDeniedView, MapCamera, MapStyleOption+MapKit
    Report/       ReportFlow, CaptureStep, AnalyzeStep, DetailsStep, ConfirmStep, CameraPicker, ReportStepChrome
    Hazards/      HazardsScreen, HazardRow, HazardGrid, HazardDetail, SeverityIndexStrip
    Insights/     InsightsScreen, BarChart, SeverityDonut, StatCard, WorstRoadsList
    Drive/        DriveSheet, HoldToStartButton, WaveformView
    Settings/     SettingsScreen
    Onboarding/   OnboardingView, RoadIllustration
    Components/   ConfidenceRing, SeverityBadge, RiskBadge, FilterChip, StepProgress, RingShape, AnimatedCheckmark, PrimaryButton, ResolveSlider, LaneDivider, EmptyState, CardStyle
  Resources/      RoadClassifier.mlpackage, MumbaiCommute.gpx, sample_drive.csv, Assets.xcassets, SampleImages/
RoadPulseTests/   Repository, Classifier, Weather (URLProtocol mock), Risk calculation, Motion spike detection
ml/               train.py, convert.py, requirements.txt, REPORT.md (data/ and checkpoints/ git-ignored)
docs/             PRD, ARCHITECTURE, DESIGN, PROGRESS, SYLLABUS_MAP
```

## Data model (programmatic Core Data)
| Entity | Attributes | Relationships |
|---|---|---|
| **Area** | name: String, city: String, ward: String?, latitude: Double, longitude: Double | hazards ↔ Hazard (to-many, cascade) |
| **Hazard** | id: UUID, type: String, severity: Int16 (1–5), confidence: Double, status: String (open/fixed), notes: String?, landmark: String?, photo: Binary (external storage), latitude: Double, longitude: Double, address: String?, rainfallMM: Double (optional, nil = unknown; not NaN, because SQLite stores NaN as NULL), createdAt: Date, updatedAt: Date | area ↔ Area (to-one, nullify) |
| **Trip** | id: UUID, startedAt: Date, endedAt: Date?, distanceMeters: Double | roughSegments ↔ RoughSegment (to-many, cascade) |
| **RoughSegment** | startLat, startLon, endLat, endLon: Double, intensity: Double (0–1), timestamp: Date | trip ↔ Trip (to-one, nullify) |

Migration: `shouldMigrateStoreAutomatically` + `shouldInferMappingModelAutomatically` = true. Add a `modelVersion` constant and document in code how a v2 attribute would be added.

## Concurrency
- UI reads: `viewContext` (main). Writes: `container.performBackgroundTask` / `newBackgroundContext()`; `automaticallyMergesChangesFromParent = true`.
- Vision requests run in `Task.detached`/a background queue; results hop to `@MainActor` ViewModels.
- Services are `async` where possible; `WeatherService` also exposes a Combine publisher.

## Key algorithms
- **Severity prefill:** `pothole` confidence → 1–5 (≥0.95→5, ≥0.85→4, ≥0.7→3, else 2); `normal` → 1.
- **Monsoon risk:** `score = severity/5 * 0.6 + min(rain7d/100, 1) * 0.4` → low < 0.4 ≤ medium < 0.7 ≤ high.
- **Worst near me:** `Σ severity / (1 + distanceKm)` per Area, top 5.
- **Drive spikes:** rolling RMS over 0.5 s of vertical acceleration (`userAcceleration` projected onto `gravity`, so any phone mount works); segment when RMS > threshold (Settings Slider, default 0.35 g); intensity = clamp(RMS / 1.0 g).

## Naming
Views end in `Screen` (tab roots), `View`, `Sheet` or `Step`; ViewModels end in `ViewModel`; services in `Service`/`Manager`. One type per file.
