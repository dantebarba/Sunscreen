//
//  PreferencesWindow.swift
//  Sunscreen
//
//  Created by David Celis on 2/14/16.
//  Copyright © 2016 David Celis. All rights reserved.
//
//  The source code of this project is licensed under The MIT License. A copy of this license
//  can be found in the LICENSE file in the root of this repository.
//

import Cocoa
import ServiceManagement

class PreferencesWindow: NSWindowController {
    let wallpapersPath = NSHomeDirectory()
    let fileManager = FileManager.default

    @IBOutlet weak var sunriseImageView: NSImageView!
    @IBOutlet weak var morningImageView: NSImageView!
    @IBOutlet weak var afternoonImageView: NSImageView!
    @IBOutlet weak var sunsetImageView: NSImageView!
    @IBOutlet weak var nightImageView: NSImageView!
    @IBOutlet weak var startAtLoginButton: NSButton!

    override var windowNibName: NSNib.Name {
        return "PreferencesWindow"
    }

    override func windowDidLoad() {
        loadExistingWallpapers()

        let defaults = UserDefaults.standard

        switch defaults.bool(forKey: "launchAtLogin") {
        case true:
            startAtLoginButton.state = .on
        case false:
            startAtLoginButton.state = .off
        }
    }

    func loadExistingWallpapers() {
        loadWallpaper("sunrise", imageView: sunriseImageView)
        loadWallpaper("morning", imageView: morningImageView)
        loadWallpaper("afternoon", imageView: afternoonImageView)
        loadWallpaper("sunset", imageView: sunsetImageView)
        loadWallpaper("night", imageView: nightImageView)
    }

    @IBAction func sunriseImageDropped(_ sender: NSImageView) {
        imageDropped(sender, name: "sunrise")
    }

    @IBAction func morningImageDropped(_ sender: NSImageView) {
        imageDropped(sender, name: "morning")
    }

    @IBAction func afternoonImageDropped(_ sender: NSImageView) {
        imageDropped(sender, name: "afternoon")
    }

    @IBAction func sunsetImageDropped(_ sender: NSImageView) {
        imageDropped(sender, name: "sunset")
    }

    @IBAction func nightImageDropped(_ sender: NSImageView) {
        imageDropped(sender, name: "night")
    }

    @IBAction func startAtLoginClicked(_ sender: NSButton) {
        let identifier = "com.davidcelis.SunscreenLauncher"
        let defaults = UserDefaults.standard

        switch sender.state {
        case .on:
            defaults.set(true, forKey: "launchAtLogin")
            SMLoginItemSetEnabled(identifier as CFString, true)
        default:
            defaults.set(false, forKey: "launchAtLogin")
            SMLoginItemSetEnabled(identifier as CFString, false)
        }
    }

    private func imageDropped(_ sender: NSImageView, name: String) {
        let manager = FileManager.default
        let defaults = UserDefaults.standard
        let uuid = UUID().uuidString
        let path = "\(wallpapersPath)/\(uuid).png"

        // If there's an old image, delete it
        removeWallpaper(name)

        if let image = sender.image {
            let bmp = NSBitmapImageRep(data: image.tiffRepresentation!)
            let png = bmp!.representation(using: .png, properties: [:])
            manager.createFile(atPath: path, contents: png, attributes: nil)
            defaults.set(path, forKey: "\(name)Wallpaper")
        }
    }

    private func loadWallpaper(_ name: String, imageView: NSImageView) {
        let defaults = UserDefaults.standard

        if let path = defaults.value(forKey: "\(name)Wallpaper") as? String,
           let image = NSImage(byReferencingFile: path) {
            imageView.image = image
        }
    }

    private func removeWallpaper(_ name: String) {
        let manager = FileManager.default
        let defaults = UserDefaults.standard

        if let oldImagePath = defaults.value(forKey: "\(name)Wallpaper") as? String {
            do {
                try manager.removeItem(atPath: oldImagePath)
            } catch {
                NSLog("\(error)")
            }
        }
    }
}
