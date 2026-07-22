# ATEM CNTRL

ATEM CNTRL is a native macOS control surface for Blackmagic Design ATEM switchers. It was created in response to an ATEM Software Control 10.3 hang on macOS Tahoe 26.5.2.

This first build restores the live switcher controls most likely to be needed during a show while avoiding the exact camera-control path implicated by the supplied hang report. It is not yet a complete replacement for every ATEM Software Control page.

## What works

- Manual connection by switcher IP address or host name
- Two persistent ATEM sessions (A and B) connected and controlled simultaneously
- Unmistakable active-session identity with independent saved addresses and live connection indicators
- A compact Signal Slate interface with broadcast tally colors, layered controls, and distinct active-state edges
- An original AC launcher icon and matching ATEM CNTRL header wordmark
- Capability-driven input lists and names
- Program and Preview source selection for the first M/E
- CUT, AUTO, Fade to Black, and a continuous T-bar
- MIX, DIP, WIPE, DVE, and STINGER next-transition selection
- Transition rate and Background/Key transition selection
- Up to four upstream key On Air controls, when available
- Downstream key Tie, On Air, and Auto controls
- AUX output routing
- Multiview output enumeration and capability-driven configuration
- Four independently clickable multiview quadrants; each changes between one large and four small windows
- Dynamic 4, 7, 10, 13, or 16-window source routing, plus classic 10-window layouts on older models
- Program/Preview swap and VU opacity
- Per-window VU meter, safe-area, label, and border visibility controls when supported
- Live state polling plus Blackmagic SDK event callbacks
- A no-hardware Demo mode
- Offline rendering, diagnostics, runtime checks, and ad-hoc code signing

Every Blackmagic SDK call is serialized on a dedicated background queue for that session. The AppKit main thread only renders immutable state snapshots, so slow switcher I/O cannot freeze the UI and the two ATEM interface graphs are never shared across queues.

## Two-switcher workflow

Select **A**, enter its address, and connect. Then select **B**, enter the second address, and connect. Switching the visible session does not disconnect the other ATEM; its connection and state updates remain active in the background. The A/B selector shows disconnected, connecting, or connected state for both units, while the fixed header always names the ATEM currently receiving commands.

Use Ethernet and give each ATEM a unique IP address or hostname. The SDK's USB fallback is selected with an empty device address, which does not provide a dependable way for this two-target UI to identify two USB-connected units.

The Blackmagic API is object/session based and exposes separate discovery and switcher objects. No documented hardware or protocol rule found requires an application to disconnect one physical ATEM before connecting another. ATEM CNTRL therefore uses two completely independent controller objects and queues. The remaining caveat is live validation: undocumented runtime-wide behavior can only be ruled out by connecting two real units on Tahoe.

The most important operational risk is selecting the wrong switcher during a show. Keep the two IP addresses stable, verify the A/B target and product name in the header before taking Program or triggering a transition, and label the physical systems A and B to match the app.

## Important scope boundary

The supplied report shows ATEM Software Control hanging during camera-default transmission. ATEM CNTRL therefore does **not** request or initialize `IBMDSwitcherCameraControl` in this build.

These ATEM Software Control areas are not implemented yet:

- Camera control
- Fairlight/audio mixing
- Media-pool transfer and media-player pages
- Streaming and ISO recording pages
- Macros, HyperDeck, SuperSource, and general switcher setup
- Additional M/E banks beyond M/E 1
- Bonjour device picker; connection is currently by IP or host name

Camera control should stay out until Blackmagic fixes the blocking SDK path or it can be isolated in a separately killable helper process. The remaining areas can be added safely on top of the existing asynchronous controller.

## Requirements

- macOS 13 or newer; the UI uses public AppKit APIs intended to remain compatible with Tahoe
- Apple Command Line Tools (`xcrun clang++`)
- Blackmagic ATEM Software Control with the Developer SDK installed
- The official runtime at:
  `/Library/Application Support/Blackmagic Design/Switchers/BMDSwitcherAPI.bundle`
- The SDK at:
  `/Applications/Blackmagic ATEM Switchers/Developer SDK/Mac OS X`

The current workstation has Blackmagic Switchers SDK 10.0 installed. The app dynamically loads the installed official runtime and only uses stable core interfaces, so the same source is intended to work with the 10.3 runtime on the Tahoe machines. That still requires an on-hardware Tahoe test.

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
make test       # validate runtime loading and enum mappings
make diagnose   # print OS, architecture, and runtime details
make verify     # build, self-test, verify signature, and lint the plist
make package    # create build/ATEM-CNTRL-0.3.1-macOS.zip
```

## Safe hardware test

Use a switcher that is not carrying an irreplaceable live output for the first test.

1. Run `make verify`.
2. Open `build/ATEM CNTRL.app` on the Tahoe Mac.
3. Enter the ATEM IP address and click **Connect**.
4. Confirm the product name, input names, current Program/Preview selections, key states, and multiview state appear without touching a control.
5. On a non-critical multiview window, test source routing and one overlay toggle, then confirm the ATEM output follows it.
6. Select a known-safe Preview input.
7. Test CUT and AUTO only after confirming the output is safe to change.
8. Select session B, connect the second ATEM, and confirm session A remains connected before issuing a safe command on each unit.
9. Leave both connected for at least ten minutes and exercise reconnect once on each session.
10. If it hangs, capture a fresh sample with `sample ATEMCNTRL 10 -file ATEMCNTRL.sample.txt` before force-quitting.

No ATEM advertised `_blackmagic._tcp` on the development machine's current network, so live hardware behavior could not be verified here.

## Design and legal notes

ATEM CNTRL depends on Blackmagic's official switcher API bundle and the permissively licensed SDK dispatch source installed with ATEM Software Control. It does not copy the proprietary ATEM Software Control UI assets or patch Blackmagic's binary.

ATEM is a trademark of Blackmagic Design. This project is independent and is not endorsed by Blackmagic Design.

See [docs/CRASH_ANALYSIS.md](docs/CRASH_ANALYSIS.md) for the evidence behind the compatibility design.
