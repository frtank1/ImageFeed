import Foundation

struct AuthConfiguration {
    let accessKey: String
    let secretKey: String
    let redirectURI: String
    let scopes: [String]

    init(
        accessKey: String,
        secretKey: String,
        redirectURI: String = Constants.defaultRedirectURI,
        scopes: [String] = Constants.defaultScopes
    ) {
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.redirectURI = redirectURI
        self.scopes = scopes
    }

    static func load() throws -> AuthConfiguration {
        try Constants.configuration.get()
    }

    static func load(
        bundle: Bundle = .main,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> AuthConfiguration {
        var values: [String: String] = [:]
        if let defaultsURL = bundle.url(forResource: "Defaults", withExtension: "plist", subdirectory: "Configuration"),
           let data = try? Data(contentsOf: defaultsURL),
           let dictionary = try? PropertyListSerialization.propertyList(from: data, format: nil),
           let strings = dictionary as? [String: String] {
            values = strings
        }
        if environment["UNSPLASH_ACCESS_KEY"] == nil || environment["UNSPLASH_SECRET_KEY"] == nil {
            if let url = bundle.url(forResource: "UnsplashSecrets", withExtension: "plist", subdirectory: "Configuration")
                ?? bundle.url(forResource: "UnsplashSecrets", withExtension: "plist") {
                guard let data = try? Data(contentsOf: url),
                      let dictionary = try? PropertyListSerialization.propertyList(from: data, format: nil),
                      let strings = dictionary as? [String: String] else {
                    throw AuthConfigurationError.invalidSecretsFile
                }
                values.merge(strings) { _, new in new }
            }
        }
        let configuration = AuthConfiguration(
            accessKey: environment["UNSPLASH_ACCESS_KEY"] ?? values["AccessKey"] ?? "",
            secretKey: environment["UNSPLASH_SECRET_KEY"] ?? values["SecretKey"] ?? "",
            redirectURI: environment["UNSPLASH_REDIRECT_URI"]
                ?? values["RedirectURI"]
                ?? Constants.defaultRedirectURI
        )
        try configuration.validate()
        return configuration
    }

    func authorizationURL(state: String? = nil) throws -> URL {
        try validate()
        var components = URLComponents()
        components.scheme = "https"
        components.host = "unsplash.com"
        components.path = "/oauth/authorize"
        components.queryItems = [
            URLQueryItem(name: "client_id", value: accessKey),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " "))
        ]
        if let state {
            components.queryItems?.append(URLQueryItem(name: "state", value: state))
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        guard let url = components.url else {
            throw AuthConfigurationError.invalidURL
        }
        return url
    }

    func tokenRequest(code: String) throws -> URLRequest {
        try validate()
        guard !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OAuth2ServiceError.invalidAuthorizationCode
        }
        guard let url = URL(string: "https://unsplash.com/oauth/token") else {
            throw AuthConfigurationError.invalidURL
        }
        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "client_id", value: accessKey),
            URLQueryItem(name: "client_secret", value: secretKey),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        guard let encodedBody = body.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B") else {
            throw AuthConfigurationError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data(encodedBody.utf8)
        return request
    }

    private func validate() throws {
        guard !accessKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !secretKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AuthConfigurationError.missingKeys
        }
        guard let redirect = URLComponents(string: redirectURI),
              let scheme = redirect.scheme,
              !scheme.isEmpty,
              redirect.url != nil else {
            throw AuthConfigurationError.invalidRedirectURI
        }
        guard !scopes.isEmpty, scopes.allSatisfy({ !$0.isEmpty }) else {
            throw AuthConfigurationError.invalidScopes
        }
    }
}

enum AuthConfigurationError: Error {
    case missingKeys
    case invalidSecretsFile
    case invalidRedirectURI
    case invalidScopes
    case invalidURL
}
