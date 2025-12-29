//
//  LoginViewController+Delegates.swift
//  Taskly
//
//  Created by EfeBülbül on 04.10.2025.
//
import UIKit
import ObjectiveC
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
import AuthenticationServices
import CryptoKit

extension SettingsViewController {

    // MARK: - Apple Reauth State (Associated Objects)
    private struct ReauthKeys {
        static var currentNonce: UInt8 = 0
        static var reauthCompletion: UInt8 = 0
    }

    private var currentNonce: String? {
        get { objc_getAssociatedObject(self, &ReauthKeys.currentNonce) as? String }
        set { objc_setAssociatedObject(self, &ReauthKeys.currentNonce, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var reauthCompletion: ((Bool, Error?) -> Void)? {
        get { objc_getAssociatedObject(self, &ReauthKeys.reauthCompletion) as? ((Bool, Error?) -> Void) }
        set { objc_setAssociatedObject(self, &ReauthKeys.reauthCompletion, newValue as Any, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if errorCode != errSecSuccess {
                // Fallback (should be extremely rare)
                return UUID().uuidString.replacingOccurrences(of: "-", with: "")
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func isAppleProviderUser() -> Bool {
        #if canImport(FirebaseAuth)
        let providers = Auth.auth().currentUser?.providerData.map { $0.providerID } ?? []
        return providers.contains("apple.com")
        #else
        return false
        #endif
    }

    /// Profil özet hücresi: avatar + ad (e-posta tap ile açılır). Giriş yoksa "Giriş Yap" görünümü.
    func buildProfileSummaryCell(_ tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "profileCell")
        var cfg = UIListContentConfiguration.subtitleCell()

        #if canImport(FirebaseAuth)
        if Auth.auth().currentUser != nil {
            cfg.text = resolvedDisplayName()
            cfg.secondaryText = ""
            cfg.image = UIImage(systemName: "person.circle.fill")
            cfg.imageProperties.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
            cfg.imageProperties.tintColor = .appBlue

            // Tap to open profile panel (name, email, sign out, delete)
            cell.gestureRecognizers?.forEach { cell.removeGestureRecognizer($0) }
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.presentProfilePanel))
            cell.addGestureRecognizer(tap)
            cell.isUserInteractionEnabled = true
            cell.accessoryView = nil

        } else {
            cfg.text = L("profile.signin")
            cfg.secondaryText = L("profile.signin.subtitle")
            cfg.image = UIImage(systemName: "person.crop.circle")
            cfg.imageProperties.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
            cfg.imageProperties.tintColor = .appBlue

            let loginButton = UIButton(type: .system)
            loginButton.setTitle(L("profile.signin"), for: .normal)
            loginButton.setTitleColor(.appBlue, for: .normal)
            loginButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            loginButton.addAction(UIAction { _ in
                self.presentLogin()
            }, for: .touchUpInside)
            cell.accessoryView = loginButton
        }
        #else
        cfg.text = L("profile.signin")
        cfg.secondaryText = L("profile.signin.subtitle")
        cfg.image = UIImage(systemName: "person.crop.circle")
        cfg.imageProperties.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
        cfg.imageProperties.tintColor = .Appblue
        #endif

        cfg.textProperties.font = .preferredFont(forTextStyle: .headline)
        cfg.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = cfg

        var bg = UIBackgroundConfiguration.listGroupedCell()
        bg.backgroundColor = .secondarySystemGroupedBackground
        cell.backgroundConfiguration = bg
        cell.layer.cornerRadius = 12
        cell.layer.masksToBounds = true

        return cell
    }

    // MARK: - Name resolution (UserSession → Auth → cached → email → fallback)
    func resolvedDisplayName() -> String {
        let sessionName = SettingsViewController.UserSession.shared.currentUser?.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let s = sessionName, !s.isEmpty { return s }
        #if canImport(FirebaseAuth)
        if let authName = Auth.auth().currentUser?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines), !authName.isEmpty {
            return authName
        }
        let authEmail = Auth.auth().currentUser?.email
        #else
        let authEmail: String? = nil
        #endif
        if let cached = cachedDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines), !cached.isEmpty {
            return cached
        }
        let email = SettingsViewController.UserSession.shared.currentUser?.email ?? cachedEmail ?? authEmail
        if let local = email?.split(separator: "@").first, !local.isEmpty {
            return String(local).capitalized
        }
        return Lf("profile.unknownName", "Bilinmiyor")
    }

    // MARK: - Account Deletion
    func presentAccountDeleteConfirm() {
        let title = Lf("account.delete.title", "Hesabı Sil")
        let msg = Lf("account.delete.message", "Bu işlem geri alınamaz. Tüm verilerin silinecek.")
        let ok = Lf("common.delete", "Sil")
        let cancel = L("common.cancel")
        let ac = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: cancel, style: .cancel))
        ac.addAction(UIAlertAction(title: ok, style: .destructive, handler: { _ in
            self.performAccountDeletion()
        }))
        present(ac, animated: true)
    }

