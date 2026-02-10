//
//  MainCoordinator.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class MainCoordinator {
    // MARK: - Properties
    private let navigationController: UINavigationController
    private let services: Services
    private let onFinish: () -> Void
    
    // MARK: - Lifecycle
    init(
        navigationController: UINavigationController,
        services: Services,
        onFinish: @escaping () -> Void
    ) {
        self.navigationController = navigationController
        self.services = services
        self.onFinish = onFinish
    }
    
    // MARK: - Methods
    func start() {
        
    }
    
    // MARK: - Private Methods
    private func finish() {
        onFinish()
    }
}

// MARK: - AuthRouting
extension MainCoordinator: MainRouting {
    
}

@MainActor
protocol MainRouting: AnyObject {
    
}
