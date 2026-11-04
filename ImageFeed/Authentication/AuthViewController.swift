import UIKit

protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ viewController: AuthViewController)
}

final class AuthViewController: UIViewController {
    weak var delegate: AuthViewControllerDelegate?

    @IBOutlet private weak var loginButton: UIButton!

    private var tokenStorage = OAuth2TokenStorage.shared
    private var configurationProvider: () throws -> AuthConfiguration = { try AuthConfiguration.load() }
    private var serviceProvider: (AuthConfiguration) -> OAuthTokenFetching = { OAuth2Service(configuration: $0) }
    private var configuration: AuthConfiguration?
    private var service: OAuthTokenFetching?
    private weak var activeWebViewController: WebViewViewController?
    private var attemptID: UUID?

    func configure(
        tokenStorage: OAuth2TokenStorage,
        configurationProvider: @escaping () throws -> AuthConfiguration = { try AuthConfiguration.load() },
        serviceProvider: @escaping (AuthConfiguration) -> OAuthTokenFetching = { OAuth2Service(configuration: $0) }
    ) {
        self.tokenStorage = tokenStorage
        self.configurationProvider = configurationProvider
        self.serviceProvider = serviceProvider
    }

    deinit {
        service?.cancel()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.layer.cornerRadius = 16
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barStyle = .black
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowWebView",
              let webViewController = segue.destination as? WebViewViewController,
              let configuration else { return }
        webViewController.configure(configuration: configuration)
        webViewController.delegate = self
        activeWebViewController = webViewController
    }

    @IBAction private func didTapLoginButton(_ sender: UIButton) {
        guard attemptID == nil,
              presentedViewController == nil,
              navigationController?.topViewController === self else { return }
        do {
            let configuration = try configurationProvider()
            self.configuration = configuration
            service = serviceProvider(configuration)
            attemptID = UUID()
            setLoading(true)
            performSegue(withIdentifier: "ShowWebView", sender: nil)
        } catch {
            showError(error)
        }
    }

    private func setLoading(_ isLoading: Bool) {
        loginButton.isEnabled = !isLoading
        loginButton.setTitle(isLoading ? "Вход…" : "Войти", for: .normal)
        loginButton.alpha = isLoading ? 0.6 : 1
    }

    private func finishAttempt() {
        attemptID = nil
        activeWebViewController = nil
        configuration = nil
        service?.cancel()
        service = nil
        setLoading(false)
    }

    private func showError(_ error: Error) {
        guard presentedViewController == nil else { return }
        let message: String
        if error is AuthConfigurationError {
            message = "Вход пока недоступен. Попробуйте позже."
        } else {
            message = "Не удалось войти. Попробуйте ещё раз."
        }
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }

    private func exchangeCode(_ code: String, attempt: UUID) {
        service?.fetchOAuthToken(code) { [weak self] result in
            guard let self, self.attemptID == attempt else { return }
            self.finishAttempt()
            switch result {
            case .success(let token):
                self.tokenStorage.token = token
                self.delegate?.didAuthenticate(self)
            case .failure(let error):
                if error as? OAuth2ServiceError != .cancelled {
                    self.showError(error)
                }
            }
        }
    }

    private func finishWebView(_ viewController: WebViewViewController, result: Result<String, Error>) {
        guard activeWebViewController === viewController, let attempt = attemptID else { return }
        activeWebViewController = nil
        navigationController?.popToViewController(self, animated: true)
        let completion = { [weak self] in
            guard let self, self.attemptID == attempt else { return }
            switch result {
            case .success(let code):
                self.exchangeCode(code, attempt: attempt)
            case .failure(let error):
                self.finishAttempt()
                if error as? OAuthCallbackError != .cancelled {
                    self.showError(error)
                }
            }
        }
        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in completion() }
        } else {
            completion()
        }
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ viewController: WebViewViewController, didAuthenticateWithCode code: String) {
        finishWebView(viewController, result: .success(code))
    }

    func webViewViewControllerDidCancel(_ viewController: WebViewViewController) {
        finishWebView(viewController, result: .failure(OAuthCallbackError.cancelled))
    }

    func webViewViewController(_ viewController: WebViewViewController, didFailWith error: Error) {
        finishWebView(viewController, result: .failure(error))
    }
}
