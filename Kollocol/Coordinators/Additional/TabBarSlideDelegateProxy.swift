//
//  TabBarSlideDelegateProxy.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.02.2026.
//

import UIKit

@MainActor
final class TabBarSlideDelegateProxy: NSObject, UITabBarControllerDelegate {
    func tabBarController(
        _ tabBarController: UITabBarController,
        animationControllerForTransitionFrom fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {

        guard
            let vcs = tabBarController.viewControllers,
            let fromIndex = vcs.firstIndex(of: fromVC),
            let toIndex = vcs.firstIndex(of: toVC)
        else { return nil }

        let direction: SlideDirection = (toIndex > fromIndex) ? .left : .right
        return SlideTabBarTransitionAnimator(direction: direction)
    }
}
