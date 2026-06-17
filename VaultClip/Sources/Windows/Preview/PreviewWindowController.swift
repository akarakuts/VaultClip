//
//  PreviewWindowController.swift
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

class PreviewWindowController: NSWindowController {
    
    var previewTextViewController: PreviewTextViewController!
    var previewImageViewController: PreviewImageViewController!
    var previewQLViewController: PreviewQLViewController!
    
    var disposeBag = DisposeBag()
    
    var previewItem: HistoryItem?
    
    private static func createPreviewViewController<T>(_: T.Type) -> T where T: PreviewViewController {
        return NSStoryboard.instantiateOrTerminate(identifier: T.sceneIdentifier)
    }

    static func create() -> PreviewWindowController {
        let window = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: true)
        window.level = NSWindow.Level(NSWindow.Level.mainMenu.rawValue - 1)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = false
        window.backgroundColor = .clear
        let previewWC = PreviewWindowController(window: window)

        previewWC.previewTextViewController = createPreviewViewController(PreviewTextViewController.self)
        previewWC.previewImageViewController = createPreviewViewController(PreviewImageViewController.self)
        previewWC.previewQLViewController = createPreviewViewController(PreviewQLViewController.self)
        
        State.main.showsRichText.distinctUntilChanged().subscribe(onNext: previewWC.onShowsRichText).disposed(by: previewWC.disposeBag)
        
        return previewWC
    }
    
    func subscribeTo(previewItem: BehaviorRelay<HistoryItem?>) -> Disposable {
        return previewItem
            .subscribe(onNext: {
                self.previewItem = $0
                if let item = $0 {
                    self.showWindow(nil)
                    self.updateController(forItem: item)
                }
                else {
                    self.close()
                }
            })
    }
    
    func updateController(forItem item: HistoryItem) {
        let controller = self.getViewController(forItem: item)
        self.contentViewController = controller
        window?.setFrame(controller.configureView(forItem: item), display: true)
    }
    
    func getViewController(forItem item: HistoryItem) -> PreviewViewController {
        if item.quickLookPreviewURL() != nil {
            return previewQLViewController
        }
        else if item.hasRasterImage() {
            return previewImageViewController
        }
        else {
            return previewTextViewController
        }
    }
    
    func onShowsRichText(_ showsRichText: Bool) {
        if let item = previewItem {
            previewTextViewController.isRichText = showsRichText
            if getViewController(forItem: item) is PreviewTextViewController {
                updateController(forItem: item)
            }
        }
    }
}
