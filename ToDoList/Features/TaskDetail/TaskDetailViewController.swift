import UIKit

// MARK: - Task Detail
final class TaskDetailViewController: UIViewController {

    private let task: Task

    // UI
    private let stack = UIStackView()
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let dateRow = UIStackView()
    private let dateIcon = UIImageView(image: UIImage(systemName: "calendar"))
    private let dateLabel = UILabel()
    private let notesTitleLabel = UILabel()
    private let notesLabel = UILabel()

    private lazy var df: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = LanguageManager.shared.currentLocale
        return f
    }()

    init(task: Task) {
        self.task = task
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = L("detail.title")
        navigationItem.largeTitleDisplayMode = .never

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])

        // Emoji
        emojiLabel.text = task.emoji
        emojiLabel.font = .systemFont(ofSize: 54)
        emojiLabel.textAlignment = .center
        let emojiContainer = UIView()
        emojiContainer.translatesAutoresizingMaskIntoConstraints = false
        emojiContainer.addSubview(emojiLabel)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emojiLabel.topAnchor.constraint(equalTo: emojiContainer.topAnchor),
            emojiLabel.centerXAnchor.constraint(equalTo: emojiContainer.centerXAnchor),
            emojiLabel.bottomAnchor.constraint(equalTo: emojiContainer.bottomAnchor)
        ])

        // Başlık
        titleLabel.text = task.title
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        // Tarih satırı
        dateRow.axis = .horizontal
        dateRow.alignment = .center
        dateRow.spacing = 8
        dateIcon.tintColor = .appBlueOrFallback
        dateIcon.contentMode = .scaleAspectFit
        dateIcon.setContentHuggingPriority(.required, for: .horizontal)
        if let d = task.dueDate {
            dateLabel.text = df.string(from: d)
            dateLabel.textColor = .secondaryLabel
        } else {
            dateLabel.text = L("detail.no.date")
            dateLabel.textColor = .tertiaryLabel
        }
        dateLabel.textAlignment = .center
        dateRow.addArrangedSubview(dateIcon)
        dateRow.addArrangedSubview(dateLabel)

        // Notlar başlığı
        notesTitleLabel.text = L("detail.notes")
        notesTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        notesTitleLabel.textAlignment = .center

        // Notlar içeriği
        if let n = task.notes, !n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            notesLabel.text = n
            notesLabel.textColor = .label
        } else {
            notesLabel.text = "—"
            notesLabel.textColor = .tertiaryLabel
        }
        notesLabel.numberOfLines = 0
        notesLabel.textAlignment = .center

        let card = UIView()
        card.backgroundColor = UIColor.secondarySystemBackground
        card.layer.cornerRadius = 14
        card.translatesAutoresizingMaskIntoConstraints = false

        let cardStack = UIStackView(arrangedSubviews: [titleLabel, dateRow])
        cardStack.axis = .vertical
        cardStack.alignment = .fill
        cardStack.spacing = 8
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cardStack)
        NSLayoutConstraint.activate([
            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        let notesCard = UIView()
        notesCard.backgroundColor = UIColor.secondarySystemBackground
        notesCard.layer.cornerRadius = 14
        notesCard.translatesAutoresizingMaskIntoConstraints = false

        let notesStack = UIStackView(arrangedSubviews: [notesTitleLabel, notesLabel])
        notesStack.axis = .vertical
        notesStack.alignment = .fill
        notesStack.spacing = 6
        notesStack.translatesAutoresizingMaskIntoConstraints = false
        notesCard.addSubview(notesStack)
        NSLayoutConstraint.activate([
            notesStack.leadingAnchor.constraint(equalTo: notesCard.leadingAnchor, constant: 16),
            notesStack.trailingAnchor.constraint(equalTo: notesCard.trailingAnchor, constant: -16),
            notesStack.topAnchor.constraint(equalTo: notesCard.topAnchor, constant: 16),
            notesStack.bottomAnchor.constraint(equalTo: notesCard.bottomAnchor, constant: -16)
        ])

        stack.addArrangedSubview(emojiContainer)
        stack.addArrangedSubview(card)
        stack.addArrangedSubview(notesCard)
    }
}
