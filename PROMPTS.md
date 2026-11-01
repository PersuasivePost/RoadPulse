# RoadPulse: Claude Code run order

The spec lives in `docs/`, so prompts stay short. Start every session in the repo root with `claude`.
Slash commands (in `.claude/commands/`): **/next** (do the next task), **/ship** (commit → CI → fix until green), **/audit** (syllabus + design check).

## One-time setup (29 Oct)
```bash
# unzip roadpulse-starter.zip, then:
cd roadpulse && git init
git config user.name "persuasivepost" && git config user.email "joshi.ashvatth@gmail.com"
gh auth login
gh repo create roadpulse --public --source=. --push
pip install torch torchvision coremltools kaggle --break-system-packages
# Kaggle token → ~/.kaggle/kaggle.json (Kaggle → Settings → Create New Token)
```

---

### 1 · F0 Setup & CI (29 Oct)
```
Read CLAUDE.md and everything in docs/. Then do F0 from docs/PRD.md: XcodeGen project.yml, the GitHub Actions workflow, the folder structure from ARCHITECTURE.md, a placeholder app and one passing test. Also add a Color extension + Assets colour sets for every token in DESIGN.md, and a Motion enum with the motion tokens, so later tasks reuse them. Then /ship.
```
**Expect / test:** a green check in the Actions tab. Every later step depends on this loop working.

### 2 · F1 ML model (29 Oct)
```
/next  Note: this is the Python ML task. Run training here on my Linux GPU (RTX 3050 Ti, 4GB, so pick a batch size that fits), write ml/requirements.txt, and also copy ~6 test images (pothole + normal) into Resources/SampleImages/ for later XCTests.
```
**Expect / test:** around 90% test accuracy, and a confusion matrix in `ml/REPORT.md` that you can reuse in your report. A green CI run means Xcode accepted the model.

### 3 · F2 Core Data (30 Oct)
```
/next
```
**Expect / test:** no UI yet. CI test results for CRUD, predicates and cascade delete are your proof.

### 4 · F3 Shell, state, onboarding, settings (30 Oct)
```
/next  Make the onboarding road illustration genuinely good. It's the first impression in the demo.
```
**Expect / test:** onboarding appears only on first launch, and you get 5 tabs. Change a setting, relaunch the app, and check it persisted.

### 5 · F4 Map (31 Oct)
```
/next
```
**Expect / test:** load demo data and you should see pulsing, colour-coded pins around Mumbai. Search "Ghatkopar" and the camera flies there. Use Debug → Simulate Location → MumbaiCommute to move the user dot.

### 🖥 Mac visit 1 (31 Oct)
```bash
git clone https://github.com/persuasivepost/roadpulse.git && cd roadpulse
brew install xcodegen && xcodegen generate && open RoadPulse.xcodeproj
```
First check that the Xcode version is 15 or newer. Run the app, note anything broken or ugly in `docs/PROGRESS.md → Blockers`, and push. Back home:
```
Read the Blockers section in docs/PROGRESS.md: these are issues I saw running on the simulator. Fix all of them, then /ship.
```

### 6 · F5 AI report flow (1 Nov)
```
/next  This is the core feature, so polish the analyze step animations (scanning line, confidence ring count-up) to the DESIGN.md standard.
```
**Expect / test:** drag a pothole photo into the simulator's Photos app, then report it. You should see the scan animation, then a ring filling to "Pothole 9x%", with the address filled in automatically. Saving should drop a new pin on the map.

### 7 · F6 Hazards list & gallery (2 Nov)
```
/next
```
**Expect / test:** try swipe, long-press, pinch-zoom and the drag-to-resolve slider. List ↔ grid should morph smoothly, and search should filter instantly.

### 8 · F7 Weather API (2 Nov)
```
/next
```
**Expect / test:** a hazard's detail view shows its rainfall and a Monsoon Risk badge. With Wi-Fi off you should get a clean error with a retry button.

### 🖥 Mac visit 2 (2 Nov)
Same routine: `git pull && xcodegen generate`, test F5–F7, write issues into Blockers, then use the fix prompt from visit 1.

### 9 · F8 Insights & Drive Mode (3 Nov)
```
/next  Generate a realistic sample_drive.csv (accelerometer z with occasional pothole spikes) aligned to the GPX route timing.
```
**Expect / test:** the Insights charts animate in each time you open the tab. "Replay sample drive" draws a live waveform and leaves a green/yellow/red trail on the map.

### 10 · F9 Polish & docs (3 Nov)
```
/next
```
then
```
/audit
```
**Expect / test:** `docs/SYLLABUS_MAP.md` is fully ticked, each row pointing at real code. That's your viva cheat sheet. The README should also look portfolio-ready.

### 🖥 Mac visit 3 (3 Nov)
Run the full flow: onboarding → report → map → list → insights → drive replay. Take screenshots (⌘S in the simulator) into `docs/screenshots/`, and record the demo with File → Record Screen.

### 4 Nov: buffer
```
Add the screenshots in docs/screenshots/ to the README, do a final review for crashes/force-unwraps, and /ship.
```

---

## Handy one-liners
- CI stuck on the same error: `Stop. Show me the exact failing log lines and explain the root cause before changing anything.`
- Something looks off on the Mac: `On the simulator, <screen> looks like <problem>. Fix it per DESIGN.md, then /ship.`
- Running low on time: `Check what's left in PROGRESS.md. Cut F8 Drive Mode down to replay-only and prioritise F9 polish.`
