import Cocoa

class ConfigureSheetController: NSWindowController {
    
    @IBOutlet weak var particleCountSlider: NSSlider!
    @IBOutlet weak var particleCountLabel: NSTextField!
    @IBOutlet weak var speedSlider: NSSlider!
    @IBOutlet weak var speedLabel: NSTextField!
    @IBOutlet weak var colorSchemePopup: NSPopUpButton!
    @IBOutlet weak var turbulenceCheckbox: NSButton!
    @IBOutlet weak var glowEffectCheckbox: NSButton!
    
    override var windowNibName: NSNib.Name? {
        return "ConfigureSheet"
    }
    
    override init(window: NSWindow?) {
        super.init(window: window)
        
        let bundle = Bundle(for: type(of: self))
        guard bundle.loadNibNamed("ConfigureSheet", owner: self, topLevelObjects: nil) else {
            createProgrammaticUI()
            return
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func createProgrammaticUI() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Particle Flow Settings"
        window.center()
        
        let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
        
        let titleLabel = NSTextField(labelWithString: "Particle Flow Configuration")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.frame = NSRect(x: 20, y: 250, width: 360, height: 30)
        contentView.addSubview(titleLabel)
        
        let particleLabel = NSTextField(labelWithString: "Particle Density:")
        particleLabel.frame = NSRect(x: 20, y: 200, width: 120, height: 20)
        contentView.addSubview(particleLabel)
        
        let particleSlider = NSSlider(value: 50, minValue: 10, maxValue: 200, target: self, action: #selector(particleCountChanged(_:)))
        particleSlider.frame = NSRect(x: 150, y: 200, width: 180, height: 20)
        contentView.addSubview(particleSlider)
        
        let particleValueLabel = NSTextField(labelWithString: "50")
        particleValueLabel.frame = NSRect(x: 340, y: 200, width: 40, height: 20)
        contentView.addSubview(particleValueLabel)
        self.particleCountLabel = particleValueLabel
        self.particleCountSlider = particleSlider
        
        let speedLabel = NSTextField(labelWithString: "Animation Speed:")
        speedLabel.frame = NSRect(x: 20, y: 160, width: 120, height: 20)
        contentView.addSubview(speedLabel)
        
        let speedSlider = NSSlider(value: 1.0, minValue: 0.1, maxValue: 3.0, target: self, action: #selector(speedChanged(_:)))
        speedSlider.frame = NSRect(x: 150, y: 160, width: 180, height: 20)
        contentView.addSubview(speedSlider)
        
        let speedValueLabel = NSTextField(labelWithString: "1.0x")
        speedValueLabel.frame = NSRect(x: 340, y: 160, width: 40, height: 20)
        contentView.addSubview(speedValueLabel)
        self.speedLabel = speedValueLabel
        self.speedSlider = speedSlider
        
        let colorLabel = NSTextField(labelWithString: "Color Scheme:")
        colorLabel.frame = NSRect(x: 20, y: 120, width: 120, height: 20)
        contentView.addSubview(colorLabel)
        
        let colorPopup = NSPopUpButton(frame: NSRect(x: 150, y: 118, width: 180, height: 25))
        colorPopup.addItems(withTitles: ["Neon Dreams", "Ocean Depths", "Sunset Glow", "Northern Lights", "Cosmic Dust"])
        contentView.addSubview(colorPopup)
        self.colorSchemePopup = colorPopup
        
        let turbulenceCheck = NSButton(checkboxWithTitle: "Enable Turbulence Fields", target: self, action: #selector(turbulenceToggled(_:)))
        turbulenceCheck.frame = NSRect(x: 20, y: 80, width: 200, height: 20)
        turbulenceCheck.state = .on
        contentView.addSubview(turbulenceCheck)
        self.turbulenceCheckbox = turbulenceCheck
        
        let glowCheck = NSButton(checkboxWithTitle: "Enable Glow Effect", target: self, action: #selector(glowToggled(_:)))
        glowCheck.frame = NSRect(x: 20, y: 50, width: 200, height: 20)
        glowCheck.state = .on
        contentView.addSubview(glowCheck)
        self.glowEffectCheckbox = glowCheck
        
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelClicked(_:)))
        cancelButton.frame = NSRect(x: 220, y: 10, width: 80, height: 30)
        contentView.addSubview(cancelButton)
        
        let okButton = NSButton(title: "OK", target: self, action: #selector(okClicked(_:)))
        okButton.frame = NSRect(x: 310, y: 10, width: 80, height: 30)
        okButton.keyEquivalent = "\r"
        contentView.addSubview(okButton)
        
        window.contentView = contentView
        self.window = window
        
        loadSettings()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        loadSettings()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        particleCountSlider?.integerValue = defaults.integer(forKey: "ParticleFlowParticleCount")
        if particleCountSlider?.integerValue == 0 {
            particleCountSlider?.integerValue = 50
        }
        particleCountLabel?.stringValue = "\(particleCountSlider?.integerValue ?? 50)"
        
        speedSlider?.doubleValue = defaults.double(forKey: "ParticleFlowSpeed")
        if speedSlider?.doubleValue == 0 {
            speedSlider?.doubleValue = 1.0
        }
        speedLabel?.stringValue = String(format: "%.1fx", speedSlider?.doubleValue ?? 1.0)
        
        colorSchemePopup?.selectItem(at: defaults.integer(forKey: "ParticleFlowColorScheme"))
        turbulenceCheckbox?.state = defaults.bool(forKey: "ParticleFlowTurbulence") ? .on : .off
        glowEffectCheckbox?.state = defaults.bool(forKey: "ParticleFlowGlow") ? .on : .off
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(particleCountSlider?.integerValue ?? 50, forKey: "ParticleFlowParticleCount")
        defaults.set(speedSlider?.doubleValue ?? 1.0, forKey: "ParticleFlowSpeed")
        defaults.set(colorSchemePopup?.indexOfSelectedItem ?? 0, forKey: "ParticleFlowColorScheme")
        defaults.set(turbulenceCheckbox?.state == .on, forKey: "ParticleFlowTurbulence")
        defaults.set(glowEffectCheckbox?.state == .on, forKey: "ParticleFlowGlow")
        defaults.synchronize()
    }
    
    @objc private func particleCountChanged(_ sender: NSSlider) {
        particleCountLabel?.stringValue = "\(sender.integerValue)"
    }
    
    @objc private func speedChanged(_ sender: NSSlider) {
        speedLabel?.stringValue = String(format: "%.1fx", sender.doubleValue)
    }
    
    @objc private func turbulenceToggled(_ sender: NSButton) {
    }
    
    @objc private func glowToggled(_ sender: NSButton) {
    }
    
    @objc private func cancelClicked(_ sender: NSButton) {
        window?.sheetParent?.endSheet(window!, returnCode: .cancel)
    }
    
    @objc private func okClicked(_ sender: NSButton) {
        saveSettings()
        window?.sheetParent?.endSheet(window!, returnCode: .OK)
    }
}