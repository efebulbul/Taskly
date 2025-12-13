//
//  SettingsViewController+ThemeAndLanguage.swift
//  Taskly
//
//  Created by EfeBülbül on 04.10.2025.
//
import UIKit

extension SettingsViewController {

    // MARK: - Theme picker
    func presentThemePicker() {
        let ac = UIAlertController(title: L("settings.theme"), message: nil, preferredStyle: .actionSheet)

        for option in ThemeOption.allCases {
            let action = UIAlertAction(title: option.title + (option == currentTheme ? " ✓" : ""), style: .default) { [weak self] _ in
                self?.currentTheme = option
                self?.tableView.reloadRows(at: [IndexPath(row: Row.theme.rawValue, section: 1)], with: .automatic)
            }
            ac.addAction(action)
        }

        ac.addAction(UIAlertAction(title: L("add.cancel"), style: .cancel))

        if let pop = ac.popoverPresentationController,
           let cell = tableView.cellForRow(at: IndexPath(row: Row.theme.rawValue, section: 1)) {
            pop.sourceView = cell
            pop.sourceRect = cell.bounds
        }
        present(ac, animated: true)
    }

    // MARK: - System language (redirect to iOS Settings)
    func presentSystemLanguageHintAndOpenSettings() {
        let ac = UIAlertController(
            title: L("lang.system.sheet.title"),
            message: L("lang.system.sheet.message"),
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: L("lang.system.sheet.cancel"), style: .cancel))
        ac.addAction(UIAlertAction(title: L("lang.system.sheet.continue"), style: .default, handler: { _ in
            let urlStr = UIApplication.openSettingsURLString
            guard let url = URL(string: urlStr), UIApplication.shared.canOpenURL(url) else {
                self.presentOK(title: L("settings.language"), message: L("lang.system.unavailable"))
                return
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }))
        present(ac, animated: true)
    }

    func applyTheme(_ option: ThemeOption) {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = option.interfaceStyle }
    }

    // MARK: - About
    func presentAbout() {
        let app = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "Taskly"
        let ver = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let msg = "\(app) v\(ver)\n" + L("about.subtitle")
        presentOK(title: L("settings.about"), message: msg)
    }

    @objc func reloadTexts() {
        // iOS dil değişimini sistem yönetiyor; bu yine de başlığı tazelemek için kalabilir.
        title = L("tab.settings")
        tabBarItem.title = L("tab.settings")
        tableView.reloadData()
    }
}
