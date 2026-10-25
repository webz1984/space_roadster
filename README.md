# Space Roadster X

A one-thumb iPhone game. You drive the RoadsterX, a thruster-equipped electric roadster, down a sunset highway. Hold to fire the air thrusters and hop over traffic, land on roofs, and swipe up to flip. A run lasts about 90 seconds.

Built with SwiftUI and SpriteKit for iOS 17 and later. Every car is an original look-alike with no real brand names or logos.

## Run it on your iPhone

You need a Mac with Xcode 16 or later and [Homebrew](https://brew.sh).

1. Install XcodeGen, which creates the Xcode project from `project.yml`:
   ```sh
   brew install xcodegen
   ```
2. Clone the repo and generate the project:
   ```sh
   git clone https://github.com/webz1984/space_roadster.git
   cd space_roadster
   xcodegen generate
   open SpaceRoadsterX.xcodeproj
   ```
3. In Xcode, select the **SpaceRoadsterX** target, open **Signing & Capabilities**, and pick your team under **Team** (sign in with your Apple ID under Xcode > Settings > Accounts first if it isn't listed).
4. Plug in your iPhone, choose it as the run destination at the top of the window, and press **Run** (⌘R). The first time, your phone will ask you to turn on Developer Mode (Settings > Privacy & Security > Developer Mode).

Run `xcodegen generate` again whenever files are added or `project.yml` changes.

### TestFlight

1. In [App Store Connect](https://appstoreconnect.apple.com), create a new app with the bundle ID `com.webz1984.spaceroadsterx` (change it in `project.yml` if that ID is taken).
2. In Xcode choose **Any iOS Device** as the destination, then **Product > Archive**.
3. In the Organizer window, choose **Distribute App > TestFlight & App Store** and follow the steps.
4. Once processing finishes, add yourself as a tester in App Store Connect and install the build from the TestFlight app.

## How to play

| Input | What it does |
| --- | --- |
| Hold anywhere | Fire the thrusters and lift off, which drains air |
| Release | Drop |
| Swipe up in the air | Backflip, worth +250, and more if you chain them |

The road refills air, a roof refills it twice as fast, and blue canisters top it up. Watch out for the Window Test: when a Wedge Truck rolls in, someone throws a steel ball at it. Dodge the ball, or flip through it for +300.

## Project layout

| Path | What's there |
| --- | --- |
| `SpaceRoadsterX/App` | SwiftUI entry point, plus the sound and haptics toggles |
| `SpaceRoadsterX/Game` | The run: physics, spawning, scoring, HUD, and the tuning numbers in `Tuning.swift` |
| `SpaceRoadsterX/Art` | Cars, props, and the sunset backdrop, all drawn in code at full Retina resolution |
| `SpaceRoadsterX/FX` | Air-thrust particles, dust, landing rings, and the crash effect |
| `SpaceRoadsterX/Feedback` | Synthesized sound effects and Core Haptics patterns |

The design doc lives in the project's Claude Docs as "Space Roadster X: Game Design".
