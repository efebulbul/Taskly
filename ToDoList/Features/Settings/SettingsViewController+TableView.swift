//
//  SettingsViewController+TableView.swift
//  Taskly
//
//  Created by EfeBülbül on 04.10.2025.
//
import UIKit
import UserNotifications
import StoreKit
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

extension SettingsViewController {

    // MARK: - Table sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        // 0: Profile, 1: General Preferences, 2: Support & Info
        return 3
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: // Profile
            #if canImport(FirebaseAuth)
            if Auth.auth().currentUser != nil {
                return ProfileRow.allCases.count
            } else {
                return 1 // sadece özet hücresi (içinde “Giriş Yap” görünümü)
            }
            #else
            return 1
            #endif

        case 1: // General Preferences
            // Dil, Tema, Bildirimler
            return 3

        case 2: // Support & Info
            // Bizi değerlendirin, Destek & Geri Bildirim, Gizlilik & Şartlar
            return 3

        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return L("settings.section.generalPreferences").uppercased()
        case 2:
            return L("settings.section.supportInfo").uppercased()
        default:
            return nil
        }
    }


    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == tableView.numberOfSections - 1 else { return nil }

        let ver = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"

        let label = UILabel()
        label.text = "Version \(ver)"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel

        let container = UIView()
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == tableView.numberOfSections - 1 ? 44 : .leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.section {
        case 0: // Profile
            return buildProfileSummaryCell(tableView)

        case 1, 2: // Settings groups
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            var cfg = cell.defaultContentConfiguration()
            cell.gestureRecognizers?.forEach { cell.removeGestureRecognizer($0) }
            cfg.textProperties.adjustsFontForContentSizeCategory = true

            cfg.imageProperties.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            cell.accessoryView = nil
            cell.accessoryType = .none
            cell.selectionStyle = .default

            if indexPath.section == 1 {
                // GENERAL PREFERENCES
                switch indexPath.row {
                case 0: // Language
                    cfg.text = L("settings.language")
                    cfg.secondaryText = L("settings.language.system")
                    cfg.secondaryTextProperties.color = .secondaryLabel
                    cfg.image = UIImage(systemName: "globe")
                    cell.accessoryType = .disclosureIndicator

                case 1: // Theme
                    cfg.text = L("settings.theme")
                    cfg.secondaryText = currentTheme.title
                    cfg.secondaryTextProperties.color = .secondaryLabel
                    cfg.image = UIImage(systemName: "paintpalette")
                    cell.accessoryType = .disclosureIndicator

                case 2: // Notifications
                    cfg.text = L("settings.notifications")
                    cfg.image = UIImage(systemName: "bell.badge")
                    cell.accessoryType = .disclosureIndicator

                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        DispatchQueue.main.async {
                            if settings.authorizationStatus == .authorized {
                                cfg.secondaryText = L("settings.notifications.on")
                                cfg.secondaryTextProperties.color = .systemGreen
                            } else {
                                cfg.secondaryText = L("settings.notifications.off")
                                cfg.secondaryTextProperties.color = .systemRed
                            }
                            cell.contentConfiguration = cfg
                        }
                    }

                default:
                    break
                }
            } else {
                // SUPPORT & INFO
                switch indexPath.row {
                case 0: // Rate Us
                    cfg.text = L("settings.rateUs")
                    cfg.secondaryText = L("settings.rateUs.subtitle")
                    cfg.secondaryTextProperties.color = .secondaryLabel
                    cfg.image = UIImage(systemName: "star.bubble")
                    cell.accessoryType = .disclosureIndicator

                case 1: // Support
                    cfg.text =  L("settings.support")
                    cfg.image =  UIImage(systemName: "envelope")
                    cfg.imageProperties.tintColor = .appBlue
                    cell.accessoryType = .disclosureIndicator

                case 2: // Legal
                    cfg.text = L("settings.legal")
                    cfg.image = UIImage(systemName: "hand.raised")
                    cfg.imageProperties.tintColor = .appBlue
                    cell.accessoryType = .disclosureIndicator

                default:
                    break
                }
            }

            cell.contentConfiguration = cfg
            var bgSet = UIBackgroundConfiguration.listGroupedCell()
            bgSet.backgroundColor = .secondarySystemGroupedBackground
            cell.backgroundConfiguration = bgSet
            cell.layer.cornerRadius = 12
            cell.layer.masksToBounds = true
            return cell

        default:
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.section {
        case 0: // Profile
            #if canImport(FirebaseAuth)
            if Auth.auth().currentUser == nil {
                presentLogin()
            }
            #else
            presentLogin()
            #endif

        case 1: // General Preferences
            switch indexPath.row {
            case 0:
                presentSystemLanguageHintAndOpenSettings()
            case 1:
                presentThemePicker()
            case 2:
                openAppSettings()
            default:
                break
            }

        case 2: // Support & Info
            switch indexPath.row {
            case 0:
                requestAppStoreReview()
            case 1:
                presentSupportFeedback()
            case 2:
                presentLegalLinks()
            default:
                break
            }

        default:
            break
        }
    }
}
