//
//  RegisterViewController.swift
//  Taskly
//
//  Created by EfeBülbül on 04.10.2025.
//

import UIKit
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import FirebaseCore

// MARK: - ItemsViewController
final class ItemsViewController: UITableViewController {

    // Firestore-backed kalıcılık
    var tasks: [Task] = [] {
        didSet { refreshEmptyState() }
    }

    // MARK: - Firestore
    let db = Firestore.firestore()
    var listener: ListenerRegistration?

    // Kategoriler (kişiselleştirilebilir, 4 adet)
    let categoriesStorageKey = "categories.v1"
    var categories: [String] = [] { didSet { saveCategories() } }

    // Filtre (nil = Tümü)
    var activeFilter: String? = nil
    let filterControl = UISegmentedControl(items: [])

    // Sadece bugünün görevlerini göster
    var showTodayOnly = false
    // Sadece bu haftanın (Pazartesi–Pazar) görevlerini göster
    var showThisWeekOnly = false
    // Sadece süresi geçmiş (tamamlanmamış) görevleri göster
    var showOverdueOnly = false

    // TR tarih/saat formatter
    lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = LanguageManager.shared.currentLocale
        return f
    }()

    let defaultCategories = ["📝","💼","🏠","🏃🏻"]

    lazy var addButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "plus"), for: .normal)
        b.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 28, weight: .bold),
            forImageIn: .normal
        )
        b.tintColor = .white
        b.backgroundColor = .appBlueOrFallback
        b.layer.cornerRadius = 32
        b.layer.shadowOpacity = 0.25
        b.layer.shadowRadius = 6
        b.translatesAutoresizingMaskIntoConstraints = false
        b.widthAnchor.constraint(equalToConstant: 64).isActive = true
        b.heightAnchor.constraint(equalToConstant: 64).isActive = true
        b.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        return b
    }()

    let emptyView = EmptyStateView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L("items.title")
        navigationController?.navigationBar.prefersLargeTitles = false

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadForLanguage),
            name: .languageDidChange,
            object: nil
        )

        // Brand in Navigation Bar
        let brandContainer = UIStackView()
        brandContainer.axis = .horizontal
        brandContainer.alignment = .center
        brandContainer.spacing = -2

        let taskLabel = UILabel()
        taskLabel.text = "Task"
        taskLabel.textColor = .label
        taskLabel.font = .systemFont(ofSize: 30, weight: .semibold)

        let lyLabel = UILabel()
        lyLabel.textColor = .appBlueOrFallback
        lyLabel.font = .systemFont(ofSize: 30, weight: .semibold)
        lyLabel.text = "ly"

        brandContainer.addArrangedSubview(taskLabel)
        brandContainer.addArrangedSubview(lyLabel)

        let brandWrapper = UIView()
        brandWrapper.addSubview(brandContainer)
        brandContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            brandContainer.leadingAnchor.constraint(equalTo: brandWrapper.leadingAnchor),
            brandWrapper.trailingAnchor.constraint(equalTo: brandContainer.trailingAnchor),
            brandContainer.topAnchor.constraint(equalTo: brandWrapper.topAnchor),
            brandWrapper.bottomAnchor.constraint(equalTo: brandContainer.bottomAnchor)
        ])

        navigationItem.titleView = brandWrapper

        // Filtre butonu (sol üst)
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain,
            target: self,
            action: #selector(presentFilterSheet)
        )
        navigationItem.leftBarButtonItem = filterButton

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TaskCell")
        tableView.rowHeight = 56
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .systemGroupedBackground
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 8
        }

        loadCategories()
        setupFilterControl()
        tableView.tableHeaderView = makeHeaderContainer(for: filterControl)

        view.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        emptyView.configure(
            title: L("empty.title"),
            subtitle: L("empty.subtitle"),
            buttonTitle: L("empty.cta")
        )
        emptyView.onPrimaryTap = { [weak self] in self?.presentAddTask() }

        startObservingTasks()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidLogin),
            name: .tasklyDidLogin,
            object: nil
        )

        refreshEmptyState()
    }

    func refreshEmptyState() {
        tableView.backgroundView = tasks.isEmpty ? emptyView : nil
    }

    // MARK: - Firestore listening
    func startObservingTasks() {
        listener?.remove()

        guard let uid = Auth.auth().currentUser?.uid else {
            tasks = []
            tableView.reloadData()
            return
        }

        listener = db.collection("users")
            .document(uid)
            .collection("tasks")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    let proj = FirebaseApp.app()?.options.projectID ?? "nil"
                    let uidLog = Auth.auth().currentUser?.uid ?? "nil"
                    print("⚠️ Tasks listen error:", error.localizedDescription, "| ProjectID:", proj, "| UID:", uidLog)
                    return
                }
                DispatchQueue.main.async {
                    self.tasks = snapshot?.documents.compactMap { doc -> Task? in
                        let data = doc.data()

                        guard
                            let title = data["title"] as? String,
                            let emoji = data["emoji"] as? String,
                            let done = data["done"] as? Bool
                        else {
                            return nil
                        }

                        let dueDate = (data["dueDate"] as? Timestamp)?.dateValue()
                        let notes = data["notes"] as? String
                        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()

                        return Task(
                            id: doc.documentID,
                            title: title,
                            emoji: emoji,
                            done: done,
                            dueDate: dueDate,
                            notes: notes,
                            createdAt: createdAt
                        )
                    } ?? []

                    self.tableView.reloadData()
                }
            }
    }

    @objc func handleDidLogin() {
        startObservingTasks()
    }

    deinit {
        listener?.remove()
        NotificationCenter.default.removeObserver(self, name: .languageDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .tasklyDidLogin, object: nil)
    }
}

// MARK: - SwiftUI Preview
#Preview {
    ViewControllerPreview {
        ItemsViewController()
    }
}
