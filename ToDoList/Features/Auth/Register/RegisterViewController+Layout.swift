//
//  RegisterViewController+Layout.swift
//  Taskly
//
//  Created by EfeBülbül on 13.12.2025.
//

import UIKit

extension RegisterViewController {

    func setupLayout() {
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        scroll.addSubview(content)
        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 14
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 24),
            content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40)
        ])

        let spacer = UIView(); spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true

        [logoView, titleLabel, subtitleLabel, spacer, nameField, emailField, passwordField, confirmField, signUpButton, footerLabel]
            .forEach { content.addArrangedSubview($0) }
    }

    func applyLocalizedTexts_Register() {
        titleLabel.text = L("register.title")
        subtitleLabel.text = L("register.subtitle")

        nameField.placeholder = L("register.name.placeholder")
        emailField.placeholder = L("register.email.placeholder")
        passwordField.placeholder = L("register.password.placeholder")
        confirmField.placeholder = L("register.confirm.placeholder")

        signUpButton.setTitle(L("register.signup"), for: .normal)
        footerLabel.text = L("register.footer")
    }

    static func makeField(placeholder: String, keyboard: UIKeyboardType = .default, secure: Bool = false) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.autocapitalizationType = .none
        tf.keyboardType = keyboard
        tf.isSecureTextEntry = secure
        tf.returnKeyType = .next
        tf.clearButtonMode = .whileEditing
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.separator.cgColor
        tf.backgroundColor = .secondarySystemBackground
        tf.heightAnchor.constraint(equalToConstant: 48).isActive = true
        tf.setLeftPadding(14)
        return tf
    }
}
