import Foundation

enum Constants {
    static let defaultBaseURLString = "https://api.unsplash.com"
    static let defaultRedirectURI = "frtank1.imagefeed://oauth/callback"
    static let defaultScopes = ["public", "read_user"]

    static let configuration: Result<AuthConfiguration, Error> = Result {
        try AuthConfiguration.load(bundle: .main, environment: ProcessInfo.processInfo.environment)
    }

    static let accessKey: String = (try? configuration.get())?.accessKey ?? ""

    static let secretKey: String = (try? configuration.get())?.secretKey ?? ""

    static let redirectURI: String = (try? configuration.get())?.redirectURI ?? defaultRedirectURI

    static let accessScope: String = ((try? configuration.get())?.scopes ?? defaultScopes).joined(separator: "+")
}
