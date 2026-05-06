import UIKit

final class StartQuizGroupTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textSecondary
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.text = "group".localized
        return label
    }()

    private let groupInfoButton: UIButton = {
        let button = UIButton(type: .system)
        let symbolConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 11, weight: .semibold)
        )
        let image = UIImage(
            systemName: "info.circle",
            withConfiguration: symbolConfiguration
        )?.withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        return button
    }()

    private let selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .accentPrimary
        button.contentHorizontalAlignment = .right
        button.semanticContentAttribute = .forceRightToLeft
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.numberOfLines = 1
        return button
    }()

    // MARK: - Constants
    static let reuseIdentifier = "StartQuizGroupTableViewCell"

    // MARK: - Properties
    var onSelectTap: ((UIView) -> Void)?
    var onInfoTap: (() -> Void)?

    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onSelectTap = nil
        onInfoTap = nil
    }

    // MARK: - Methods
    func configure(selectedGroupTitle: String) {
        let symbolConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 13, weight: .semibold)
        )
        let chevronImage = UIImage(
            systemName: "chevron.up.chevron.down",
            withConfiguration: symbolConfiguration
        )?.withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)

        selectButton.setAttributedTitle(
            NSAttributedString(
                string: selectedGroupTitle,
                attributes: [
                    .foregroundColor: UIColor.accentPrimary,
                    .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
                ]
            ),
            for: .normal
        )
        selectButton.setImage(chevronImage, for: .normal)
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(titleLabel)
        titleLabel.pinTop(to: contentView.topAnchor, 8)
        titleLabel.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 40)
        titleLabel.pinBottom(to: contentView.bottomAnchor, 16)

        contentView.addSubview(selectButton)
        selectButton.pinCenterY(to: titleLabel)
        selectButton.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)

        contentView.addSubview(groupInfoButton)
        groupInfoButton.pinCenterY(to: titleLabel)
        groupInfoButton.pinRight(to: selectButton.leadingAnchor, 8)

        titleLabel.pinRight(to: groupInfoButton.leadingAnchor, 8, .lsOE)

        groupInfoButton.addTarget(self, action: #selector(handleInfoTap), for: .touchUpInside)
        selectButton.addTarget(self, action: #selector(handleSelectTap), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc
    private func handleSelectTap() {
        onSelectTap?(selectButton)
    }

    @objc
    private func handleInfoTap() {
        onInfoTap?()
    }
}

final class StartQuizGroupSelectionPopoverViewController: UIViewController {
    // MARK: - Types
    private struct Option {
        let id: String?
        let title: String
    }

    // MARK: - UI Components
    private let searchTextField: UITextField = {
        let field = UITextField()
        field.backgroundColor = .dividerPrimary
        field.textColor = .textSecondary
        field.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        field.layer.cornerRadius = 18
        field.attributedPlaceholder = NSAttributedString(
            string: "groupsSearchPlaceholder".localized,
            attributes: [
                .foregroundColor: UIColor.textSecondary,
                .font: UIFont.systemFont(ofSize: 15, weight: .medium)
            ]
        )

        let iconConfiguration = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 15, weight: .medium))
        let iconImage = UIImage(systemName: "magnifyingglass", withConfiguration: iconConfiguration)?
            .withTintColor(.textSecondary, renderingMode: .alwaysOriginal)
        let iconImageView = UIImageView(image: iconImage)
        iconImageView.frame = CGRect(x: 12, y: 14.5, width: 15, height: 15)

        let leftAccessoryView = UIView(frame: CGRect(x: 0, y: 0, width: 35, height: 44))
        leftAccessoryView.addSubview(iconImageView)
        field.leftView = leftAccessoryView
        field.leftViewMode = .always

        field.addPadding(right: 12)
        field.setHeight(44)
        return field
    }()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 0
        tableView.showsVerticalScrollIndicator = true
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textSecondary
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "groupsNoGroupsWithSuchName".localized
        return label
    }()

    private let selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.layer.cornerRadius = 18
        button.setHeight(44)
        button.setAttributedTitle(
            NSAttributedString(
                string: "select".localized,
                attributes: [
                    .foregroundColor: UIColor.textWhite,
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
                ]
            ),
            for: .normal
        )
        return button
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let rowHeight: CGFloat = 52
        static let maxVisibleRows: CGFloat = 6
        static let horizontalInset: CGFloat = 12
        static let topInset: CGFloat = 12
        static let searchToTableSpacing: CGFloat = 8
        static let spacingBetweenTableAndButton: CGFloat = 8
        static let bottomInset: CGFloat = 16
        static let searchFieldHeight: CGFloat = 44
        static let buttonHeight: CGFloat = 44
        static let preferredWidth: CGFloat = 320
    }

    // MARK: - Properties
    var onSelect: ((String?) -> Void)?

    private let withoutGroupOption = Option(id: nil, title: "withoutGroup".localized)
    private var allGroupOptions: [Option]
    private var filteredOptions: [Option] = []
    private var selectedGroupId: String?
    private var searchQuery = ""
    private var isShowingEmptySearchState = false

    // MARK: - Lifecycle
    init(groups: [StartQuizModels.GroupOption], selectedGroupId: String?) {
        self.allGroupOptions = groups.map { Option(id: $0.id, title: $0.title) }
        self.selectedGroupId = selectedGroupId
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnBackgroundTap()
        configureUI()
        updateFilteredOptions()
        updatePreferredContentSize()
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.backgroundColor = .backgroundSecondary

        view.addSubview(searchTextField)
        searchTextField.pinTop(to: view.topAnchor, UIConstants.topInset)
        searchTextField.pinLeft(to: view.leadingAnchor, UIConstants.horizontalInset)
        searchTextField.pinRight(to: view.trailingAnchor, UIConstants.horizontalInset)
        searchTextField.setHeight(UIConstants.searchFieldHeight)

        view.addSubview(tableView)
        tableView.pinTop(to: searchTextField.bottomAnchor, UIConstants.searchToTableSpacing)
        tableView.pinLeft(to: view.leadingAnchor)
        tableView.pinRight(to: view.trailingAnchor)

        view.addSubview(selectButton)
        selectButton.pinTop(to: tableView.bottomAnchor, UIConstants.spacingBetweenTableAndButton)
        selectButton.pinLeft(to: view.leadingAnchor, UIConstants.horizontalInset)
        selectButton.pinRight(to: view.trailingAnchor, UIConstants.horizontalInset)
        selectButton.pinBottom(to: view.safeAreaLayoutGuide.bottomAnchor, UIConstants.bottomInset)

        tableView.register(
            StartQuizGroupSelectionOptionTableViewCell.self,
            forCellReuseIdentifier: StartQuizGroupSelectionOptionTableViewCell.reuseIdentifier
        )
        tableView.dataSource = self
        tableView.delegate = self

        searchTextField.addTarget(self, action: #selector(handleSearchTextChanged), for: .editingChanged)
        selectButton.addTarget(self, action: #selector(handleSelectTap), for: .touchUpInside)
    }

    private func updatePreferredContentSize() {
        let rowsCount: CGFloat = {
            if isShowingEmptySearchState {
                return UIConstants.maxVisibleRows
            }
            return CGFloat(max(1, filteredOptions.count))
        }()
        let visibleRows = min(rowsCount, UIConstants.maxVisibleRows)
        tableView.isScrollEnabled = rowsCount > UIConstants.maxVisibleRows

        let tableHeight = visibleRows * UIConstants.rowHeight
        let height = UIConstants.topInset
            + UIConstants.searchFieldHeight
            + UIConstants.searchToTableSpacing
            + tableHeight
            + UIConstants.spacingBetweenTableAndButton
            + UIConstants.buttonHeight
            + UIConstants.bottomInset

        preferredContentSize = CGSize(
            width: UIConstants.preferredWidth,
            height: height
        )
    }

    private func updateFilteredOptions() {
        let normalizedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let isSearching = normalizedQuery.isEmpty == false

        if isSearching {
            filteredOptions = allGroupOptions.filter {
                $0.title.localizedCaseInsensitiveContains(normalizedQuery)
            }
        } else {
            filteredOptions = [withoutGroupOption] + allGroupOptions
        }

        let showEmptyState = isSearching && filteredOptions.isEmpty
        isShowingEmptySearchState = showEmptyState
        tableView.backgroundView = showEmptyState ? emptyStateLabel : nil
        tableView.reloadData()
        updatePreferredContentSize()
    }

    @objc
    private func handleSelectTap() {
        onSelect?(selectedGroupId)
        dismiss(animated: true)
    }

    @objc
    private func handleSearchTextChanged() {
        searchQuery = searchTextField.text ?? ""
        updateFilteredOptions()
    }
}

// MARK: - UITableViewDataSource
extension StartQuizGroupSelectionPopoverViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: StartQuizGroupSelectionOptionTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? StartQuizGroupSelectionOptionTableViewCell else {
            return UITableViewCell()
        }

        guard filteredOptions.indices.contains(indexPath.row) else {
            return UITableViewCell()
        }

        let option = filteredOptions[indexPath.row]
        cell.configure(
            title: option.title,
            isWithoutGroupOption: option.id == nil,
            isSelected: option.id == selectedGroupId
        )
        return cell
    }
}

