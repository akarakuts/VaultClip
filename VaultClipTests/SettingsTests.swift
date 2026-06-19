//
//  SettingsTests.swift
//  VaultClipTests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip
import RxRelay
import RxSwift

class SettingsTests: XCTestCase {
    
    var old: [String: Any]!
    private var productionEnvironment: AppEnvironment!
    
    override func setUp() {
        old = UserDefaults.standard.blank()
        productionEnvironment = AppEnvironment.shared
        let isolated = Settings.loadPersisted()
        Settings.installShared(isolated)
        AppEnvironment.shared?.settings = isolated
    }

    override func tearDown() {
        UserDefaults.standard.restore(from: old)
        VaultClipTestSupport.reinstallSharedPointers(from: productionEnvironment)
        productionEnvironment = nil
    }
    
    func testDefaultSettings() {
        // 1. Given nothing
        
        // 2. Load the settings
        let settings = Settings.main
        
        // 3. Assert they are default values
//        XCTAssertEqual(settings!.panelPosition, Settings.default.panelPosition)
//        XCTAssertEqual(settings!.pasteboardChangeCount, Settings.default.pasteboardChangeCount)
        XCTAssertEqual(settings, Settings.default)
    }

    func testPersistentStorage() {
        // 1. Given settings
        var settings = Settings.main
        
        // 2. Set some things
        settings.panelPosition = .bottom
        settings.pasteboardChangeCount = 42
        Settings.main = settings
        // Retrieve the settings again
        settings = Settings.main
        
        // 3. Check they have been saved
        XCTAssertEqual(settings.panelPosition, .bottom)
        XCTAssertEqual(settings.pasteboardChangeCount, 42)
    }
    
    func testObserving() {
        // 1. Given fresh settings
        XCTAssertEqual(Settings.main.panelPosition, Settings.default.panelPosition)
        XCTAssertEqual(Settings.main.pasteboardChangeCount, Settings.default.pasteboardChangeCount)
        let disposeBag = DisposeBag()
        
        // 2. Bind settings to behaviour relays
        let panelPosition = BehaviorRelay<PanelPosition>(value: .right)
        Settings.main.bindPanelPositionTo(state: panelPosition).disposed(by: disposeBag)
        panelPosition.accept(.bottom)
        
        let pasteboardChangeCount = BehaviorRelay<Int>(value: -1)
        Settings.main.bindPasteboardChangeCountTo(state: pasteboardChangeCount.asObservable()).disposed(by: disposeBag)
        pasteboardChangeCount.accept(42)
        
        // 3. Check that the settings have been saved
        XCTAssertEqual(Settings.main.panelPosition, .bottom)
        XCTAssertEqual(Settings.main.pasteboardChangeCount, 42)
    }
}
