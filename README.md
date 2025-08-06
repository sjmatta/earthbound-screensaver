# Particle Flow Screensaver

A modern macOS screensaver featuring dynamic particle systems with flowing animations, built with Swift and SpriteKit.

## Features

- **Dynamic Particle System**: Multiple particle emitters creating flowing, organic animations
- **Physics-Based Movement**: Turbulence and vortex fields for realistic particle behavior
- **Color Transitions**: Smooth color gradients that transition over time
- **Circular Motion Paths**: Particles follow orbital paths with varying speeds
- **Configuration Options**: Customizable settings for particle density, speed, and effects
- **60 FPS Performance**: Optimized for smooth animations

## Technical Stack

- **Swift 5.9+**: Modern Swift with latest language features
- **SpriteKit**: Apple's 2D graphics framework for particle systems
- **GameplayKit**: For advanced physics simulations
- **ScreenSaver Framework**: Native macOS screensaver integration

## Animation Techniques

1. **Particle Emitters**: Multiple SKEmitterNode instances with customized properties
2. **Force Fields**: SKFieldNode for turbulence and vortex effects
3. **Procedural Animation**: Dynamic parameter changes based on sine waves
4. **Color Interpolation**: Smooth RGB transitions between color palettes
5. **Orbital Paths**: Circular motion with varying radii and speeds

## Installation

### Build from Source

1. Clone or download the project
2. Run the build script:
   ```bash
   chmod +x build.sh
   ./build.sh
   ```
3. Double-click `build/ParticleFlow.saver` to install
4. Open System Settings > Screen Saver and select "Particle Flow"

### Security Note

If macOS blocks the screensaver:
1. Go to System Settings > Privacy & Security
2. Click "Open Anyway" next to the warning
3. Or run: `xattr -d com.apple.quarantine build/ParticleFlow.saver`

## Configuration

The screensaver includes a configuration sheet with options for:
- Particle density (10-200 particles)
- Animation speed (0.1x - 3.0x)
- Color schemes (5 presets)
- Turbulence field toggle
- Glow effect toggle

## Architecture

- **ParticleFlowView.swift**: Main ScreenSaverView subclass
- **ParticleFlowScene.swift**: SpriteKit scene with particle logic
- **ConfigureSheetController.swift**: Settings interface

## System Requirements

- macOS 11.0 (Big Sur) or later
- Apple Silicon or Intel Mac
- SpriteKit and GameplayKit frameworks (included with macOS)

## License

MIT License - Feel free to modify and distribute

## Acknowledgments

Inspired by modern particle visualization techniques and the active Swift screensaver community on GitHub.