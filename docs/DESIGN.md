# RoadPulse: Design System

**Mood:** asphalt and road-marking paint. Dark, calm surfaces with bright yellow lane-marking accents and a clear severity colour scale. It should feel like a road-safety instrument, not a generic to-do app.

**Signature motif:** the dashed **lane line**. It appears as section dividers (`LaneDivider`), the loading indicator (dashes moving forward), the onboarding road, and the Drive Mode waveform baseline. Use it consistently; it makes the app recognisable.

## Colour (define in `Assets.xcassets` with light/dark variants + a `Color` extension)
| Token | Light | Dark | Use |
|---|---|---|---|
| `asphalt` | #F2F3F5 | #15171B | app background |
| `surface` | #FFFFFF | #1E2127 | cards, sheets |
| `surfaceRaised` | #FFFFFF | #272B33 | pins' halo, chips |
| `ink` | #14161A | #F2F3F5 | primary text |
| `inkMuted` | #5E6470 | #9AA1AD | secondary text |
| `laneYellow` | #E8A900 | #FFC83D | **accent**: primary buttons, lane lines, selection |
| `sev1` | #2FB45A | #34C759 | smooth / minor |
| `sev2` | #A4C93A | #B5D94A | low |
| `sev3` | #F2B705 | #FFCC00 | medium |
| `sev4` | #F07B12 | #FF9500 | high |
| `sev5` | #D7263D | #FF453A | severe |
| `fixedGrey` | #A0A6B0 | #5C626C | resolved hazards |

Severity colour always comes from one helper (`Severity.color`). Never hard-code it.

## Typography
- Headings & numbers: **SF Pro Rounded** (`.fontDesign(.rounded)`), bold/heavy. Big stat numbers use `.monospacedDigit()` so counters don't jitter.
- Body: SF Pro default. Use semantic styles only (`.largeTitle`, `.headline`, `.body`, `.caption`) so Dynamic Type works.

## Spacing & shape
- Spacing scale: 4 · 8 · 12 · 16 · 24 · 32. Screen padding 16.
- Corner radius: 12 (chips, small cards), 20 (cards, sheets), capsule for buttons/chips.
- `.cardStyle()` modifier: `surface` fill, radius 20, 1 pt hairline stroke (`inkMuted` @ 12%), soft shadow in light mode only.

## Motion
| Token | Value | Use |
|---|---|---|
| `Motion.snappy` | `.spring(response: 0.3, dampingFraction: 0.8)` | taps, selection, chips |
| `Motion.smooth` | `.spring(response: 0.5, dampingFraction: 0.85)` | sheets, layout changes, matched geometry |
| `Motion.reveal` | `.easeOut(duration: 0.8)` | rings, chart bars growing |
| `Motion.pulse` | `.easeInOut(duration: 1.2).repeatForever(autoreverses: true)` | severe pins |
| stagger | 0.05 s per item | chart bars, list appear |

Rules: animate state, not views (prefer implicit `.animation(_, value:)`; use `withAnimation` for user-triggered changes). Button press = scale 0.96. Every custom animation checks `accessibilityReduceMotion` and falls back to an opacity fade.

## Components
- **HazardPin**: 34 pt circle in severity colour, white SF Symbol (`exclamationmark.triangle.fill` pothole, `line.diagonal` crack), `surfaceRaised` halo; selected = 1.3× scale + yellow ring; severe = pulsing outer ring.
- **ConfidenceRing**: 160 pt, 14 pt stroke, track `inkMuted` 15%, progress in severity colour, round caps, centre number counts up (rounded heavy, monospaced).
- **SeverityBadge / RiskBadge**: capsule, tinted background (colour @ 18%), coloured text.
- **FilterChip**: capsule, unselected `surfaceRaised`, selected `laneYellow` with `ink` text.
- **PrimaryButton**: full-width capsule, `laneYellow` fill, `ink` label, haptic on tap.
- **ResolveSlider**: track with lane-dash pattern; thumb slides right; past 80% → green check + success haptic; otherwise spring back.
- **LaneDivider**: 2 pt dashed line `[10, 8]` in `laneYellow` @ 60%.
- **EmptyState**: road illustration + one line + action button.

## Iconography & imagery
SF Symbols only, `.symbolRenderingMode(.hierarchical)`; use `.symbolEffect(.bounce)` on success states. Hazard photos: aspect-fill, radius 12.

## Screens (layout intent)
- **Map**: full-bleed map; floating search bar top; filter chips under it; Drive Mode FAB bottom-right (yellow).
- **Report**: step progress shown as 4 lane dashes filling yellow at the top of each step.
- **Hazards**: large title, segmented List/Grid toggle in toolbar, sections headed by Area with count badge.
- **Insights**: vertical scroll of cards: stat row (3 cards) → bar chart → donut → worst roads.
- **Settings**: grouped Form, demo/destructive actions at the bottom.
