//
//  GroupsLogicTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 28.04.2026.
//

import Testing
@testable import Kollocol

struct GroupsLogicTests {
    @Test
    func groupsLogicCanBeInitializedAndUsedAsInteractor() {
        let presenter = GroupsPresenterMock()
        let interactor: GroupsInteractor = GroupsLogic(presenter: presenter)

        #expect((interactor as? GroupsLogic) != nil)
    }
}

private final class GroupsPresenterMock: GroupsPresenter {
}
