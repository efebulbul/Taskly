//
//  RegisterViewController+Delegates.swift
//  Taskly
//
//  Created by EfeBülbül on 13.12.2025.
//

import UIKit

extension RegisterViewController: UITextFieldDelegate {

    func wireDelegates() {
        nameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        confirmField.delegate = self
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameField:
            emailField.becomeFirstResponder()
        case emailField:
            passwordField.becomeFirstResponder()
        case passwordField:
            confirmField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
            didTapSignUp()
        }
        return true
    }
}
