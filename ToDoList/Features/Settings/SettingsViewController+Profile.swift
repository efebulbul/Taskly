import UIKit
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

extension SettingsViewController {

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

    func performAccountDeletion() {
        #if canImport(FirebaseAuth)
        guard let _ = Auth.auth().currentUser else {
            self.presentOK(title: L("common.error"), message: "No current user.")
            return
        }
        #endif
        #if canImport(FirebaseFirestore)
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(uid)

        db.collection("users").document(uid).collection("tasks").getDocuments { snap, _ in
            let batch = db.batch()
            snap?.documents.forEach { batch.deleteDocument($0.reference) }
            batch.deleteDocument(userDoc)
            batch.commit { [weak self] _ in
                guard let self = self else { return }
                #if canImport(FirebaseAuth)
                Auth.auth().currentUser?.delete(completion: { err in
                    DispatchQueue.main.async {
                        if let err = err as NSError?, err.code == AuthErrorCode.requiresRecentLogin.rawValue {
                            self.presentOK(title: L("auth.required.title"), message: Lf("auth.required.message", "Lütfen devam etmek için tekrar giriş yap."))
                            return
                        } else if let err = err {
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
                })
                #endif
            }
        }
        #else
        self.presentOK(title: L("common.error"), message: "Firestore not available in this build.")
        #endif
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
