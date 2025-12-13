//
//  LoginViewController+Google.swift
//  Taskly
//
//  Created by EfeBülbül on 13.12.2025.
//

import UIKit

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

extension LoginViewController {

    func startGoogleSignIn() {
        #if canImport(GoogleSignIn)
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            showAlert("Google Sign-In", "clientID bulunamadı. GoogleService-Info.plist dosyasını kontrol et.")
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                print("Google Sign-In error:", error)
                self.showAlert("Giriş Hatası", error.localizedDescription)
                return
            }
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.showAlert("Giriş Hatası", "Google kimlik belirteci alınamadı.")
                return
            }
            let accessToken = user.accessToken.tokenString

            #if canImport(FirebaseAuth)
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let self = self else { return }
                if let error = error {
                    print("Firebase Google sign-in hata:", error)
                    self.showAlert("Giriş Hatası", error.localizedDescription)
                    return
                }

                #if canImport(FirebaseFirestore)
                if let uid = Auth.auth().currentUser?.uid {
                    let db = Firestore.firestore()
                    var profile: [String: Any] = ["updatedAt": FieldValue.serverTimestamp()]
                    if let email = authResult?.user.email ?? user.profile?.email { profile["email"] = email }
                    let display = authResult?.user.displayName ?? user.profile?.name
                    if let name = display { profile["displayName"] = name }
                    db.collection("users").document(uid).setData(["profile": profile], merge: true)
                }
                #endif

                NotificationCenter.default.post(name: .tasklyDidLogin, object: nil)
                self.dismiss(animated: true)
            }
            #else
            self.showAlert("Firebase Eksik", "FirebaseAuth modülü ekli değil. Lütfen FirebaseAuth'u hedefe bağla.")
            #endif
        }
        #else
        showAlert("Google Sign-In", "GoogleSignIn SDK ekli değil. Swift Package Manager ile 'GoogleSignIn' paketini ekleyin.")
        #endif
    }
}
