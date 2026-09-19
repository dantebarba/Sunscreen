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
import ImageIO

/// An image view that records the file URL of the most recently dropped file so the
/// original wallpaper file can be copied verbatim instead of being re-encoded.
class WallpaperDropView: NSImageView {
    private(set) var lastDroppedFileURL: URL?

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL]
        lastDroppedFileURL = urls?.first
        return super.performDragOperation(sender)
    }
}

class PreferencesWindow: NSWindowController, NSWindowDelegate {
    let wallpapersPath = NSHomeDirectory()
    let fileManager = FileManager.default

    var onClose: (() -> Void)?

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

    func windowWillClose(_ notification: Notification) {
        onClose?()
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
        let defaults = UserDefaults.standard

        removeWallpaper(name)

        if let sourceURL = (sender as? WallpaperDropView)?.lastDroppedFileURL {
            copyDroppedFile(sourceURL, name: name)
        } else if let png = pngData(from: sender.image) {
            let path = "\(wallpapersPath)/\(UUID().uuidString).png"
            fileManager.createFile(atPath: path, contents: png, attributes: nil)
            defaults.set(path, forKey: "\(name)Wallpaper")
        }
    }

    private func copyDroppedFile(_ sourceURL: URL, name: String) {
        let ext = sourceURL.pathExtension
        let filename = ext.isEmpty ? UUID().uuidString : "\(UUID().uuidString).\(ext)"
        let destination = URL(fileURLWithPath: "\(wallpapersPath)/\(filename)")

        do {
            try fileManager.copyItem(at: sourceURL, to: destination)
            UserDefaults.standard.set(destination.path, forKey: "\(name)Wallpaper")
        } catch {
            NSLog("\(error)")
        }
    }

    private func pngData(from image: NSImage?) -> Data? {
        guard let tiff = image?.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }

    private func loadWallpaper(_ name: String, imageView: NSImageView) {
        let defaults = UserDefaults.standard

        guard let path = defaults.value(forKey: "\(name)Wallpaper") as? String else {
            return
        }

        let scale = imageView.window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        imageView.image = downsampledImage(atPath: path, fittingPointSize: imageView.bounds.size, scale: scale)
    }

    /// Loads a wallpaper file as a thumbnail sized to the preview's pixel dimensions,
    /// so a multi-megapixel image never gets decoded at full resolution for a small preview.
    private func downsampledImage(atPath path: String, fittingPointSize pointSize: NSSize, scale: CGFloat) -> NSImage? {
        let url = URL(fileURLWithPath: path)

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        let maxPixelSize = Int(max(pointSize.width, pointSize.height) * scale)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        let size = NSSize(width: CGFloat(thumbnail.width) / scale, height: CGFloat(thumbnail.height) / scale)
        return NSImage(cgImage: thumbnail, size: size)
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
