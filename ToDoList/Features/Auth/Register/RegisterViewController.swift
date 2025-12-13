//
//  RegisterViewController.swift
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

final class RegisterViewController: UIViewController {

    // MARK: - Localization helper
    func L(_ key: String) -> String { NSLocalizedString(key, comment: "") }

    func Lf(_ key: String, _ fallback: String) -> String {
        let v = NSLocalizedString(key, comment: "")
        return (v == key) ? fallback : v
    }

    // MARK: - UI
    let scroll = UIScrollView()
    let content = UIStackView()

    let logoView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "AppLogo"))
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(red: 0/255, green: 111/255, blue: 255/255, alpha: 1)
        iv.heightAnchor.constraint(equalToConstant: 84).isActive = true
        return iv
    }()

    let titleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Kayıt Ol"
        lb.font = .systemFont(ofSize: 32, weight: .bold)
        lb.textAlignment = .center
        return lb
    }()

    let subtitleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Yeni bir Taskly hesabı oluştur"
        lb.font = .preferredFont(forTextStyle: .subheadline)
        lb.textColor = .secondaryLabel
        lb.textAlignment = .center
        return lb
    }()

    let nameField: UITextField = RegisterViewController.makeField(placeholder: "Ad Soyad")
    let emailField: UITextField = RegisterViewController.makeField(placeholder: "E-posta", keyboard: .emailAddress)
    let passwordField: UITextField = RegisterViewController.makeField(placeholder: "Şifre", secure: true)
    let confirmField: UITextField = RegisterViewController.makeField(placeholder: "Şifreyi tekrar gir", secure: true)

    let signUpButton: UIButton = {
        let bt = UIButton(type: .system)
        bt.setTitle("Kayıt Ol", for: .normal)
        bt.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        bt.backgroundColor = UIColor(red: 0/255, green: 111/255, blue: 255/255, alpha: 1)
        bt.tintColor = .white
        bt.layer.cornerRadius = 12
        bt.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return bt
    }()

    let footerLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Zaten hesabın var mı? Giriş Yap"
        lb.font = .preferredFont(forTextStyle: .footnote)
        lb.textColor = UIColor(red: 0/255, green: 111/255, blue: 255/255, alpha: 1)
        lb.textAlignment = .center
        lb.isUserInteractionEnabled = true
        return lb
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) { overrideUserInterfaceStyle = .dark }
        view.backgroundColor = .black
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupLayout()
        applyLocalizedTexts_Register()

        signUpButton.addTarget(self, action: #selector(didTapSignUp), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(backToLogin))
        footerLabel.addGestureRecognizer(tap)

        wireDelegates()
        scroll.keyboardDismissMode = .interactive

        let tapDismiss = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapDismiss.cancelsTouchesInView = false
        view.addGestureRecognizer(tapDismiss)

        confirmField.returnKeyType = .done
    }
}
