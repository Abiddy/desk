//
//  AppDelegate.swift
//  HelpDeskCommunity
//
//  Created on Feb 12, 2026.
//

import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        configureTabBarAppearance()
        return true
    }

    /// Tab bar styling – must run on main thread at launch (no setImageInsets to avoid UIKit main-thread crash).
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        // Do NOT set UITabBarItem.appearance().imageInsets / titlePositionAdjustment here;
        // it can trigger setImageInsets: on UITabBarButtonLabel off the main thread and crash.
    }
}
