import UIKit
import Combine

class CurrencyListViewController: UIViewController {

    private let viewModel = CurrencyListViewModel()
    private var cancellables = Set<AnyCancellable>()
    var onSelect: ((Currency) -> Void)?

    // MARK: - UI Elements

    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "Buscar por nome ou código"
        return sc
    }()

    private let sortSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: SortOrder.allCases.map { $0.label })
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(CurrencyCell.self, forCellReuseIdentifier: CurrencyCell.reuseID)
        tv.delegate = self
        tv.dataSource = self
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 56
        return tv
    }()

    private let emptyLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Nenhuma moeda encontrada."
        lbl.textColor = .secondaryLabel
        lbl.textAlignment = .center
        lbl.font = .systemFont(ofSize: 16)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.isHidden = true
        return lbl
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Moedas"
        view.backgroundColor = .systemBackground

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        setupUI()
        bindViewModel()
        Task { await viewModel.fetchCurrencies() }
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(sortSegment)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            sortSegment.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            sortSegment.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sortSegment.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: sortSegment.bottomAnchor, constant: 8),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        sortSegment.addTarget(self, action: #selector(sortChanged), for: .valueChanged)
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$filteredCurrencies
            .receive(on: RunLoop.main)
            .sink { [weak self] currencies in
                self?.tableView.reloadData()
                self?.emptyLabel.isHidden = !currencies.isEmpty
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] loading in
                loading ? self?.activityIndicator.startAnimating()
                        : self?.activityIndicator.stopAnimating()
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: RunLoop.main)
            .compactMap { $0 }
            .sink { [weak self] msg in self?.showError(msg) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func sortChanged(_ sc: UISegmentedControl) {
        let order = SortOrder.allCases[sc.selectedSegmentIndex]
        viewModel.sort(by: order)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Erro", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate

extension CurrencyListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.filteredCurrencies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CurrencyCell.reuseID, for: indexPath) as! CurrencyCell
        cell.configure(with: viewModel.filteredCurrencies[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let currency = viewModel.filteredCurrencies[indexPath.row]
        onSelect?(currency)
        dismiss(animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension CurrencyListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.filter(with: searchController.searchBar.text ?? "")
    }
}

// MARK: - CurrencyCell

class CurrencyCell: UITableViewCell {
    static let reuseID = "CurrencyCell"

    private let codeLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 16, weight: .bold)
        return lbl
    }()

    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = .secondaryLabel
        lbl.numberOfLines = 0
        return lbl
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let stack = UIStackView(arrangedSubviews: [codeLabel, nameLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with currency: Currency) {
        codeLabel.text = "\(currency.flag)  \(currency.code)"
        nameLabel.text = currency.name
    }
}
