import Foundation

// MARK: - Persistence
protocol PersistenceServiceProtocol {
    func save<T: Encodable>(_ object: T, forKey key: String)
    func load<T: Decodable>(forKey key: String, as type: T.Type) -> T?
}

class UserDefaultsPersistenceService: PersistenceServiceProtocol {
    private let defaults = UserDefaults.standard
    
    func save<T: Encodable>(_ object: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(object) {
            defaults.set(encoded, forKey: key)
        }
    }
    
    func load<T: Decodable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Network
protocol NetworkServiceProtocol {
    func fetchCurrencies() async throws -> CurrencyListResponse
    func fetchLiveRates() async throws -> LiveRatesResponse
}

class BTGNetworkService: NetworkServiceProtocol {
    private let listURL = "https://raw.githubusercontent.com/Banking-iOS/mock-interview/main/api/list.json"
    private let liveURL = "https://raw.githubusercontent.com/Banking-iOS/mock-interview/main/api/live.json"
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchCurrencies() async throws -> CurrencyListResponse {
        guard let url = URL(string: listURL) else { throw APIError.invalidURL }
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError
            }
            return try JSONDecoder().decode(CurrencyListResponse.self, from: data)
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func fetchLiveRates() async throws -> LiveRatesResponse {
        guard let url = URL(string: liveURL) else { throw APIError.invalidURL }
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError
            }
            return try JSONDecoder().decode(LiveRatesResponse.self, from: data)
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Repository
protocol CurrencyRepositoryProtocol {
    func getCurrencies() async throws -> [Currency]
    func getLiveRates() async throws -> LiveRates
}

class CurrencyRepository: CurrencyRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    private let persistenceService: PersistenceServiceProtocol
    
    private let currenciesKey = "cached_currencies"
    private let ratesKey = "cached_rates"
    
    init(networkService: NetworkServiceProtocol = BTGNetworkService(),
         persistenceService: PersistenceServiceProtocol = UserDefaultsPersistenceService()) {
        self.networkService = networkService
        self.persistenceService = persistenceService
    }
    
    func getCurrencies() async throws -> [Currency] {
        do {
            let response = try await networkService.fetchCurrencies()
            if response.success, let dict = response.currencies {
                let currencies = dict.map { Currency(code: $0.key, name: $0.value) }.sorted(by: { $0.name < $1.name })
                persistenceService.save(currencies, forKey: currenciesKey)
                return currencies
            } else {
                return try getCachedCurrencies()
            }
        } catch {
            return try getCachedCurrencies()
        }
    }
    
    func getLiveRates() async throws -> LiveRates {
        do {
            let response = try await networkService.fetchLiveRates()
            if response.success, let quotes = response.quotes {
                let rates = LiveRates(source: response.source ?? "USD", quotes: quotes)
                persistenceService.save(rates, forKey: ratesKey)
                return rates
            } else {
                return try getCachedRates()
            }
        } catch {
            return try getCachedRates()
        }
    }
    
    private func getCachedCurrencies() throws -> [Currency] {
        guard let cached = persistenceService.load(forKey: currenciesKey, as: [Currency].self) else {
            // Mock fallback data so that it always works locally even without internet/API availability
            return [
                Currency(code: "USD", name: "United States Dollar"),
                Currency(code: "BRL", name: "Brazilian Real"),
                Currency(code: "EUR", name: "Euro"),
                Currency(code: "GBP", name: "British Pound")
            ].sorted(by: { $0.name < $1.name })
        }
        return cached
    }
    
    private func getCachedRates() throws -> LiveRates {
        guard let cached = persistenceService.load(forKey: ratesKey, as: LiveRates.self) else {
            // Mock fallback data
            return LiveRates(source: "USD", quotes: [
                "USDUSD": 1.0,
                "USDBRL": 5.0,
                "USDEUR": 0.9,
                "USDGBP": 0.8
            ])
        }
        return cached
    }
}
