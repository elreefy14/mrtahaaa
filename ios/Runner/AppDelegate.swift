import Flutter
import GoogleMaps
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Provide the Google Maps API key
        GMSServices.provideAPIKey("AIzaSyBCUdcDFvWmHDl94vcWToYa5vD3ukF8rG8")

        // Set up notifications
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
        }

        // Register FlutterLocalNotificationsPlugin
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }

        // Register all the plugins with the Flutter engine
        GeneratedPluginRegistrant.register(with: self)

        // Register RetrytechPlugin manually if necessary


        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}