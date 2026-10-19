// =============================================================================
// File: MainFlutterWindow.swift
// Purpose: Creates the macOS window that displays the Flutter interface.
// =============================================================================
import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // Attach a Flutter view controller and register desktop plugins.
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
