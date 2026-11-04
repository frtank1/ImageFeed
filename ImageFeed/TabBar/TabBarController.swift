import UIKit

final class TabBarController: UITabBarController {
    override var childForStatusBarStyle: UIViewController? {
        selectedViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 26 / 255, green: 27 / 255, blue: 34 / 255, alpha: 1)
        appearance.shadowColor = .clear
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .white
        tabBar.unselectedItemTintColor = UIColor(red: 174 / 255, green: 175 / 255, blue: 180 / 255, alpha: 1)

        guard let controllers = viewControllers, controllers.count == 2 else { return }
        controllers[0].tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "tab_feed")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "tab_feed_selected")?.withRenderingMode(.alwaysOriginal)
        )
        controllers[0].tabBarItem.accessibilityLabel = "Лента"
        controllers[1].tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "tab_profile")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "tab_profile_selected")?.withRenderingMode(.alwaysOriginal)
        )
        controllers[1].tabBarItem.accessibilityLabel = "Профиль"
        for controller in controllers {
            controller.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        }
    }
}
