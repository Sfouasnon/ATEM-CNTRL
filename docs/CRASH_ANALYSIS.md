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

- Do not query or initialize `IBMDSwitcherCameraControl`.
- Never call `ConnectTo()`, a getter, or a setter on AppKit's main thread.
- Serialize all API activity on one dedicated queue per switcher session to avoid concurrent access to an interface graph.
- Send immutable state snapshots to the main thread for display.
- Keep the window responsive even if a Blackmagic API call is slow.
- Use periodic state refresh as a fallback in addition to SDK callbacks.
- Provide an offline Demo mode and runtime self-test.

## What remains uncertain

The hang report proves where the process stopped, but a stack sample alone cannot identify the precise kernel descriptor or Blackmagic source-code defect. The causal explanation is therefore an inference from the blocking `write()` and lock ownership—not a source-level proof.

ATEM CNTRL still uses Blackmagic's installed API bundle for core switching. The current evidence suggests avoiding camera initialization is sufficient, but only a Tahoe 26.5.2 hardware test can confirm that the rest of the runtime is stable.
