//
//  AppDelegate.swift
//  SunscreenLauncher
//
//  Created by David Celis on 2/18/16.
//  Copyright © 2016 David Celis. All rights reserved.
//
//  The source code of this project is licensed under The MIT License. A copy of this license
//  can be found in the LICENSE file in the root of this repository.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let identifier = "com.davidcelis.Sunscreen"
        let running = NSWorkspace.shared.runningApplications
        var alreadyRunning = false

        for app in running {
            if app.bundleIdentifier == identifier {
                alreadyRunning = true
                break
            }
        }

        if !alreadyRunning {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(terminate), name: NSNotification.Name("killme"), object: identifier)

            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents

            // SunscreenLauncher.app lives at:
            // Sunscreen.app/Contents/Library/LoginItems/SunscreenLauncher.app
            // Remove last 4 components to reach Sunscreen.app
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.removeLast()

            let appPath = NSString.path(withComponents: components)
            let appURL = URL(fileURLWithPath: appPath)

            NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        } else {
            NSApp.terminate(nil)
        }
    }

    @objc func terminate() {
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {

    }
}

