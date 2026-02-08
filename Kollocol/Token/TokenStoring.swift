//
//  TokenStoring.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

protocol TokenStoring: Actor {
    func accessToken() async -> String?
    func refreshToken() async -> String?
    func set(_ pair: TokenPair) async
    func clear() async
}
