#!/bin/bash

PROJECT_NAME="ParticleFlow"
BUNDLE_NAME="${PROJECT_NAME}.saver"
BUILD_DIR="build"
MACOS_DIR="${BUILD_DIR}/${BUNDLE_NAME}/Contents/MacOS"
RESOURCES_DIR="${BUILD_DIR}/${BUNDLE_NAME}/Contents/Resources"

echo "Building ${PROJECT_NAME} screensaver..."

rm -rf ${BUILD_DIR}
mkdir -p ${MACOS_DIR}
mkdir -p ${RESOURCES_DIR}
mkdir -p ${BUILD_DIR}/arm64
mkdir -p ${BUILD_DIR}/x86_64

echo "Compiling Swift files for arm64..."
swiftc \
    -target arm64-apple-macos11.0 \
    -emit-library \
    -o "${BUILD_DIR}/arm64/${PROJECT_NAME}" \
    -framework ScreenSaver \
    -framework SpriteKit \
    -framework GameplayKit \
    -framework Cocoa \
    -module-name ${PROJECT_NAME} \
    -emit-module \
    -emit-module-path "${BUILD_DIR}/arm64/${PROJECT_NAME}.swiftmodule" \
    -parse-as-library \
    -Xlinker -rpath \
    -Xlinker @executable_path/../Frameworks \
    -Xlinker -rpath \
    -Xlinker @loader_path/../Frameworks \
    ParticleFlowView.swift \
    ParticleFlowScene.swift \
    SimpleTestScene.swift \
    ConfigureSheetController.swift

if [ $? -ne 0 ]; then
    echo "ARM64 compilation failed!"
    exit 1
fi

echo "Compiling Swift files for x86_64..."
swiftc \
    -target x86_64-apple-macos11.0 \
    -emit-library \
    -o "${BUILD_DIR}/x86_64/${PROJECT_NAME}" \
    -framework ScreenSaver \
    -framework SpriteKit \
    -framework GameplayKit \
    -framework Cocoa \
    -module-name ${PROJECT_NAME} \
    -emit-module \
    -emit-module-path "${BUILD_DIR}/x86_64/${PROJECT_NAME}.swiftmodule" \
    -parse-as-library \
    -Xlinker -rpath \
    -Xlinker @executable_path/../Frameworks \
    -Xlinker -rpath \
    -Xlinker @loader_path/../Frameworks \
    ParticleFlowView.swift \
    ParticleFlowScene.swift \
    SimpleTestScene.swift \
    ConfigureSheetController.swift

if [ $? -ne 0 ]; then
    echo "x86_64 compilation failed!"
    exit 1
fi

echo "Creating universal binary..."
lipo -create \
    "${BUILD_DIR}/arm64/${PROJECT_NAME}" \
    "${BUILD_DIR}/x86_64/${PROJECT_NAME}" \
    -output "${MACOS_DIR}/${PROJECT_NAME}"

if [ $? -ne 0 ]; then
    echo "Failed to create universal binary!"
    exit 1
fi

echo "Copying Info.plist..."
cp Info.plist "${BUILD_DIR}/${BUNDLE_NAME}/Contents/"

echo "Creating PkgInfo..."
echo "BNDL????" > "${BUILD_DIR}/${BUNDLE_NAME}/Contents/PkgInfo"

echo "Setting bundle executable permissions..."
chmod +x "${MACOS_DIR}/${PROJECT_NAME}"

echo "Signing screensaver bundle..."
codesign --force --deep -s - "${BUILD_DIR}/${BUNDLE_NAME}"

echo "Verifying universal binary..."
file "${MACOS_DIR}/${PROJECT_NAME}"
lipo -info "${MACOS_DIR}/${PROJECT_NAME}"

echo "Verifying code signature..."
codesign -dv "${BUILD_DIR}/${BUNDLE_NAME}" 2>&1 | grep -E "Identifier|Signature"

echo "Build complete!"
echo "Screensaver bundle created at: ${BUILD_DIR}/${BUNDLE_NAME}"
echo ""
echo "To install:"
echo "  1. Double-click ${BUILD_DIR}/${BUNDLE_NAME}"
echo "  2. Click 'Install' when prompted"
echo "  3. Open System Settings > Screen Saver and select 'Particle Flow'"
echo ""
echo "If you get a security warning:"
echo "  - Go to System Settings > Privacy & Security"
echo "  - Click 'Open Anyway' next to the warning about ${BUNDLE_NAME}"