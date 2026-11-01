# RoadPulse on a Mac: setup, simulator checks and iPhone demo

The repo has no `.xcodeproj`. XcodeGen generates it from `project.yml`; after that it is a normal Xcode project.

## 1. Open the project

### 1.1 Check Xcode
```bash
xcodebuild -version
```
You need **Xcode 15 or newer** (the app targets iOS 17; CI uses Xcode 16.4). If it's missing, install it from the App Store.

### 1.2 Install XcodeGen
With Homebrew:
```bash
brew install xcodegen
```
On a lab Mac without admin rights or Homebrew, use the standalone binary:
```bash
curl -L -o xcodegen.zip https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip
unzip xcodegen.zip
# binary: ./xcodegen/bin/xcodegen
```

### 1.3 Clone over HTTPS
HTTPS avoids needing an SSH key on that Mac.
```bash
git clone https://github.com/PersuasivePost/RoadPulse.git
cd RoadPulse
```
If the repo is private, sign in with `gh auth login`, or use a GitHub personal access token as the password.

### 1.4 Generate and open
```bash
xcodegen generate            # or ./xcodegen/bin/xcodegen generate
open RoadPulse.xcodeproj
```
- The `.xcodeproj` is git-ignored; never commit it.
- After every `git pull`, run `xcodegen generate` again.

### 1.5 Run and test
- Top bar: choose the **RoadPulse** scheme and an **iPhone 15 / 16** simulator (iOS 17+).
- **⌘R** runs the app. The first build takes a minute or two, partly because it compiles the Core ML model.
- **⌘U** runs all XCTests, the same suite as CI.

## 2. Simulator checklist (Mac visits 1 and 2)

| Check | How |
|---|---|
| Demo data | Finish the intro, then **Settings → Load demo data** (25 hazards in 5 areas). |
| GPS | While the app runs: **Xcode → Debug → Simulate Location → MumbaiCommute**. The blue dot moves Kalyan → Thane → Ghatkopar. The Report flow needs a location to save. |
| Report flow | Report tab → **Try a sample photo** (simulator-only menu). In Details, **Scan signboard → Use sample signboard** tests OCR. |
| Map | Filter chips, search "Thane", tap a pin, Directions, Mark fixed. |
| Hazards | List ↔ Gallery morph, swipe to resolve or delete, long-press preview, detail pinch-zoom and double-tap, Resolve slider, Share. |
| Weather | Open a hazard: rainfall loads. Switch the Mac's Wi-Fi off to see the error and Retry. |
| Drive Mode | Yellow car button on the Map → **Replay sample drive**. About 90 s: the waveform moves and a coloured trail stays on the map. |
| Dark Mode | **⇧⌘A** in the simulator. |
| Large text | Xcode's **Environment Overrides** button (debug bar) while the app runs. |
| Reduce Motion | Simulator **Settings → Accessibility → Motion → Reduce Motion**. |
| Screenshots | **⌘S** in the simulator saves one to the Desktop (for the README). |

## 3. Run on your iPhone

A free Apple ID is enough; no paid developer account is needed.

1. **Add your Apple ID:** **Xcode → Settings → Accounts → + → Apple ID**.
2. **Signing:**
   - Click the blue **RoadPulse** project → **RoadPulse** target → **Signing & Capabilities**.
   - Tick **Automatically manage signing**; **Team** = *Your Name (Personal Team)*.
   - If the bundle ID is "not available", change it to something unique (e.g. `com.ashvatth.roadpulse`).
   - `xcodegen generate` resets the Team, so pick it again after regenerating.
3. **Prepare the iPhone (iOS 17+):**
   - Connect it with a cable, unlock it, tap **Trust This Computer**.
   - **Settings → Privacy & Security → Developer Mode → On**, then restart. The option appears only after Xcode has tried to run on the phone once.
4. **Run:** pick your iPhone in Xcode's device menu, then **⌘R**.
5. **First launch only:** the phone says **Untrusted Developer**. Go to **Settings → General → VPN & Device Management → your Apple ID → Trust**, then run again.
6. **Allow the prompts** for location, camera and motion.

> Apps signed with a free account stop opening after **7 days**. Install on 3 or 4 Nov so it works on demo day. Once installed, the app runs without the Mac.

## 4. Demo on the iPhone (about 5 minutes)

### Showing your screen
- **Mirror and record:** connect the iPhone to the Mac, open **QuickTime Player → File → New Movie Recording**, and pick the iPhone from the dropdown next to the record button. That mirrors the phone on the Mac or projector and records the demo video.
- **Alternative:** the iPhone's built-in **Screen Recording** in Control Center.

### Before you start
- Wi-Fi on (weather and search need internet).
- **Settings → Load demo data**.
- A pothole photo ready on a laptop screen or printed, in case there's no real pothole nearby.

### Script
1. **Intro (30 s).** **Settings → Show intro again**: animated road, location permission.
2. **Map (1 min).**
   - Pins: colour = severity, grey = fixed, severe ones pulse.
   - Tap the **4+** chip to filter; search "Thane" and the map flies there.
   - Tap a pin: photo, rainfall and monsoon risk, Directions.
3. **Report, the AI feature (1.5 min).**
   - Photograph the pothole picture; the confidence ring fills.
   - Say: *on-device Core ML, MobileNetV3, 96.7% test accuracy, no internet needed.*
   - Details: severity is prefilled from the confidence; the address is found automatically.
   - Save: the app jumps to the new pin on the map.
4. **Hazards (1 min).**
   - Toggle List / Gallery (photos morph).
   - Swipe a row to resolve; long-press another for the preview.
   - Open one: pinch-zoom, double-tap reset, slide **Resolve**, **Share**.
5. **Insights (30 s).** Bars grow, tap a donut slice, worst roads near me. Mention the charts are drawn with `Path`/`Shape`, no chart library.
6. **Drive Mode (1 min).**
   - Yellow car button → **press and hold** to start (the ring fills).
   - Tap the phone firmly on the desk a few times; the waveform spikes. Stop.
   - A real GPS trail needs actual movement, so indoors use **Replay sample drive** for a reliable coloured trail.
7. **Close (15 s).** Toggle Dark Mode in Control Center. Mention `docs/SYLLABUS_MAP.md` maps every syllabus topic to code.

### Backup plan
If the phone has no GPS indoors or no network, run the same script on the simulator: Simulate Location, sample photos and the replay drive cover everything.
