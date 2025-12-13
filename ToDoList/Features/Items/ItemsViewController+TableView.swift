import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore

// MARK: - TableView DataSource & Delegate
extension ItemsViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        if tasks.isEmpty { return 0 }
        return showOverdueOnly ? 1 : 2
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        if showOverdueOnly {
            return L("list.section.pending")
        } else {
            return section == 0 ? L("list.section.pending") : L("list.section.done")
        }
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        if showOverdueOnly {
            return pending.count
        } else {
            return section == 0 ? pending.count : completed.count
        }
    }

    func item(at indexPath: IndexPath) -> Task {
        if showOverdueOnly {
            return pending[indexPath.row]
        } else {
            return indexPath.section == 0 ? pending[indexPath.row] : completed[indexPath.row]
        }
    }

    func globalIndex(from indexPath: IndexPath) -> Int? {
        let t = item(at: indexPath)
        return tasks.firstIndex(where: { $0.id == t.id })
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        let it = item(at: indexPath)

        var cfg = cell.defaultContentConfiguration()
        cfg.attributedText = nil
        cfg.text = it.title

        if it.done {
            cfg.textProperties.font  = .systemFont(ofSize: 16, weight: .regular)
            cfg.textProperties.color = .secondaryLabel
        } else {
            cfg.textProperties.font  = .systemFont(ofSize: 16, weight: .semibold)
            cfg.textProperties.color = .label
        }

        cfg.image = UIImage(systemName: it.done ? "checkmark.circle.fill" : "circle")
        cfg.imageProperties.tintColor = it.done ? .systemGreen : .tertiaryLabel
        cfg.imageProperties.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: 18,
            weight: .semibold
        )

        // Secondary text: notes + dueDate
        let hasNotes = !(it.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasDate = it.dueDate != nil

        if hasNotes && hasDate {
            let notesText = it.notes!.trimmingCharacters(in: .whitespacesAndNewlines)
            cfg.secondaryText = "\(notesText) • \(dateFormatter.string(from: it.dueDate!))"
        } else if hasNotes {
            cfg.secondaryText = it.notes!.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if hasDate {
            cfg.secondaryText = dateFormatter.string(from: it.dueDate!)
        } else {
            cfg.secondaryText = nil
        }
        cfg.secondaryTextProperties.color = .secondaryLabel

        let emoji = UILabel()
        emoji.text = it.emoji
        emoji.font = .systemFont(ofSize: 20)
        let acc = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        emoji.translatesAutoresizingMaskIntoConstraints = false
        acc.addSubview(emoji)
        NSLayoutConstraint.activate([
            emoji.centerXAnchor.constraint(equalTo: acc.centerXAnchor),
            emoji.centerYAnchor.constraint(equalTo: acc.centerYAnchor)
        ])
        cell.accessoryView = acc
        cell.contentConfiguration = cfg

        var bg = UIBackgroundConfiguration.listGroupedCell()
        bg.backgroundColor = .secondarySystemGroupedBackground
        cell.backgroundConfiguration = bg
        cell.layer.cornerRadius = 12
        cell.layer.masksToBounds = true

        let sel = UIView()
        sel.backgroundColor = .appBlue
            .withAlphaComponent(0.12)
        sel.layer.cornerRadius = 12
        sel.layer.masksToBounds = true
        cell.selectedBackgroundView = sel

        return cell
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let t = item(at: indexPath)
        let vc = TaskDetailViewController(task: t)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        vc.modalPresentationStyle = .pageSheet
        vc.modalTransitionStyle = .coverVertical
        present(vc, animated: true)
    }

    // MARK: - Swipe Actions
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: L("actions.delete")) { [weak self] _,_,done in
            guard let self = self else { return }
            if let gi = self.globalIndex(from: indexPath) {
                let task = self.tasks[gi]

                DispatchQueue.main.async {
                    self.tasks.removeAll { $0.id == task.id }
                    self.tableView.reloadData()
                    self.refreshEmptyState()
                }

                ReminderScheduler.cancel(for: task)

                if let id = task.id, let uid = Auth.auth().currentUser?.uid {
                    self.db.collection("users")
                        .document(uid)
                        .collection("tasks")
                        .document(id)
                        .delete { err in
                            if let err = err {
                                let proj = FirebaseApp.app()?.options.projectID ?? "nil"
                                print("Delete error:", err.localizedDescription, "| ProjectID:", proj)
                            }
                        }
                }
            }
            done(true)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }

    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let t = item(at: indexPath)
        let title = t.done ? L("actions.undo") : L("actions.complete")

        let action = UIContextualAction(style: .normal, title: title) { [weak self] _,_,done in
            guard let self = self, let gi = self.globalIndex(from: indexPath) else { return }
            var target = self.tasks[gi]
            let newDone = !target.done
            target.done = newDone

            DispatchQueue.main.async {
                self.tasks[gi].done = newDone
                self.tableView.reloadData()
                self.refreshEmptyState()
            }

            if newDone {
                ReminderScheduler.cancel(for: target)
            } else {
                ReminderScheduler.schedule(for: target)
            }

            if let id = target.id, let uid = Auth.auth().currentUser?.uid {
                self.db.collection("users")
                    .document(uid)
                    .collection("tasks")
                    .document(id)
                    .updateData(["done": newDone]) { err in
                        if let err = err {
                            let proj = FirebaseApp.app()?.options.projectID ?? "nil"
                            print("Toggle error:", err.localizedDescription, "| ProjectID:", proj)
                        }
                    }
            }
            done(true)
        }

        action.image = UIImage(systemName: t.done ? "arrow.uturn.left" : "checkmark")
        action.backgroundColor = t.done ? .systemGray : .systemGreen
        return UISwipeActionsConfiguration(actions: [action])
    }
}