    // MARK: - Reauthentication
    private func reauthenticateWithAppleIfPossible(completion: @escaping (Bool, Error?) -> Void) {
        // Only meaningful when FirebaseAuth exists and the current user is an Apple provider user.
        #if canImport(FirebaseAuth)
        guard isAppleProviderUser() else {
            completion(false, nil)
            return
        }

        self.reauthCompletion = completion

        let nonce = randomNonceString()
        self.currentNonce = nonce

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        // For reauth we don't need scopes; Apple may still prompt (Face ID/Touch ID/passcode).
        request.requestedScopes = []
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
        #else
        completion(false, nil)
        #endif
    }

    func performAccountDeletion() {
        #if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            self.presentOK(title: L("common.error"), message: "No current user.")
            return
        }
        let uid = user.uid
        #else
        self.presentOK(title: L("common.error"), message: "Auth not available in this build.")
        return
        #endif

        // Step 1: Ensure we have a recent login (otherwise Firebase returns requiresRecentLogin).
        // We test by attempting a lightweight delete later; if it fails we will reauth and retry.

        func runFirestoreCleanupThenDeleteUser() {
            #if canImport(FirebaseFirestore)
            let db = Firestore.firestore()
            let userDoc = db.collection("users").document(uid)

            db.collection("users").document(uid).collection("tasks").getDocuments { [weak self] snap, _ in
                guard let self = self else { return }

                let batch = db.batch()
                snap?.documents.forEach { batch.deleteDocument($0.reference) }
                batch.deleteDocument(userDoc)

                batch.commit { [weak self] _ in
                    guard let self = self else { return }

                    // Now delete the Auth user (should succeed if login is recent)
                    Auth.auth().currentUser?.delete { err in
                        DispatchQueue.main.async {
                            if let err = err as NSError?, err.code == AuthErrorCode.requiresRecentLogin.rawValue {
                                // Reauth (Face ID / Apple prompt) then retry the Auth delete ONLY.
                                self.reauthenticateWithAppleIfPossible { success, reauthErr in
                                    if !success {
                                        let msg = reauthErr?.localizedDescription ?? Lf("auth.required.message", "Lütfen devam etmek için tekrar giriş yap.")
                                        self.presentOK(title: L("auth.required.title"), message: msg)
                                        return
                                    }
                                    Auth.auth().currentUser?.delete { err2 in
                                        DispatchQueue.main.async {
                                            if let err2 = err2 {
                                                self.presentOK(title: L("common.error"), message: err2.localizedDescription)
                                                return
                                            }
                                            SettingsViewController.UserSession.shared.signOut()
                                            try? Auth.auth().signOut()
                                            self.tableView.reloadData()
                                            let login = LoginViewController()
                                            login.modalPresentationStyle = .fullScreen
                                            self.present(login, animated: true)
                                        }
                                    }
                                }
                                return
                            }

                            if let err = err {
                                self.presentOK(title: L("common.error"), message: err.localizedDescription)
                                return
                            }

                            SettingsViewController.UserSession.shared.signOut()
                            try? Auth.auth().signOut()
                            self.tableView.reloadData()
                            let login = LoginViewController()
                            login.modalPresentationStyle = .fullScreen
                            self.present(login, animated: true)
                        }
                    }
                }
            }
            #else
            DispatchQueue.main.async {
                self.presentOK(title: L("common.error"), message: "Firestore not available in this build.")
            }
            #endif
        }

