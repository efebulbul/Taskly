//
//  SettingsViewController+Notifications.swift
//  Taskly
//
//  Created by EfeBülbül on 04.10.2025.
//
import UIKit
import UserNotifications

extension SettingsViewController {

    // MARK: - Daily Reminder 08:00
    func enableDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    self.scheduleDailyReminder()
                case .notDetermined:
                    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                        DispatchQueue.main.async {
                            if granted { self.scheduleDailyReminder() }
                            else {
                                UserDefaults.standard.set(false, forKey: self.dailyReminderKey)
                                self.presentOK(title: L("settings.notifications"), message: L("notifications.permission.denied"))
                                self.tableView.reloadData()
                            }
                        }
                    }
                case .denied:
                    UserDefaults.standard.set(false, forKey: self.dailyReminderKey)
                    self.presentOK(title: L("settings.notifications"), message: L("notifications.permission.settings"))
                    self.tableView.reloadData()
                default:
                    break
                }
            }
        }
    }

    func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = L("app.title")
        content.body = L("notif.daily.body")
        content.sound = .default

        var comp = DateComponents()
        comp.hour = 8
        comp.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comp, repeats: true)
        let request = UNNotificationRequest(identifier: dailyReminderIdentifier, content: content, trigger: trigger)

        center.add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    UserDefaults.standard.set(false, forKey: self?.dailyReminderKey ?? "")
                    self?.presentOK(title: L("settings.notifications"), message: error.localizedDescription)
                    self?.tableView.reloadData()
                }
            }
        }
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
    }

    // MARK: - Notifications
    func requestNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.presentOK(title: L("common.error"), message: error.localizedDescription)
                    return
                }
                if granted {
                    self?.presentOK(title: L("settings.notifications"), message: L("notifications.permission.sampleScheduled"))
                    self?.scheduleSampleNotification()
                } else {
                    self?.presentOK(title: L("settings.notifications"), message: L("notifications.permission.denied"))
                }
            }
        }
    }

    func scheduleSampleNotification() {
        let content = UNMutableNotificationContent()
        content.title = L("app.title")
        content.body = L("notif.sample.body")
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
