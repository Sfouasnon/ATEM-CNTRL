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
- Switcher video standard selection with separate Format and Frame Rate menus, offering every standard the installed SDK defines — 23.98, 24, 25, 29.97, 30, 50, 59.94, 60 and beyond, at each resolution the switcher reports — filtered by the switcher's own `DoesSupportVideoMode` answers and confirmed before it is applied
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
- Dedicated Media window for the colour generators: macOS colour picker, hex entry, hue/saturation/luma sliders, an exposure control calibrated in stops of emitted light, grayscale and 75% colour-bar presets, and one-click routing of the generator to Preview or Program
- Explicit, restartable camera-control engine that runs outside the main app and is terminated if startup stalls, the ATEM disconnects, or its target address changes
- Independent A/B target selectors in every feature window
- Window-menu shortcuts: Switcher Console `⌘1`, Audio `⌘2`, Camera/Color `⌘3`, HyperDeck `⌘4`, Input & Output Labels `⌘5`, and Media / Color Generators `⌘6`
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

## Exposing a colour generator in stops

The Media window exists for one job: put a known flat colour on a wall or a monitor, then move its brightness up or down by a photographic amount without changing the colour.

The ATEM describes a colour generator as hue, saturation, and luma. Luma is a **signal level**, not an amount of light — so halving the number does not halve the light the wall emits. A Rec.709 display or an LED processor applies a gamma of roughly 2.4 to the signal before anything is emitted. One stop down therefore scales luma by `2^(-1/2.4)`, about 0.75, not by 0.5.

The `−1`, `−⅔`, `−⅓`, `+⅓`, `+⅔`, `+1` buttons do exactly that arithmetic. The readout next to the luma slider shows how far you have ridden the colour away from the last one you actually chose, in stops, so "we set the gray card, then came down a third" stays legible. Picking a new colour — the picker, a hex value, or any preset — re-arms that reference.

The grayscale presets are named for what they are metering:

| Button | Luma sent | Meaning |
| --- | --- | --- |
| `BLACK` | 0.0% | Full black |
| `18% GRAY` | 40.9% | An 18% reflectance gray card through the Rec.709 curve |
| `50%` | 50.0% | Half signal, the usual LED-wall alignment gray |
| `90% WHITE` | 94.9% | A 90% reflectance white card through the Rec.709 curve |
| `100%` | 100.0% | Peak white |

The `75% colour bars` row sets the six standard bars, each of which is saturation 100% at luma 37.5% with only the hue changing. Under the swatch, the window also prints the 10-bit legal-range code value, which is what an LED-wall processor is measuring.

Colour-generator writes use the same echo suppression as the transition rate field and the multiview writes: a `SetLuma` call returns before the switcher acknowledges it, so for a second after a local write the UI keeps showing what you asked for rather than letting the 250 ms poll drag the slider back under your hand. Slider drags are coalesced to one switcher write per 40 ms.

Colour generators are stored on the switcher. Whatever you leave them set to survives quitting the app.

## Remaining scope

These ATEM Software Control areas are not implemented yet:

- Media-pool transfer and media-player stills/clips (the Media window currently covers the colour generators only)
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

### Generated video-standard table

`build` first generates `Sources/ATEMVideoModeTable.inc` by running `Tools/generate_video_modes.py` over the installed `BMDSwitcherAPI.h`. The script reads the `BMDSwitcherVideoMode` enum, decodes each name into a resolution and a frame rate (`bmdSwitcherVideoMode1080p2997` becomes `1080p` at `29.97`), sorts them, and emits the table the Video Standard menus are built from.

This is generated rather than hand-written because the enum grows with each SDK release. A fixed list is wrong twice over: it hides frame rates the switcher can actually run, and it stops compiling the moment it names a symbol the installed header does not define. Generating it means the app always offers exactly the standards the installed SDK knows about, and installing a newer ATEM Software Control picks up its additions on the next build.

The file is regenerated on every build, so it cannot go stale; it is not committed, and `make video-modes` regenerates it on its own. Do not edit it directly. Any standard the switcher reports that the table cannot name — possible when the 10.3 runtime is paired with 10.0 headers — is still selectable, listed as `Mode <n>`.

Useful commands:

```sh
make demo       # launch without hardware
make preview    # render the UI to build/preview.png
make preview-multiview # render the multiview editor to build/multiview-preview.png
make preview-audio # render the dedicated audio window
make preview-color # render the dedicated color window
make preview-labels # render the Input & Output Labels window
make preview-media # render the Media / colour generator window
make preview-hyperdeck # render the dedicated HyperDeck window
make video-modes # regenerate the video-standard table from the installed SDK header
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
9. Open Media, note the existing Color 1 and Color 2 values before changing anything, set Color 2 to `50%` gray, route it to **Preview** — never Program on a live switcher — confirm the multiview follows, ride it one stop down and back, then restore the original values.
10. On a non-critical multiview window, test source routing and one overlay toggle, then confirm the ATEM output follows it.
11. Select a known-safe Preview input and test CUT/AUTO only after confirming the output is safe to change.
12. Select session B, connect the second ATEM, and confirm session A remains connected before issuing a safe command on each unit and in each feature window.
13. Leave both connected for at least ten minutes and exercise reconnect once on each session.
14. If the main app hangs, capture a fresh sample with `sample ATEMCNTRL 10 -file ATEMCNTRL.sample.txt` before force-quitting. If only Color stalls, stop the isolated engine and retain its status message.

No ATEM advertised `_blackmagic._tcp` on the development machine's current network, so live hardware behavior could not be verified here.

## Design and legal notes

ATEM CNTRL depends on Blackmagic's official switcher API bundle and the permissively licensed SDK dispatch source installed with ATEM Software Control. It does not copy the proprietary ATEM Software Control UI assets or patch Blackmagic's binary.

ATEM is a trademark of Blackmagic Design. This project is independent and is not endorsed by Blackmagic Design.

See [docs/CRASH_ANALYSIS.md](docs/CRASH_ANALYSIS.md) for the evidence behind the compatibility design.
