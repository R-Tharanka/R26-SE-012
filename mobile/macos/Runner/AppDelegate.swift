// =============================================================================
// File: AppDelegate.swift
// Purpose: Controls the desktop lifecycle of the macOS Flutter application.
// =============================================================================
import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Close the application when its final window closes.
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    // Allow macOS to restore the application state securely.
    return true
  }
}
