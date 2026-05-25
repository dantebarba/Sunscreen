//
//  StatusMenuController.swift
//  Sunscreen
//
//  Created by David Celis on 2/13/16.
//  Copyright © 2016 David Celis. All rights reserved.
//  The source code of this project is licensed under The MIT License. A copy of this license
//  can be found in the LICENSE file in the root of this repository.
//

import Cocoa
import CoreLocation

class StatusMenuController: NSObject, CLLocationManagerDelegate {
    @IBOutlet weak var statusMenu: NSMenu!

    var preferencesWindow: PreferencesWindow!

    var currentLocation: CLLocation?
    var timer: Timer?

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let locationManager = CLLocationManager()

    override func awakeFromNib() {
        let icon = NSImage(named: "StatusIcon")
        icon?.isTemplate = true // Dark mode support

        statusItem.button?.image = icon
        statusItem.menu = statusMenu

        preferencesWindow = PreferencesWindow()

        locationManager.delegate = self

        switch locationManager.authorizationStatus {
        case .denied:
            showLocationServicesErrorForStatus(.denied)
        case .restricted:
            showLocationServicesErrorForStatus(.restricted)
        default:
            break
        }

        showPreferences()

        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }

    @IBAction func preferencesClicked(_ sender: NSMenuItem) {
        showPreferences()
    }

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()

        currentLocation = locations.last

        if timer == nil {
            timer = Timer(fireAt: Date(), interval: 60, target: self, selector: #selector(updateWallpaper), userInfo: nil, repeats: true)
            RunLoop.main.add(timer!, forMode: .common)

            let workspace = NSWorkspace.shared
            workspace.notificationCenter.addObserver(self, selector: #selector(updateWallpaper), name: NSWorkspace.activeSpaceDidChangeNotification, object: workspace)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()

        let alert = NSAlert()

        alert.messageText = "Location Unavailable"
        alert.informativeText = "Sunscreen requires your current location to calculate sunrise and sunset times, but we weren't able to get your location. Sorry about that!"
        alert.addButton(withTitle: "OK")

        alert.runModal()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .restricted, .denied:
            showLocationServicesErrorForStatus(manager.authorizationStatus)
        default:
            return
        }
    }

    @objc func updateWallpaper() {
        guard let location = currentLocation else { return }
        let times = SunCalculator.calculateTimes(Date(), latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)

        setWallpaper(times.currentPeriod)
    }

    private func setWallpaper(_ period: String) {
        let defaults = UserDefaults.standard

        if let path = defaults.value(forKey: "\(period)Wallpaper") as? String {
            let url = URL(fileURLWithPath: path)

            do {
                let workspace = NSWorkspace.shared

                for screen in NSScreen.screens {
                    try workspace.setDesktopImageURL(url, for: screen, options: workspace.desktopImageOptions(for: screen) ?? [:])
                }
            } catch {
                NSLog("\(error)")
            }
        }
    }

    private func showPreferences() {
        preferencesWindow.showWindow(nil)

        preferencesWindow.window?.center()
        preferencesWindow.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showLocationServicesErrorForStatus(_ authorizationStatus: CLAuthorizationStatus) {
        let alert = NSAlert()

        switch authorizationStatus {
        case .denied:
            alert.messageText = "Location Services Access Denied"
            alert.informativeText = "Sunscreen requires your current location to calculate sunrise and sunset times, but you denied access. Please open System Preferences to enable Location Services, and then re-open Sunscreen."
        case .restricted:
            alert.messageText = "Location Services Access Restricted"
            alert.informativeText = "Sunscreen requires Location Services access, but your account is restricted. Please contact a system administrator. Sunscreen will now exit."
        default:
            return
        }

        alert.addButton(withTitle: "OK")
        if alert.runModal() == .alertFirstButtonReturn {
            NSApp.terminate(nil)
        }
    }
}
