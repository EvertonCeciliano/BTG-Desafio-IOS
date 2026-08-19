import UIKit
import Combine

class ConversionViewController: UIViewController {

    private let viewModel = ConversionViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Header

    private let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "btg-logo"))
        iv.contentMode = .scaleAspectFit
        iv.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return iv
    }()

    private let headerLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Conversor de Moedas"
        lbl.font = .systemFont(ofSize: 26, weight: .bold)
        lbl.textAlignment = .center
        return lbl
    }()

    // MARK: - Amount

    private let amountCard: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 16
        return v
    }()

    private let amountHintLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "VALOR"
        lbl.font = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = .secondaryLabel
        return lbl
    }()

    private let amountTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "0,00"
        tf.keyboardType = .decimalPad
        tf.font = .systemFont(ofSize: 36, weight: .semibold)
        tf.borderStyle = .none
        return tf
    }()

    // MARK: - Currency Selection

    private let fromHintLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "DE"
        lbl.font = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = .secondaryLabel
        return lbl
    }()

    private let toHintLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "PARA"
        lbl.font = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = .secondaryLabel
        return lbl
    }()

    private let originButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.layer.cornerRadius = 16
        return btn
    }()

    private let destButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.layer.cornerRadius = 16
        return btn
    }()

    private let swapButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        btn.setImage(UIImage(systemName: "arrow.left.arrow.right", withConfiguration: cfg), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 22
        return btn
    }()

    // MARK: - Result

    private let resultCard: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBlue.withAlphaComponent(0.08)
        v.layer.cornerRadius = 16
        return v
    }()

    private let resultHintLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "RESULTADO"
        lbl.font = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = .secondaryLabel
        lbl.textAlignment = .center
        return lbl
    }()

    private let resultValueLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "--"
        lbl.font = .systemFont(ofSize: 44, weight: .bold)
        lbl.textColor = .systemBlue
        lbl.textAlignment = .center
        lbl.adjustsFontSizeToFitWidth = true
        lbl.minimumScaleFactor = 0.4
        return lbl
    }()

    private let resultCurrencyLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 13)
        lbl.textColor = .secondaryLabel
        lbl.textAlignment = .center
        return lbl
    }()

    private let rateTitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Taxa de câmbio comercial  ⓘ"
        lbl.font = .systemFont(ofSize: 12, weight: .medium)
        lbl.textColor = .secondaryLabel
        lbl.textAlignment = .center
        return lbl
    }()

    private let ratePillLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 15, weight: .semibold)
        lbl.textColor = .label
        lbl.textAlignment = .center
        lbl.backgroundColor = .secondarySystemFill
        lbl.layer.cornerRadius = 12
        lbl.layer.masksToBounds = true
        return lbl
    }()

    private let rateContainer: UIView = {
        let v = UIView()
        v.isHidden = true
        return v
    }()

    // MARK: - Scroll

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    // MARK: - Activity Indicator

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        bindViewModel()
        Task { await viewModel.fetchRates() }
    }


    // MARK: - Setup

    private func setupUI() {
        view.addSubview(scrollView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Amount card
        let amountInner = makeVStack([amountHintLabel, amountTextField], spacing: 6)
        amountInner.layoutMargins = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
        amountInner.isLayoutMarginsRelativeArrangement = true
        amountInner.translatesAutoresizingMaskIntoConstraints = false
        amountCard.addSubview(amountInner)
        pinEdges(amountInner, to: amountCard)

        // Currency row
        let fromColumn = makeVStack([fromHintLabel, originButton], spacing: 6)
        let toColumn   = makeVStack([toHintLabel, destButton], spacing: 6)
        let currencyRow = UIStackView(arrangedSubviews: [fromColumn, swapButton, toColumn])
        currencyRow.axis = .horizontal
        currencyRow.spacing = 12
        currencyRow.alignment = .center
        fromColumn.widthAnchor.constraint(equalTo: toColumn.widthAnchor).isActive = true

        // Result card
        let resultInner = makeVStack([resultHintLabel, resultValueLabel, resultCurrencyLabel], spacing: 4)
        resultInner.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        resultInner.isLayoutMarginsRelativeArrangement = true
        resultInner.translatesAutoresizingMaskIntoConstraints = false
        resultCard.addSubview(resultInner)
        pinEdges(resultInner, to: resultCard)

        // Rate container
        ratePillLabel.translatesAutoresizingMaskIntoConstraints = false
        rateContainer.addSubview(rateTitleLabel)
        rateContainer.addSubview(ratePillLabel)
        rateTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            rateTitleLabel.topAnchor.constraint(equalTo: rateContainer.topAnchor),
            rateTitleLabel.centerXAnchor.constraint(equalTo: rateContainer.centerXAnchor),

            ratePillLabel.topAnchor.constraint(equalTo: rateTitleLabel.bottomAnchor, constant: 8),
            ratePillLabel.centerXAnchor.constraint(equalTo: rateContainer.centerXAnchor),
            ratePillLabel.bottomAnchor.constraint(equalTo: rateContainer.bottomAnchor),
            ratePillLabel.widthAnchor.constraint(greaterThanOrEqualTo: rateTitleLabel.widthAnchor),
        ])
        ratePillLabel.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

        // Main stack inside scroll
        let mainStack = makeVStack([logoImageView, headerLabel, rateContainer, amountCard, currencyRow, resultCard], spacing: 20)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            mainStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            mainStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),

            originButton.heightAnchor.constraint(equalToConstant: 68),
            destButton.heightAnchor.constraint(equalToConstant: 68),
            swapButton.widthAnchor.constraint(equalToConstant: 44),
            swapButton.heightAnchor.constraint(equalToConstant: 44),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        amountTextField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)
        originButton.addTarget(self, action: #selector(originTapped), for: .touchUpInside)
        destButton.addTarget(self, action: #selector(destTapped), for: .touchUpInside)
        swapButton.addTarget(self, action: #selector(swapTapped), for: .touchUpInside)

        configureCurrencyButton(originButton, currency: viewModel.originCurrency)
        configureCurrencyButton(destButton, currency: viewModel.destinationCurrency)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$originCurrency
            .receive(on: RunLoop.main)
            .sink { [weak self] currency in
                self?.configureCurrencyButton(self?.originButton, currency: currency)
            }
            .store(in: &cancellables)

        viewModel.$destinationCurrency
            .receive(on: RunLoop.main)
            .sink { [weak self] currency in
                self?.configureCurrencyButton(self?.destButton, currency: currency)
                self?.resultCurrencyLabel.text = currency.map { "\($0.name) (\($0.code))" } ?? ""
            }
            .store(in: &cancellables)

        viewModel.$resultText
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.resultValueLabel.text = result.isEmpty ? "--" : result
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] loading in
                loading ? self?.activityIndicator.startAnimating()
                        : self?.activityIndicator.stopAnimating()
            }
            .store(in: &cancellables)

        viewModel.$rateText
            .receive(on: RunLoop.main)
            .sink { [weak self] rate in
                guard let self else { return }
                rateContainer.isHidden = rate.isEmpty
                ratePillLabel.text = rate.isEmpty ? nil : "  \(rate)  "
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: RunLoop.main)
            .compactMap { $0 }
            .sink { [weak self] msg in self?.showError(msg) }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo }
            .receive(on: RunLoop.main)
            .sink { [weak self] info in
                guard let self,
                      let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
                let inset = frame.height - view.safeAreaInsets.bottom
                UIView.animate(withDuration: duration) {
                    self.scrollView.contentInset.bottom = inset
                    self.scrollView.verticalScrollIndicatorInsets.bottom = inset
                }
                let rect = self.scrollView.convert(self.amountTextField.bounds, from: self.amountTextField)
                self.scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -24), animated: true)
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double }
            .receive(on: RunLoop.main)
            .sink { [weak self] duration in
                UIView.animate(withDuration: duration) {
                    self?.scrollView.contentInset.bottom = 0
                    self?.scrollView.verticalScrollIndicatorInsets.bottom = 0
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func amountChanged(_ tf: UITextField) {
        viewModel.amountText = tf.text ?? ""
    }

    @objc private func swapTapped() {
        swapButton.isEnabled = false

        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 1) {
            self.swapButton.transform = self.swapButton.transform.rotated(by: .pi)
        }

        UIView.animate(withDuration: 0.15, animations: {
            self.originButton.alpha = 0
            self.originButton.transform = CGAffineTransform(translationX: 20, y: 0)
            self.destButton.alpha = 0
            self.destButton.transform = CGAffineTransform(translationX: -20, y: 0)
        }) { _ in
            self.viewModel.swapCurrencies()
            self.configureCurrencyButton(self.originButton, currency: self.viewModel.originCurrency)
            self.configureCurrencyButton(self.destButton, currency: self.viewModel.destinationCurrency)
            self.originButton.transform = CGAffineTransform(translationX: -20, y: 0)
            self.destButton.transform = CGAffineTransform(translationX: 20, y: 0)
            UIView.animate(withDuration: 0.2) {
                self.originButton.alpha = 1
                self.originButton.transform = .identity
                self.destButton.alpha = 1
                self.destButton.transform = .identity
            } completion: { _ in
                self.swapButton.isEnabled = true
            }
        }
    }
    @objc private func originTapped()   { openCurrencyList(isOrigin: true) }
    @objc private func destTapped()     { openCurrencyList(isOrigin: false) }
    @objc private func dismissKeyboard() { view.endEditing(true) }

    private func openCurrencyList(isOrigin: Bool) {
        let vc = CurrencyListViewController()
        vc.onSelect = { [weak self] currency in
            if isOrigin {
                self?.viewModel.originCurrency = currency
            } else {
                self?.viewModel.destinationCurrency = currency
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Erro", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Helpers

    private func configureCurrencyButton(_ button: UIButton?, currency: Currency?) {
        guard let button else { return }
        var cfg = UIButton.Configuration.gray()
        let flag = currency?.flag ?? ""
        cfg.title = flag.isEmpty ? (currency?.code ?? "---") : "\(flag) \(currency?.code ?? "---")"
        cfg.subtitle = currency?.name ?? "Selecionar"
        cfg.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.systemFont(ofSize: 20, weight: .bold)
            return out
        }
        cfg.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.systemFont(ofSize: 11)
            return out
        }
        cfg.background.cornerRadius = 16
        button.configuration = cfg
    }

    private func makeVStack(_ views: [UIView], spacing: CGFloat) -> UIStackView {
        let sv = UIStackView(arrangedSubviews: views)
        sv.axis = .vertical
        sv.spacing = spacing
        return sv
    }

    private func pinEdges(_ child: UIView, to parent: UIView) {
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: parent.topAnchor),
            child.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
        ])
    }
}
