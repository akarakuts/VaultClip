//
//  HelpViewController.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

class HelpViewController: NSViewController {
    
    var timer: Timer!
    
    @IBOutlet var waitingView: NSView!
    @IBOutlet var instructionsView: NSView!
    
    var hasControl = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hasControl = Helper.isControlGranted(showPopup: false)
        waitingView.isHidden = hasControl
        instructionsView.isHidden = !hasControl
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (t) in
            let new = Helper.isControlGranted(showPopup: false)
            if new != self.hasControl {
                self.hasControl = new
                self.waitingView.isHidden = self.hasControl
                self.instructionsView.isHidden = !self.hasControl
                
                self.updateSize()
            }
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        view.window?.title = L10n.helpWindowTitle
        updateSize()
    }
    
    func updateSize() {
        guard let window = view.window else { return }
        let size: NSSize
        if hasControl,
           let instructions = children.compactMap({ $0 as? HelpInstructionsViewController }).first {
            instructions.refreshContent()
            instructions.view.layoutSubtreeIfNeeded()
            let fitted = instructions.view.fittingSize
            size = NSSize(width: max(520, fitted.width), height: max(420, fitted.height))
        } else if hasControl {
            size = instructionsView.fittingSize
        } else {
            size = waitingView.fittingSize
        }
        window.setContentSize(size)
        window.center()
    }
}
