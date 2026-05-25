//
//  AppDelegate.swift
//  Sunscreen
//
//  Created by David Celis on 2/13/16.
//  Copyright © 2016 David Celis. All rights reserved.
//
//  The source code of this project is licensed under The MIT License. A copy of this license
//  can be found in the LICENSE file in the root of this repository.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let identifier = "com.davidcelis.SunscreenLauncher"
        var startedAtLogin = false

        for app in NSWorkspace.shared.runningApplications {
            if app.bundleIdentifier == identifier {
                startedAtLogin = true
            }
        }

        if startedAtLogin {
            DistributedNotificationCenter.default().postNotificationName(NSNotification.Name("killme"), object: Bundle.main.bundleIdentifier!)
        }

        let defaults = UserDefaults.standard

        if defaults.bool(forKey: "launchAtLogin") {
            SMLoginItemSetEnabled(identifier as CFString, true)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

