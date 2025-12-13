//
//  LoginViewController+Actions.swift
//  Taskly
//
//  Created by EfeBülbül on 04.10.2025.
//

import UIKit
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

extension LoginViewController {

    func wireActions() {
        signInButton.addTarget(self, action: #selector(didTapEmailSignIn), for: .touchUpInside)
        appleButton.addTarget(self, action: #selector(didTapApple), for: .touchUpInside)
        googleButton.addTarget(self, action: #selector(didTapGoogle), for: .touchUpInside)
    }

    @objc func didTapEmailSignIn() {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let pass = passwordField.text ?? ""

        guard email.contains("@"), pass.count >= 6 else {
            showAlert(
                Lf("auth.error.title", "Error"),
                Lf("auth.validation.missing", "Please enter a valid email and a password of at least 6 characters.")
            )
            return
        }

        #if canImport(FirebaseAuth)
        Auth.auth().signIn(withEmail: email, password: pass) { [weak self] result, error in
            guard let self = self else { return }
            if let err = error as NSError? {
                if err.code == AuthErrorCode.userNotFound.rawValue {
                    let ac = UIAlertController(
                        title: self.Lf("auth.userNotFound.title", "Account Not Found"),
                        message: self.Lf("auth.userNotFound.message", "No account exists with this email. Would you like to sign up?"),
                        preferredStyle: .alert
                    )
                    ac.addAction(UIAlertAction(title: self.L("common.cancel"), style: .cancel))
                    ac.addAction(UIAlertAction(title: self.L("register.signup"), style: .default, handler: { _ in
                        self.openRegister()
                    }))
                    self.present(ac, animated: true)
                } else if err.code == AuthErrorCode.wrongPassword.rawValue {
                    self.showAlert(
                        self.Lf("auth.wrongPassword.title", "Incorrect Password"),
                        self.Lf("auth.wrongPassword.message", "Please check your password and try again.")
                    )
                } else {
                    self.showAlert(self.Lf("auth.error.title", "Sign-in Error"), err.localizedDescription)
                }
                return
            }

            let name = result?.user.displayName ?? (email.components(separatedBy: "@").first?.capitalized ?? "User")
            let user = SettingsViewController.AppUser(
                name: name,
                email: email,
                avatar: UIImage(systemName: "person.crop.circle.fill")
            )
            SettingsViewController.UserSession.shared.currentUser = user
            self.dismiss(animated: true)
        }
        #else
        showAlert("Giriş Kullanılamıyor", "E-posta ile giriş için FirebaseAuth eklenmeli. Lütfen önce kayıt ol veya Google/Apple ile giriş seçeneklerini kullan.")
        #endif
    }

    @objc func didTapApple() {
        if #available(iOS 13.0, *) {
            startSignInWithAppleFlow()
        } else {
            showAlert(
                Lf("auth.unsupported.title", "Unsupported"),
                Lf("auth.unsupported.message", "This feature requires iOS 13 or later.")
            )
        }
    }

    @objc func didTapGoogle() {
        startGoogleSignIn()
    }

    func showAlert(_ t: String, _ m: String) {
        let ac = UIAlertController(title: t, message: m, preferredStyle: .alert)
        let okTitle = NSLocalizedString("settings.ok", comment: "OK button")
        ac.addAction(UIAlertAction(title: okTitle, style: .default))
        present(ac, animated: true)
    }

    @objc func openRegister() {
        let vc = RegisterViewController()
        vc.modalPresentationStyle = .formSheet
        present(vc, animated: true)
    }

    func presentSystemLanguageHintAndOpenSettings() {
        let title = L("lang.system.sheet.title")
        let message = L("lang.system.sheet.message")
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: L("lang.system.sheet.cancel"), style: .cancel))
        ac.addAction(UIAlertAction(title: L("lang.system.sheet.continue"), style: .default, handler: { _ in
            let urlStr = UIApplication.openSettingsURLString
            guard let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) else {
                self.showAlert(self.L("settings.language"), self.L("lang.system.unavailable"))
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }))
        present(ac, animated: true)
    }
}


extension LoginViewController {

    func setupRegisterTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(openRegister))
        registerLabel.addGestureRecognizer(tap)
    }

    @objc func didTapLanguage() {
        presentSystemLanguageHintAndOpenSettings()
    }
}
