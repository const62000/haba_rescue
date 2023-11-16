import UIKit
import Flutter
import GoogleMaps


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set up Google Maps API key
    GMSServices.provideAPIKey("AIzaSyCr3FYiPyCXjAHl218A2r7fVLAOr08E544")


    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
