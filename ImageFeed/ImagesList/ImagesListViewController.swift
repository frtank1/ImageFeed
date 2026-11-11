import UIKit

final class ImagesListViewController: UIViewController {
    @IBOutlet private var tableView: UITableView?

    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    private let photosName = Array(0..<20).map { String($0) }
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == showSingleImageSegueIdentifier,
              let indexPath = sender as? IndexPath,
              photosName.indices.contains(indexPath.row),
              let controller = segue.destination as? SingleImageViewController else { return }
        controller.image = UIImage(named: photosName[indexPath.row])
    }

    private func configureCell(_ cell: ImagesListCell, at indexPath: IndexPath) {
        let image = UIImage(named: photosName[indexPath.row])
        cell.configure(
            image: image,
            dateText: image == nil ? nil : dateFormatter.string(from: Date()),
            isLiked: indexPath.row.isMultiple(of: 2)
        )
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photosName.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reusableCell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        guard let cell = reusableCell as? ImagesListCell else {
            return UITableViewCell()
        }
        configureCell(cell, at: indexPath)
        return cell
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let image = UIImage(named: photosName[indexPath.row]), image.size.width > 0 else {
            return 0
        }
        let imageWidth = max(0, tableView.bounds.width - 32)
        return image.size.height / image.size.width * imageWidth + 8
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
}
