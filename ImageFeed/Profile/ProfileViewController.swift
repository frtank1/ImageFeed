import UIKit

final class ProfileViewController: UIViewController {
    private let avatarImageView = UIImageView(image: UIImage(named: "avatar"))
    private let nameLabel = UILabel()
    private let loginNameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let logoutButton = UIButton(type: .custom)

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 26 / 255, green: 27 / 255, blue: 34 / 255, alpha: 1)
        configureViews()
        configureConstraints()
    }

    private func configureViews() {
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 35
        avatarImageView.clipsToBounds = true

        nameLabel.text = "Екатерина Новикова"
        nameLabel.font = .systemFont(ofSize: 23, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 0

        loginNameLabel.text = "@ekaterina_nov"
        loginNameLabel.font = .systemFont(ofSize: 13)
        loginNameLabel.textColor = UIColor(red: 174 / 255, green: 175 / 255, blue: 180 / 255, alpha: 1)

        descriptionLabel.text = "Hello, World!"
        descriptionLabel.font = .systemFont(ofSize: 13)
        descriptionLabel.textColor = .white
        descriptionLabel.numberOfLines = 0

        logoutButton.setImage(UIImage(named: "logout_button"), for: .normal)
        logoutButton.accessibilityLabel = "Выйти"
        logoutButton.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)

        for subview in [avatarImageView, nameLabel, loginNameLabel, descriptionLabel, logoutButton] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }
    }

    private func configureConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            avatarImageView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 32),
            avatarImageView.widthAnchor.constraint(equalToConstant: 70),
            avatarImageView.heightAnchor.constraint(equalToConstant: 70),
            nameLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            loginNameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            logoutButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            logoutButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func didTapLogoutButton() {
    }
}
