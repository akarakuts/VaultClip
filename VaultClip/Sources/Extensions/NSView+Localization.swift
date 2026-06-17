import AppKit

extension NSView {

    /// Depth-first search for a subview with the given accessibility identifier.
    func descendantView(withAccessibilityIdentifier identifier: String) -> NSView? {
        if accessibilityIdentifier() == identifier { return self }
        for subview in subviews {
            if let match = subview.descendantView(withAccessibilityIdentifier: identifier) {
                return match
            }
        }
        return nil
    }
}
