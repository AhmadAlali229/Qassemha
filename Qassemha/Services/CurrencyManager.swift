//
//  CurrencyManager.swift
//  Qassemha
//
//  Created on 2025-11-10.
//

import Foundation
import SwiftUI

enum Currency: String, CaseIterable, Codable {
    case riyal = "SAR"
    case usd = "USD"

    var symbol: String {
        switch self {
        case .riyal:
            return "﷼"
        case .usd:
            return "$"
        }
    }

    var name: String {
        switch self {
        case .riyal:
            return "Saudi Riyal"
        case .usd:
            return "US Dollar"
        }
    }

    var code: String {
        return self.rawValue
    }
}

class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()

    @Published var selectedCurrency: Currency {
        didSet {
            UserDefaults.standard.set(selectedCurrency.rawValue, forKey: "selectedCurrency")
        }
    }

    private init() {
        // Set Riyal as default currency
        let savedCurrency = UserDefaults.standard.string(forKey: "selectedCurrency")
        self.selectedCurrency = Currency(rawValue: savedCurrency ?? Currency.riyal.rawValue) ?? .riyal
    }

    /// Formats monetary amount with currently selected currency symbol and two decimal places
    /// Ensures consistent currency display across all receipt and payment views
    // Format amount with current currency
    func format(amount: Double) -> String {
        return "\(selectedCurrency.symbol)\(String(format: "%.2f", amount))"
    }

    /// Formats monetary amount with specified currency symbol, overriding user preference
    /// Allows displaying amounts in original receipt currency when needed
    // Format amount with specific currency
    func format(amount: Double, currency: Currency) -> String {
        return "\(currency.symbol)\(String(format: "%.2f", amount))"
    }

    // Get currency symbol
    var currencySymbol: String {
        return selectedCurrency.symbol
    }

    // Get currency code
    var currencyCode: String {
        return selectedCurrency.code
    }

    /// Switches between Riyal and USD currency options
    /// Provides quick currency switching for users operating in multiple markets
    // Toggle between currencies
    func toggleCurrency() {
        selectedCurrency = selectedCurrency == .riyal ? .usd : .riyal
    }

    /// Updates selected currency to specified value
    /// Allows programmatic currency changes from settings or receipt scanning
    // Set specific currency
    func setCurrency(_ currency: Currency) {
        selectedCurrency = currency
    }
}
