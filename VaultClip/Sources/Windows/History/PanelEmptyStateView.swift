//
// PanelEmptyStateView — SwiftUI ContentUnavailable-style empty panel (U10).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import SwiftUI

struct PanelEmptyStateContent: View {
    let model: PanelEmptyStateModel
    var onPrimary: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: model.symbolName)
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(.secondary)
            Text(model.title)
                .font(.headline)
                .multilineTextAlignment(.center)
            if !model.description.isEmpty {
                Text(model.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
            if let title = model.primaryButtonTitle {
                Button(title) { onPrimary?() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

final class PanelEmptyStateHostView: NSView {
    private let hosting = NSHostingView(rootView: PanelEmptyStateContent(
        model: PanelEmptyStateModel(symbolName: "doc.on.clipboard", title: "", description: "", primaryButtonTitle: nil)
    ))
    var onPrimary: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        hosting.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: trailingAnchor),
            hosting.topAnchor.constraint(equalTo: topAnchor),
            hosting.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        isHidden = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    func apply(_ model: PanelEmptyStateModel?) {
        guard let model else {
            isHidden = true
            return
        }
        hosting.rootView = PanelEmptyStateContent(model: model, onPrimary: onPrimary)
        isHidden = false
    }
}
