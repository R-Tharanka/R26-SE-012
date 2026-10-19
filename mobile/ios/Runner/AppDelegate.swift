// =============================================================================
// File: AppDelegate.swift
// Purpose: Starts the Flutter application and registers its iOS plugins.
// =============================================================================
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Pass application startup to Flutter's app delegate.
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Register plugins after Flutter creates its implicit engine.
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
