APP_NAME := ATEMCNTRL
APP_DISPLAY_NAME := ATEM CNTRL
APP_VERSION := 0.3.1
BUNDLE_ID := com.local.atem-edit
BUILD_DIR := build
APP_BUNDLE := $(BUILD_DIR)/$(APP_DISPLAY_NAME).app
PACKAGE := $(BUILD_DIR)/ATEM-CNTRL-$(APP_VERSION)-macOS.zip
CONTENTS := $(APP_BUNDLE)/Contents
MACOS_DIR := $(CONTENTS)/MacOS
RESOURCES_DIR := $(CONTENTS)/Resources
BINARY := $(MACOS_DIR)/$(APP_NAME)

SDK_ROOT := /Applications/Blackmagic ATEM Switchers/Developer SDK/Mac OS X
SDK_INCLUDE := $(SDK_ROOT)/include
SDK_DISPATCH := $(SDK_INCLUDE)/BMDSwitcherAPIDispatch.cpp
API_BUNDLE := /Library/Application Support/Blackmagic Design/Switchers/BMDSwitcherAPI.bundle

SOURCES := \
	Sources/main.mm \
	Sources/ATEMController.mm \
	Sources/ControlSurfaceWindowController.mm

CXX := xcrun clang++
CXXFLAGS := -std=c++17 -fobjc-arc -fblocks -Wall -Wextra -Wno-deprecated-declarations \
	-arch arm64 -arch x86_64 -mmacosx-version-min=13.0 -I"$(SDK_INCLUDE)" -I"Sources"
LDFLAGS := -framework Cocoa -framework CoreFoundation

.PHONY: all build package run demo preview preview-multiview test diagnose clean verify requirements

all: build

requirements:
	@test -f "$(SDK_INCLUDE)/BMDSwitcherAPI.h" || \
		(printf '%s\n' "Missing Blackmagic Switchers SDK at $(SDK_ROOT). Install ATEM Software Control with Developer SDK." >&2; exit 1)
	@test -d "$(API_BUNDLE)" || \
		(printf '%s\n' "Missing BMDSwitcherAPI.bundle. Install ATEM Software Control before building." >&2; exit 1)

build: requirements
	@mkdir -p "$(MACOS_DIR)" "$(RESOURCES_DIR)"
	$(CXX) $(CXXFLAGS) $(SOURCES) "$(SDK_DISPATCH)" -o "$(BINARY)" $(LDFLAGS)
	cp Resources/Info.plist "$(CONTENTS)/Info.plist"
	cp Resources/AppIcon.icns "$(RESOURCES_DIR)/AppIcon.icns"
	cp Resources/Brand/ATEMCNTRL-Logo.png "$(RESOURCES_DIR)/ATEMCNTRL-Logo.png"
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

test: build
	"$(BINARY)" --self-test

diagnose: build
	"$(BINARY)" --diagnostics

verify: build test
	codesign --verify --deep --strict --verbose=2 "$(APP_BUNDLE)"
	plutil -lint "$(CONTENTS)/Info.plist"

clean:
	rm -rf "$(APP_BUNDLE)"
