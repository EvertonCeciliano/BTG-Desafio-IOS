import XCTest
@testable import btg

@MainActor
final class CurrencyListViewModelTests: XCTestCase {

    private var sut: CurrencyListViewModel!
    private var mockRepo: MockCurrencyRepository!

    override func setUp() async throws {
        mockRepo = MockCurrencyRepository()
        sut = CurrencyListViewModel(repository: mockRepo)
        await sut.fetchCurrencies()
    }

    override func tearDown() {
        sut = nil
        mockRepo = nil
    }

    // MARK: - fetchCurrencies

    func test_fetch_populatesAllCurrencies() {
        XCTAssertEqual(sut.filteredCurrencies.count, mockRepo.mockCurrencies.count)
    }

    func test_fetch_onError_setsErrorMessage() async {
        mockRepo.shouldThrow = true
        let vm = CurrencyListViewModel(repository: mockRepo)
        await vm.fetchCurrencies()
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
        XCTAssertTrue(vm.filteredCurrencies.isEmpty)
    }

    // MARK: - filter

    func test_filterByCode_returnsExactMatch() {
        sut.filter(with: "USD")
        XCTAssertEqual(sut.filteredCurrencies.count, 1)
        XCTAssertEqual(sut.filteredCurrencies.first?.code, "USD")
    }

    func test_filterByName_caseInsensitive() {
        sut.filter(with: "euro")
        XCTAssertEqual(sut.filteredCurrencies.count, 1)
        XCTAssertEqual(sut.filteredCurrencies.first?.code, "EUR")
    }

    func test_filterByPartialName() {
        sut.filter(with: "Real")
        XCTAssertEqual(sut.filteredCurrencies.count, 1)
        XCTAssertEqual(sut.filteredCurrencies.first?.code, "BRL")
    }

    func test_filterNoMatch_returnsEmpty() {
        sut.filter(with: "ZZZNOMATCH")
        XCTAssertTrue(sut.filteredCurrencies.isEmpty)
    }

    func test_filterEmpty_returnsAll() {
        sut.filter(with: "ZZZNOMATCH")
        sut.filter(with: "")
        XCTAssertEqual(sut.filteredCurrencies.count, mockRepo.mockCurrencies.count)
    }

    // MARK: - sort

    func test_sortByCode_isAlphabetical() {
        sut.sort(by: .code)
        let codes = sut.filteredCurrencies.map { $0.code }
        XCTAssertEqual(codes, codes.sorted())
    }

    func test_sortByName_isAlphabetical() {
        sut.sort(by: .name)
        let names = sut.filteredCurrencies.map { $0.name }
        XCTAssertEqual(names, names.sorted())
    }

    func test_sortPreservesAfterFilter() {
        sut.sort(by: .code)
        sut.filter(with: "")
        let codes = sut.filteredCurrencies.map { $0.code }
        XCTAssertEqual(codes, codes.sorted())
    }

    func test_filterPreservesSort() {
        sut.sort(by: .code)
        sut.filter(with: "U")
        XCTAssertTrue(sut.filteredCurrencies.allSatisfy {
            $0.code.lowercased().contains("u") || $0.name.lowercased().contains("u")
        })
    }
}
