import Foundation

enum Constants {
    static let defaultBaseURLString = "https://api.unsplash.com"
    static let defaultRedirectURI = "https://unsplash.com/oauth/authorize/native"
    static let defaultScopes = ["public", "read_user"]

    static let configuration: Result<AuthConfiguration, Error> = Result {
        try AuthConfiguration.load(bundle: .main, environment: ProcessInfo.processInfo.environment)
    }

    static var accessKey: String {
        (try? configuration.get())?.accessKey ?? ""
    }

    static var secretKey: String {
        (try? configuration.get())?.secretKey ?? ""
    }

    static var redirectURI: String {
        (try? configuration.get())?.redirectURI ?? defaultRedirectURI
    }

    static var accessScope: String {
        ((try? configuration.get())?.scopes ?? defaultScopes).joined(separator: "+")
    }
}
