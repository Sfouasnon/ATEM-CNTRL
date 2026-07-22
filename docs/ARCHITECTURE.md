# Architecture

```text
                         AppKit controls
                     active target A or B
                       ╱             ╲
        immutable snapshots           immutable snapshots
                 ╱                       ╲
        ATEMController A              ATEMController B
        serial queue A                serial queue B
                 │                       │
                 └──── BMDSwitcherAPI.bundle ────┘
                           │             │
                       ATEM A         ATEM B
```

`ATEMController` is the only component allowed to hold or call Blackmagic COM-style interfaces. The app owns two instances. Each instance creates its own discovery object, switcher interface graph, polling timer, and serial dispatch queue. Connection, enumeration, commands, callback refreshes, and teardown never cross between sessions.

Each controller constructs `ATEMState` snapshots containing value objects for inputs, keyers, AUX outputs, and multiviews. Both snapshots cross to the main queue and stay cached while `ControlSurfaceWindowController` renders the selected target. UI code never dereferences an SDK object, and switching the visible target does not alter either connection.

The app queries the connected device before exposing controls. This lets the same UI adapt to ATEM Mini, Television Studio, and Constellation families without hard-coding one input count or keyer layout.

Input availability is preserved per source instead of assuming every source belongs on every bus. M/E, AUX, and multiview selectors intersect the source mask with the destination capability mask. Multiview controls are likewise enabled only when `IBMDSwitcherMultiView` reports the corresponding layout, routing, VU-meter, safe-area, Program/Preview-swap, or overlay capability.

For quadrant-capable models, `BMDSwitcherMultiViewLayout` is treated as the four-bit mask defined by the SDK: top-left, top-right, bottom-left, and bottom-right are toggled independently between one large window and four small windows. The visible routing controls consequently expand through 4, 7, 10, 13, and 16 windows. Non-quadrant models retain the classic Program Top/Bottom/Left/Right selector.

The build intentionally compiles Blackmagic's installed `BMDSwitcherAPIDispatch.cpp`, which dynamically loads the official API bundle. No private macOS APIs or direct reverse-engineered ATEM network packets are used.
