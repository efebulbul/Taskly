//
//  LoginViewController+Keyboard.swift
//  Taskly
//
//  Created by EfeBülbül on 13.12.2025.
//

import UIKit

extension LoginViewController {

    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(kbChange(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
    }

    @objc func kbChange(_ n: Notification) {
        guard let info = n.userInfo,
              let end = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let inset = max(0, view.bounds.maxY - end.origin.y) + 12
        scroll.contentInset.bottom = inset
        scroll.verticalScrollIndicatorInsets.bottom = inset
    }
}


extension LoginViewController {

    func setupDismissKeyboardGesture() {
        let tapDismiss = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapDismiss.cancelsTouchesInView = false
        view.addGestureRecognizer(tapDismiss)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
