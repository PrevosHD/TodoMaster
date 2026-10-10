//
//  KeyboardDismiss.swift
//  TodoMaster
//

import SwiftUI
import UIKit

extension View {
    /// Tippen außerhalb eines Textfelds schließt die Tastatur. Gilt fürs ganze Fenster, also auch für Sheets.
    func dismissesKeyboardOnTapOutside() -> some View {
        background(KeyboardDismissInstaller())
    }
}

private struct KeyboardDismissInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> InstallerView {
        InstallerView()
    }

    func updateUIView(_ uiView: InstallerView, context: Context) {}

    final class InstallerView: UIView, UIGestureRecognizerDelegate {
        private static var installedWindows = NSHashTable<UIWindow>.weakObjects()

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window, !Self.installedWindows.contains(window) else { return }
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            tap.cancelsTouchesInView = false
            tap.delegate = self
            window.addGestureRecognizer(tap)
            Self.installedWindows.add(window)
        }

        @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
            recognizer.view?.endEditing(true)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var view = touch.view
            while let current = view {
                if current is UITextField || current is UITextView { return false }
                view = current.superview
            }
            return true
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
