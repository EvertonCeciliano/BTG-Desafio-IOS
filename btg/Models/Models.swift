import Foundation

struct Currency: Codable, Equatable, Hashable {
    let code: String
    let name: String

    var flag: String {
        let countryCode = code.prefix(2).uppercased()
        guard countryCode.first?.isLetter == true, countryCode.last?.isLetter == true else { return "🏳️" }
        let base: UInt32 = 127397
        return countryCode.unicodeScalars.compactMap {
            Unicode.Scalar(base + $0.value).map(String.init)
        }.joined()
    }
}

struct LiveRates: Codable {
    let source: String
    let quotes: [String: Double]
}

struct CurrencyListResponse: Codable {
    let success: Bool
    let terms: String?
    let privacy: String?
    let currencies: [String: String]?
    let error: APIErrorResponse?
}

struct LiveRatesResponse: Codable {
    let success: Bool
    let terms: String?
    let privacy: String?
    let timestamp: Int?
    let source: String?
    let quotes: [String: Double]?
    let error: APIErrorResponse?
}

struct APIErrorResponse: Codable {
    let code: Int
    let info: String
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case serverError
    case networkError(Error)
    case decodingError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL configuration."
        case .serverError: return "Server returned an error."
        case .networkError(let error): return error.localizedDescription
        case .decodingError: return "Failed to decode response."
        case .noData: return "No data available."
        }
    }
}
