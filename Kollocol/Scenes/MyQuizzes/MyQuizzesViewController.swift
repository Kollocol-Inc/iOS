//
//  MainViewController.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class MyQuizzesViewController: UIViewController {
    // MARK: - Properties
    private var interactor: MyQuizzesInteractor

    // MARK: - Lifecycle
    init(interactor: MyQuizzesInteractor) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    // MARK: - Private Methods
    private func configureUI() {
//        view.setPrimaryBackground()
        view.backgroundColor = .blue
    }
}
