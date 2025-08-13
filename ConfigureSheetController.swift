import Cocoa

class ConfigureSheetController: NSObject {
    
    // The window property that will be returned to the screensaver
    var window: NSWindow?
    
    // Background settings
    private var backgroundPopUp: NSPopUpButton!
    private var transitionSpeedSlider: NSSlider!
    private var transitionLabel: NSTextField!
    private var showNamesCheckbox: NSButton!
    
    // Animation settings
    private var animationSpeedSlider: NSSlider!
    private var animationSpeedLabel: NSTextField!
    private var distortionIntensitySlider: NSSlider!
    private var distortionIntensityLabel: NSTextField!
    
    // CRT effect settings
    private var crtEnabledCheckbox: NSButton!
    private var scanlineIntensitySlider: NSSlider!
    private var scanlineLabel: NSTextField!
    private var pixelSizeSlider: NSSlider!
    private var pixelSizeLabel: NSTextField!
    private var curvatureSlider: NSSlider!
    private var curvatureLabel: NSTextField!
    private var vignetteSlider: NSSlider!
    private var vignetteLabel: NSTextField!
    
    override init() {
        super.init()
        
        // Create window programmatically
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 580),
                             styleMask: [.titled, .closable],
                             backing: .buffered,
                             defer: false)
        window.title = "Earthbound Battle Backgrounds Settings"
        window.center()
        
        self.window = window
        
        // Create content view
        let contentView = NSView(frame: window.contentView!.bounds)
        
        var yPosition = 530
        
        // Title label
        let titleLabel = NSTextField(labelWithString: "Earthbound Battle Backgrounds")
        titleLabel.frame = NSRect(x: 20, y: yPosition, width: 560, height: 30)
        titleLabel.alignment = .center
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        contentView.addSubview(titleLabel)
        
        yPosition -= 50
        
        // MARK: - Background Selection Section
        let bgSectionLabel = NSTextField(labelWithString: "Background Selection")
        bgSectionLabel.frame = NSRect(x: 20, y: yPosition, width: 200, height: 20)
        bgSectionLabel.font = NSFont.boldSystemFont(ofSize: 14)
        contentView.addSubview(bgSectionLabel)
        
        yPosition -= 35
        
        // Background selection
        let bgLabel = NSTextField(labelWithString: "Background:")
        bgLabel.frame = NSRect(x: 40, y: yPosition, width: 100, height: 20)
        contentView.addSubview(bgLabel)
        
        backgroundPopUp = NSPopUpButton(frame: NSRect(x: 150, y: yPosition - 2, width: 400, height: 26))
        backgroundPopUp.addItem(withTitle: "Random (Cycle All)")
        backgroundPopUp.menu?.addItem(NSMenuItem.separator())
        
        let backgrounds = EarthboundBackground.getAllBackgrounds()
        for (index, bg) in backgrounds.enumerated() {
            backgroundPopUp.addItem(withTitle: "\(index + 1). \(bg.name)")
        }
        
        let defaults = UserDefaults.standard
        let savedIndex = defaults.integer(forKey: "EarthboundBackgroundIndex")
        backgroundPopUp.selectItem(at: savedIndex)
        contentView.addSubview(backgroundPopUp)
        
        yPosition -= 35
        
        // Transition speed
        let speedLabel = NSTextField(labelWithString: "Transition:")
        speedLabel.frame = NSRect(x: 40, y: yPosition, width: 100, height: 20)
        contentView.addSubview(speedLabel)
        
        transitionSpeedSlider = NSSlider(frame: NSRect(x: 150, y: yPosition - 2, width: 300, height: 26))
        transitionSpeedSlider.minValue = 10
        transitionSpeedSlider.maxValue = 120
        transitionSpeedSlider.doubleValue = defaults.double(forKey: "EarthboundTransitionSpeed")
        if transitionSpeedSlider.doubleValue == 0 {
            transitionSpeedSlider.doubleValue = 30
        }
        transitionSpeedSlider.target = self
        transitionSpeedSlider.action = #selector(sliderChanged(_:))
        contentView.addSubview(transitionSpeedSlider)
        
        transitionLabel = NSTextField(labelWithString: "\(Int(transitionSpeedSlider.doubleValue)) seconds")
        transitionLabel.frame = NSRect(x: 460, y: yPosition, width: 90, height: 20)
        transitionLabel.isEditable = false
        contentView.addSubview(transitionLabel)
        
        yPosition -= 30
        
        // Show background names checkbox
        showNamesCheckbox = NSButton(checkboxWithTitle: "Show background names on transition", target: nil, action: nil)
        showNamesCheckbox.frame = NSRect(x: 40, y: yPosition, width: 250, height: 20)
        showNamesCheckbox.state = defaults.bool(forKey: "EarthboundShowNames") ? .on : .off
        contentView.addSubview(showNamesCheckbox)
        
        yPosition -= 40
        
        // MARK: - Animation Settings Section
        let animSectionLabel = NSTextField(labelWithString: "Animation Settings")
        animSectionLabel.frame = NSRect(x: 20, y: yPosition, width: 200, height: 20)
        animSectionLabel.font = NSFont.boldSystemFont(ofSize: 14)
        contentView.addSubview(animSectionLabel)
        
        yPosition -= 35
        
        // Animation speed
        let animSpeedLabel = NSTextField(labelWithString: "Speed:")
        animSpeedLabel.frame = NSRect(x: 40, y: yPosition, width: 100, height: 20)
        contentView.addSubview(animSpeedLabel)
        
        animationSpeedSlider = NSSlider(frame: NSRect(x: 150, y: yPosition - 2, width: 300, height: 26))
        animationSpeedSlider.minValue = 0.1
        animationSpeedSlider.maxValue = 2.0
        animationSpeedSlider.doubleValue = defaults.double(forKey: "EarthboundAnimationSpeed")
        if animationSpeedSlider.doubleValue == 0 {
            animationSpeedSlider.doubleValue = 1.0  // Default authentic SNES speed for 30 FPS
        }
        animationSpeedSlider.target = self
        animationSpeedSlider.action = #selector(sliderChanged(_:))
        contentView.addSubview(animationSpeedSlider)
        
        animationSpeedLabel = NSTextField(labelWithString: String(format: "%.1fx", animationSpeedSlider.doubleValue))
        animationSpeedLabel.frame = NSRect(x: 460, y: yPosition, width: 90, height: 20)
        animationSpeedLabel.isEditable = false
        contentView.addSubview(animationSpeedLabel)
        
        yPosition -= 35
        
        // Distortion intensity
        let distortionLabel = NSTextField(labelWithString: "Distortion:")
        distortionLabel.frame = NSRect(x: 40, y: yPosition, width: 100, height: 20)
        contentView.addSubview(distortionLabel)
        
        distortionIntensitySlider = NSSlider(frame: NSRect(x: 150, y: yPosition - 2, width: 300, height: 26))
        distortionIntensitySlider.minValue = 0.5
        distortionIntensitySlider.maxValue = 3.0
        distortionIntensitySlider.doubleValue = defaults.double(forKey: "EarthboundDistortionIntensity")
        if distortionIntensitySlider.doubleValue == 0 {
            distortionIntensitySlider.doubleValue = 1.0
        }
        distortionIntensitySlider.target = self
        distortionIntensitySlider.action = #selector(sliderChanged(_:))
        contentView.addSubview(distortionIntensitySlider)
        
        distortionIntensityLabel = NSTextField(labelWithString: String(format: "%.1fx", distortionIntensitySlider.doubleValue))
        distortionIntensityLabel.frame = NSRect(x: 460, y: yPosition, width: 90, height: 20)
        distortionIntensityLabel.isEditable = false
        contentView.addSubview(distortionIntensityLabel)
        
        yPosition -= 40
        
        // MARK: - CRT Effects Section
        let crtSectionLabel = NSTextField(labelWithString: "CRT Effects")
        crtSectionLabel.frame = NSRect(x: 20, y: yPosition, width: 200, height: 20)
        crtSectionLabel.font = NSFont.boldSystemFont(ofSize: 14)
        contentView.addSubview(crtSectionLabel)
        
        yPosition -= 30
        
        // CRT enabled checkbox
        crtEnabledCheckbox = NSButton(checkboxWithTitle: "Enable CRT effects", target: self, action: #selector(crtToggled(_:)))
        crtEnabledCheckbox.frame = NSRect(x: 40, y: yPosition, width: 200, height: 20)
        crtEnabledCheckbox.state = defaults.bool(forKey: "EarthboundCRTEnabled") ? .on : .off
        if !defaults.objectExists(forKey: "EarthboundCRTEnabled") {
            crtEnabledCheckbox.state = .on  // Default to enabled
        }
        contentView.addSubview(crtEnabledCheckbox)
        
        yPosition -= 35
        
        // Scanline intensity
        let scanlineLabel = NSTextField(labelWithString: "Scanlines:")
        scanlineLabel.frame = NSRect(x: 40, y: yPosition, width: 100, height: 20)
        contentView.addSubview(scanlineLabel)
        
        scanlineIntensitySlider = NSSlider(frame: NSRect(x: 150, y: yPosition - 2, width: 300, height: 26))
        scanlineIntensitySlider.minValue = 0.0
        scanlineIntensitySlider.maxValue = 0.5
        scanlineIntensitySlider.doubleValue = defaults.double(forKey: "EarthboundScanlineIntensity")
        if scanlineIntensitySlider.doubleValue == 0 && !defaults.objectExists(forKey: "EarthboundScanlineIntensity") {
            scanlineIntensitySlider.doubleValue = 0.25
        }
        scanlineIntensitySlider.target = self
        scanlineIntensitySlider.action = #selector(sliderChanged(_:))
        scanlineIntensitySlider.isEnabled = crtEnabledCheckbox.state == .on
        contentView.addSubview(scanlineIntensitySlider)
        
        self.scanlineLabel = NSTextField(labelWithString: String(format: "%.0f%%", scanlineIntensitySlider.doubleValue * 100))
        self.scanlineLabel.frame = NSRect(x: 460, y: yPosition, width: 90, height: 20)
        self.scanlineLabel.isEditable = false
        contentView.addSubview(self.scanlineLabel)
        
        yPosition -= 35
        
        // Pixel size
        let pixelLabel = NSTextField(labelWithString: "Pixellation:")
        pixelLabel.frame = NSRect(x: 40, y: yPosition, width: 100, height: 20)
        contentView.addSubview(pixelLabel)
        
        pixelSizeSlider = NSSlider(frame: NSRect(x: 150, y: yPosition - 2, width: 300, height: 26))
        pixelSizeSlider.minValue = 1.0
        pixelSizeSlider.maxValue = 6.0
        pixelSizeSlider.doubleValue = defaults.double(forKey: "EarthboundPixelSize")
        if pixelSizeSlider.doubleValue == 0 {
            pixelSizeSlider.doubleValue = 3.0
        }
        pixelSizeSlider.target = self
        pixelSizeSlider.action = #selector(sliderChanged(_:))
        pixelSizeSlider.isEnabled = crtEnabledCheckbox.state == .on
        contentView.addSubview(pixelSizeSlider)
        
        pixelSizeLabel = NSTextField(labelWithString: String(format: "%.0fx", pixelSizeSlider.doubleValue))
        pixelSizeLabel.frame = NSRect(x: 460, y: yPosition, width: 90, height: 20)
        pixelSizeLabel.isEditable = false
        contentView.addSubview(pixelSizeLabel)
        
        yPosition -= 35
        
        // Curvature
        let curvatureLabel = NSTextField(labelWithString: "Curvature:")
        curvatureLabel.frame = NSRect(x: 40, y: yPosition, width: 100, height: 20)
        contentView.addSubview(curvatureLabel)
        
        curvatureSlider = NSSlider(frame: NSRect(x: 150, y: yPosition - 2, width: 300, height: 26))
        curvatureSlider.minValue = 0.0
        curvatureSlider.maxValue = 0.05
        curvatureSlider.doubleValue = defaults.double(forKey: "EarthboundCurvature")
        if curvatureSlider.doubleValue == 0 && !defaults.objectExists(forKey: "EarthboundCurvature") {
            curvatureSlider.doubleValue = 0.015
        }
        curvatureSlider.target = self
        curvatureSlider.action = #selector(sliderChanged(_:))
        curvatureSlider.isEnabled = crtEnabledCheckbox.state == .on
        contentView.addSubview(curvatureSlider)
        
        self.curvatureLabel = NSTextField(labelWithString: String(format: "%.0f%%", curvatureSlider.doubleValue * 100))
        self.curvatureLabel.frame = NSRect(x: 460, y: yPosition, width: 90, height: 20)
        self.curvatureLabel.isEditable = false
        contentView.addSubview(self.curvatureLabel)
        
        yPosition -= 35
        
        // Vignette
        let vignetteTextLabel = NSTextField(labelWithString: "Vignette:")
        vignetteTextLabel.frame = NSRect(x: 40, y: yPosition, width: 100, height: 20)
        contentView.addSubview(vignetteTextLabel)
        
        vignetteSlider = NSSlider(frame: NSRect(x: 150, y: yPosition - 2, width: 300, height: 26))
        vignetteSlider.minValue = 0.0
        vignetteSlider.maxValue = 0.5
        vignetteSlider.doubleValue = defaults.double(forKey: "EarthboundVignette")
        if vignetteSlider.doubleValue == 0 && !defaults.objectExists(forKey: "EarthboundVignette") {
            vignetteSlider.doubleValue = 0.2
        }
        vignetteSlider.target = self
        vignetteSlider.action = #selector(sliderChanged(_:))
        vignetteSlider.isEnabled = crtEnabledCheckbox.state == .on
        contentView.addSubview(vignetteSlider)
        
        vignetteLabel = NSTextField(labelWithString: String(format: "%.0f%%", vignetteSlider.doubleValue * 100))
        vignetteLabel.frame = NSRect(x: 460, y: yPosition, width: 90, height: 20)
        vignetteLabel.isEditable = false
        contentView.addSubview(vignetteLabel)
        
        yPosition -= 40
        
        // Separator line
        let separator = NSBox()
        separator.boxType = .separator
        separator.frame = NSRect(x: 20, y: yPosition, width: 560, height: 1)
        contentView.addSubview(separator)
        
        yPosition -= 20
        
        // Info text
        let infoText = NSTextField(wrappingLabelWithString: "Experience authentic Earthbound/Mother 2 battle backgrounds with 327 unique patterns, procedural distortion effects, and optional CRT display emulation.")
        infoText.frame = NSRect(x: 20, y: yPosition - 40, width: 560, height: 40)
        infoText.alignment = .center
        infoText.font = NSFont.systemFont(ofSize: 11)
        infoText.textColor = NSColor.secondaryLabelColor
        contentView.addSubview(infoText)
        
        // Button bar
        let defaultsButton = NSButton(title: "Defaults", target: self, action: #selector(resetToDefaults(_:)))
        defaultsButton.frame = NSRect(x: 20, y: 20, width: 80, height: 30)
        defaultsButton.bezelStyle = .rounded
        contentView.addSubview(defaultsButton)
        
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelSheet(_:)))
        cancelButton.frame = NSRect(x: 410, y: 20, width: 80, height: 30)
        cancelButton.bezelStyle = .rounded
        contentView.addSubview(cancelButton)
        
        let okButton = NSButton(title: "OK", target: self, action: #selector(saveAndClose(_:)))
        okButton.frame = NSRect(x: 500, y: 20, width: 80, height: 30)
        okButton.bezelStyle = .rounded
        okButton.keyEquivalent = "\r"
        contentView.addSubview(okButton)
        
        window.contentView = contentView
    }
    
    @objc private func sliderChanged(_ sender: NSSlider) {
        if sender === transitionSpeedSlider {
            transitionLabel.stringValue = "\(Int(sender.doubleValue)) seconds"
        } else if sender === animationSpeedSlider {
            animationSpeedLabel.stringValue = String(format: "%.1fx", sender.doubleValue)
        } else if sender === distortionIntensitySlider {
            distortionIntensityLabel.stringValue = String(format: "%.1fx", sender.doubleValue)
        } else if sender === scanlineIntensitySlider {
            scanlineLabel.stringValue = String(format: "%.0f%%", sender.doubleValue * 100)
        } else if sender === pixelSizeSlider {
            pixelSizeLabel.stringValue = String(format: "%.0fx", sender.doubleValue)
        } else if sender === curvatureSlider {
            curvatureLabel.stringValue = String(format: "%.0f%%", sender.doubleValue * 100)
        } else if sender === vignetteSlider {
            vignetteLabel.stringValue = String(format: "%.0f%%", sender.doubleValue * 100)
        }
    }
    
    @objc private func crtToggled(_ sender: NSButton) {
        let enabled = sender.state == .on
        scanlineIntensitySlider.isEnabled = enabled
        pixelSizeSlider.isEnabled = enabled
        curvatureSlider.isEnabled = enabled
        vignetteSlider.isEnabled = enabled
    }
    
    @objc private func resetToDefaults(_ sender: Any) {
        backgroundPopUp.selectItem(at: 0)
        transitionSpeedSlider.doubleValue = 30
        showNamesCheckbox.state = .off
        animationSpeedSlider.doubleValue = 1.0  // Authentic SNES speed
        distortionIntensitySlider.doubleValue = 1.0
        crtEnabledCheckbox.state = .on
        scanlineIntensitySlider.doubleValue = 0.25
        pixelSizeSlider.doubleValue = 3.0
        curvatureSlider.doubleValue = 0.015
        vignetteSlider.doubleValue = 0.2
        
        // Update all labels
        sliderChanged(transitionSpeedSlider)
        sliderChanged(animationSpeedSlider)
        sliderChanged(distortionIntensitySlider)
        sliderChanged(scanlineIntensitySlider)
        sliderChanged(pixelSizeSlider)
        sliderChanged(curvatureSlider)
        sliderChanged(vignetteSlider)
        
        // Update enabled state
        crtToggled(crtEnabledCheckbox)
    }
    
    @objc private func cancelSheet(_ sender: Any) {
        if let window = window {
            // If this is a sheet, end it properly
            if let parent = window.sheetParent {
                parent.endSheet(window)
            } else {
                // Fallback for standalone window
                window.close()
            }
        }
    }
    
    @objc private func saveAndClose(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.set(backgroundPopUp.indexOfSelectedItem, forKey: "EarthboundBackgroundIndex")
        defaults.set(transitionSpeedSlider.doubleValue, forKey: "EarthboundTransitionSpeed")
        defaults.set(showNamesCheckbox.state == .on, forKey: "EarthboundShowNames")
        defaults.set(animationSpeedSlider.doubleValue, forKey: "EarthboundAnimationSpeed")
        defaults.set(distortionIntensitySlider.doubleValue, forKey: "EarthboundDistortionIntensity")
        defaults.set(crtEnabledCheckbox.state == .on, forKey: "EarthboundCRTEnabled")
        defaults.set(scanlineIntensitySlider.doubleValue, forKey: "EarthboundScanlineIntensity")
        defaults.set(pixelSizeSlider.doubleValue, forKey: "EarthboundPixelSize")
        defaults.set(curvatureSlider.doubleValue, forKey: "EarthboundCurvature")
        defaults.set(vignetteSlider.doubleValue, forKey: "EarthboundVignette")
        defaults.synchronize()
        
        if let window = window {
            // If this is a sheet, end it properly
            if let parent = window.sheetParent {
                parent.endSheet(window)
            } else {
                // Fallback for standalone window
                window.close()
            }
        }
    }
}

// Extension to check if UserDefaults key exists
extension UserDefaults {
    func objectExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }
}