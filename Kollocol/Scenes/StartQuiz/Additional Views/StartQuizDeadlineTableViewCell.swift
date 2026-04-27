//
//  StartQuizDeadlineTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 22.03.2026.
//

import UIKit

final class StartQuizDeadlineTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textSecondary
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.text = "deadline".localized
        return label
    }()

    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale.current
        picker.tintColor = .accentPrimary
        return picker
    }()

    // MARK: - Constants
    static let reuseIdentifier = "StartQuizDeadlineTableViewCell"

    // MARK: - Properties
    var onDateChanged: ((Date) -> Void)?

    private var isApplyingConfiguration = false

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
        onDateChanged = nil
    }

    // MARK: - Methods
    func configure(selectedDate: Date, minimumDate: Date) {
        isApplyingConfiguration = true
        datePicker.minimumDate = minimumDate

        if selectedDate < minimumDate {
            datePicker.date = minimumDate
        } else {
            datePicker.date = selectedDate
        }
        isApplyingConfiguration = false
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        datePicker.setContentHuggingPriority(.required, for: .horizontal)
        datePicker.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentView.addSubview(titleLabel)
        titleLabel.pinTop(to: contentView.topAnchor, 8)
        titleLabel.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 40)
        titleLabel.pinBottom(to: contentView.bottomAnchor, 16)

        contentView.addSubview(datePicker)
        datePicker.pinCenterY(to: titleLabel)
        datePicker.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)

        datePicker.addTarget(self, action: #selector(handleDateChanged), for: .valueChanged)
    }

    // MARK: - Actions
    @objc
    private func handleDateChanged() {
        guard isApplyingConfiguration == false else { return }
        onDateChanged?(datePicker.date)
    }
}
