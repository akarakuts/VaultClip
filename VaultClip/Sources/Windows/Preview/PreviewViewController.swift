//
//  PreviewViewController.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa
import RxSwift
import RxRelay

protocol PreviewViewController: NSViewController {
    
    static var sceneIdentifier: NSStoryboard.SceneIdentifier { get }
    
    /**
     Asks the view controller to configure the view, and return the desired window frame.
     
     - Parameter item: The item to configure the preview of.
     - Returns: The desired window frame
     */
    func configureView(forItem item: HistoryItem) -> NSRect
}
