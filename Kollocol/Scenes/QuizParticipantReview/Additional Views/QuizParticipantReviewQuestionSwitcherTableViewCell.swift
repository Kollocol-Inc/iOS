//
//  QuizParticipantReviewQuestionSwitcherTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import UIKit

final class QuizParticipantReviewQuestionSwitcherTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 0)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()

    // MARK: - Constants
    static let reuseIdentifier = "QuizParticipantReviewQuestionSwitcherTableViewCell"

    private enum UIConstants {
        static let itemWidth: CGFloat = 48
        static let itemHeight: CGFloat = 60
    }

    // MARK: - Properties
    var onQuestionTap: ((Int) -> Void)?

    private var items: [QuizParticipantReviewModels.QuestionSwitcherItemViewData] = []
    private var selectedQuestionIndex = 0
    private var previousSelectedQuestionIndex: Int?
    private var hasPerformedInitialCentering = false

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
        onQuestionTap = nil
    }

    // MARK: - Methods
    func configure(
        items: [QuizParticipantReviewModels.QuestionSwitcherItemViewData],
        selectedQuestionIndex: Int
    ) {
        let shouldAnimateCentering = hasPerformedInitialCentering
            && previousSelectedQuestionIndex != selectedQuestionIndex

        self.items = items
        self.selectedQuestionIndex = selectedQuestionIndex
        previousSelectedQuestionIndex = selectedQuestionIndex
        hasPerformedInitialCentering = true
        collectionView.reloadData()

        guard items.indices.contains(selectedQuestionIndex) else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let indexPath = IndexPath(item: selectedQuestionIndex, section: 0)
            self.collectionView.layoutIfNeeded()
            self.collectionView.scrollToItem(
                at: indexPath,
                at: .centeredHorizontally,
                animated: shouldAnimateCentering
            )
        }
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(collectionView)
        collectionView.pin(to: contentView)

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            QuizParticipantReviewQuestionIndexCollectionViewCell.self,
            forCellWithReuseIdentifier: QuizParticipantReviewQuestionIndexCollectionViewCell.reuseIdentifier
        )
    }
}

// MARK: - UICollectionViewDataSource
extension QuizParticipantReviewQuestionSwitcherTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: QuizParticipantReviewQuestionIndexCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? QuizParticipantReviewQuestionIndexCollectionViewCell else {
            return UICollectionViewCell()
        }

        guard items.indices.contains(indexPath.item) else {
            return UICollectionViewCell()
        }

        cell.configure(with: items[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension QuizParticipantReviewQuestionSwitcherTableViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else {
            return
        }

        let index = indexPath.item
        onQuestionTap?(index)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension QuizParticipantReviewQuestionSwitcherTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: UIConstants.itemWidth, height: UIConstants.itemHeight)
    }
}
