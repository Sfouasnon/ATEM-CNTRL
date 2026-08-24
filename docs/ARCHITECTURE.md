# Architecture

```text
  Switcher Console   Audio   HyperDeck   Media / Color Gens   Camera / Color
              │                 │             │                  │
              └──── immutable snapshots + A/B target selection ─┤
                                │                                │ bounded,
                    ┌───────────┴───────────┐                    │ coalesced IPC
             ATEMController A       ATEMController B             │
               serial queue A         serial queue B             ▼
                    │                       │              ATEMCameraHelper
                    └── BMDSwitcherAPI.bundle ──┘            killable process
                         │              │                    │
                      ATEM A         ATEM B          selected ATEM A or B
```

`ATEMController` is the only component allowed to hold or call Blackmagic COM-style interfaces. The app owns two instances. Each instance creates its own discovery object, switcher interface graph, polling timer, and serial dispatch queue. Connection, enumeration, commands, callback refreshes, and teardown never cross between sessions.

Each controller constructs `ATEMState` snapshots containing value objects for inputs, keyers, AUX outputs, and multiviews, plus separate `ATEMAudioState` and `ATEMHyperDeckState` snapshots. They cross to the main queue and stay cached while the Switcher Console, Audio, and HyperDeck windows render their selected target. Feature snapshots use notifications rather than replacing the console’s single `stateHandler`. UI code never dereferences an SDK object, and switching the visible target does not alter either connection.

Fairlight callbacks copy their level and peak arrays immediately, enqueue them onto that controller’s queue, and publish at a bounded 10 Hz UI cadence. The SDK provides dBFS levels—not PCM—so the rolling waveform view is a history plot of those official values. Every source is identified by the pair `(audioInputId, sourceId)` because source IDs are scoped to an input.

HyperDeck control stays inside the ATEM session. `SetNetworkAddress` programs the selected ATEM’s HyperDeck slot; the ATEM hardware, not the Mac, then owns the TCP 9993 connection to the deck. IPv4 addresses use the SDK’s documented least-significant-byte-first packing and have a self-test round trip. Clip menus are populated by `IBMDSwitcherHyperDeckClipIterator`; clip IDs are treated as opaque values and are never synthesized from the reported clip count.

Camera control is the deliberate exception to in-process ownership. The main app does not query `IBMDSwitcherCameraControl`. On explicit user request it launches `ATEMCameraHelper`, which creates an independent connection to exactly one selected ATEM and owns every camera-control pointer and call. IPC writes occur on a separate serial queue, keep exactly one command outstanding until its reply, and coalesce pending commands by operation/camera/parameter, so a hung helper cannot back-pressure AppKit. An eight-second startup watchdog, a three-second command watchdog, and TERM-to-KILL escalation make the subsystem restartable. Camera adjustments remain disabled until every color parameter for the newly selected camera has been read back. Changing sessions, disconnecting, changing the target address, or closing the Color window stops the helper.

Colour generators are read and written through `IBMDSwitcherInputColor`, queried off the `IBMDSwitcherInput` objects whose port type is `bmdSwitcherPortTypeColorGenerator` during the same enumeration pass that builds the input, label, and AUX tables. They publish as immutable `ATEMColorGeneratorState` snapshots carrying the SDK input ID, so the Media window can route a generator to Program or Preview without ever holding an SDK pointer.

Writes to a generator reuse the pending-value reconciliation the multiview writes introduced — the `PendingValue<T>` helpers are shared rather than duplicated. `SetHue`, `SetSaturation`, and `SetLuma` each return before the switcher acknowledges, so an unguarded 250 ms poll would drag a slider back mid-drag. Only `S_OK` marks a value pending; the SDK's `S_FALSE` no-op means the switcher already held that value. Hue is reconciled with a wider tolerance than saturation and luma because it is reported in degrees rather than 0...1.

Exposure arithmetic lives in `Sources/ATEMColorMath.h`, a header-only file free of AppKit and SDK types so the `--self-test` in `ATEMController.mm` can verify it alongside the UI that uses it. Colour-generator luma is a signal level, so a photographic stop is not a doubling of the number: because the display transfer function is a pure power law, scaling emitted light by `2^stops` is scaling luma by `2^(stops / 2.4)`. The self-test pins this against the 75% colour bars, whose six primaries must all resolve to saturation 100% at luma 37.5%, and against an up-then-down stop round trip.

Multiview state is cached independently for every output. A failed SDK getter preserves only that output's last-known value, and successful writes receive a short readback grace period so asynchronous hardware acknowledgement cannot momentarily snap the UI back. Bulk label and border changes execute against one `IBMDSwitcherMultiView` object in a single queue operation and publish one completed snapshot.

The app queries the connected device before exposing controls. This lets the same UI adapt to ATEM Mini, Television Studio, and Constellation families without hard-coding one input count or keyer layout.

Input availability is preserved per source instead of assuming every source belongs on every bus. M/E, AUX, and multiview selectors intersect the source mask with the destination capability mask. Multiview controls are likewise enabled only when `IBMDSwitcherMultiView` reports the corresponding layout, routing, VU-meter, safe-area, Program/Preview-swap, or overlay capability.

Input and output labels share the SDK's `IBMDSwitcherInput` namespace: AUX, multiview, M/E, key, and monitor outputs are output-typed input endpoints. The controller retains those interfaces only inside its serialized session queue, publishes immutable label targets to AppKit, and refreshes dependent routing, AUX, audio, and HyperDeck names after an edit.

For quadrant-capable models, `BMDSwitcherMultiViewLayout` is treated as the four-bit mask defined by the SDK: top-left, top-right, bottom-left, and bottom-right are toggled independently between one large window and four small windows. The SDK window IDs remain positions in a fixed 4x4 grid even when a quadrant is large. A four-large-window layout therefore routes physical IDs `0`, `2`, `8`, and `10`, not the compact range `0...3`; split quadrants reveal the remaining IDs in their 2x2 block. The 16-slot physical capacity is enforced whenever the SDK reports quadrant support, so a transient or inconsistent count cannot reactivate compact routing. The UI presents these sparse physical IDs as sequential visible Window 1, Window 2, and so on. Visible routing controls consequently expand through 4, 7, 10, 13, and 16 windows. The self-test walks all 16 layout masks and verifies both the visible physical IDs and source persistence while windows are hidden and revealed.

Non-quadrant models retain the classic Program Top/Bottom/Left/Right selector and their reported sequential window count. Their physical windows 0 and 1 are reserved for Program/Preview by the SDK, so ATEM CNTRL exposes them for status and overlays but disables source routing for those two windows. Mutating multiview calls accept only `S_OK` as an acknowledged write; the SDK's `S_FALSE` no-op response is never cached as a successful setting.

The app and camera helper each compile Blackmagic's installed `BMDSwitcherAPIDispatch.cpp`, which dynamically loads the official API bundle in that process. No private macOS APIs or direct reverse-engineered ATEM network packets are used.
