//
//  CardTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.02.2026.
//

import UIKit

final class CardsTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.clipsToBounds = false
        return collectionView
    }()

    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = .textSecondary
        control.pageIndicatorTintColor = .dividerPrimary
        control.hidesForSinglePage = true
        control.isUserInteractionEnabled = false
        return control
    }()

    // MARK: - Constants
    static let reuseIdentifier = "CardTableViewCell"

    private enum UIConstants {
        static let collectionHeight: CGFloat = 150
        static let pageControlTopInset: CGFloat = 8
        static let pageControlBottomInset: CGFloat = 8
        static let collectionBottomInsetWithoutPageControl: CGFloat = 16
    }

    // MARK: - Properties
    var onQuizTypeTap: ((QuizType) -> Void)?
    var onQuizStartTap: ((QuizInstanceViewData) -> Void)?
    var onQuizTap: ((QuizInstanceViewData) -> Void)?

    private var items: [QuizInstanceViewData] = []
    private var isTemplate = false
    private var collectionBottomConstraintWithoutPageControl: NSLayoutConstraint?
    private var pageControlTopConstraint: NSLayoutConstraint?
    private var pageControlBottomConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let expectedSize = CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)

        if layout.itemSize != expectedSize {
            layout.itemSize = expectedSize
            layout.invalidateLayout()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        onQuizTypeTap = nil
        onQuizStartTap = nil
        onQuizTap = nil
        items = []
        isTemplate = false

        pageControl.numberOfPages = 0
        pageControl.currentPage = 0

        collectionView.setContentOffset(.zero, animated: false)
        collectionView.reloadData()
    }

    // MARK: - Methods
    func configure(with items: [QuizInstanceViewData], isTemplate: Bool = false) {
        self.items = items
        self.isTemplate = isTemplate
        reloadContent()
    }

    // MARK: - Private Methods
    private func configureUI() {
        configureBackground()
        configureCollectionView()
        configureConstraints()
    }

    private func configureBackground() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        clipsToBounds = false
        layer.masksToBounds = false
        contentView.clipsToBounds = false
        contentView.layer.masksToBounds = false
    }

    private func configureCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CardCollectionViewCell.self, forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdentifier)
    }

    private func configureConstraints() {
        contentView.addSubview(collectionView)
        contentView.addSubview(pageControl)

        collectionView.pinTop(to: contentView.topAnchor)
        collectionView.pinHorizontal(to: contentView)
        collectionView.setHeight(UIConstants.collectionHeight)

        pageControlTopConstraint = pageControl.pinTop(to: collectionView.bottomAnchor, UIConstants.pageControlTopInset)
        pageControl.pinCenterX(to: contentView.centerXAnchor)
        pageControlBottomConstraint = pageControl.pinBottom(to: contentView.bottomAnchor, UIConstants.pageControlBottomInset)

        collectionBottomConstraintWithoutPageControl = collectionView.pinBottom(
            to: contentView.bottomAnchor,
            UIConstants.collectionBottomInsetWithoutPageControl
        )
        collectionBottomConstraintWithoutPageControl?.isActive = false
    }

    private func reloadContent() {
        let itemsCount = items.count
        let hasMultipleItems = itemsCount > 1

        pageControl.numberOfPages = itemsCount
        pageControl.currentPage = 0
        pageControl.isHidden = !hasMultipleItems

        collectionView.isScrollEnabled = hasMultipleItems

        pageControlTopConstraint?.isActive = hasMultipleItems
        pageControlBottomConstraint?.isActive = hasMultipleItems
        collectionBottomConstraintWithoutPageControl?.isActive = !hasMultipleItems

        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        collectionView.setContentOffset(.zero, animated: false)
    }

    private func updateCurrentPage() {
        let pageWidth = collectionView.bounds.width
        guard pageWidth > 0, pageControl.numberOfPages > 0 else { return }

        let page = Int(round(collectionView.contentOffset.x / pageWidth))
        let safePage = max(0, min(page, pageControl.numberOfPages - 1))
        pageControl.currentPage = safePage
    }
}

// MARK: - UICollectionViewDataSource
extension CardsTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CardCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as? CardCollectionViewCell
        else {
            return UICollectionViewCell()
        }

        let item: QuizInstanceViewData? = items.indices.contains(indexPath.item) ? items[indexPath.item] : nil
        cell.configure(with: item, isTemplate: isTemplate)
        cell.onQuizTypeTap = { [weak self] quizType in
            self?.onQuizTypeTap?(quizType)
        }
        cell.onQuizStartTap = { [weak self] in
            guard let self, let item else { return }
            self.onQuizStartTap?(item)
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension CardsTableViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else {
            return
        }

        onQuizTap?(items[indexPath.item])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentPage()
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let pageWidth = collectionView.bounds.width
        guard pageWidth > 0 else { return }

        let targetPage = round(targetContentOffset.pointee.x / pageWidth)
        targetContentOffset.pointee.x = targetPage * pageWidth
    }
}
