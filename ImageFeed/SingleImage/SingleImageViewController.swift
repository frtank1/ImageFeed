import UIKit

final class SingleImageViewController: UIViewController {
    var image: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            updateImage()
        }
    }

    @IBOutlet private weak var scrollView: UIScrollView!
    private let imageView = UIImageView()
    private let shareButton = UIButton(type: .custom)
    private let backButton = UIButton(type: .custom)
    private var lastViewportSize: CGSize = .zero

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 26 / 255, green: 27 / 255, blue: 34 / 255, alpha: 1)
        configureViews()
        updateImage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard scrollView.bounds.size != lastViewportSize else { return }
        rescaleImage()
    }

    private func configureViews() {
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = "Фотография"
        scrollView.addSubview(imageView)

        let navigationBackground = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        navigationBackground.translatesAutoresizingMaskIntoConstraints = false
        navigationBackground.isUserInteractionEnabled = false
        view.addSubview(navigationBackground)

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(named: "back_button")?.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = .white
        backButton.accessibilityLabel = "Назад"
        backButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)
        view.addSubview(backButton)

        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setImage(UIImage(named: "share_button"), for: .normal)
        shareButton.accessibilityLabel = "Поделиться"
        shareButton.addTarget(self, action: #selector(didTapShareButton), for: .touchUpInside)
        view.addSubview(shareButton)

        NSLayoutConstraint.activate([
            navigationBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBackground.topAnchor.constraint(equalTo: view.topAnchor),
            navigationBackground.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 6),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -17),
            shareButton.widthAnchor.constraint(equalToConstant: 50),
            shareButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func updateImage() {
        scrollView.zoomScale = 1
        imageView.image = image
        imageView.frame = CGRect(origin: .zero, size: image?.size ?? .zero)
        scrollView.contentSize = imageView.bounds.size
        shareButton.isEnabled = image != nil
        lastViewportSize = .zero
        view.setNeedsLayout()
    }

    private func rescaleImage() {
        let viewport = scrollView.bounds.size
        guard let image,
              image.size.width > 0,
              image.size.height > 0,
              viewport.width > 0,
              viewport.height > 0 else { return }

        lastViewportSize = viewport
        let horizontalScale = viewport.width / image.size.width
        let verticalScale = viewport.height / image.size.height
        let fitScale = min(horizontalScale, verticalScale)
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        let initialScale = min(scrollView.maximumZoomScale, max(scrollView.minimumZoomScale, fitScale))
        scrollView.setZoomScale(initialScale, animated: false)
        scrollView.layoutIfNeeded()
        centerImage()
        scrollView.contentOffset = CGPoint(
            x: max(0, (scrollView.contentSize.width - viewport.width) / 2) - scrollView.contentInset.left,
            y: max(0, (scrollView.contentSize.height - viewport.height) / 2) - scrollView.contentInset.top
        )
    }

    private func centerImage() {
        let horizontalInset = max(0, (scrollView.bounds.width - scrollView.contentSize.width) / 2)
        let verticalInset = max(0, (scrollView.bounds.height - scrollView.contentSize.height) / 2)
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }

    @objc private func didTapShareButton() {
        guard let image else { return }
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityController.popoverPresentationController?.sourceView = shareButton
        activityController.popoverPresentationController?.sourceRect = shareButton.bounds
        present(activityController, animated: true)
    }

    @objc private func didTapBackButton() {
        dismiss(animated: true)
    }
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}
