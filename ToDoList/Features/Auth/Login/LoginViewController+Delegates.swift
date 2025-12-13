//
//  LoginViewController+Delegates.swift
//  Taskly
//
//  Created by EfeBülbül on 04.10.2025.
//

import UIKit
import AuthenticationServices

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

extension LoginViewController: UITextFieldDelegate {

    func wireDelegates() {
        emailField.delegate = self
        passwordField.delegate = self
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField { passwordField.becomeFirstResponder() }
        else { textField.resignFirstResponder(); didTapEmailSignIn() }
        return true
    }

    @objc func didRegister(_ note: Notification) {
        if let email = note.userInfo?["email"] as? String {
            emailField.text = email
            passwordField.becomeFirstResponder()
        }
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {

        guard let appleID = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        guard let nonce = currentNonce else {
            assertionFailure("Nonce kayıp")
            return
        }
        guard let tokenData = appleID.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            print("identityToken alınamadı.")
            showAlert(
                Lf("auth.error.title", "Sign-in Error"),
                Lf("auth.apple.missingToken", "Could not retrieve Apple identity token.")
            )
            return
        }

        #if canImport(FirebaseAuth)
        let credential = OAuthProvider.appleCredential(withIDToken: idToken,
                                                      rawNonce: nonce,
                                                      fullName: appleID.fullName)

        Auth.auth().signIn(with: credential) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                print("Firebase Apple sign-in hata:", error)
                self.showAlert("Giriş Hatası", error.localizedDescription)
                return
            }

            if let fn = appleID.fullName,
               (fn.givenName?.isEmpty == false || fn.familyName?.isEmpty == false) {
                let display = [fn.givenName, fn.familyName].compactMap { $0 }.joined(separator: " ")
                let change = Auth.auth().currentUser?.createProfileChangeRequest()
                change?.displayName = display
                change?.commitChanges(completion: nil)
            }

            #if canImport(FirebaseFirestore)
            if let uid = Auth.auth().currentUser?.uid {
                let db = Firestore.firestore()
                var profile: [String: Any] = ["updatedAt": FieldValue.serverTimestamp()]

                let curEmail = Auth.auth().currentUser?.email ?? appleID.email
                if let email = curEmail { profile["email"] = email }

                let appleFullName: String? = {
                    if let fn = appleID.fullName, (fn.givenName?.isEmpty == false || fn.familyName?.isEmpty == false) {
                        return [fn.givenName, fn.familyName].compactMap { $0 }.joined(separator: " ")
                    }
                    return nil
                }()
                let computedName = Auth.auth().currentUser?.displayName
                    ?? appleFullName
                    ?? curEmail?.components(separatedBy: "@").first?.capitalized
                    ?? "User"
                profile["displayName"] = computedName

                db.collection("users").document(uid).setData(["profile": profile], merge: true)
            }
            #endif

            DispatchQueue.main.async {
                let curEmail = Auth.auth().currentUser?.email ?? appleID.email ?? ""
                let appleFullName: String? = {
                    if let fn = appleID.fullName, (fn.givenName?.isEmpty == false || fn.familyName?.isEmpty == false) {
                        return [fn.givenName, fn.familyName].compactMap { $0 }.joined(separator: " ")
                    }
                    return nil
                }()
                let displayNow = Auth.auth().currentUser?.displayName
                    ?? appleFullName
                    ?? curEmail.components(separatedBy: "@").first?.capitalized
                    ?? "User"

                let appUser = SettingsViewController.AppUser(
                    name: displayNow,
                    email: curEmail,
                    avatar: UIImage(systemName: "person.crop.circle.fill")
                )
                SettingsViewController.UserSession.shared.currentUser = appUser

                if let u = Auth.auth().currentUser, (u.displayName == nil || u.displayName?.isEmpty == true) {
                    let change = u.createProfileChangeRequest()
                    change.displayName = displayNow
                    change.commitChanges(completion: nil)
                }

                NotificationCenter.default.post(name: .init("Taskly.UserSessionDidUpdate"), object: nil)
                NotificationCenter.default.post(name: .tasklyDidLogin, object: nil)
                self.dismiss(animated: true)
            }
        }
        #else
        showAlert("Firebase Eksik", "FirebaseAuth modülü ekli değil. Lütfen FirebaseAuth'u hedefe bağla.")
        #endif
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        if let ae = error as? ASAuthorizationError, ae.code == .canceled { return }
        print("Apple sign-in başarısız:", error)
        showAlert(Lf("auth.error.title", "Sign-in Error"), error.localizedDescription)
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        view.window ?? ASPresentationAnchor()
    }
}

