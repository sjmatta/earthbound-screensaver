#!/bin/bash

# Automated test script for ParticleFlow screensaver
# This script builds the screensaver and runs automated tests

set -e  # Exit on error

PROJECT_NAME="ParticleFlow"
BUILD_DIR="build"
BUNDLE_NAME="${PROJECT_NAME}.saver"
BUNDLE_PATH="${BUILD_DIR}/${BUNDLE_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 ParticleFlow Screensaver Automated Test Suite${NC}"
echo "================================================"

# Step 1: Clean previous build
echo -e "\n${YELLOW}📦 Step 1: Cleaning previous build...${NC}"
rm -rf ${BUILD_DIR}

# Step 2: Build the screensaver
echo -e "\n${YELLOW}📦 Step 2: Building screensaver...${NC}"
./build.sh

if [ ! -f "${BUNDLE_PATH}/Contents/MacOS/${PROJECT_NAME}" ]; then
    echo -e "${RED}❌ Build failed - executable not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful${NC}"

# Step 3: Run Swift test harness
echo -e "\n${YELLOW}🔬 Step 3: Running test harness...${NC}"
swift TestHarness.swift

# Step 4: Additional validation tests
echo -e "\n${YELLOW}🔍 Step 4: Running validation tests...${NC}"

# Check bundle structure
echo "  Checking bundle structure..."
if [ -f "${BUNDLE_PATH}/Contents/Info.plist" ]; then
    echo -e "  ${GREEN}✅ Info.plist present${NC}"
else
    echo -e "  ${RED}❌ Info.plist missing${NC}"
    exit 1
fi

if [ -f "${BUNDLE_PATH}/Contents/MacOS/${PROJECT_NAME}" ]; then
    echo -e "  ${GREEN}✅ Executable present${NC}"
else
    echo -e "  ${RED}❌ Executable missing${NC}"
    exit 1
fi

# Check code signature
echo "  Checking code signature..."
if codesign -dv "${BUNDLE_PATH}" 2>&1 | grep -q "Signature"; then
    echo -e "  ${GREEN}✅ Bundle is signed${NC}"
else
    echo -e "  ${YELLOW}⚠️  Bundle is not signed${NC}"
fi

# Check architectures
echo "  Checking architectures..."
ARCHS=$(lipo -info "${BUNDLE_PATH}/Contents/MacOS/${PROJECT_NAME}" 2>&1)
if echo "$ARCHS" | grep -q "x86_64"; then
    echo -e "  ${GREEN}✅ x86_64 architecture present${NC}"
else
    echo -e "  ${YELLOW}⚠️  x86_64 architecture missing${NC}"
fi

if echo "$ARCHS" | grep -q "arm64"; then
    echo -e "  ${GREEN}✅ arm64 architecture present${NC}"
else
    echo -e "  ${YELLOW}⚠️  arm64 architecture missing${NC}"
fi

# Step 5: Performance test (optional)
echo -e "\n${YELLOW}⚡ Step 5: Performance test...${NC}"

# Create a simple performance test script
cat > perf_test.swift << 'EOF'
#!/usr/bin/env swift

import Foundation
import ScreenSaver
import AppKit

let bundlePath = "build/ParticleFlow.saver"
guard let bundle = Bundle(path: bundlePath),
      bundle.load(),
      let viewClass = bundle.principalClass as? ScreenSaverView.Type,
      let view = viewClass.init(frame: NSRect(x: 0, y: 0, width: 1920, height: 1080), isPreview: false) else {
    print("Failed to load screensaver for performance test")
    exit(1)
}

// Measure animation startup time
let startTime = CFAbsoluteTimeGetCurrent()
view.startAnimation()
let initTime = CFAbsoluteTimeGetCurrent() - startTime

// Run for a brief period
Thread.sleep(forTimeInterval: 2.0)

// Stop and measure cleanup time
let stopTime = CFAbsoluteTimeGetCurrent()
view.stopAnimation()
let cleanupTime = CFAbsoluteTimeGetCurrent() - stopTime

print(String(format: "  Initialization time: %.3f ms", initTime * 1000))
print(String(format: "  Cleanup time: %.3f ms", cleanupTime * 1000))

if initTime < 0.1 {  // Less than 100ms
    print("  ✅ Performance acceptable")
} else {
    print("  ⚠️  Initialization might be slow")
}
EOF

swift perf_test.swift
rm perf_test.swift

# Step 6: Console log test
echo -e "\n${YELLOW}📝 Step 6: Checking for console errors...${NC}"

# Create a script to check for recent console errors
cat > console_check.swift << 'EOF'
#!/usr/bin/env swift

import Foundation

// Check Console logs for recent errors related to ParticleFlow
let task = Process()
task.launchPath = "/usr/bin/log"
task.arguments = ["show", "--predicate", "process == 'legacyScreenSaver' OR process == 'WallpaperAgent'", "--style", "compact", "--last", "1m"]

let pipe = Pipe()
task.standardOutput = pipe
task.standardError = pipe

task.launch()
task.waitUntilExit()

let data = pipe.fileHandleForReading.readDataToEndOfFile()
if let output = String(data: data, encoding: .utf8) {
    if output.contains("ParticleFlow") {
        if output.contains("error") || output.contains("exception") || output.contains("crash") {
            print("  ⚠️  Found potential errors in console logs")
            print(output)
        } else {
            print("  ✅ No errors found in recent console logs")
        }
    } else {
        print("  ℹ️  No recent ParticleFlow activity in console logs")
    }
}
EOF

swift console_check.swift
rm console_check.swift

# Final summary
echo -e "\n${BLUE}=====================================
📊 Test Summary
=====================================${NC}"

echo -e "${GREEN}✅ All automated tests completed${NC}"
echo -e "\nThe screensaver has been built and tested successfully."
echo -e "Bundle location: ${BUNDLE_PATH}"
echo -e "\nTo install manually:"
echo -e "  1. Double-click ${BUNDLE_PATH}"
echo -e "  2. Click 'Install' when prompted"
echo -e "  3. Open System Settings > Screen Saver and select 'Particle Flow'"