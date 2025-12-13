//
//  LoginViewController.swift
//  Taskly
//
//  Created by EfeBülbül on 13.12.2025.
//

import UIKit
import AuthenticationServices
import CryptoKit
import WebKit
import SwiftUI

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

#Preview {
  ViewControllerPreview {
    LoginViewController()
  }
}

final class LoginViewController: UIViewController {

    // MARK: - Localization helper
    func L(_ key: String) -> String { NSLocalizedString(key, comment: "") }

    func Lf(_ key: String, _ fallback: String) -> String {
        let v = NSLocalizedString(key, comment: "")
        return (v == key) ? fallback : v
    }

    // MARK: - UI
    let scroll = UIScrollView()
    let content = UIStackView()

    // Apple Sign In nonce (replay-attack koruması)
    var currentNonce: String?

    let logoView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "AppLogo"))
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(red: 0/255, green: 111/255, blue: 255/255, alpha: 1)
        iv.heightAnchor.constraint(equalToConstant: 84).isActive = true
        return iv
    }()

    let titleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Taskly"
        lb.font = .systemFont(ofSize: 32, weight: .bold)
        lb.textAlignment = .center
        return lb
    }()

    let subtitleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Hızlı, sade ve odaklı görev yönetimi"
        lb.font = .preferredFont(forTextStyle: .subheadline)
        lb.textColor = .secondaryLabel
        lb.textAlignment = .center
        return lb
    }()

    let emailField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "E-posta"
        tf.autocapitalizationType = .none
        tf.keyboardType = .emailAddress
        tf.returnKeyType = .next
        tf.clearButtonMode = .whileEditing
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.separator.cgColor
        tf.backgroundColor = .secondarySystemBackground
        tf.heightAnchor.constraint(equalToConstant: 48).isActive = true
        tf.setLeftPadding(14)
        return tf
    }()

    let passwordField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Şifre"
        tf.isSecureTextEntry = true
        tf.returnKeyType = .done
        tf.clearButtonMode = .whileEditing
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.separator.cgColor
        tf.backgroundColor = .secondarySystemBackground
        tf.heightAnchor.constraint(equalToConstant: 48).isActive = true
        tf.setLeftPadding(14)
        return tf
    }()

    let signInButton: UIButton = {
        let bt = UIButton(type: .system)
        bt.setTitle("Giriş Yap", for: .normal)
        bt.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        bt.backgroundColor = UIColor(red: 0/255, green: 111/255, blue: 255/255, alpha: 1)
        bt.tintColor = .white
        bt.layer.cornerRadius = 12
        bt.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return bt
    }()

    let divider: UIStackView = {
        let l = UIView(); l.backgroundColor = .separator; l.heightAnchor.constraint(equalToConstant: 1).isActive = true
        let r = UIView(); r.backgroundColor = .separator; r.heightAnchor.constraint(equalToConstant: 1).isActive = true
        let lbl = UILabel()
        lbl.text = "veya bununla devam et"
        lbl.font = .preferredFont(forTextStyle: .footnote)
        lbl.textColor = .secondaryLabel
        let h = UIStackView(arrangedSubviews: [l, lbl, r])
        h.axis = .horizontal
        h.spacing = 12
        h.alignment = .center
        l.widthAnchor.constraint(equalTo: r.widthAnchor).isActive = true
        return h
    }()

    let appleButton: ASAuthorizationAppleIDButton = {
        let b = ASAuthorizationAppleIDButton(type: .signIn, style: .whiteOutline)
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
        b.cornerRadius = 12
        return b
    }()

    let googleButton: UIButton = {
        let bt = UIButton(type: .system)
        var cfg = UIButton.Configuration.tinted()
        cfg.baseBackgroundColor = .systemBackground
        cfg.baseForegroundColor = UIColor(red: 0/255, green: 111/255, blue: 255/255, alpha: 1)
        cfg.cornerStyle = .large
        cfg.title = "Google ile devam et"
        cfg.image = UIImage(systemName: "globe")
        cfg.imagePadding = 8
        bt.configuration = cfg
        bt.layer.borderWidth = 1
        bt.layer.borderColor = UIColor.separator.cgColor
        bt.layer.cornerRadius = 12
        bt.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return bt
    }()

    let footerLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Devam ederek Gizlilik Politikası ve Kullanım Şartları’nı kabul etmiş olursun."
        lb.font = .preferredFont(forTextStyle: .caption2)
        lb.textColor = .secondaryLabel
        lb.numberOfLines = 0
        lb.textAlignment = .center
        return lb
    }()

    let registerLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Hesabın yok mu? Kayıt Ol"
        lb.font = .preferredFont(forTextStyle: .footnote)
        lb.textColor = UIColor(red: 0/255, green: 111/255, blue: 255/255, alpha: 1)
        lb.textAlignment = .center
        lb.isUserInteractionEnabled = true
        return lb
    }()

    let languageButton: UIButton = {
        let b = UIButton(type: .system)

        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.title = NSLocalizedString("settings.language", comment: "")
            config.image = UIImage(systemName: "globe")
            config.imagePadding = 6
            config.baseForegroundColor = .appBlue
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 12)
            config.background.backgroundColor = .secondarySystemBackground
            config.background.cornerRadius = 10
            b.configuration = config
        } else {
            if let img = UIImage(systemName: "globe") {
                b.setImage(img, for: .normal)
                b.tintColor = .appBlue
            }
            b.setTitle(NSLocalizedString("settings.language", comment: ""), for: .normal)
            b.setTitleColor(.appBlue, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 12)
            b.layer.cornerRadius = 10
            b.backgroundColor = .secondarySystemBackground
        }

        b.accessibilityIdentifier = "login.language.button"
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) { overrideUserInterfaceStyle = .dark }
        view.backgroundColor = .black
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupLayout()
        applyLocalizedTexts_Login()
        applyBrandTitle()

        wireActions()
        wireDelegates()
        registerForKeyboardNotifications()
        setupDismissKeyboardGesture()
        setupRegisterTap()
        setupLanguageButton()

        NotificationCenter.default.addObserver(self, selector: #selector(didRegister(_:)), name: .tasklyDidRegister, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}
