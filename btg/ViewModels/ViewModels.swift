import Foundation
import Combine

// MARK: - ConversionViewModel

class ConversionViewModel {
    @Published var originCurrency: Currency? = Currency(code: "USD", name: "United States Dollar")
    @Published var destinationCurrency: Currency? = Currency(code: "BRL", name: "Brazilian Real")
    @Published var amountText: String = ""
    @Published var resultText: String = ""
    @Published var rateText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let repository: CurrencyRepositoryProtocol
    private var rates: LiveRates?
    private var cancellables = Set<AnyCancellable>()

    init(repository: CurrencyRepositoryProtocol = CurrencyRepository()) {
        self.repository = repository

        $originCurrency
            .combineLatest($destinationCurrency)
            .sink { [weak self] (origin, dest) in
                self?.updateRate(origin: origin, dest: dest)
            }
            .store(in: &cancellables)

        $amountText
            .combineLatest($originCurrency, $destinationCurrency)
            .sink { [weak self] (amount, origin, dest) in
                self?.calculateConversion(amount: amount, origin: origin, dest: dest)
            }
            .store(in: &cancellables)
    }

    @MainActor
    func fetchRates() async {
        isLoading = true
        do {
            rates = try await repository.getLiveRates()
            updateRate(origin: originCurrency, dest: destinationCurrency)
            calculateConversion(amount: amountText, origin: originCurrency, dest: destinationCurrency)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func updateRate(origin: Currency?, dest: Currency?) {
        guard let origin, let dest, let rates else { return }

        let originKey = "\(rates.source)\(origin.code)"
        let destKey   = "\(rates.source)\(dest.code)"

        let originRate = rates.quotes[originKey] ?? 1.0
        let destRate   = rates.quotes[destKey] ?? 1.0

        let unitInUSD = origin.code == rates.source ? 1.0 : 1.0 / originRate
        let unitRate  = dest.code == rates.source ? unitInUSD : unitInUSD * destRate
        rateText = "1 \(origin.code) = \(formatRate(unitRate)) \(dest.code)"
    }

    func calculateConversion(amount: String, origin: Currency?, dest: Currency?) {
        guard let origin,
              let dest,
              let rates else {
            resultText = ""
            return
        }

        let sanitized = amount.replacingOccurrences(of: ",", with: ".")
        guard !sanitized.isEmpty,
              let value = Double(sanitized),
              value > 0 else {
            resultText = ""
            return
        }

        let originKey = "\(rates.source)\(origin.code)"
        let destKey   = "\(rates.source)\(dest.code)"

        let originRate = rates.quotes[originKey] ?? 1.0
        let destRate   = rates.quotes[destKey] ?? 1.0

        let amountInUSD = origin.code == rates.source ? value : value / originRate
        let finalAmount = dest.code == rates.source ? amountInUSD : amountInUSD * destRate

        resultText = String(format: "%.2f", finalAmount)
    }

    private func formatRate(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 3
        formatter.maximumFractionDigits = value >= 1 ? 4 : 6
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.4f", value)
    }

    func swapCurrencies() {
        let temp = originCurrency
        originCurrency = destinationCurrency
        destinationCurrency = temp
    }
}

// MARK: - CurrencyListViewModel

enum SortOrder: CaseIterable {
    case name, code

    var label: String {
        switch self {
        case .name: return "Nome"
        case .code: return "Código"
        }
    }
}

class CurrencyListViewModel {
    @Published var filteredCurrencies: [Currency] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var allCurrencies: [Currency] = []
    private var searchQuery: String = ""
    private(set) var sortOrder: SortOrder = .name

    private let repository: CurrencyRepositoryProtocol

    init(repository: CurrencyRepositoryProtocol = CurrencyRepository()) {
        self.repository = repository
    }

    @MainActor
    func fetchCurrencies() async {
        isLoading = true
        do {
            allCurrencies = try await repository.getCurrencies()
            applyFilterAndSort()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func filter(with query: String) {
        searchQuery = query
        applyFilterAndSort()
    }

    func sort(by order: SortOrder) {
        sortOrder = order
        applyFilterAndSort()
    }

    private func applyFilterAndSort() {
        var result = allCurrencies

        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            result = result.filter {
                $0.code.lowercased().contains(q) || $0.name.lowercased().contains(q)
            }
        }

        switch sortOrder {
        case .name: result.sort { $0.name < $1.name }
        case .code: result.sort { $0.code < $1.code }
        }

        filteredCurrencies = result
    }
}