// MARK: - UITableViewDelegate
extension StartQuizGroupSelectionPopoverViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UIConstants.rowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard filteredOptions.indices.contains(indexPath.row) else { return }

        selectedGroupId = filteredOptions[indexPath.row].id
        tableView.reloadData()
    }
}

private final class StartQuizGroupSelectionOptionTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textSecondary
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let markControl = AnswerOptionMarkControl()

    // MARK: - Constants
    static let reuseIdentifier = "StartQuizGroupSelectionOptionTableViewCell"

    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods
    func configure(title: String, isWithoutGroupOption: Bool, isSelected: Bool) {
        titleLabel.text = title
        titleLabel.textColor = isWithoutGroupOption ? .textPrimary : .textSecondary
        markControl.apply(
            configuration: .init(
                kind: .singleChoice,
                size: .regular,
                visualState: .neutral,
                isSelected: isSelected
            )
        )
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(titleLabel)
        titleLabel.pinTop(to: contentView.topAnchor)
        titleLabel.pinBottom(to: contentView.bottomAnchor)
        titleLabel.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 16)

        contentView.addSubview(markControl)
        markControl.pinCenterY(to: titleLabel)
        markControl.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
        markControl.isUserInteractionEnabled = false

        titleLabel.pinRight(to: markControl.leadingAnchor, 12, .lsOE)
    }
}
