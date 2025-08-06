#!/bin/bash

echo "Building test app..."

swiftc \
    -o ParticleFlowTest \
    -framework Cocoa \
    -framework SpriteKit \
    -framework GameplayKit \
    TestApp.swift \
    ParticleFlowScene.swift

if [ $? -eq 0 ]; then
    echo "Test app built successfully!"
    echo "Running test app..."
    ./ParticleFlowTest
else
    echo "Build failed!"
fi