import Foundation
import UserNotifications

// MARK: - Yerel Bildirim Zamanlayıcı (30 dk önce + tam saatinde)
enum ReminderScheduler {
    static func schedule(for task: Task) {
        guard let due = task.dueDate, !task.done else { return }
        let center = UNUserNotificationCenter.current()

        cancel(for: task)

        let now = Date()

        if due > now {
            let contentAt = UNMutableNotificationContent()
            contentAt.title = L("reminder.dueNow.title")
            contentAt.body  = task.title
            contentAt.sound = .default

            let triggerAt = UNCalendarNotificationTrigger(
                dateMatching: calendarComponents(from: due),
                repeats: false
            )

            let reqAt = UNNotificationRequest(
                identifier: id(task, suffix: "at"),
                content: contentAt,
                trigger: triggerAt
            )

            center.add(reqAt, withCompletionHandler: nil)
        }

        let before = due.addingTimeInterval(-30 * 60)
        if before > now {
            let contentBefore = UNMutableNotificationContent()
            contentBefore.title = L("reminder.thirtyMins.title")
            contentBefore.body  = task.title
            contentBefore.sound = .default

            let triggerBefore = UNCalendarNotificationTrigger(
                dateMatching: calendarComponents(from: before),
                repeats: false
            )

            let reqBefore = UNNotificationRequest(
                identifier: id(task, suffix: "30m"),
                content: contentBefore,
                trigger: triggerBefore
            )

            center.add(reqBefore, withCompletionHandler: nil)
        }
    }

    static func cancel(for task: Task) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [id(task, suffix: "at"), id(task, suffix: "30m")]
        )
    }

    private static func id(_ task: Task, suffix: String) -> String {
        (task.id ?? UUID().uuidString) + "#" + suffix
    }

    private static func calendarComponents(from date: Date) -> DateComponents {
        var cal = Calendar.current
        cal.locale = LanguageManager.shared.currentLocale
        return cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    }
}
