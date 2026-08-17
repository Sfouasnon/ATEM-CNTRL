# Task: get ATEM CNTRL compiling again after a feature patch

You are working on `~/Desktop/ATEM CNTRL`, a native macOS (Objective-C++ / AppKit) control
surface for Blackmagic ATEM switchers. It builds against the Blackmagic Switchers SDK
installed at `/Applications/Blackmagic ATEM Switchers/Developer SDK/Mac OS X`.

A patch was just applied by another agent that could **not compile it** — that environment had
no access to the Blackmagic SDK headers. Your job is to make it build, verify it, and fix only
what is actually broken.

## Build it

```sh
cd ~/Desktop/ATEM\ CNTRL
make verify
```

`make verify` = build (universal arm64 + x86_64) → `--self-test` → `codesign --verify` → plist lint.
Compiler flags are `-std=c++17 -fobjc-arc -Wall -Wextra`. Warnings are not errors, but report any
new ones you introduce.

## What changed, and why

Two things were added. Read the diff first: `git diff HEAD`.

**1. Switcher video standard (format + frame rate) — new feature.**
The app had no `GetVideoMode` / `SetVideoMode` support at all. Added:

- `ATEMVideoModeOption` class in `Sources/ATEMController.h` (raw mode + format name + frame rate name)
- `videoMode`, `canChangeVideoMode`, `supportedVideoModes` on `ATEMState`
- `-[ATEMController setVideoMode:]`
- `-[ATEMController refreshSupportedVideoModesLocked]`, called once per connection from
  `configureConnectedSwitcherLocked`
- A "Video Standard" card in `Sources/ControlSurfaceWindowController.mm` (Format popup,
  Frame Rate popup, SET STANDARD button behind a critical `NSAlert`)

**2. Fixed the Next Transition RATE field being unusable.**
`applyState:` was writing `state.transitionRate` into `rateField`/`rateStepper` on every state
publish, and the controller publishes every 250 ms from `_pollTimer`. The field was overwritten
four times a second, so typing never survived and the stepper snapped back. Now guarded by
`-isEditingRateField` and `rateEchoSuppressUntil`.

## The failure you should expect

`Sources/ATEMController.mm` contains `kATEMVideoModeTable`, which names `bmdSwitcherVideoMode*`
enum constants **directly**. If any of those symbols is absent from the installed
`BMDSwitcherAPI.h`, you get:

```
error: use of undeclared identifier 'bmdSwitcherVideoMode8KHDp2398'
```

**The fix is to delete that single table line.** Nothing else. The table is deliberately one
entry per line so this stays a one-line deletion, and a numeric fallback probe
(`kATEMVideoModeProbeLimit`, values 0–127 via `DoesSupportVideoMode`) still surfaces any
unlabelled mode as `Mode N`, so no mode becomes unreachable.

The 8K / `4KHD` entries are the most likely to be missing. Before deleting, confirm against the
real header so you delete the right lines and can report the actual supported set:

```sh
grep -n 'bmdSwitcherVideoMode' \
  "/Applications/Blackmagic ATEM Switchers/Developer SDK/Mac OS X/include/BMDSwitcherAPI.h"
```

If the header spells a mode differently (e.g. a `2160p` symbol rather than `4KHDp`), **correct
the symbol name rather than dropping the row** — the row's `"2160p"` / `"59.94"` label strings
are what the UI shows and are independent of the SDK's naming.

## Also verify against the real header

These were written from memory and not checked against the SDK. Confirm each and fix the call
site if the signature differs:

- `IBMDSwitcher::DoesSupportVideoMode(BMDSwitcherVideoMode, bool*)`
- `IBMDSwitcher::GetVideoMode(BMDSwitcherVideoMode*)`
- `IBMDSwitcher::SetVideoMode(BMDSwitcherVideoMode)`

If `SetVideoMode` does not exist on `IBMDSwitcher` in this SDK version, stop and report where it
does live rather than inventing a path to it.

## Rules

- **Minimal fixes only.** Fix compile errors. Do not refactor, rename, reformat, or "improve"
  code that already compiles.
- **Do not weaken the two RATE guards.** `-isEditingRateField` and `rateEchoSuppressUntil` in
  `ControlSurfaceWindowController.mm` are the actual bug fix, not incidental. Same for the
  `syncedVideoMode` sentinel on the video popups. If one of them blocks a compile, fix the
  compile error — do not delete the guard.
- **Do not initialize `IBMDSwitcherCameraControl` in the main app process.** That path is what
  hangs ATEM Software Control on Tahoe; camera control is deliberately exiled to the separate
  `ATEMCameraHelper` binary. This is the core safety design of the project.
- **Do not connect to hardware.** No switcher is assumed present. Verify offline only.
- Keep the video standard change behind its explicit SET STANDARD button and confirmation alert.
  It re-syncs every switcher output, so it must never become a live-on-change popup.

## Offline verification once it builds

```sh
make demo      # launches with simulated state; both video popups and the RATE field are live
make preview   # renders the switcher console to build/preview.png without hardware
```

`make demo` advertises the full mode table, so it exercises the Format → Frame Rate popup
repopulation and the RATE field guards with no switcher attached. Open `build/preview.png` and
confirm the new "Video Standard" card sits between the transition row and the AUX card, and that
nothing in the layout is clipped or overlapping — the card was given a fixed 104pt height and a
horizontal spacer that has not been visually checked.

## Report back

1. Did it build? Exact errors if not.
2. Which `kATEMVideoModeTable` lines you deleted or corrected, and why.
3. The full list of `bmdSwitcherVideoMode*` symbols the installed header actually defines.
4. Any SDK signature that differed from what the patch assumed.
5. Whether the Video Standard card renders correctly in `build/preview.png`.

Do not commit or push. Leave the working tree dirty for review.
