import UIKit

// MARK: - Filtreleme & Kategoriler
extension ItemsViewController {

    func loadCategories() {
        if let saved = UserDefaults.standard.array(forKey: categoriesStorageKey) as? [String],
           saved.count == 4 {
            categories = saved
        } else {
            categories = defaultCategories
        }
    }

    func saveCategories() {
        UserDefaults.standard.set(categories, forKey: categoriesStorageKey)
    }

    func isInCurrentWeek(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return false
        }
        return weekInterval.contains(date)
    }

    var pending: [Task] {
        tasks.filter {
            !$0.done &&
            (activeFilter == nil || $0.emoji == activeFilter) &&
            (!showTodayOnly || Calendar.current.isDateInToday($0.dueDate ?? Date.distantPast)) &&
            (!showThisWeekOnly || isInCurrentWeek($0.dueDate)) &&
            (!showOverdueOnly || (($0.dueDate ?? Date.distantFuture) < Date() && !$0.done))
        }
    }

    var completed: [Task] {
        tasks.filter {
            $0.done &&
            (activeFilter == nil || $0.emoji == activeFilter) &&
            (!showTodayOnly || Calendar.current.isDateInToday($0.dueDate ?? Date.distantPast)) &&
            (!showThisWeekOnly || isInCurrentWeek($0.dueDate))
        }
    }

    func setupFilterControl() {
        let previousIndex = filterControl.selectedSegmentIndex

        filterControl.removeAllSegments()
        filterControl.insertSegment(withTitle: L("filter.all"), at: 0, animated: false)
        for (idx, e) in categories.enumerated() {
            filterControl.insertSegment(withTitle: e, at: idx + 1, animated: false)
        }

        if previousIndex != UISegmentedControl.noSegment,
           previousIndex < filterControl.numberOfSegments {
            filterControl.selectedSegmentIndex = previousIndex
        } else {
            filterControl.selectedSegmentIndex = 0
        }

        filterControl.removeTarget(nil, action: nil, for: .allEvents)
        filterControl.addTarget(self, action: #selector(filterChanged(_:)), for: .valueChanged)
        filterControl.translatesAutoresizingMaskIntoConstraints = false

        let alreadyHasLP = filterControl.gestureRecognizers?.contains { $0 is UILongPressGestureRecognizer } ?? false
        if !alreadyHasLP {
            let lp = UILongPressGestureRecognizer(
                target: self,
                action: #selector(handleCategoryLongPress(_:))
            )
            filterControl.addGestureRecognizer(lp)
        }
    }

    func makeHeaderContainer(for view: UIView) -> UIView {
        let container = UIView(
            frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 54)
        )
        container.backgroundColor = .clear
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 16),
            view.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    @objc func filterChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            activeFilter = nil
        } else {
            let idx = sender.selectedSegmentIndex - 1
            activeFilter = categories.indices.contains(idx) ? categories[idx] : nil
        }
        tableView.reloadData()
        refreshEmptyState()
    }

    @objc func presentFilterSheet() {
        let ac = UIAlertController(
            title: L("filter.sheet.title"),
            message: nil,
            preferredStyle: .actionSheet
        )

        ac.addAction(UIAlertAction(title: L("filter.menu.allTasks"), style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.showTodayOnly = false
            self.showThisWeekOnly = false
            self.showOverdueOnly = false
            self.tableView.reloadData()
            self.refreshEmptyState()
        }))

        ac.addAction(UIAlertAction(title: L("filter.menu.todayTasks"), style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.showTodayOnly = true
            self.showThisWeekOnly = false
            self.showOverdueOnly = false
            self.tableView.reloadData()
            self.refreshEmptyState()
        }))

        ac.addAction(UIAlertAction(title: L("filter.menu.weekTasks"), style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.showTodayOnly = false
            self.showThisWeekOnly = true
            self.showOverdueOnly = false
            self.tableView.reloadData()
            self.refreshEmptyState()
        }))

        ac.addAction(UIAlertAction(title: L("filter.menu.overdueTasks"), style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.showTodayOnly = false
            self.showThisWeekOnly = false
            self.showOverdueOnly = true
            self.tableView.reloadData()
            self.refreshEmptyState()
        }))

        ac.addAction(UIAlertAction(title: L("common.cancel"), style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.barButtonItem = navigationItem.leftBarButtonItem
        }

        present(ac, animated: true)
    }

    @objc func handleCategoryLongPress(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began else { return }
        let point = gr.location(in: filterControl)
        guard filterControl.numberOfSegments > 0 else { return }
        let segmentWidth = filterControl.bounds.width / CGFloat(filterControl.numberOfSegments)
        var index = Int(point.x / segmentWidth)
        index = max(0, min(index, filterControl.numberOfSegments - 1))

        // 0: Tümü (düzenlenemez)
        guard index > 0 else { return }
        let catIdx = index - 1
        guard categories.indices.contains(catIdx) else { return }

        let current = categories[catIdx]
        let ac = UIAlertController(
            title: L("cat.edit.title"),
            message: L("cat.edit.message"),
            preferredStyle: .alert
        )
        ac.addTextField { tf in
            tf.placeholder = "🔖"
            tf.text = current
        }
        ac.addAction(UIAlertAction(title: L("common.cancel"), style: .cancel))
        ac.addAction(UIAlertAction(title: L("common.save"), style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let text = ac.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard text.isSingleEmoji else {
                self.showAlert(title: L("cat.invalid.title"), message: L("cat.invalid.message"))
                return
            }
            self.categories[catIdx] = text
            if self.filterControl.selectedSegmentIndex == index {
                self.activeFilter = text
            }
            self.setupFilterControl()
            self.tableView.reloadData()
            self.refreshEmptyState()
        }))
        present(ac, animated: true)
    }
}
