//
//  AboutViewController.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class AboutViewController: NSViewController {
    
    @IBOutlet var versionLabel: NSTextField!
    
    @IBOutlet var infoTextView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? ""
        let build = info["CFBundleVersion"] as? String ?? ""

        versionLabel.stringValue = "Version \(version) (\(build))"
        
        infoTextView.isAutomaticLinkDetectionEnabled = true
        // https://stackoverflow.com/a/25762502
        infoTextView.isEditable = true
        infoTextView.checkTextInDocument(nil)
        infoTextView.isEditable = false
    }
}
