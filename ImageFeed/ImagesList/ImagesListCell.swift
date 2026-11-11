import UIKit

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"

    @IBOutlet private var cellImage: UIImageView?
    @IBOutlet private var dateLabel: UILabel?
    @IBOutlet private var likeButton: UIButton?

    private let dateGradient = CAGradientLayer()

    override func awakeFromNib() {
        super.awakeFromNib()
        guard let cellImage else { return }
        cellImage.layer.cornerRadius = 16
        cellImage.clipsToBounds = true
        dateGradient.colors = [
            UIColor(red: 26 / 255, green: 27 / 255, blue: 34 / 255, alpha: 0).cgColor,
            UIColor(red: 26 / 255, green: 27 / 255, blue: 34 / 255, alpha: 1).cgColor
        ]
        cellImage.layer.addSublayer(dateGradient)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let cellImage else { return }
        contentView.layoutIfNeeded()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let gradientHeight = min(30, cellImage.bounds.height)
        dateGradient.frame = CGRect(
            x: 0,
            y: cellImage.bounds.height - gradientHeight,
            width: cellImage.bounds.width,
            height: gradientHeight
        )
        CATransaction.commit()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage?.image = nil
        dateLabel?.text = nil
        likeButton?.setImage(nil, for: .normal)
    }

    func configure(image: UIImage?, dateText: String?, isLiked: Bool) {
        cellImage?.image = image
        dateLabel?.text = dateText
        let imageName = isLiked ? "like_button_on" : "like_button_off"
        likeButton?.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal), for: .normal)
    }
}
