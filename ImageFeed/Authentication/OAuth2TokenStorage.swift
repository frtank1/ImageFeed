import Foundation

final class OAuth2TokenStorage {
    static let shared = OAuth2TokenStorage()

    private let userDefaults: UserDefaults
    private let tokenKey = "bearerToken"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var token: String? {
        get {
            userDefaults.string(forKey: tokenKey)
        }
        set {
            if let newValue {
                userDefaults.set(newValue, forKey: tokenKey)
            } else {
                userDefaults.removeObject(forKey: tokenKey)
            }
        }
    }
}
