//
//  PreviewImageViewController.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class PreviewImageViewController: NSViewController, PreviewViewController {
    
    static let sceneIdentifier = NSStoryboard.SceneIdentifier(stringLiteral: "PreviewImageViewController")
    
    private let imageView = NSImageView(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(imageView)
        
        view.wantsLayer = true
        view.layer?.cornerRadius = 10
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // See: https://stackoverflow.com/a/24323553
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    func configureView(forItem item: HistoryItem) -> NSRect {
        // TODO: Fix with "Missing image" image
        let image = item.getImage() ?? NSImage(size: NSSize(width: 0, height: 0))
        imageView.image = image
        return calculateWindowFrame(forImage: image)
    }
    
    func calculateWindowFrame(forImage image: NSImage) -> NSRect {
        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenFrame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1024, height: 768)
        let maxWindowWidth = screenFrame.width * 0.8
        let maxWindowHeight = screenFrame.height * 0.8
        
        var windowWidth: CGFloat = 0
        var windowHeight: CGFloat = 0
        
        if image.size.width > image.size.height {
            windowWidth = min(maxWindowWidth, image.size.width)
            windowHeight = windowWidth * image.size.height/image.size.width
        }
        else {
            windowHeight = min(maxWindowHeight, image.size.height)
            windowWidth = windowHeight * image.size.width/image.size.height
        }
        
        let center = NSPoint(x: screenFrame.midX - windowWidth / 2, y: screenFrame.midY - windowHeight / 2)
        
        return NSRect(origin: center, size: NSSize(width: windowWidth, height: windowHeight))
    }
}
