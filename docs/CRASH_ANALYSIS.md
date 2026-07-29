# ATEM Software Control 10.3 hang analysis

Source: hang report supplied during development; the original report is not committed.

## Conclusion

This is an application hang report, not an exception crash. ATEM Software Control was unresponsive for 50 seconds while its main UI thread synchronously sent camera-control defaults. A switcher connection thread was simultaneously waiting on a mutex owned by the main thread. That pattern is consistent with a blocking I/O/lock interaction in the ATEM 10.3 camera-control initialization path on Tahoe.

Power-cycling the switcher is unlikely to address this software-side wait. Reproducing it on two Tahoe machines further weakens a single-Mac or transient-hardware explanation.

## Evidence

- Date: 2026-07-21 15:14:46 +0100
- OS: macOS 26.5.2, build 25F84
- Architecture: arm64e system, arm64 ATEM process
- Hardware: Mac16,10 with 16 GB RAM
- Event: `hang`
- Process note: unresponsive for 50 seconds before sampling
- The UI event loop reaches `SwitcherWindow::connectingFinished()` and `SwitcherWindow::setSwitcher()`.
- It then enters `CameraControlModel::setSwitcher()`, `flushCameraList()`, and `APICameraControl::setDefaults()`.
- The terminal application frame is `CBMDSwitcherCameraControl::SendCameraControlAtom()` followed by the kernel `write()` call.
- `BMDSwitcherConnection::ConnectionThread()` is in `SendDataPackets()` and blocked on a mutex attributed to the main ATEM thread.
- The report contains no exception type, crash signal, or faulting instruction typical of a conventional crash.

The final sampled main-thread path through `Terminate()` reflects the user/system ending the hung process; it is not the initiating fault.

## Design response in ATEM CNTRL

- Never query or initialize `IBMDSwitcherCameraControl` in the main application process.
- Never call `ConnectTo()`, a getter, or a setter on AppKit's main thread.
- Serialize all API activity on one dedicated queue per switcher session to avoid concurrent access to an interface graph.
- Send immutable state snapshots to the main thread for display.
- Keep the window responsive even if a Blackmagic API call is slow.
- Use periodic state refresh as a fallback in addition to SDK callbacks.
- Provide an offline Demo mode and runtime self-test.
- Launch camera/color control only on explicit user request in `ATEMCameraHelper`, a separate process with its own discovery object, ATEM connection, and camera-control interface graph.
- Send helper commands through bounded, coalesced asynchronous IPC; never write to the helper pipe from AppKit, and keep only one command outstanding until its reply.
- Stop the helper on session/address changes or disconnect, apply an eight-second startup watchdog and three-second command watchdog, and escalate from termination to forced kill if its SDK thread cannot exit.

## What remains uncertain

The hang report proves where the process stopped, but a stack sample alone cannot identify the precise kernel descriptor or Blackmagic source-code defect. The causal explanation is therefore an inference from the blocking `write()` and lock ownership—not a source-level proof.

ATEM CNTRL still uses Blackmagic's installed API bundle for core switching, Fairlight audio, and ATEM-managed HyperDeck control. Camera control remains capable of hanging inside its helper, but that failure is contained by process isolation. Only a Tahoe 26.5.2 hardware test can confirm that the main process stays stable and that force-stopping the helper releases every affected ATEM/runtime resource.
