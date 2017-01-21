//
//  AppDelegate.swift
//  CarDash
//
//  Created by Alexandre Blin on 12/06/2016.
//  Copyright © 2016 Alexandre Blin. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var dashboardViewController: DashboardViewController? {
        return self.window?.rootViewController?.storyboard?.instantiateViewController(withIdentifier: "DashboardViewController") as? DashboardViewController
    }

    var externalWindow: UIWindow?

    var sleepPreventer: MMPDeepSleepPreventer {
        return MMPDeepSleepPreventer()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        sleepPreventer.startPreventSleep()

        // Register for connect/disconnect notifications
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.screenDidConnect(_:)), name: NSNotification.Name.UIScreenDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.screenDidDisconnect(_:)), name: NSNotification.Name.UIScreenDidDisconnect, object: nil)

        // Setup external screen if it's already connected when starting the app
        if UIScreen.screens.count >= 2 {
            setupScreen(UIScreen.screens[1])
        }

        return true
    }

    func setupScreen(_ screen: UIScreen) {
        // Undocumented overscanCompensation value to disable it completely
        screen.overscanCompensation = UIScreenOverscanCompensation(rawValue: 3)!

        let window = UIWindow(frame: screen.bounds)
        window.screen = screen
        window.rootViewController = dashboardViewController
        window.isHidden = false
        window.makeKeyAndVisible()

        externalWindow = window
    }

    func screenDidConnect(_ notification: Notification) {
        guard let screen = notification.object as? UIScreen else {
            return
        }

        if UIScreen.screens.index(of: screen) == 1 {
            setupScreen(screen)
        }
    }

    func screenDidDisconnect(_ notification: Notification) {
        externalWindow?.isHidden = true
        externalWindow = nil
    }

}
