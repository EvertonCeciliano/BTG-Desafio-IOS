import XCTest
@testable import btg

final class CurrencyRepositoryTests: XCTestCase {

    private var sut: CurrencyRepository!
    private var mockNetwork: MockNetworkService!
    private var mockPersistence: MockPersistenceService!

    override func setUp() {
        mockNetwork = MockNetworkService()
        mockPersistence = MockPersistenceService()
        sut = CurrencyRepository(networkService: mockNetwork, persistenceService: mockPersistence)
    }

    override func tearDown() {
        sut = nil
        mockNetwork = nil
        mockPersistence = nil
    }

    // MARK: - getCurrencies

    func test_getCurrencies_success_returnsNetworkData() async throws {
        let currencies = try await sut.getCurrencies()
        XCTAssertFalse(currencies.isEmpty)
        XCTAssertTrue(currencies.contains { $0.code == "USD" })
    }

    func test_getCurrencies_success_persistsData() async throws {
        _ = try await sut.getCurrencies()
        XCTAssertNotNil(mockPersistence.storage["cached_currencies"])
    }

    func test_getCurrencies_networkFailure_usesCachedData() async throws {
        _ = try await sut.getCurrencies()
        mockNetwork.shouldThrow = true
        let currencies = try await sut.getCurrencies()
        XCTAssertFalse(currencies.isEmpty)
    }

    func test_getCurrencies_networkFailure_noCache_returnsFallback() async throws {
        mockNetwork.shouldThrow = true
        let currencies = try await sut.getCurrencies()
        XCTAssertFalse(currencies.isEmpty)
    }

    func test_getCurrencies_sortedAlphabeticallyByName() async throws {
        let currencies = try await sut.getCurrencies()
        let names = currencies.map { $0.name }
        XCTAssertEqual(names, names.sorted())
    }

    // MARK: - getLiveRates

    func test_getLiveRates_success_returnsNetworkData() async throws {
        let rates = try await sut.getLiveRates()
        XCTAssertEqual(rates.source, "USD")
        XCTAssertFalse(rates.quotes.isEmpty)
    }

    func test_getLiveRates_success_persistsData() async throws {
        _ = try await sut.getLiveRates()
        XCTAssertNotNil(mockPersistence.storage["cached_rates"])
    }

    func test_getLiveRates_networkFailure_usesCachedData() async throws {
        _ = try await sut.getLiveRates()
        mockNetwork.shouldThrow = true
        let rates = try await sut.getLiveRates()
        XCTAssertFalse(rates.quotes.isEmpty)
    }

    func test_getLiveRates_networkFailure_noCache_returnsFallback() async throws {
        mockNetwork.shouldThrow = true
        let rates = try await sut.getLiveRates()
        XCTAssertFalse(rates.quotes.isEmpty)
    }

    func test_getLiveRates_containsUSDUSDRate() async throws {
        let rates = try await sut.getLiveRates()
        XCTAssertEqual(rates.quotes["USDUSD"], 1.0)
    }
}
