#!/usr/bin/env swift

import Foundation
import ScreenSaver
import AppKit

// Test harness for automated screensaver testing
// This can be run directly from command line: swift TestHarness.swift

class ScreensaverTestHarness {
    private var bundle: Bundle?
    private var principalClass: AnyClass?
    private var screensaverView: ScreenSaverView?
    private var testWindow: NSWindow?
    private var testResults: [String: Bool] = [:]
    
    init() {
        // Initialize test environment
        print("🧪 EarthboundBattle Screensaver Test Harness")
        print("========================================")
    }
    
    func loadScreensaver(at path: String) -> Bool {
        print("\n📦 Loading screensaver bundle...")
        
        guard let bundle = Bundle(path: path) else {
            print("❌ Failed to load bundle at: \(path)")
            return false
        }
        
        self.bundle = bundle
        print("✅ Bundle loaded: \(bundle.bundleIdentifier ?? "unknown")")
        
        // Load the principal class
        guard bundle.load() else {
            print("❌ Failed to load bundle executable")
            return false
        }
        
        guard let principalClass = bundle.principalClass else {
            print("❌ No principal class found in bundle")
            return false
        }
        
        self.principalClass = principalClass
        print("✅ Principal class loaded: \(String(describing: principalClass))")
        
        return true
    }
    
    func testInitialization() -> Bool {
        print("\n🔬 Test 1: Initialization")
        print("-------------------------")
        
        guard let viewClass = principalClass as? ScreenSaverView.Type else {
            print("❌ Principal class is not a ScreenSaverView subclass")
            testResults["initialization"] = false
            return false
        }
        
        // Test preview mode initialization
        let previewFrame = NSRect(x: 0, y: 0, width: 800, height: 600)
        guard let previewView = viewClass.init(frame: previewFrame, isPreview: true) else {
            print("❌ Failed to initialize in preview mode")
            testResults["initialization"] = false
            return false
        }
        
        print("✅ Preview mode initialization successful")
        
        // Test full screen mode initialization
        guard let fullScreenView = viewClass.init(frame: previewFrame, isPreview: false) else {
            print("❌ Failed to initialize in full screen mode")
            testResults["initialization"] = false
            return false
        }
        
        self.screensaverView = fullScreenView
        print("✅ Full screen mode initialization successful")
        
        testResults["initialization"] = true
        return true
    }
    
    func testAnimation() -> Bool {
        print("\n🔬 Test 2: Animation")
        print("--------------------")
        
        guard let view = screensaverView else {
            print("❌ No screensaver view available")
            testResults["animation"] = false
            return false
        }
        
        // Start animation
        view.startAnimation()
        print("✅ Animation started")
        
        // Check if animation time interval is set
        let interval = view.animationTimeInterval
        if interval > 0 {
            print("✅ Animation interval set: \(interval) seconds")
        } else {
            print("⚠️  No animation interval set")
        }
        
        // Let it run briefly
        Thread.sleep(forTimeInterval: 0.5)
        
        // Stop animation
        view.stopAnimation()
        print("✅ Animation stopped")
        
        testResults["animation"] = true
        return true
    }
    
    func testConfiguration() -> Bool {
        print("\n🔬 Test 3: Configuration")
        print("------------------------")
        
        guard let view = screensaverView else {
            print("❌ No screensaver view available")
            testResults["configuration"] = false
            return false
        }
        
        if view.hasConfigureSheet {
            print("✅ Configuration sheet available")
            
            if let _ = view.configureSheet {
                print("✅ Configuration sheet can be created")
                testResults["configuration"] = true
                return true
            } else {
                print("⚠️  Configuration sheet creation returned nil")
                testResults["configuration"] = false
                return false
            }
        } else {
            print("ℹ️  No configuration sheet provided")
            testResults["configuration"] = true
            return true
        }
    }
    
    func testRendering() -> Bool {
        print("\n🔬 Test 4: Rendering")
        print("--------------------")
        
        guard let view = screensaverView else {
            print("❌ No screensaver view available")
            testResults["rendering"] = false
            return false
        }
        
        // Create an off-screen window for rendering test
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = view
        window.makeKeyAndOrderFront(nil)
        
        print("✅ View added to test window")
        
        // Start animation in window
        view.startAnimation()
        
        // Check if view has subviews (like SKView)
        if view.subviews.count > 0 {
            print("✅ View has \(view.subviews.count) subview(s)")
            
            // Check for SKView
            for subview in view.subviews {
                print("   - Subview type: \(type(of: subview))")
            }
        } else {
            print("⚠️  View has no subviews")
        }
        
        // Run briefly to allow rendering
        Thread.sleep(forTimeInterval: 1.0)
        
        view.stopAnimation()
        window.close()
        
        testResults["rendering"] = true
        return true
    }
    
    func testMemoryManagement() -> Bool {
        print("\n🔬 Test 5: Memory Management")
        print("----------------------------")
        
        guard let viewClass = principalClass as? ScreenSaverView.Type else {
            print("❌ Principal class is not a ScreenSaverView subclass")
            testResults["memory"] = false
            return false
        }
        
        // Create and destroy multiple instances
        var views: [ScreenSaverView] = []
        
        for i in 1...5 {
            if let view = viewClass.init(frame: NSRect(x: 0, y: 0, width: 800, height: 600), isPreview: false) {
                views.append(view)
                view.startAnimation()
                print("✅ Created instance \(i)")
            }
        }
        
        // Stop all animations
        for view in views {
            view.stopAnimation()
        }
        
        views.removeAll()
        print("✅ All instances cleaned up")
        
        testResults["memory"] = true
        return true
    }
    
    func runAllTests() {
        let bundlePath = "build/EarthboundBattle.saver"
        
        // Check if bundle exists
        if !FileManager.default.fileExists(atPath: bundlePath) {
            print("❌ Screensaver bundle not found at: \(bundlePath)")
            print("   Run ./build.sh first to build the screensaver")
            exit(1)
        }
        
        // Load the screensaver
        guard loadScreensaver(at: bundlePath) else {
            print("\n❌ Failed to load screensaver bundle")
            exit(1)
        }
        
        // Run tests
        let tests = [
            ("Initialization", testInitialization),
            ("Animation", testAnimation),
            ("Configuration", testConfiguration),
            ("Rendering", testRendering),
            ("Memory Management", testMemoryManagement)
        ]
        
        var passedTests = 0
        let totalTests = tests.count
        
        for (_, test) in tests {
            if test() {
                passedTests += 1
            }
        }
        
        // Print summary
        print("\n=====================================")
        print("📊 Test Summary")
        print("=====================================")
        
        for (name, result) in testResults {
            let status = result ? "✅ PASS" : "❌ FAIL"
            print("\(status) - \(name)")
        }
        
        print("\n🏁 Results: \(passedTests)/\(totalTests) tests passed")
        
        if passedTests == totalTests {
            print("🎉 All tests passed!")
            exit(0)
        } else {
            print("⚠️  Some tests failed")
            exit(1)
        }
    }
}

// Run the test harness
let harness = ScreensaverTestHarness()
harness.runAllTests()