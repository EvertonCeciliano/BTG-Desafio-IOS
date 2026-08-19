import XCTest
import Combine
@testable import btg

@MainActor
final class ConversionViewModelTests: XCTestCase {

    private var sut: ConversionViewModel!
    private var mockRepo: MockCurrencyRepository!

    override func setUp() async throws {
        mockRepo = MockCurrencyRepository()
        sut = ConversionViewModel(repository: mockRepo)
        await sut.fetchRates()
    }

    override func tearDown() {
        sut = nil
        mockRepo = nil
    }

    // MARK: - fetchRates

    func test_fetchRates_clearsLoadingFlag() async {
        let vm = ConversionViewModel(repository: mockRepo)
        await vm.fetchRates()
        XCTAssertFalse(vm.isLoading)
    }

    func test_fetchRates_setsRateText() {
        XCTAssertFalse(sut.rateText.isEmpty)
    }

    func test_fetchRates_onError_setsErrorMessage() async {
        mockRepo.shouldThrow = true
        let vm = ConversionViewModel(repository: mockRepo)
        await vm.fetchRates()
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - calculateConversion

    func test_conversion_USDtoBRL() {
        sut.calculateConversion(
            amount: "1",
            origin: Currency(code: "USD", name: "United States Dollar"),
            dest: Currency(code: "BRL", name: "Brazilian Real")
        )
        XCTAssertEqual(sut.resultText, "5.00")
    }

    func test_conversion_BRLtoUSD() {
        sut.calculateConversion(
            amount: "5",
            origin: Currency(code: "BRL", name: "Brazilian Real"),
            dest: Currency(code: "USD", name: "United States Dollar")
        )
        XCTAssertEqual(sut.resultText, "1.00")
    }

    func test_conversion_crossRate_BRLtoEUR() {
        // 10 BRL → USD: 10/5 = 2 → EUR: 2 * 0.9 = 1.80
        sut.calculateConversion(
            amount: "10",
            origin: Currency(code: "BRL", name: "Brazilian Real"),
            dest: Currency(code: "EUR", name: "Euro")
        )
        XCTAssertEqual(sut.resultText, "1.80")
    }

    func test_conversion_sameCurrency_returnsEqualAmount() {
        sut.calculateConversion(
            amount: "100",
            origin: Currency(code: "USD", name: "United States Dollar"),
            dest: Currency(code: "USD", name: "United States Dollar")
        )
        XCTAssertEqual(sut.resultText, "100.00")
    }

    func test_conversion_emptyAmount_clearsResult() {
        sut.calculateConversion(
            amount: "",
            origin: Currency(code: "USD", name: "United States Dollar"),
            dest: Currency(code: "BRL", name: "Brazilian Real")
        )
        XCTAssertEqual(sut.resultText, "")
    }

    func test_conversion_invalidAmount_clearsResult() {
        sut.calculateConversion(
            amount: "abc",
            origin: Currency(code: "USD", name: "United States Dollar"),
            dest: Currency(code: "BRL", name: "Brazilian Real")
        )
        XCTAssertEqual(sut.resultText, "")
    }

    func test_conversion_zeroAmount_clearsResult() {
        sut.calculateConversion(
            amount: "0",
            origin: Currency(code: "USD", name: "United States Dollar"),
            dest: Currency(code: "BRL", name: "Brazilian Real")
        )
        XCTAssertEqual(sut.resultText, "")
    }

    func test_conversion_commaDecimalSeparator() {
        sut.calculateConversion(
            amount: "2,5",
            origin: Currency(code: "USD", name: "United States Dollar"),
            dest: Currency(code: "BRL", name: "Brazilian Real")
        )
        XCTAssertEqual(sut.resultText, "12.50")
    }

    func test_conversion_nilOrigin_clearsResult() {
        sut.calculateConversion(
            amount: "10",
            origin: nil,
            dest: Currency(code: "BRL", name: "Brazilian Real")
        )
        XCTAssertEqual(sut.resultText, "")
    }

    func test_conversion_nilDest_clearsResult() {
        sut.calculateConversion(
            amount: "10",
            origin: Currency(code: "USD", name: "United States Dollar"),
            dest: nil
        )
        XCTAssertEqual(sut.resultText, "")
    }

    // MARK: - swapCurrencies

    func test_swap_exchangesOriginAndDestination() {
        let original = sut.originCurrency
        let dest = sut.destinationCurrency
        sut.swapCurrencies()
        XCTAssertEqual(sut.originCurrency, dest)
        XCTAssertEqual(sut.destinationCurrency, original)
    }

    func test_swap_twice_restoresOriginalPair() {
        let original = sut.originCurrency
        let dest = sut.destinationCurrency
        sut.swapCurrencies()
        sut.swapCurrencies()
        XCTAssertEqual(sut.originCurrency, original)
        XCTAssertEqual(sut.destinationCurrency, dest)
    }
}
