//
//  UserDefaultsService.swift
//  Kollocol
//
//  Created by Arseniy on 07.02.2026.
//

import Foundation

enum AppThemePreference: String {
    case system
    case light
    case dark
}

enum AppLanguagePreference: String {
    case system
    case ru
    case en

    var localeIdentifier: String? {
        switch self {
        case .system:
            return nil
        case .ru:
            return "ru"
        case .en:
            return "en"
        }
    }
}

// MARK: - UserDefaultsServiceImpl
final class UserDefaultsServiceImpl: UserDefaultsService {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func set<T>(_ value: T?, for key: UserDefaultsKey) {
        let k = key.rawValue
        if let value {
            defaults.set(value, forKey: k)
        } else {
            defaults.removeObject(forKey: k)
        }
    }

    func value<T>(for key: UserDefaultsKey) -> T? {
        defaults.object(forKey: key.rawValue) as? T
    }

    func remove(_ key: UserDefaultsKey) {
        defaults.removeObject(forKey: key.rawValue)
    }

    func exists(_ key: UserDefaultsKey) -> Bool {
        defaults.object(forKey: key.rawValue) != nil
    }

    var isRegistered: Bool {
        get { value(for: .isRegistered) ?? false }
        set { set(newValue, for: .isRegistered) }
    }

    var appThemePreference: AppThemePreference {
        get {
            guard let rawValue: String = value(for: .appThemePreference),
                  let preference = AppThemePreference(rawValue: rawValue)
            else {
                return .system
            }
            return preference
        }
        set { set(newValue.rawValue, for: .appThemePreference) }
    }

    var appLanguagePreference: AppLanguagePreference {
        get {
            guard let rawValue: String = value(for: .appLanguagePreference),
                  let preference = AppLanguagePreference(rawValue: rawValue)
            else {
                return .system
            }
            return preference
        }
        set { set(newValue.rawValue, for: .appLanguagePreference) }
    }
}

// MARK: - UserDefaultsService
protocol UserDefaultsService: AnyObject {
    func set<T>(_ value: T?, for key: UserDefaultsKey)
    func value<T>(for key: UserDefaultsKey) -> T?
    func remove(_ key: UserDefaultsKey)
    func exists(_ key: UserDefaultsKey) -> Bool

    var isRegistered: Bool { get set }
    var appThemePreference: AppThemePreference { get set }
    var appLanguagePreference: AppLanguagePreference { get set }
}

// MARK: - UserDefaultsKey
enum UserDefaultsKey: String {
    case isRegistered
    case appThemePreference
    case appLanguagePreference
}
