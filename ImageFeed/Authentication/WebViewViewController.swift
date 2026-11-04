import UIKit
import WebKit

protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ viewController: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ viewController: WebViewViewController)
    func webViewViewController(_ viewController: WebViewViewController, didFailWith error: Error)
}

final class WebViewViewController: UIViewController {
    weak var delegate: WebViewViewControllerDelegate?

    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var progressView: UIProgressView!

    private var configuration: AuthConfiguration?
    private let state = UUID().uuidString
    private var progressObservation: NSKeyValueObservation?
    private var isFinished = false

    func configure(configuration: AuthConfiguration) {
        self.configuration = configuration
    }

    deinit {
        progressObservation?.invalidate()
        webView?.stopLoading()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "nav_back_button")?.withRenderingMode(.alwaysTemplate),
            style: .plain,
            target: self,
            action: #selector(cancelAuthorization)
        )
        navigationItem.leftBarButtonItem?.accessibilityLabel = "Назад"
        navigationController?.navigationBar.tintColor = UIColor(red: 26 / 255, green: 27 / 255, blue: 34 / 255, alpha: 1)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        webView.navigationDelegate = self
        loadAuthorizationPage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barStyle = .default
        navigationController?.setNavigationBarHidden(false, animated: animated)
        guard !isFinished, progressObservation == nil else { return }
        progressObservation = webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] webView, _ in
            let progress = webView.estimatedProgress
            DispatchQueue.main.async {
                self?.updateProgress(progress)
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        progressObservation?.invalidate()
        progressObservation = nil
    }

    private func loadAuthorizationPage() {
        guard let configuration else {
            finish(with: .failure(AuthConfigurationError.missingKeys))
            return
        }
        do {
            let url = try configuration.authorizationURL(state: state)
            progressView.isHidden = false
            progressView.progress = 0
            webView.load(URLRequest(url: url))
        } catch {
            finish(with: .failure(error))
        }
    }

    private func updateProgress(_ progress: Double) {
        guard !isFinished else { return }
        progressView.setProgress(Float(progress), animated: true)
        progressView.isHidden = abs(progress - 1) <= 0.0001
    }

    @objc private func cancelAuthorization() {
        finish(with: .failure(OAuthCallbackError.cancelled))
    }

    private func finish(with result: Result<String, Error>) {
        guard !isFinished else { return }
        isFinished = true
        progressObservation?.invalidate()
        webView.stopLoading()
        switch result {
        case .success(let code):
            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
        case .failure(let error):
            if error as? OAuthCallbackError == .cancelled {
                delegate?.webViewViewControllerDidCancel(self)
            } else {
                delegate?.webViewViewController(self, didFailWith: error)
            }
        }
    }

    private func showLoadingError(_ error: Error) {
        guard !isFinished,
              (error as NSError).code != NSURLErrorCancelled,
              presentedViewController == nil else { return }
        progressView.isHidden = true
        let alert = UIAlertController(
            title: "Не удалось загрузить страницу",
            message: "Проверьте подключение к интернету и попробуйте ещё раз.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { [weak self] _ in
            self?.cancelAuthorization()
        })
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            self?.loadAuthorizationPage()
        })
        present(alert, animated: true)
    }
}

extension WebViewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, let configuration else {
            decisionHandler(.cancel)
            return
        }
        let parser = OAuthCallbackParser(redirectURI: configuration.redirectURI, expectedState: state)
        if let result = parser.result(for: url) {
            decisionHandler(.cancel)
            finish(with: result.mapError { $0 as Error })
        } else {
            decisionHandler(url.scheme?.lowercased() == "https" ? .allow : .cancel)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showLoadingError(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showLoadingError(error)
    }
}
