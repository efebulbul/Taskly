//
//  RegisterViewController+Actions.swift
//  Taskly
//
//  Created by EfeBülbül on 13.12.2025.
//

import UIKit

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseCore)
import FirebaseCore
#endif

extension RegisterViewController {

    @objc func didTapSignUp() {
        guard let email = emailField.text, email.contains("@"),
              let pass = passwordField.text, pass.count >= 6,
              pass == confirmField.text else {
            showAlert("Hata", "Geçerli e-posta ve eşleşen en az 6 karakterli şifre girin.")
            return
        }

        let displayName = nameField.text?.isEmpty == false
        ? nameField.text!
        : (email.components(separatedBy: "@").first?.capitalized ?? "Kullanıcı")

        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            showAlert("Firebase Bağlı Değil", "FirebaseApp.configure() çalışmıyor. AppDelegate içinde FirebaseApp.configure() çağrısını ve GoogleService-Info.plist dosyasını kontrol et.")
            return
        }
        #endif

        #if canImport(FirebaseAuth)
        Auth.auth().createUser(withEmail: email, password: pass) { [weak self] result, error in
            guard let self = self else { return }

            if let err = error as NSError? {
                if Auth.auth().currentUser != nil {
                    NotificationCenter.default.post(name: .tasklyDidRegister, object: nil, userInfo: ["email": email])
                    self.showAlert("Kayıt Başarılı", "Hesabın oluşturuldu. Lütfen giriş yap ekranından oturum aç.")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.dismiss(animated: true) }
                    return
                }

                switch err.code {
                case AuthErrorCode.emailAlreadyInUse.rawValue:
                    NotificationCenter.default.post(name: .tasklyDidRegister, object: nil, userInfo: ["email": email])
                    self.showAlert(self.Lf("register.error.title", "Error"),
                                   self.Lf("register.error.emailInUse", "This email address is already in use."))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.dismiss(animated: true) }
                case AuthErrorCode.invalidEmail.rawValue:
                    self.showAlert("Geçersiz E-posta", "Lütfen geçerli bir e-posta adresi gir.")
                case AuthErrorCode.weakPassword.rawValue:
                    self.showAlert("Zayıf Şifre", "Şifren en az 6 karakter olmalı.")
                case AuthErrorCode.networkError.rawValue:
                    self.showAlert("Ağ Hatası", "İnternet bağlantını kontrol edip tekrar dene.")
                default:
                    self.showAlert("Kayıt Hatası", err.localizedDescription)
                }
                return
            }

            if let user = result?.user {
                let change = user.createProfileChangeRequest()
                change.displayName = displayName
                change.commitChanges { _ in
                    NotificationCenter.default.post(name: .tasklyDidRegister, object: nil, userInfo: ["email": email])
                    self.showAlert("Kayıt Başarılı", "Hesabın oluşturuldu. Lütfen giriş yap ekranından oturum aç.")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.dismiss(animated: true) }
                }
            } else {
                NotificationCenter.default.post(name: .tasklyDidRegister, object: nil, userInfo: ["email": email])
                self.showAlert("Kayıt Başarılı", "Hesabın oluşturuldu. Lütfen giriş yap ekranından oturum aç.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.dismiss(animated: true) }
            }
        }
        #else
        NotificationCenter.default.post(name: .tasklyDidRegister, object: nil, userInfo: ["email": email])
        showAlert("Demo Kayıt", "FirebaseAuth yüklü değil; kayıt sadece yerelde oluşturuldu. Giriş yap ekranından oturum açmayı dene.")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.dismiss(animated: true) }
        #endif
    }

    @objc func backToLogin() {
        dismiss(animated: true)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func showAlert(_ title: String, _ message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okTitle = NSLocalizedString("settings.ok", comment: "OK button")
        ac.addAction(UIAlertAction(title: okTitle, style: .default))
        present(ac, animated: true)
    }
}
