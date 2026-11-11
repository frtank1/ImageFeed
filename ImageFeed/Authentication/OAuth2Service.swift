import Foundation

protocol OAuthTokenFetching: AnyObject {
    func fetchAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void)
    func cancel()
}

final class OAuth2Service: OAuthTokenFetching {
    typealias Completion = (Result<String, Error>) -> Void

    static let shared = OAuth2Service()

    private let session = URLSession.shared
    private var task: URLSessionDataTask?
    private var requestID: UUID?
    private var completion: Completion?

    private init() {}

    deinit {
        task?.cancel()
    }

    func fetchAuthToken(code: String, completion: @escaping Completion) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.fetchAuthToken(code: code, completion: completion)
            }
            return
        }
        cancel()
        let request: URLRequest
        do {
            let configuration = try AuthConfiguration.load()
            request = try configuration.tokenRequest(code: code)
        } catch {
            print(OAuth2Diagnostics.requestError(error))
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
        let identifier = UUID()
        requestID = identifier
        self.completion = completion
        task = session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self, self.requestID == identifier else { return }
                self.finish(with: self.tokenResult(data: data, response: response, error: error))
            }
        }
        task?.resume()
    }

    func cancel() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.cancel()
            }
            return
        }
        let pendingTask = task
        finish(with: .failure(OAuth2ServiceError.cancelled))
        pendingTask?.cancel()
    }

    private func finish(with result: Result<String, Error>) {
        let callback = completion
        completion = nil
        task = nil
        requestID = nil
        if let callback {
            DispatchQueue.main.async {
                callback(result)
            }
        }
    }

    private func tokenResult(data: Data?, response: URLResponse?, error: Error?) -> Result<String, Error> {
        if let error {
            print(OAuth2Diagnostics.networkError(error))
            return .failure(error)
        }
        guard let response = response as? HTTPURLResponse else {
            print("OAuth: invalid HTTP response")
            return .failure(OAuth2ServiceError.invalidResponse)
        }
        guard (200..<300).contains(response.statusCode) else {
            print(OAuth2Diagnostics.httpError(response.statusCode))
            return .failure(OAuth2ServiceError.httpStatus(response.statusCode))
        }
        guard let data, !data.isEmpty else {
            print("OAuth: empty response body")
            return .failure(OAuth2ServiceError.emptyData)
        }
        let body: OAuthTokenResponseBody
        do {
            body = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
        } catch {
            print(OAuth2Diagnostics.decodingError(error))
            return .failure(OAuth2ServiceError.decodingFailed)
        }
        guard !body.accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("OAuth: empty token in response")
            return .failure(OAuth2ServiceError.emptyToken)
        }
        return .success(body.accessToken)
    }
}

enum OAuth2Diagnostics {
    static func requestError(_ error: Error) -> String {
        let category: String
        switch error {
        case AuthConfigurationError.missingKeys:
            category = "missing configuration"
        case AuthConfigurationError.invalidSecretsFile:
            category = "invalid configuration file"
        case AuthConfigurationError.invalidURL:
            category = "invalid URL"
        case AuthConfigurationError.invalidRedirectURI:
            category = "invalid redirect URI"
        case AuthConfigurationError.invalidScopes:
            category = "invalid scopes"
        case OAuth2ServiceError.invalidAuthorizationCode:
            category = "invalid authorization code"
        default:
            category = "request construction failed"
        }
        return "OAuth: \(category)"
    }

    static func networkError(_ error: Error) -> String {
        if let error = error as? URLError {
            return "OAuth: network error (\(error.code.rawValue))"
        }
        return "OAuth: network error"
    }

    static func httpError(_ statusCode: Int) -> String {
        "OAuth: HTTP error (\(statusCode))"
    }

    static func decodingError(_ error: Error) -> String {
        let category: String
        switch error {
        case DecodingError.typeMismatch:
            category = "typeMismatch"
        case DecodingError.valueNotFound:
            category = "valueNotFound"
        case DecodingError.keyNotFound:
            category = "keyNotFound"
        case DecodingError.dataCorrupted:
            category = "dataCorrupted"
        default:
            category = "unknown"
        }
        return "OAuth: JSON decoding error (\(category))"
    }
}

enum OAuth2ServiceError: Error, Equatable {
    case invalidAuthorizationCode
    case invalidResponse
    case httpStatus(Int)
    case emptyData
    case decodingFailed
    case emptyToken
    case cancelled
}
