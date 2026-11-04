import UIKit

final class SplashViewController: UIViewController {
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private var tokenStorage = OAuth2TokenStorage.shared
    private var mainViewControllerProvider: () -> UIViewController = {
        UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabBarViewController")
    }
    private var isRouting = false

    func configure(
        tokenStorage: OAuth2TokenStorage,
        mainViewControllerProvider: (() -> UIViewController)? = nil
    ) {
        self.tokenStorage = tokenStorage
        if let mainViewControllerProvider {
            self.mainViewControllerProvider = mainViewControllerProvider
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !isRouting else { return }
        isRouting = true
        if let token = tokenStorage.token, !token.isEmpty {
            switchToTabBarController()
        } else {
            performSegue(withIdentifier: showAuthenticationScreenSegueIdentifier, sender: nil)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == showAuthenticationScreenSegueIdentifier,
              let navigationController = segue.destination as? UINavigationController,
              let authViewController = navigationController.viewControllers.first as? AuthViewController else { return }
        authViewController.configure(tokenStorage: tokenStorage)
        authViewController.delegate = self
    }

    private func switchToTabBarController() {
        guard let window = view.window else {
            isRouting = false
            return
        }
        window.rootViewController = mainViewControllerProvider()
        window.makeKeyAndVisible()
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ viewController: AuthViewController) {
        dismiss(animated: false) { [weak self] in
            self?.switchToTabBarController()
        }
    }
}
