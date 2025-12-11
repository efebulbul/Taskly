import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore

// MARK: - Görev Ekleme & Dil Güncelleme
extension ItemsViewController {

    @objc func addTapped() {
        presentAddTask()
    }

    func presentAddTask() {
        let ac = UIAlertController(
            title: L("add.title"),
            message: L("add.message"),
            preferredStyle: .alert
        )

        ac.addTextField { tf in
            tf.placeholder = L("add.placeholder.title")
            tf.autocapitalizationType = .sentences
        }

        ac.addTextField { tf in
            tf.placeholder = L("add.placeholder.notes")
            tf.autocapitalizationType = .sentences
        }

        let pickerVC = UIViewController()
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.locale = LanguageManager.shared.currentLocale
        var cal = Calendar.current
        cal.locale = LanguageManager.shared.currentLocale
        picker.calendar = cal
        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .wheels
        }
        picker.minimumDate = Date()
        picker.translatesAutoresizingMaskIntoConstraints = false
        pickerVC.view.addSubview(picker)
        NSLayoutConstraint.activate([
            picker.leadingAnchor.constraint(equalTo: pickerVC.view.leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: pickerVC.view.trailingAnchor),
            picker.topAnchor.constraint(equalTo: pickerVC.view.topAnchor),
            picker.bottomAnchor.constraint(equalTo: pickerVC.view.bottomAnchor),
            picker.heightAnchor.constraint(equalToConstant: 180)
        ])
        pickerVC.preferredContentSize = CGSize(width: 270, height: 180)
        ac.setValue(pickerVC, forKey: "contentViewController")

        ac.addAction(UIAlertAction(title: L("add.cancel"), style: .cancel))

        ac.addAction(UIAlertAction(title: L("add.add"), style: .default, handler: { [weak self, weak ac] _ in
            guard let self = self else { return }
            let rawTitle = ac?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !rawTitle.isEmpty else {
                self.showAlert(title: L("alerts.missing.title"), message: L("alerts.missing.message"))
                return
            }

            let rawNotes = ac?.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let finalNotes: String? = rawNotes.isEmpty ? nil : rawNotes

            let addTask: (String) -> Void = { chosenEmoji in
                let due = picker.date
                guard let uid = Auth.auth().currentUser?.uid else {
                    self.showAlert(title: L("auth.required.title"), message: L("auth.required.message"))
                    return
                }

                let col = self.db.collection("users").document(uid).collection("tasks")
                let doc = col.document()

                let data: [String: Any?] = [
                    "title": rawTitle,
                    "emoji": chosenEmoji,
                    "done": false,
                    "dueDate": due,
                    "notes": finalNotes,
                    "createdAt": Timestamp(date: Date())
                ]

                doc.setData(data.compactMapValues { $0 }, merge: true) { err in
                    if let err = err {
                        let proj = FirebaseApp.app()?.options.projectID ?? "nil"
                        print("⚠️ Add task error:", err.localizedDescription, "| ProjectID:", proj, "| UID:", uid)
                        self.showAlert(title: L("common.error"),
                                       message: L("tasks.add.failed") + "\n" + err.localizedDescription)
                        return
                    }

                    let scheduled = Task(
                        id: doc.documentID,
                        title: rawTitle,
                        emoji: chosenEmoji,
                        done: false,
                        dueDate: due,
                        notes: finalNotes,
                        createdAt: nil
                    )

                    ReminderScheduler.schedule(for: scheduled)

                    DispatchQueue.main.async {
                        var immediate = scheduled
                        immediate.createdAt = Date()
                        self.tasks.append(immediate)
                        self.tableView.reloadData()
                        self.refreshEmptyState()
                    }
                }
            }

            if let chosen = self.activeFilter {
                addTask(chosen)
            } else {
                let chooser = UIAlertController(
                    title: L("add.choose.category"),
                    message: nil,
                    preferredStyle: .actionSheet
                )
                for e in self.categories {
                    chooser.addAction(UIAlertAction(title: e, style: .default, handler: { _ in addTask(e) }))
                }
                chooser.addAction(UIAlertAction(title: L("add.back"), style: .cancel))
                if let pop = chooser.popoverPresentationController {
                    pop.sourceView = self.view
                    pop.sourceRect = CGRect(x: self.view.bounds.midX, y: 80, width: 1, height: 1)
                }
                self.present(chooser, animated: true)
            }
        }))

        present(ac, animated: true)
    }

    func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: L("settings.ok"), style: .default))
        present(ac, animated: true)
    }

    @objc func reloadForLanguage() {
        title = L("items.title")
        dateFormatter.locale = LanguageManager.shared.currentLocale

        setupFilterControl()
        emptyView.configure(
            title: L("empty.title"),
            subtitle: L("empty.subtitle"),
            buttonTitle: L("empty.cta")
        )
        tableView.reloadData()
        refreshEmptyState()
    }
}
