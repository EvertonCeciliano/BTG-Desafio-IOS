import Foundation
@testable import btg

// MARK: - MockCurrencyRepository

final class MockCurrencyRepository: CurrencyRepositoryProtocol {
    var shouldThrow = false
    var mockCurrencies: [Currency] = [
        Currency(code: "USD", name: "United States Dollar"),
        Currency(code: "BRL", name: "Brazilian Real"),
        Currency(code: "EUR", name: "Euro"),
        Currency(code: "GBP", name: "British Pound"),
    ]
    var mockRates = LiveRates(source: "USD", quotes: [
        "USDUSD": 1.0,
        "USDBRL": 5.0,
        "USDEUR": 0.9,
        "USDGBP": 0.8,
    ])

    func getCurrencies() async throws -> [Currency] {
        if shouldThrow { throw APIError.noData }
        return mockCurrencies
    }

    func getLiveRates() async throws -> LiveRates {
        if shouldThrow { throw APIError.noData }
        return mockRates
    }
}

// MARK: - MockNetworkService

final class MockNetworkService: NetworkServiceProtocol {
    var shouldThrow = false
    var currencyResponse = CurrencyListResponse(
        success: true,
        terms: nil,
        privacy: nil,
        currencies: [
            "USD": "United States Dollar",
            "BRL": "Brazilian Real",
            "EUR": "Euro",
            "GBP": "British Pound",
        ],
        error: nil
    )
    var liveRatesResponse = LiveRatesResponse(
        success: true,
        terms: nil,
        privacy: nil,
        timestamp: nil,
        source: "USD",
        quotes: ["USDUSD": 1.0, "USDBRL": 5.0, "USDEUR": 0.9, "USDGBP": 0.8],
        error: nil
    )

    func fetchCurrencies() async throws -> CurrencyListResponse {
        if shouldThrow { throw APIError.networkError(URLError(.notConnectedToInternet)) }
        return currencyResponse
    }

    func fetchLiveRates() async throws -> LiveRatesResponse {
        if shouldThrow { throw APIError.networkError(URLError(.notConnectedToInternet)) }
        return liveRatesResponse
    }
}

// MARK: - MockPersistenceService

final class MockPersistenceService: PersistenceServiceProtocol {
    var storage: [String: Data] = [:]

    func save<T: Encodable>(_ object: T, forKey key: String) {
        storage[key] = try? JSONEncoder().encode(object)
    }

    func load<T: Decodable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = storage[key] else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
