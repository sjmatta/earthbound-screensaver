import Cocoa

class ConfigureSheetController: NSWindowController {
    
    private var backgroundPopUp: NSPopUpButton!
    private var transitionSpeedSlider: NSSlider!
    private var transitionLabel: NSTextField!
    private var showNamesCheckbox: NSButton!
    
    override init(window: NSWindow?) {
        super.init(window: window)
        
        // Create window programmatically
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 350),
                             styleMask: [.titled, .closable],
                             backing: .buffered,
                             defer: false)
        window.title = "Earthbound Battle Backgrounds Settings"
        window.center()
        
        self.window = window
        
        // Create content view
        let contentView = NSView(frame: window.contentView!.bounds)
        
        // Title label
        let titleLabel = NSTextField(labelWithString: "Earthbound Battle Backgrounds")
        titleLabel.frame = NSRect(x: 20, y: 300, width: 460, height: 30)
        titleLabel.alignment = .center
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        contentView.addSubview(titleLabel)
        
        // Background selection
        let bgLabel = NSTextField(labelWithString: "Background:")
        bgLabel.frame = NSRect(x: 20, y: 250, width: 100, height: 20)
        contentView.addSubview(bgLabel)
        
        backgroundPopUp = NSPopUpButton(frame: NSRect(x: 130, y: 248, width: 350, height: 26))
        backgroundPopUp.addItem(withTitle: "Random (Cycle All)")
        backgroundPopUp.menu?.addItem(NSMenuItem.separator())
        
        let backgrounds = EarthboundBackground.getAllBackgrounds()
        for (index, bg) in backgrounds.enumerated() {
            backgroundPopUp.addItem(withTitle: "\(index + 1). \(bg.name)")
        }
        
        // Load saved preference
        let defaults = UserDefaults.standard
        let savedIndex = defaults.integer(forKey: "EarthboundBackgroundIndex")
        backgroundPopUp.selectItem(at: savedIndex)
        
        contentView.addSubview(backgroundPopUp)
        
        // Transition speed
        let speedLabel = NSTextField(labelWithString: "Transition Speed:")
        speedLabel.frame = NSRect(x: 20, y: 200, width: 120, height: 20)
        contentView.addSubview(speedLabel)
        
        transitionSpeedSlider = NSSlider(frame: NSRect(x: 150, y: 198, width: 250, height: 26))
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
        transitionLabel.frame = NSRect(x: 410, y: 200, width: 70, height: 20)
        transitionLabel.isEditable = false
        transitionLabel.isBordered = false
        transitionLabel.backgroundColor = NSColor.clear
        contentView.addSubview(transitionLabel)
        
        // Show background names checkbox
        showNamesCheckbox = NSButton(checkboxWithTitle: "Show background names", target: self, action: #selector(checkboxChanged(_:)))
        showNamesCheckbox.frame = NSRect(x: 20, y: 150, width: 200, height: 20)
        showNamesCheckbox.state = defaults.bool(forKey: "EarthboundShowNames") ? .on : .off
        contentView.addSubview(showNamesCheckbox)
        
        // Info text
        let infoText = NSTextField(wrappingLabelWithString: "Experience the iconic battle backgrounds from Earthbound/Mother 2, featuring 327 unique layer patterns with procedural distortion effects.")
        infoText.frame = NSRect(x: 20, y: 70, width: 460, height: 60)
        infoText.alignment = .center
        infoText.font = NSFont.systemFont(ofSize: 11)
        contentView.addSubview(infoText)
        
        // Button bar
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelSheet(_:)))
        cancelButton.frame = NSRect(x: 310, y: 20, width: 80, height: 30)
        cancelButton.bezelStyle = .rounded
        contentView.addSubview(cancelButton)
        
        let okButton = NSButton(title: "OK", target: self, action: #selector(saveAndClose(_:)))
        okButton.frame = NSRect(x: 400, y: 20, width: 80, height: 30)
        okButton.bezelStyle = .rounded
        okButton.keyEquivalent = "\r"
        contentView.addSubview(okButton)
        
        window.contentView = contentView
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc private func sliderChanged(_ sender: NSSlider) {
        transitionLabel.stringValue = "\(Int(sender.doubleValue)) seconds"
    }
    
    @objc private func checkboxChanged(_ sender: NSButton) {
        // Update will be saved when OK is clicked
    }
    
    @objc private func cancelSheet(_ sender: Any) {
        window?.close()
    }
    
    @objc private func saveAndClose(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.set(backgroundPopUp.indexOfSelectedItem, forKey: "EarthboundBackgroundIndex")
        defaults.set(transitionSpeedSlider.doubleValue, forKey: "EarthboundTransitionSpeed")
        defaults.set(showNamesCheckbox.state == .on, forKey: "EarthboundShowNames")
        defaults.synchronize()
        
        window?.close()
    }
}