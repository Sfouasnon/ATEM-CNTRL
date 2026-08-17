# ATEM CNTRL

ATEM CNTRL is a native macOS control surface for Blackmagic Design ATEM switchers. It was created in response to an ATEM Software Control 10.3 hang on macOS Tahoe 26.5.2.

Version 0.4 expands the compact live switcher console with dedicated Fairlight Audio, Camera/Color, and HyperDeck windows. It avoids the exact camera-control path implicated by the supplied hang report by moving that subsystem into a separately killable helper process. It is not yet a complete replacement for every ATEM Software Control page.

## What works

- Manual connection by switcher IP address or host name
- Two persistent ATEM sessions (A and B) connected and controlled simultaneously
- Unmistakable active-session identity with independent saved addresses and live connection indicators
- A compact Signal Slate interface with broadcast tally colors, layered controls, and distinct active-state edges
- An original AC launcher icon and matching ATEM CNTRL header wordmark
- Capability-driven input lists and names
- Dedicated Input & Output Labels window for editing switcher-stored long and short names, including AUX and multiview outputs
- Program and Preview source selection for the first M/E
- CUT, AUTO, Fade to Black, and a continuous T-bar
- MIX, DIP, WIPE, DVE, and STINGER next-transition selection
- Transition rate and Background/Key transition selection, with the rate field and stepper protected from being overwritten by the state poll while you edit them
- Switcher video standard selection with separate Format and Frame Rate menus, built from the switcher's own `DoesSupportVideoMode` answers and confirmed before it is applied
- Up to four upstream key On Air controls, when available
- Downstream key Tie, On Air, and Auto controls
- AUX output routing
- Multiview output enumeration and capability-driven configuration
- Four independently clickable multiview quadrants; each changes between one large and four small windows
- Dynamic 4, 7, 10, 13, or 16-window source routing, plus classic 10-window layouts on older models
- Correct fixed-grid SDK routing for large quadrants, including the four-camera 2x2 layout
- Exhaustive regression coverage for all 16 quadrant combinations and hidden-window source persistence
- Correct handling of fixed Program/Preview windows on classic non-quadrant multiviews
- Program/Preview swap and VU opacity
- Per-window VU meter, safe-area, label, and border visibility controls when supported
- Per-multiview Labels and Borders bulk toggles with On, Off, and Mixed status
- Independent per-output readback caching so one multiview cannot reset another during a transient SDK read
- Dedicated Fairlight Audio window with a horizontal mixer, stereo meters, peak markers, rolling level history, source faders, pan, Off/On/AFV, master fader, and peak reset
- Dedicated HyperDeck window with ATEM-managed IPv4 configuration, associated switcher input, connection/remote/model status, real SDK clip IDs/names/durations, timecode state, Play/Stop/Record/Jog/Shuttle, Loop, Single Clip, and Auto-roll
- Dedicated Camera/Color window with Lift, Gamma, Gain, Offset, Contrast, Luma Mix, Hue, Saturation, per-stage reset, and full color reset
- Explicit, restartable camera-control engine that runs outside the main app and is terminated if startup stalls, the ATEM disconnects, or its target address changes
- Independent A/B target selectors in every feature window
- Window-menu shortcuts: Switcher Console `⌘1`, Audio `⌘2`, Camera/Color `⌘3`, HyperDeck `⌘4`, and Input & Output Labels `⌘5`
- Live state polling plus Blackmagic SDK event callbacks
- A no-hardware Demo mode
- Offline rendering, diagnostics, runtime checks, and ad-hoc code signing

Every core, Fairlight, and HyperDeck SDK call is serialized on a dedicated background queue for that session. The AppKit main thread only renders immutable state snapshots, so slow switcher I/O cannot freeze the UI and the two ATEM interface graphs are never shared across queues. Camera control is stricter: its entire discovery, connection, interface graph, getters, and setters live in `ATEMCameraHelper`, with bounded asynchronous IPC from the app.

## Two-switcher workflow

Select **A**, enter its address, and connect. Then select **B**, enter the second address, and connect. Switching the visible session does not disconnect the other ATEM; its connection and state updates remain active in the background. The A/B selector shows disconnected, connecting, or connected state for both units, while the fixed header always names the ATEM currently receiving commands.

Use Ethernet and give each ATEM a unique IP address or hostname. The SDK's USB fallback is selected with an empty device address, which does not provide a dependable way for this two-target UI to identify two USB-connected units.

The Blackmagic API is object/session based and exposes separate discovery and switcher objects. No documented hardware or protocol rule found requires an application to disconnect one physical ATEM before connecting another. ATEM CNTRL therefore uses two completely independent controller objects and queues. The remaining caveat is live validation: undocumented runtime-wide behavior can only be ruled out by connecting two real units on Tahoe.

The most important operational risk is selecting the wrong switcher during a show. Keep the two IP addresses stable, verify the A/B target and product name in the header before taking Program or triggering a transition, and label the physical systems A and B to match the app.

## Camera-control safety boundary

