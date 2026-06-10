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
        
        updateSize()
    }
    
    func updateSize() {
        self.view.window?.setContentSize(self.hasControl ? instructionsView.fittingSize : waitingView.fittingSize)
        self.view.window?.center()
    }
}
