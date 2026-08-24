APP_NAME := ATEMCNTRL
APP_DISPLAY_NAME := ATEM CNTRL
APP_VERSION := 0.4.1
BUNDLE_ID := com.local.atem-edit
BUILD_DIR := build
APP_BUNDLE := $(BUILD_DIR)/$(APP_DISPLAY_NAME).app
PACKAGE := $(BUILD_DIR)/ATEM-CNTRL-$(APP_VERSION)-macOS.zip
CONTENTS := $(APP_BUNDLE)/Contents
MACOS_DIR := $(CONTENTS)/MacOS
RESOURCES_DIR := $(CONTENTS)/Resources
HELPERS_DIR := $(CONTENTS)/Helpers
BINARY := $(MACOS_DIR)/$(APP_NAME)
CAMERA_HELPER := $(HELPERS_DIR)/ATEMCameraHelper

SDK_ROOT := /Applications/Blackmagic ATEM Switchers/Developer SDK/Mac OS X
SDK_INCLUDE := $(SDK_ROOT)/include
SDK_HEADER := $(SDK_INCLUDE)/BMDSwitcherAPI.h
SDK_DISPATCH := $(SDK_INCLUDE)/BMDSwitcherAPIDispatch.cpp
API_BUNDLE := /Library/Application Support/Blackmagic Design/Switchers/BMDSwitcherAPI.bundle

# The video-standard table is generated from the installed SDK header so the app
# offers exactly the frame rates that SDK defines, including any Blackmagic adds
# later. See Tools/generate_video_modes.py.
VIDEO_MODE_GENERATOR := Tools/generate_video_modes.py
VIDEO_MODE_TABLE := Sources/ATEMVideoModeTable.inc
PYTHON := /usr/bin/python3

SOURCES := \
	Sources/main.mm \
	Sources/ATEMController.mm \
	Sources/ControlSurfaceWindowController.mm \
	Sources/AudioWindowController.mm \
	Sources/ColorWindowController.mm \
	Sources/LabelsWindowController.mm \
	Sources/MediaWindowController.mm \
	Sources/HyperDeckWindowController.mm

CXX := xcrun clang++
CXXFLAGS := -std=c++17 -fobjc-arc -fblocks -Wall -Wextra -Wno-deprecated-declarations \
	-arch arm64 -arch x86_64 -mmacosx-version-min=13.0 -I"$(SDK_INCLUDE)" -I"Sources"
LDFLAGS := -framework Cocoa -framework CoreFoundation

.PHONY: all build package run demo preview preview-multiview preview-audio preview-color preview-labels preview-media preview-hyperdeck test diagnose clean verify requirements video-modes

all: build

requirements:
	@test -f "$(SDK_HEADER)" || \
		(printf '%s\n' "Missing Blackmagic Switchers SDK at $(SDK_ROOT). Install ATEM Software Control with Developer SDK." >&2; exit 1)
	@test -d "$(API_BUNDLE)" || \
		(printf '%s\n' "Missing BMDSwitcherAPI.bundle. Install ATEM Software Control before building." >&2; exit 1)
	@test -x "$(PYTHON)" || \
		(printf '%s\n' "Missing $(PYTHON), needed to generate the video-standard table. Install the Apple Command Line Tools." >&2; exit 1)

# Regenerated on every build, so installing a new ATEM Software Control release picks
# up its new video standards immediately and the table can never go stale.
#
# Deliberately a phony recipe rather than a file target with $(SDK_HEADER) as a
# prerequisite: make splits prerequisites on whitespace, and the SDK path contains
# spaces, so a file rule would look for a target called "/Applications/Blackmagic".
# Regenerating unconditionally costs milliseconds and this Makefile recompiles every
# source on every build regardless, so there is nothing to save by being clever.
video-modes: requirements
	@"$(PYTHON)" "$(VIDEO_MODE_GENERATOR)" --header "$(SDK_HEADER)" --output "$(VIDEO_MODE_TABLE)"

build: requirements video-modes
	@mkdir -p "$(MACOS_DIR)" "$(RESOURCES_DIR)" "$(HELPERS_DIR)"
	$(CXX) $(CXXFLAGS) $(SOURCES) "$(SDK_DISPATCH)" -o "$(BINARY)" $(LDFLAGS)
	$(CXX) $(CXXFLAGS) Sources/CameraHelperMain.mm "$(SDK_DISPATCH)" -o "$(CAMERA_HELPER)" $(LDFLAGS)
	cp Resources/Info.plist "$(CONTENTS)/Info.plist"
	cp Resources/AppIcon.icns "$(RESOURCES_DIR)/AppIcon.icns"
	cp Resources/Brand/ATEMCNTRL-Logo.png "$(RESOURCES_DIR)/ATEMCNTRL-Logo.png"
	codesign --force --sign - "$(CAMERA_HELPER)"
	codesign --force --deep --sign - "$(APP_BUNDLE)"

package: build
	ditto -c -k --sequesterRsrc --keepParent "$(APP_BUNDLE)" "$(PACKAGE)"

run: build
	open "$(APP_BUNDLE)"

demo: build
	open -n "$(APP_BUNDLE)" --args --demo

preview: build
	"$(BINARY)" --demo --render-preview "$(BUILD_DIR)/preview.png"

preview-multiview: build
	"$(BINARY)" --demo --render-multiview-preview "$(BUILD_DIR)/multiview-preview.png"

preview-audio: build
	"$(BINARY)" --demo --render-audio-preview "$(BUILD_DIR)/audio-preview.png"

preview-color: build
	"$(BINARY)" --demo --render-color-preview "$(BUILD_DIR)/color-preview.png"

preview-labels: build
	"$(BINARY)" --demo --render-labels-preview "$(BUILD_DIR)/labels-preview.png"

preview-media: build
	"$(BINARY)" --demo --render-media-preview "$(BUILD_DIR)/media-preview.png"

preview-hyperdeck: build
	"$(BINARY)" --demo --render-hyperdeck-preview "$(BUILD_DIR)/hyperdeck-preview.png"

test: build
	"$(BINARY)" --self-test

diagnose: build
	"$(BINARY)" --diagnostics

verify: build test
	codesign --verify --deep --strict --verbose=2 "$(APP_BUNDLE)"
	plutil -lint "$(CONTENTS)/Info.plist"

clean:
	rm -rf "$(APP_BUNDLE)"
	rm -f "$(VIDEO_MODE_TABLE)"