        // First attempt: run cleanup and delete.
        // If delete fails with requiresRecentLogin, we reauth and retry delete.
        runFirestoreCleanupThenDeleteUser()
    }

    // MARK: - Profile actions
    @objc func showEmail(_ sender: UITapGestureRecognizer) {
        #if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else { return }
        let email = user.email ?? L("profile.email.missing")
        let alert = UIAlertController(title: L("profile.email.title"), message: email, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L("settings.ok"), style: .default))
        present(alert, animated: true)
        #endif
    }

    func presentLogin() {
        let login = LoginViewController()
        login.modalPresentationStyle = .fullScreen
        present(login, animated: true)
    }

    func presentSignOutConfirm() {
        let ac = UIAlertController(title: L("actions.signout"), message: L("signout.confirm.message"), preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: L("common.cancel"), style: .cancel))
        ac.addAction(UIAlertAction(title: L("actions.signout"), style: .destructive, handler: { _ in
            #if canImport(FirebaseAuth)
            do { try Auth.auth().signOut() } catch { print("SignOut error: \(error)") }
            #endif
            self.cachedDisplayName = nil
            self.cachedEmail = nil
            self.tableView.reloadData()

            let login = LoginViewController()
            login.modalPresentationStyle = .fullScreen
            DispatchQueue.main.async {
                self.present(login, animated: true)
            }
        }))
        present(ac, animated: true)
    }

    // MARK: - Profile Panel (sheet)
    @objc func presentProfilePanel() {
        let vc = ProfilePanelViewController()
        #if canImport(FirebaseAuth)
        if let user = (Auth.auth().currentUser) {
            vc.displayName = self.resolvedDisplayName()
            vc.email = user.email
        } else {
            vc.displayName = self.resolvedDisplayName()
            vc.email = cachedEmail
        }
        #else
        vc.displayName = self.resolvedDisplayName()
        vc.email = cachedEmail
        #endif
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        vc.host = self
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }

    // MARK: - Profile loading
    func updateProfileUI() {
        #if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            cachedDisplayName = nil
            cachedEmail = nil
            return
        }
        cachedDisplayName = user.displayName
        cachedEmail = user.email

        #if canImport(FirebaseFirestore)
        if cachedDisplayName == nil || cachedEmail == nil {
            Firestore.firestore().collection("users").document(user.uid).getDocument { [weak self] snap, _ in
                guard let self = self else { return }
                let dict = snap?.data()?["profile"] as? [String: Any]
                let displayFS = dict?["displayName"] as? String
                let emailFS = dict?["email"] as? String
                if self.cachedDisplayName == nil { self.cachedDisplayName = displayFS }
                if self.cachedEmail == nil { self.cachedEmail = emailFS }
                DispatchQueue.main.async { self.tableView.reloadData() }
            }
        }
        #endif
        #endif
    }

    @objc func handleDidLogin() {
        updateProfileUI()
        tableView.reloadData()
    }
}

#if canImport(FirebaseAuth)
extension SettingsViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            reauthCompletion?(false, nil)
            reauthCompletion = nil
            currentNonce = nil
            return
        }

        guard let nonce = currentNonce else {
            reauthCompletion?(false, nil)
            reauthCompletion = nil
            return
        }

        guard let identityToken = appleIDCredential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            let err = NSError(domain: "Taskly", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch Apple identity token."])
            reauthCompletion?(false, err)
            reauthCompletion = nil
            currentNonce = nil
            return
        }

        let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                      rawNonce: nonce,
                                                      fullName: appleIDCredential.fullName)

        Auth.auth().currentUser?.reauthenticate(with: credential) { [weak self] _, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.reauthCompletion?(error == nil, error)
                self.reauthCompletion = nil
                self.currentNonce = nil
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            self.reauthCompletion?(false, error)
            self.reauthCompletion = nil
            self.currentNonce = nil
        }
    }
}
#endif