The supplied report shows ATEM Software Control hanging during camera-default transmission. ATEM CNTRL therefore never requests or initializes `IBMDSwitcherCameraControl` in its main process. Camera/Color only starts after you explicitly click **Start Isolated Engine**. If the SDK call stalls, **Stop / Kill Engine** terminates the helper without taking down the live switcher, audio, or HyperDeck windows.

Camera controls are capability-checked in the helper before a read or write. The current Blackmagic SDK exposes color values, not camera pictures or scopes; ATEM CNTRL does not synthesize a video preview.

The Fairlight API likewise exposes level and peak values in dBFS rather than PCM samples. The Audio window’s live “waveforms” are rolling histories of those official level callbacks.

## Remaining scope

These ATEM Software Control areas are not implemented yet:

- Media-pool transfer and media-player pages
- Streaming and ISO recording pages
- Macros, SuperSource, and the remaining general switcher setup controls (multiview standard, down-conversion, 3G-SDI output level, label sets)
- Full Fairlight EQ/dynamics/effects editors and legacy non-Fairlight mixer fallback
- HyperDeck storage-media management, callbacks, and detailed transient-error reporting
- Camera lens, exposure, detail, and tally controls outside the color-correction category
- Additional M/E banks beyond M/E 1
- Bonjour device picker; connection is currently by IP or host name

Those areas can be added as capability-driven windows on top of the existing asynchronous controller and isolated-helper pattern.

## Requirements

- macOS 13 or newer; the UI uses public AppKit APIs intended to remain compatible with Tahoe
- Apple Command Line Tools (`xcrun clang++`)
- Blackmagic ATEM Software Control with the Developer SDK installed
- The official runtime at:
  `/Library/Application Support/Blackmagic Design/Switchers/BMDSwitcherAPI.bundle`
- The SDK at:
  `/Applications/Blackmagic ATEM Switchers/Developer SDK/Mac OS X`

The current workstation has Blackmagic Switchers SDK 10.0 installed. The app dynamically loads the installed official runtime and uses the current switcher, Fairlight, HyperDeck, and camera-control interfaces. It is intended to work with the 10.3 runtime on the Tahoe machines, but that still requires an on-hardware Tahoe test.

## Build and run

```sh
make build
open "build/ATEM CNTRL.app"
```

The built app is `build/ATEM CNTRL.app`. It is ad-hoc signed for local testing. Distribution to other Macs should use a Developer ID certificate and notarization.
The Makefile produces a universal Apple Silicon/Intel binary.

Useful commands:

```sh
make demo       # launch without hardware
make preview    # render the UI to build/preview.png
make preview-multiview # render the multiview editor to build/multiview-preview.png
make preview-audio # render the dedicated audio window
make preview-color # render the dedicated color window
make preview-labels # render the Input & Output Labels window
make preview-hyperdeck # render the dedicated HyperDeck window
make test       # validate runtime loading and enum mappings
make diagnose   # print OS, architecture, and runtime details
make verify     # build, self-test, verify signature, and lint the plist
make package    # create build/ATEM-CNTRL-0.4.1-macOS.zip
```

## Safe hardware test

Use a switcher that is not carrying an irreplaceable live output for the first test.

1. Run `make verify`.
2. Open `build/ATEM CNTRL.app` on the Tahoe Mac.
3. Enter the ATEM IP address and click **Connect**.
4. Confirm the product name, input names, current Program/Preview selections, key states, and multiview state appear without touching a control.
5. Open Input & Output Labels, rename one non-critical input and AUX output, confirm the new labels appear in the console, then restore both names.
6. Open Audio, confirm channel names and idle levels, then move one non-critical source fader and return it to its original value.
7. Open HyperDeck, verify each slot’s existing address before changing anything, then test transport only on non-critical media. The ATEM owns the TCP 9993 connection; the Mac does not connect directly to the deck.
8. Open Camera/Color and start the isolated engine. Read values first; test one small change on a non-critical camera, reset it, then stop and restart the helper once.
9. On a non-critical multiview window, test source routing and one overlay toggle, then confirm the ATEM output follows it.
10. Select a known-safe Preview input and test CUT/AUTO only after confirming the output is safe to change.
11. Select session B, connect the second ATEM, and confirm session A remains connected before issuing a safe command on each unit and in each feature window.
12. Leave both connected for at least ten minutes and exercise reconnect once on each session.
13. If the main app hangs, capture a fresh sample with `sample ATEMCNTRL 10 -file ATEMCNTRL.sample.txt` before force-quitting. If only Color stalls, stop the isolated engine and retain its status message.

No ATEM advertised `_blackmagic._tcp` on the development machine's current network, so live hardware behavior could not be verified here.

## Design and legal notes

ATEM CNTRL depends on Blackmagic's official switcher API bundle and the permissively licensed SDK dispatch source installed with ATEM Software Control. It does not copy the proprietary ATEM Software Control UI assets or patch Blackmagic's binary.

ATEM is a trademark of Blackmagic Design. This project is independent and is not endorsed by Blackmagic Design.

See [docs/CRASH_ANALYSIS.md](docs/CRASH_ANALYSIS.md) for the evidence behind the compatibility design.
