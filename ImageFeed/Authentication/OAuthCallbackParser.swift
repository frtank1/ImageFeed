import Foundation

struct OAuthCallbackParser {
    let redirectURI: String
    let expectedState: String

    func result(for url: URL) -> Result<String, OAuthCallbackError>? {
        guard let expected = URLComponents(string: redirectURI),
              let actual = URLComponents(url: url, resolvingAgainstBaseURL: false),
              actual.scheme?.lowercased() == expected.scheme?.lowercased(),
              actual.host?.lowercased() == expected.host?.lowercased(),
              actual.port == expected.port,
              actual.percentEncodedPath == expected.percentEncodedPath,
              actual.user == nil,
              actual.password == nil else {
            return nil
        }
        let items = actual.queryItems ?? []
        let states = items.filter { $0.name == "state" }
        guard states.count == 1, states.first?.value == expectedState else {
            return .failure(.invalidState)
        }
        let errors = items.filter { $0.name == "error" }
        if !errors.isEmpty {
            return .failure(errors.count == 1 && errors.first?.value == "access_denied" ? .cancelled : .authorizationFailed)
        }
        let codes = items.filter { $0.name == "code" }
        guard codes.count == 1,
              let code = codes.first?.value,
              !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.missingCode)
        }
        return .success(code)
    }
}

enum OAuthCallbackError: Error, Equatable {
    case invalidState
    case missingCode
    case authorizationFailed
    case cancelled
}
