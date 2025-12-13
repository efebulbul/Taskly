//
//  LoginViewController+Layout.swift
//  Taskly
//
//  Created by EfeBülbül on 04.10.2025.
//

import UIKit

extension LoginViewController {

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

        let spacer1 = UIView(); spacer1.heightAnchor.constraint(equalToConstant: 8).isActive = true
        let spacer2 = UIView(); spacer2.heightAnchor.constraint(equalToConstant: 6).isActive = true

        let socialStack = UIStackView(arrangedSubviews: [appleButton, googleButton])
        socialStack.axis = .vertical
        socialStack.spacing = 10

        [logoView, titleLabel, subtitleLabel, spacer1, emailField, passwordField, signInButton, divider, socialStack, spacer2, registerLabel, footerLabel]
            .forEach { content.addArrangedSubview($0) }

        scroll.keyboardDismissMode = .interactive
    }

    func applyLocalizedTexts_Login() {
        subtitleLabel.text = L("login.subtitle")

        emailField.placeholder = L("login.email.placeholder")
        passwordField.placeholder = L("login.password.placeholder")

        signInButton.setTitle(L("login.signin"), for: .normal)

        if var cfg = googleButton.configuration {
            cfg.title = L("login.google")
            googleButton.configuration = cfg
        }

        if let h = divider.arrangedSubviews.compactMap({ $0 as? UILabel }).first {
            h.text = L("login.orcontinue")
        }

        registerLabel.text = L("login.noaccount")
        footerLabel.text = L("login.footer")
    }

    func applyBrandTitle() {
        let appBlue = UIColor(named: "AppBlue") ?? UIColor(red: 0/255, green: 111/255, blue: 255/255, alpha: 1)
        let baseFont = UIFont.systemFont(ofSize: 32, weight: .bold)

        let taskPart = NSAttributedString(string: "Task", attributes: [
            .font: baseFont,
            .foregroundColor: UIColor.label
        ])

        let lyPart = NSAttributedString(string: "ly", attributes: [
            .font: baseFont,
            .foregroundColor: appBlue
        ])

        let brandTitle = NSMutableAttributedString()
        brandTitle.append(taskPart)
        brandTitle.append(lyPart)

        titleLabel.attributedText = brandTitle
        titleLabel.accessibilityLabel = "Taskly"
    }

    func setupLanguageButton() {
        languageButton.addTarget(self, action: #selector(didTapLanguage), for: .touchUpInside)
        view.addSubview(languageButton)
        languageButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            languageButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            languageButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12)
        ])
    }
}
