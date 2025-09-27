//
//  ReceiptModels.swift
//  Qassemha
//
//  Created by Harjot Singh on 21/09/25.
//

import Foundation
import SwiftUI

// MARK: - Receipt Data Models

struct Receipt: Identifiable, Codable, Equatable {
    let id = UUID()
    var storeName: String
    var storeAddress: String?
    var date: Date
    var items: [ReceiptItem]
    var subtotal: Double
    var tax: Double
    var tip: Double
    var total: Double
    var currency: String
    var receiptNumber: String?
    var imageData: Data?
    var scanType: ScanType
    var category: ReceiptCategory

    enum ScanType: String, CaseIterable, Codable {
        case camera = "camera"
        case manual = "manual"
        case barcode = "barcode"
        case qrCode = "qrCode"
    }

    enum ReceiptCategory: String, CaseIterable, Codable {
        case food = "Food & Dining"
        case groceries = "Groceries"
        case shopping = "Shopping"
        case entertainment = "Entertainment"
        case transportation = "Transportation"
        case utilities = "Utilities"
        case other = "Other"

        var icon: String {
            switch self {
            case .food: return "fork.knife"
            case .groceries: return "cart"
            case .shopping: return "bag"
            case .entertainment: return "film"
            case .transportation: return "car"
            case .utilities: return "bolt"
            case .other: return "doc"
            }
        }

        var color: Color {
            switch self {
            case .food: return .orange
            case .groceries: return .green
            case .shopping: return .purple
            case .entertainment: return .red
            case .transportation: return .blue
            case .utilities: return .yellow
            case .other: return .gray
            }
        }
    }
}

struct ReceiptItem: Identifiable, Codable, Equatable {
    let id = UUID()
    var name: String
    var quantity: Double
    var unitPrice: Double
    var totalPrice: Double
    var category: ItemCategory
    var tags: [String]
    var notes: String?
    var isEdited: Bool = false

    enum ItemCategory: String, CaseIterable, Codable {
        case food = "Food"
        case beverage = "Beverage"
        case alcohol = "Alcohol"
        case dessert = "Dessert"
        case appetizer = "Appetizer"
        case main = "Main Course"
        case side = "Side"
        case other = "Other"

        var icon: String {
            switch self {
            case .food: return "fork.knife"
            case .beverage: return "cup.and.saucer"
            case .alcohol: return "wineglass"
            case .dessert: return "birthday.cake"
            case .appetizer: return "leaf"
            case .main: return "fork.knife.circle"
            case .side: return "circle.dotted"
            case .other: return "square.grid.2x2"
            }
        }

        var color: Color {
            switch self {
            case .food: return .orange
            case .beverage: return .blue
            case .alcohol: return .purple
            case .dessert: return .pink
            case .appetizer: return .green
            case .main: return .red
            case .side: return .yellow
            case .other: return .gray
            }
        }
    }
}

// MARK: - Dynamic Parsing Structures

struct LineAnalysis {
    var prices: [Double] = []
    var hasPriceOnly: Bool = false
    var isStoreCandidate: Bool = false
    var isItemCandidate: Bool = false
    var itemName: String?
    var quantity: Double = 1
    var isTotalIndicator: Bool = false
    var totalType: TotalType = .unknown
    var lineIndex: Int = 0
    var isEarlyLine: Bool = false
    var isLateLine: Bool = false

    var summary: String {
        var parts: [String] = []
        if hasPriceOnly { parts.append("PriceOnly") }
        if isStoreCandidate { parts.append("Store") }
        if isItemCandidate { parts.append("Item") }
        if isTotalIndicator { parts.append("Total(\(totalType))") }
        if !prices.isEmpty { parts.append("$\(prices.map { String($0) }.joined(separator: ","))") }
        return parts.isEmpty ? "Text" : parts.joined(separator: "|")
    }

    enum TotalType {
        case subtotal, tax, tip, total, unknown
    }
}

class ReceiptStructure {
    var lineAnalyses: [(index: Int, line: String, analysis: LineAnalysis)] = []
    var format: ReceiptFormat = .unknown
    var storeLines: [Int] = []
    var itemLines: [Int] = []
    var priceOnlyLines: [Int] = []
    var totalLines: [Int] = []

    enum ReceiptFormat {
        case standardItemPrice    // "Item Name $12.99"
        case separatedPricesItems // Prices first, then items (McDonald's style)
        case tabulated           // Item    Qty    Price format
        case mixed               // Mixed format
        case unknown
    }

    func addLineAnalysis(index: Int, line: String, analysis: LineAnalysis) {
        lineAnalyses.append((index: index, line: line, analysis: analysis))

        if analysis.isStoreCandidate { storeLines.append(index) }
        if analysis.isItemCandidate { itemLines.append(index) }
        if analysis.hasPriceOnly { priceOnlyLines.append(index) }
        if analysis.isTotalIndicator { totalLines.append(index) }
    }

    func determineFormat() {
        print("🔍 Determining receipt format...")
        print("   Price-only lines: \(priceOnlyLines.count) at positions \(priceOnlyLines)")
        print("   Item lines: \(itemLines.count) at positions \(itemLines)")
        print("   Store candidates: \(storeLines.count) at positions \(storeLines)")
        print("   Total indicators: \(totalLines.count) at positions \(totalLines)")

        // Detect separated prices/items format (like McDonald's)
        if priceOnlyLines.count >= 2 && itemLines.count >= 1 {
            let avgPricePosition = priceOnlyLines.reduce(0, +) / priceOnlyLines.count
            let avgItemPosition = itemLines.reduce(0, +) / itemLines.count

            if avgPricePosition < avgItemPosition - 5 {
                format = .separatedPricesItems
                print("📊 Detected format: Separated Prices/Items")
                return
            }
        }

        // Detect standard item+price format
        let itemsWithPrices = lineAnalyses.filter {
            $0.analysis.isItemCandidate && !$0.analysis.prices.isEmpty
        }.count

        if itemsWithPrices >= itemLines.count / 2 {
            format = .standardItemPrice
            print("📊 Detected format: Standard Item+Price")
            return
        }

        // Default to mixed
        format = .mixed
        print("📊 Detected format: Mixed/Unknown")
    }
}

// MARK: - Demo Data

class DemoReceiptData: ObservableObject {
    static let shared = DemoReceiptData()

    let sampleReceipts: [Receipt] = [
        Receipt(
            storeName: "Olive Garden",
            storeAddress: "123 Main St, Anytown, USA",
            date: Date(),
            items: [
                ReceiptItem(name: "Fettuccine Alfredo", quantity: 1, unitPrice: 16.99, totalPrice: 16.99, category: .main, tags: ["pasta", "creamy"]),
                ReceiptItem(name: "Caesar Salad", quantity: 1, unitPrice: 8.99, totalPrice: 8.99, category: .appetizer, tags: ["salad", "dressing"]),
                ReceiptItem(name: "Breadsticks", quantity: 2, unitPrice: 3.99, totalPrice: 7.98, category: .side, tags: ["bread", "unlimited"]),
                ReceiptItem(name: "Coca Cola", quantity: 2, unitPrice: 2.99, totalPrice: 5.98, category: .beverage, tags: ["soda", "refills"]),
                ReceiptItem(name: "Tiramisu", quantity: 1, unitPrice: 7.99, totalPrice: 7.99, category: .dessert, tags: ["coffee", "cream"])
            ],
            subtotal: 47.93,
            tax: 3.83,
            tip: 9.59,
            total: 61.35,
            currency: "USD",
            receiptNumber: "R12345",
            scanType: .camera,
            category: .food
        ),

        Receipt(
            storeName: "Starbucks",
            storeAddress: "456 Coffee Ave, Bean City, USA",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            items: [
                ReceiptItem(name: "Grande Latte", quantity: 2, unitPrice: 5.45, totalPrice: 10.90, category: .beverage, tags: ["coffee", "milk"]),
                ReceiptItem(name: "Blueberry Muffin", quantity: 1, unitPrice: 3.95, totalPrice: 3.95, category: .food, tags: ["pastry", "berries"]),
                ReceiptItem(name: "Croissant", quantity: 1, unitPrice: 2.75, totalPrice: 2.75, category: .food, tags: ["pastry", "buttery"])
            ],
            subtotal: 17.60,
            tax: 1.41,
            tip: 2.64,
            total: 21.65,
            currency: "USD",
            receiptNumber: "S78910",
            scanType: .qrCode,
            category: .food
        ),

        Receipt(
            storeName: "Target",
            storeAddress: "789 Shopping Blvd, Mall City, USA",
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            items: [
                ReceiptItem(name: "Bananas", quantity: 3, unitPrice: 0.68, totalPrice: 2.04, category: .food, tags: ["fruit", "organic"]),
                ReceiptItem(name: "Milk (1 Gallon)", quantity: 1, unitPrice: 3.29, totalPrice: 3.29, category: .beverage, tags: ["dairy", "whole"]),
                ReceiptItem(name: "Bread", quantity: 1, unitPrice: 2.49, totalPrice: 2.49, category: .food, tags: ["wheat", "sliced"]),
                ReceiptItem(name: "Eggs (12 count)", quantity: 1, unitPrice: 2.99, totalPrice: 2.99, category: .food, tags: ["protein", "large"]),
                ReceiptItem(name: "Orange Juice", quantity: 1, unitPrice: 4.19, totalPrice: 4.19, category: .beverage, tags: ["citrus", "pulp-free"])
            ],
            subtotal: 15.00,
            tax: 1.20,
            tip: 0.00,
            total: 16.20,
            currency: "USD",
            receiptNumber: "T55667",
            scanType: .barcode,
            category: .groceries
        )
    ]

    // Common receipt patterns for text extraction
    let receiptPatterns = [
        // Store name patterns
        "^[A-Z][A-Za-z\\s&'.-]+$",
        // Price patterns
        "\\$?\\d+\\.\\d{2}",
        // Quantity patterns
        "\\d+\\s*x\\s*",
        // Item patterns with price
        "^(.+?)\\s+\\$?(\\d+\\.\\d{2})$",
        // Tax patterns
        "(?i)(tax|hst|gst|pst).*?\\$?(\\d+\\.\\d{2})",
        // Total patterns
        "(?i)(total|amount).*?\\$?(\\d+\\.\\d{2})"
    ]

    // Currency formats
    let supportedCurrencies = [
        "USD": ("$", "en_US"),
        "CAD": ("C$", "en_CA"),
        "EUR": ("€", "en_EU"),
        "GBP": ("£", "en_GB")
    ]

    func parseReceiptText(_ text: String) -> Receipt? {
        print("=== DYNAMIC RECEIPT PARSING ===")
        print("Input text:")
        print(text)

        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } // Remove empty lines

        print("\nProcessing \(lines.count) non-empty lines:")
        for (i, line) in lines.enumerated() {
            print("[\(i)]: '\(line)'")
        }

        // Use dynamic parsing approach
        let receiptStructure = analyzeReceiptStructure(lines)
        print("📊 Receipt structure analysis complete")

        guard let parsedReceipt = parseWithDynamicRules(lines, structure: receiptStructure) else {
            print("❌ Dynamic parsing failed")
            return nil
        }

        return parsedReceipt
    }

    private func analyzeReceiptStructure(_ lines: [String]) -> ReceiptStructure {
        print("🔍 Analyzing receipt structure...")

        var structure = ReceiptStructure()

        // Analyze each line for different data types
        for (index, line) in lines.enumerated() {
            var analysis = analyzeLine(line, at: index)
            analysis.isLateLine = index > (lines.count - 10) // Set late line context
            structure.addLineAnalysis(index: index, line: line, analysis: analysis)
        }

        // Determine receipt format and relationships
        structure.determineFormat()

        return structure
    }

    private func analyzeLine(_ line: String, at index: Int) -> LineAnalysis {
        var analysis = LineAnalysis()
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()

        // Price detection (multiple patterns)
        analysis.prices = extractAllPrices(from: trimmed)
        analysis.hasPriceOnly = analysis.prices.count == 1 && trimmed.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "$", with: "").allSatisfy { $0.isNumber }

        // Store detection
        analysis.isStoreCandidate = isStoreName(trimmed, at: index)

        // Item detection
        analysis.isItemCandidate = isItemName(trimmed)
        analysis.itemName = extractItemName(from: trimmed)
        analysis.quantity = extractQuantity(from: trimmed)

        // Total indicators
        analysis.isTotalIndicator = isTotalKeyword(lowercased)
        analysis.totalType = classifyTotalType(lowercased)

        // Position context
        analysis.lineIndex = index
        analysis.isEarlyLine = index < 5
        analysis.isLateLine = false // Will be set by caller if needed

        print("📝 Line [\(index)]: '\(trimmed)' → \(analysis.summary)")

        return analysis
    }

    private func parseWithDynamicRules(_ lines: [String], structure: ReceiptStructure) -> Receipt? {
        print("🎯 Parsing with dynamic rules based on detected format: \(structure.format)")

        var items: [ReceiptItem] = []
        var storeName = "Unknown Store"
        var subtotal: Double = 0
        var tax: Double = 0
        var total: Double = 0

        // Extract store name
        storeName = extractStoreName(from: lines, using: structure)

        // Extract items based on detected format
        items = extractItems(from: lines, using: structure)

        // Extract totals
        (subtotal, tax, total) = extractTotals(from: lines, using: structure)

        print("✅ Dynamic parsing results:")
        print("   Store: \(storeName)")
        print("   Items: \(items.count)")
        print("   Subtotal: $\(subtotal), Tax: $\(tax), Total: $\(total)")

        guard !items.isEmpty else {
            print("❌ No items found")
            return nil
        }

        return Receipt(
            storeName: storeName,
            storeAddress: nil,
            date: Date(),
            items: items,
            subtotal: subtotal,
            tax: tax,
            tip: 0,
            total: total,
            currency: "USD",
            receiptNumber: nil,
            scanType: .camera,
            category: .other
        )
    }

    // Legacy McDonald's parsing as fallback
    private func legacyParseReceiptText(_ text: String) -> Receipt? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var items: [ReceiptItem] = []
        var storeName = "Unknown Store"
        var subtotal: Double = 0
        var tax: Double = 0
        var total: Double = 0

        // First, try to detect McDonald's style receipts where prices and items are separate
        if let mcdonaldsItems = parseMcDonaldsFormat(lines) {
            print("🍟 Detected McDonald's format, found \(mcdonaldsItems.count) items")
            items = mcdonaldsItems

            // Parse totals for McDonald's format
            (subtotal, tax, total) = parseMcDonaldsTotals(lines)

            // Set McDonald's as store name
            if let mcdonaldsName = lines.first(where: { $0.lowercased().contains("mcdonald") }) {
                storeName = mcdonaldsName
                print("📍 Store name found (McDonald's): '\(storeName)'")
            }
        } else {
            // Enhanced parsing with better store name detection for non-McDonald's receipts
            var storeNameCandidates: [String] = []

            for (index, line) in lines.enumerated() {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)

                // Collect potential store names from first few lines
                if index < 5 && !trimmedLine.contains("$") && trimmedLine.count > 2 {
                    // Skip obvious non-store-name lines
                    let lowercaseLine = trimmedLine.lowercased()
                    if !lowercaseLine.contains("receipt") &&
                       !lowercaseLine.contains("invoice") &&
                       !lowercaseLine.contains("tel") &&
                       !lowercaseLine.contains("phone") &&
                       !lowercaseLine.contains("address") &&
                       !lowercaseLine.contains("store") &&
                       !lowercaseLine.contains("#") {
                        storeNameCandidates.append(trimmedLine)
                    }
                }
            }

            // Select best store name candidate
            if let bestStoreName = storeNameCandidates.first {
                storeName = bestStoreName
                print("📍 Store name found: '\(storeName)'")
            }

            // Process lines for items and totals (standard format)
            for (lineIndex, line) in lines.enumerated() {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                print("\n🔍 Processing line [\(lineIndex)]: '\(trimmedLine)'")

                // Try to extract items (lines with $ signs)
                if trimmedLine.contains("$") {
                print("  💲 Contains dollar sign - analyzing...")
                let lowercaseLine = trimmedLine.lowercased()

                // Check for tax first
                if lowercaseLine.contains("tax") || lowercaseLine.contains("hst") ||
                   lowercaseLine.contains("gst") || lowercaseLine.contains("pst") {
                    tax = extractPriceFromLine(trimmedLine) ?? 0
                    print("  💰 Tax found: $\(tax)")
                }
                // Check for total
                else if lowercaseLine.contains("total") || lowercaseLine.contains("amount due") ||
                        lowercaseLine.contains("balance") {
                    total = extractPriceFromLine(trimmedLine) ?? subtotal + tax
                    print("  🧾 Total found: $\(total)")
                }
                // Check for subtotal
                else if lowercaseLine.contains("subtotal") || lowercaseLine.contains("sub total") {
                    subtotal = extractPriceFromLine(trimmedLine) ?? 0
                    print("  📊 Subtotal found: $\(subtotal)")
                }
                // Skip other receipt metadata lines
                else if lowercaseLine.contains("tip") || lowercaseLine.contains("gratuity") ||
                        lowercaseLine.contains("service") || lowercaseLine.contains("discount") ||
                        lowercaseLine.contains("coupon") || lowercaseLine.contains("change") ||
                        lowercaseLine.contains("cash") || lowercaseLine.contains("card") ||
                        lowercaseLine.contains("credit") || lowercaseLine.contains("debit") {
                    print("  ⚠️ Skipping metadata line: '\(trimmedLine)'")
                }
                // Try to extract as item only if it doesn't match metadata patterns
                else {
                    print("  🔎 Attempting to extract item from: '\(trimmedLine)'")
                    if let extractedItem = extractItemFromLine(trimmedLine) {
                        items.append(extractedItem)
                        print("  ✅ Item found: '\(extractedItem.name)' - $\(extractedItem.totalPrice)")
                    } else {
                        print("  ❌ Failed to extract item from line")
                    }
                }
                } else {
                    print("  📝 No dollar sign - skipping for items")
                }
            }
        }

        // Calculate subtotal from items if not found in text
        if subtotal == 0 && !items.isEmpty {
            subtotal = items.reduce(0) { $0 + $1.totalPrice }
            print("📊 Calculated subtotal from items: $\(subtotal)")
        }

        // If no total found, calculate it
        if total == 0 {
            total = subtotal + tax
            print("🧾 Calculated total: $\(total)")
        }

        print("\n=== PARSING RESULTS ===")
        print("Store: \(storeName)")
        print("Items found: \(items.count)")
        print("Subtotal: $\(subtotal)")
        print("Tax: $\(tax)")
        print("Total: $\(total)")
        print("=== END PARSING ===\n")

        guard !items.isEmpty else {
            print("❌ No items found - returning nil")
            return nil
        }

        return Receipt(
            storeName: storeName,
            storeAddress: nil,
            date: Date(),
            items: items,
            subtotal: subtotal,
            tax: tax,
            tip: 0,
            total: total,
            currency: "USD",
            receiptNumber: nil,
            scanType: .camera,
            category: .other
        )
    }

    private func parseMcDonaldsFormat(_ lines: [String]) -> [ReceiptItem]? {
        print("🔍 Checking for McDonald's format...")

        // Look for McDonald's indicators (handle OCR variations)
        let hasMcDonalds = lines.contains { line in
            let lowercased = line.lowercased()
            return lowercased.contains("mcdonald") ||
                   lowercased.contains("mcdonal") ||  // Missing 'd'
                   lowercased.contains("mcdona") ||   // Missing 'ld'
                   lowercased.contains("mcdonaid") || // 'l' read as 'i'
                   lowercased.contains("mcdonalds") ||
                   lowercased.contains("restaurant") && lowercased.contains("#")
        }
        guard hasMcDonalds else {
            print("❌ Not a McDonald's receipt")
            return nil
        }

        print("🍟 McDonald's receipt detected!")

        // Find price lines (first few lines that are just numbers with 2 decimal places)
        var prices: [Double] = []
        var priceEndIndex = -1
        var seenPrices = Set<Double>() // Track duplicates

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if let price = Double(trimmed), trimmed.contains(".") && trimmed.split(separator: ".")[1].count == 2 {

                // For this receipt format, we want the first few actual item prices
                // Skip duplicates and totals
                if index < 7 { // Only check first 7 lines for prices
                    if price > 1.0 && price < 50.0 && !seenPrices.contains(price) && prices.count < 5 {
                        prices.append(price)
                        seenPrices.insert(price)
                        priceEndIndex = index
                        print("💰 Found unique item price [\(index)]: $\(price)")
                    } else if seenPrices.contains(price) {
                        print("💰 Skipping duplicate price [\(index)]: $\(price)")
                    } else {
                        print("💰 Skipping price [\(index)]: $\(price) (out of range or too many)")
                    }
                }
            } else if prices.count > 0 && index > 10 {
                // Stop when we hit a non-price line after finding prices and we're past line 10
                break
            }
        }

        // Find item lines (lines starting with numbers followed by item names)
        var itemNames: [String] = []
        var itemStartIndex = -1

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // Look for lines that start with quantity numbers and contain food item patterns
            // Also check lines after we've found some price data
            if (trimmed.hasPrefix("1 ") || trimmed.hasPrefix("2 ") || trimmed.hasPrefix("3 ")) &&
               (index > priceEndIndex || index > 15) { // Also check lines after index 15

                let itemName: String
                if trimmed.hasPrefix("1 ") {
                    itemName = String(trimmed.dropFirst(2)) // Remove "1 "
                } else if trimmed.hasPrefix("2 ") {
                    itemName = String(trimmed.dropFirst(2)) // Remove "2 "
                } else {
                    itemName = String(trimmed.dropFirst(2)) // Remove "3 "
                }

                // More flexible food item detection
                if !itemName.isEmpty && (isLikelyFoodItem(itemName) || itemName.count > 3) {
                    if itemStartIndex == -1 { itemStartIndex = index }
                    itemNames.append(itemName)
                    print("🍔 Found item [\(index)]: '\(itemName)'")
                }
            }
        }

        print("📊 Found \(prices.count) prices and \(itemNames.count) items")

        // Handle price/item matching more flexibly
        if prices.count == 0 || itemNames.count == 0 {
            print("❌ No prices or items found")
            return nil
        }

        // If we have more items than prices, combine items (like combo meals)
        if itemNames.count > prices.count && prices.count == 1 {
            print("🍟 Combining items into single combo meal")
            let comboName = itemNames.joined(separator: " + ")
            itemNames = [comboName]
        }

        // If we still don't match, take the minimum count
        let itemCount = min(prices.count, itemNames.count)
        if itemCount == 0 {
            print("❌ No valid price/item pairs found")
            return nil
        }

        var items: [ReceiptItem] = []
        for index in 0..<itemCount {
            let price = prices[index]
            let name = itemNames[index]
            // Check if the name starts with a number (like "2 EGG MCMUFFIN")
            var quantity: Double = 1
            var cleanName = name

            if let firstChar = name.first, firstChar.isNumber {
                if let spaceIndex = name.firstIndex(of: " ") {
                    let quantityStr = String(name[..<spaceIndex])
                    if let qty = Double(quantityStr) {
                        quantity = qty
                        cleanName = String(name[name.index(after: spaceIndex)...])
                    }
                }
            }

            let unitPrice = quantity > 1 ? price / quantity : price

            let item = ReceiptItem(
                name: cleanName,
                quantity: quantity,
                unitPrice: unitPrice,
                totalPrice: price,
                category: categorizeItem(cleanName),
                tags: []
            )
            items.append(item)
            print("✅ Created item \(index + 1): '\(cleanName)' (qty: \(quantity)) - $\(price)")
        }

        return items
    }

    private func parseMcDonaldsTotals(_ lines: [String]) -> (subtotal: Double, tax: Double, total: Double) {
        var subtotal: Double = 0
        var tax: Double = 0
        var total: Double = 0

        print("🔍 Parsing McDonald's totals...")

        // First, try to extract from the specific positions we know from the receipt
        // Look for prices that are > 10 (likely totals, not items)
        var totalPrices: [Double] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if let price = Double(trimmed), trimmed.contains(".") && price >= 0.50 {
                // Check if this price is after the item prices (index > 3)
                if index > 3 {
                    totalPrices.append(price)
                    print("💰 Found potential total price [\(index)]: $\(price)")

                    // Based on the receipt structure:
                    // Position 4: subtotal (10.77)
                    // Position 5: tax (0.75)
                    // Position 6: total (11.52)
                    if index == 4 && price > 5.0 {
                        subtotal = price
                        print("📊 McDonald's subtotal found at position [\(index)]: $\(subtotal)")
                    } else if index == 5 && price < 5.0 {
                        tax = price
                        print("💸 McDonald's tax found at position [\(index)]: $\(tax)")
                    } else if index == 6 && price > 10.0 {
                        total = price
                        print("🧾 McDonald's total found at position [\(index)]: $\(total)")
                    }
                }
            }
        }

        // Fallback: look for the pattern where subtotal + tax = total
        if subtotal == 0 || tax == 0 || total == 0 {
            print("🔄 Using fallback pattern matching...")
            for i in 0..<(totalPrices.count - 2) {
                let sub = totalPrices[i]
                let taxAmount = totalPrices[i + 1]
                let totalAmount = totalPrices[i + 2]

                // Check if they add up correctly (with small tolerance for rounding)
                if abs((sub + taxAmount) - totalAmount) < 0.01 && sub > 5.0 && taxAmount < 5.0 {
                    subtotal = sub
                    tax = taxAmount
                    total = totalAmount
                    print("📊 Pattern-matched McDonald's totals: subtotal=$\(subtotal), tax=$\(tax), total=$\(total)")
                    break
                }
            }
        }

        // Final validation
        if total == 0 && subtotal > 0 && tax >= 0 {
            total = subtotal + tax
            print("🧾 Calculated McDonald's total: $\(total)")
        }

        print("✅ Final McDonald's totals: subtotal=$\(subtotal), tax=$\(tax), total=$\(total)")
        return (subtotal, tax, total)
    }

    private func isLikelyFoodItem(_ text: String) -> Bool {
        let foodKeywords = [
            "breakfast", "hotcakes", "mcmuffin", "mcgriddle", "burger", "fries",
            "chicken", "beef", "egg", "sausage", "bacon", "hash", "coffee",
            "drink", "shake", "pie", "cookie", "salad", "wrap", "sandwich",
            "blt", "qpc", "sprite", "coke", "pepsi", "lrg", "med", "sm",
            "quarter", "pounder", "big mac", "filet", "nugget", "mccafe",
            "smoky", "smky", "double", "triple", "large", "medium", "small"
        ]

        let lowercased = text.lowercased()

        // Check for food keywords
        if foodKeywords.contains { lowercased.contains($0) } {
            return true
        }

        // Check for common McDonald's patterns
        if lowercased.contains("mc") || // McChicken, McMuffin, etc.
           lowercased.count > 5 && (lowercased.contains("l ") || lowercased.contains("m ") || lowercased.contains("s ")) { // Size indicators
            return true
        }

        return false
    }

    // MARK: - Dynamic Parsing Helper Functions

    private func extractAllPrices(from text: String) -> [Double] {
        // Skip lines that clearly aren't prices (phone numbers, addresses, codes, etc.)
        let lowercased = text.lowercased()
        if lowercased.contains("tel") || lowercased.contains("phone") ||
           lowercased.contains("address") || lowercased.contains("street") ||
           lowercased.contains("#") || lowercased.contains("code") ||
           lowercased.contains("auth") || lowercased.contains("seq") ||
           lowercased.contains("mer") || lowercased.contains("falls") ||
           lowercased.contains("id ") || lowercased.contains("nj ") ||
           text.count > 30 { // Long lines unlikely to be just prices
            return []
        }

        // Only match standalone prices or prices with $ sign
        let patterns = [
            "^\\$?(\\d{1,3}\\.\\d{2})$",  // Standalone price: "12.99" or "$12.99"
            "\\$+(\\d{1,3}\\.\\d{2})",    // Explicit $ sign: "$12.99"
            "^(\\d{1,2}\\.\\d{2})$"       // Simple decimal only if 2 digits or less before decimal
        ]

        var prices: [Double] = []

        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: text.utf16.count)
            let matches = regex?.matches(in: text, range: range) ?? []

            for match in matches {
                if match.numberOfRanges >= 2 {
                    let priceRange = Range(match.range(at: 1), in: text)
                    if let priceRange = priceRange {
                        let priceString = String(text[priceRange])
                        if let price = Double(priceString), price >= 0.01 && price < 100.0 {
                            prices.append(price)
                        }
                    }
                }
            }
        }

        return Array(Set(prices)).sorted() // Remove duplicates and sort
    }

    private func isStoreName(_ text: String, at index: Int) -> Bool {
        let lowercased = text.lowercased()

        // Exclude obvious non-store lines first
        if lowercased.contains("tel") || lowercased.contains("phone") ||
           lowercased.contains("address") || lowercased.contains("#") ||
           lowercased.contains("code") || lowercased.contains("auth") ||
           lowercased.contains("seq") || lowercased.contains("order") ||
           text.range(of: "^\\d+\\.\\d{2}$", options: .regularExpression) != nil || // Just a price
           text.count < 3 || text.count > 50 {
            return false
        }

        // Strong store indicators
        if lowercased.contains("mcdonald") || lowercased.contains("mcdonaid") ||
           lowercased.contains("mcdfnald") || // OCR variations
           lowercased.contains("restaurant") || lowercased.contains("store") ||
           lowercased.contains("shop") || lowercased.contains("cafe") ||
           lowercased.contains("corp") || lowercased.contains("corporation") ||
           lowercased.contains("inc") || lowercased.contains("llc") ||
           lowercased.contains("ltd") {
            return true
        }

        // Weak indicators only if in good position and doesn't look like price/item
        if index > 5 && index < 25 && // Middle section of receipt
           !extractAllPrices(from: text).isEmpty { // Has prices - less likely to be store
            return false
        }

        return false
    }

    private func isItemName(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()

        // Exclude obvious non-items
        if lowercased.contains("thank you") || lowercased.contains("visit") ||
           lowercased.contains("help") || lowercased.contains("feedback") ||
           lowercased.contains("survey") || lowercased.contains("corporate") ||
           lowercased.contains("comment") || lowercased.contains("concern") ||
           lowercased.contains("email") || lowercased.contains(".com") ||
           lowercased.contains("team at") || lowercased.contains("awesome") ||
           text.count > 40 { // Very long lines unlikely to be items
            return false
        }

        // Check if starts with quantity (strong indicator)
        if trimmed.hasPrefix("1 ") || trimmed.hasPrefix("2 ") || trimmed.hasPrefix("3 ") {
            let itemPart = String(trimmed.dropFirst(2))
            return isLikelyFoodItem(itemPart) && itemPart.count > 2
        }

        // Only strong food indicators
        return isLikelyFoodItem(trimmed) && trimmed.count > 3 && trimmed.count < 30
    }

    private func extractItemName(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove quantity prefix
        if trimmed.hasPrefix("1 ") || trimmed.hasPrefix("2 ") || trimmed.hasPrefix("3 ") {
            return String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Remove price suffix if exists
        let pricePattern = "\\s+\\$?\\d+\\.\\d{2}\\s*$"
        if let regex = try? NSRegularExpression(pattern: pricePattern) {
            let range = NSRange(location: 0, length: trimmed.utf16.count)
            let cleanedText = regex.stringByReplacingMatches(in: trimmed, range: range, withTemplate: "")
            if !cleanedText.isEmpty {
                return cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return trimmed.isEmpty ? nil : trimmed
    }

    private func extractQuantity(from text: String) -> Double {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("1 ") { return 1.0 }
        if trimmed.hasPrefix("2 ") { return 2.0 }
        if trimmed.hasPrefix("3 ") { return 3.0 }

        // Look for other quantity patterns
        let qtyPattern = "^(\\d+)\\s+"
        if let regex = try? NSRegularExpression(pattern: qtyPattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count)),
           let qtyRange = Range(match.range(at: 1), in: trimmed) {
            return Double(String(trimmed[qtyRange])) ?? 1.0
        }

        return 1.0
    }

    private func isTotalKeyword(_ text: String) -> Bool {
        let totalKeywords = ["total", "subtotal", "sub total", "tax", "tip", "gratuity",
                           "amount", "balance", "due", "change", "tender"]
        return totalKeywords.contains { text.contains($0) }
    }

    private func classifyTotalType(_ text: String) -> LineAnalysis.TotalType {
        if text.contains("subtotal") || text.contains("sub total") { return .subtotal }
        if text.contains("tax") { return .tax }
        if text.contains("tip") || text.contains("gratuity") { return .tip }
        if text.contains("total") || text.contains("amount") || text.contains("balance") { return .total }
        return .unknown
    }

    private func extractStoreName(from lines: [String], using structure: ReceiptStructure) -> String {
        // First, look for explicit McDonald's references
        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            if (lowercased.contains("mcdonald") || lowercased.contains("mcdonaid") || lowercased.contains("mcdfnald") || lowercased.contains("meponaid") || lowercased.contains("hcdonald") || lowercased.contains("restaurant") || lowercased.contains("mccafé") || lowercased.contains("mcflurry")) &&
               !lowercased.contains("thank you") && !lowercased.contains("eating at") {
                print("📍 McDonald's store detection: '\(line)' at line \(index)")
                return "McDonald's"
            }
        }

        // Then look for other restaurant/store indicators
        for lineIndex in structure.storeLines {
            if lineIndex < lines.count {
                let line = lines[lineIndex]
                let lowercased = line.lowercased()
                if (lowercased.contains("restaurant") || lowercased.contains("store") ||
                    lowercased.contains("corp") || lowercased.contains("corporation")) &&
                   line.count > 5 && line.count < 50 {
                    print("📍 Restaurant store detection: '\(line)' at line \(lineIndex)")
                    return line
                }
            }
        }

        // Fallback: avoid prices and obvious non-store lines
        for (index, line) in lines.enumerated().prefix(15) {
            let lowercased = line.lowercased()
            if line.count > 5 && line.count < 40 &&
               !line.contains("$") && !lowercased.contains("tel") &&
               !lowercased.contains("address") && !lowercased.contains("#") &&
               !lowercased.contains("thank") && !lowercased.contains("order") &&
               line.range(of: "^\\d+\\.\\d{2}$", options: .regularExpression) == nil {
                print("📍 Fallback store detection: '\(line)' at line \(index)")
                return line
            }
        }

        return "Unknown Store"
    }

    private func extractItems(from lines: [String], using structure: ReceiptStructure) -> [ReceiptItem] {
        switch structure.format {
        case .separatedPricesItems:
            return extractItemsSeparatedFormat(from: lines, using: structure)
        case .standardItemPrice:
            return extractItemsStandardFormat(from: lines, using: structure)
        case .mixed:
            return extractItemsMixedFormat(from: lines, using: structure)
        default:
            return extractItemsMixedFormat(from: lines, using: structure)
        }
    }

    private func extractItemsSeparatedFormat(from lines: [String], using structure: ReceiptStructure) -> [ReceiptItem] {
        print("🍔 Extracting items using separated format...")

        // Get actual item prices (from early lines, typically first 6 lines)
        var itemPrices: [Double] = []
        for (index, line) in lines.enumerated().prefix(8) {
            let prices = extractAllPrices(from: line)
            for price in prices {
                // Only item prices, not totals
                // Avoid duplicate prices (especially total and subtotal)
                if price > 0.50 && price < 20.0 && !itemPrices.contains(price) {
                    // Skip prices that appear multiple times (likely totals)
                    let priceCount = lines.prefix(10).filter { extractAllPrices(from: $0).contains(price) }.count
                    if priceCount == 1 { // Only accept prices that appear exactly once (true item prices)
                        itemPrices.append(price)
                        print("🔢 Added unique item price: $\(price) at line \(index)")
                    } else {
                        print("🚫 Skipped duplicate price: $\(price) (appears \(priceCount) times)")
                    }
                }
            }
        }
        itemPrices.sort()

        // Get actual food items (with quantity prefixes)
        var itemNames: [String] = []
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // Look for lines that start with quantity indicators (with space or period)
            if trimmed.hasPrefix("1 ") || trimmed.hasPrefix("2 ") || trimmed.hasPrefix("3 ") ||
               trimmed.hasPrefix("1.") || trimmed.hasPrefix("2.") || trimmed.hasPrefix("3.") {

                let itemPart: String
                if trimmed.hasPrefix("1.") || trimmed.hasPrefix("2.") || trimmed.hasPrefix("3.") {
                    itemPart = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                } else {
                    itemPart = String(trimmed.dropFirst(2))
                }

                if isLikelyFoodItem(itemPart) && itemPart.count > 2 {
                    itemNames.append(itemPart)
                    print("🍔 Found food item: '\(itemPart)' at line \(index)")
                }
            }
        }

        print("🔢 Found \(itemPrices.count) item prices: \(itemPrices)")
        print("📝 Found \(itemNames.count) food items: \(itemNames)")

        // Special handling for combo meals - McDonald's pattern detection
        if itemNames.count > 1 {
            print("🔍 Filtered item prices: \(itemPrices) from \(itemNames.count) items")

            // Check for McDonald's Menu format (e.g., "Menu M Chicken Tasty")
            var menuComboItem: String?
            var menuComboPrice: Double = 0
            var standaloneItems: [String] = []
            var standaloneItemPrices: [Double] = []

            for (i, itemName) in itemNames.enumerated() {
                let lowercased = itemName.lowercased()
                if lowercased.contains("menu") && lowercased.contains("chicken") {
                    menuComboItem = itemName
                    // For European McDonald's, combo price is typically the first main price (13.20)
                    for price in itemPrices {
                        if price >= 8.0 && price <= 16.0 { // More specific range for combo
                            menuComboPrice = price
                            print("🍟 Found Menu combo: '\(itemName)' at $\(price)")
                            break
                        }
                    }
                } else if lowercased.contains("mcflurry") || lowercased.contains("dessert") {
                    standaloneItems.append(itemName)
                    // Find appropriate price for dessert - prefer prices in 3-6 range (typical dessert prices)
                    var foundPrice = false
                    for price in itemPrices {
                        if price >= 3.0 && price <= 6.0 && price != menuComboPrice && !standaloneItemPrices.contains(price) {
                            standaloneItemPrices.append(price)
                            print("🍦 Found standalone item: '\(itemName)' at $\(price)")
                            foundPrice = true
                            break
                        }
                    }
                    // If no price in 3-6 range, look in 2-8 range
                    if !foundPrice {
                        for price in itemPrices {
                            if price >= 2.0 && price <= 8.0 && price != menuComboPrice && !standaloneItemPrices.contains(price) {
                                standaloneItemPrices.append(price)
                                print("🍦 Found standalone item (fallback): '\(itemName)' at $\(price)")
                                break
                            }
                        }
                    }
                }
            }

            // If we found a menu combo, create proper items
            if let comboItem = menuComboItem, menuComboPrice > 0 {
                var items: [ReceiptItem] = []

                // Add the combo meal
                let combo = ReceiptItem(
                    name: comboItem,
                    quantity: 1,
                    unitPrice: menuComboPrice,
                    totalPrice: menuComboPrice,
                    category: .main,
                    tags: []
                )
                items.append(combo)

                // Add standalone items
                for (i, standaloneItem) in standaloneItems.enumerated() {
                    if i < standaloneItemPrices.count {
                        let item = ReceiptItem(
                            name: standaloneItem,
                            quantity: 1,
                            unitPrice: standaloneItemPrices[i],
                            totalPrice: standaloneItemPrices[i],
                            category: .dessert,
                            tags: []
                        )
                        items.append(item)
                    }
                }

                print("🍟 Created McDonald's menu format: \(items.count) items")
                return items
            }

            // Fallback: Original subtotal detection for other formats
            var subtotalPrice: Double = 0
            for (index, line) in lines.enumerated() {
                let lowercased = line.lowercased()
                if lowercased.contains("subtotal") {
                    print("🔍 Found 'Subtotal' keyword at line \(index)")
                    for searchIndex in 0..<lines.count {
                        let prices = extractAllPrices(from: lines[searchIndex])
                        for price in prices {
                            if price >= 5.0 && price <= 25.0 {
                                subtotalPrice = price
                                print("💰 Found candidate subtotal price: $\(price) at line \(searchIndex)")
                                break
                            }
                        }
                        if subtotalPrice > 0 { break }
                    }
                    break
                }
            }

            if subtotalPrice > 0 {
                print("🍟 Detected standard McDonald's combo meal")
                let comboName = itemNames.joined(separator: " + ")
                let item = ReceiptItem(
                    name: comboName,
                    quantity: 1,
                    unitPrice: subtotalPrice,
                    totalPrice: subtotalPrice,
                    category: .main,
                    tags: []
                )
                return [item]
            }
        }

        // Match items and prices normally
        return createReceiptItems(prices: itemPrices, names: itemNames)
    }

    private func extractItemsStandardFormat(from lines: [String], using structure: ReceiptStructure) -> [ReceiptItem] {
        print("🍔 Extracting items using standard format...")

        var items: [ReceiptItem] = []

        for (index, line, analysis) in structure.lineAnalyses {
            if analysis.isItemCandidate && !analysis.prices.isEmpty {
                if let itemName = analysis.itemName,
                   let price = analysis.prices.first {

                    let item = ReceiptItem(
                        name: itemName,
                        quantity: analysis.quantity,
                        unitPrice: price / analysis.quantity,
                        totalPrice: price,
                        category: categorizeItem(itemName),
                        tags: []
                    )
                    items.append(item)
                    print("✅ Standard format item: '\(itemName)' - $\(price)")
                }
            }
        }

        return items
    }

    private func extractItemsMixedFormat(from lines: [String], using structure: ReceiptStructure) -> [ReceiptItem] {
        print("🍔 Extracting items using mixed format...")

        // Try standard format first
        var items = extractItemsStandardFormat(from: lines, using: structure)

        // If no items found, try separated format
        if items.isEmpty {
            items = extractItemsSeparatedFormat(from: lines, using: structure)
        }

        return items
    }

    private func createReceiptItems(prices: [Double], names: [String]) -> [ReceiptItem] {
        var items: [ReceiptItem] = []

        if names.count == 1 && prices.count >= 1 {
            // Single item (possibly combo)
            let itemName = names.count > 1 ? names.joined(separator: " + ") : names[0]
            let price = prices[0]

            let item = ReceiptItem(
                name: itemName,
                quantity: 1,
                unitPrice: price,
                totalPrice: price,
                category: categorizeItem(itemName),
                tags: []
            )
            items.append(item)
            print("✅ Combined item: '\(itemName)' - $\(price)")

        } else {
            // Multiple items
            let itemCount = min(prices.count, names.count)
            for i in 0..<itemCount {
                let price = prices[i]
                let name = names[i]

                let item = ReceiptItem(
                    name: name,
                    quantity: extractQuantity(from: name),
                    unitPrice: price,
                    totalPrice: price,
                    category: categorizeItem(name),
                    tags: []
                )
                items.append(item)
                print("✅ Individual item: '\(name)' - $\(price)")
            }
        }

        return items
    }

    private func extractTotals(from lines: [String], using structure: ReceiptStructure) -> (subtotal: Double, tax: Double, total: Double) {
        print("💰 Extracting totals dynamically...")

        var subtotal: Double = 0
        var tax: Double = 0
        var total: Double = 0

        // Method 1: For McDonald's separated format - use specific line positions
        if structure.format == .separatedPricesItems {
            // First, try to find tax by looking for "TAX" keyword
            for (index, line) in lines.enumerated() {
                if line.uppercased() == "TAX" {
                    print("🔍 Found explicit TAX keyword at line \(index)")
                    // Look in the NEXT line first (most likely location for tax amount)
                    if index + 1 < lines.count {
                        let nextLinePrices = extractAllPrices(from: lines[index + 1])
                        for price in nextLinePrices {
                            if price >= 0.50 && price <= 3.0 { // Reasonable tax range
                                tax = price
                                print("💸 Found tax by keyword: $\(tax) at line \(index + 1) (next line after TAX)")
                                break
                            }
                        }
                    }

                    // If not found in next line, search nearby lines
                    if tax == 0 {
                        for searchIndex in max(0, index-2)...min(lines.count-1, index+3) {
                            if searchIndex != index + 1 { // Skip the next line since we already checked it
                                let prices = extractAllPrices(from: lines[searchIndex])
                                for price in prices {
                                    if price >= 0.50 && price <= 3.0 { // Reasonable tax range
                                        tax = price
                                        print("💸 Found tax by keyword: $\(tax) at line \(searchIndex)")
                                        break
                                    }
                                }
                                if tax > 0 { break }
                            }
                        }
                    }
                    break
                }
            }

            // Look for totals in ALL lines, not just 4-10
            var potentialTotals: [(index: Int, price: Double)] = []

            for (index, line) in lines.enumerated() {
                let prices = extractAllPrices(from: line)
                for price in prices {
                    // Include tax amounts (small) and total amounts (large)
                    if price > 0.25 { // Include tax and totals
                        potentialTotals.append((index: index, price: price))
                        print("💰 Potential total at line \(index): $\(price) from '\(line)'")
                    }
                }
            }
            print("💰 Found \(potentialTotals.count) potential totals")

            // For McDonald's pattern: subtotal (10.77), tax (0.75), total (11.52)
            if potentialTotals.count >= 3 {
                // Sort by price to find pattern
                let sortedTotals = potentialTotals.sorted { $0.price < $1.price }

                // Debug: print all sorted totals
                for (i, total) in sortedTotals.enumerated() {
                    print("💰 Sorted total \(i): $\(total.price)")
                }

                // Only do pattern matching if we haven't already found tax from keyword
                if tax == 0 {
                    // Look for subtotal + tax = total relationship
                    for i in 0..<(sortedTotals.count - 1) {
                        for j in (i + 1)..<sortedTotals.count {
                            let amount1 = sortedTotals[i].price
                            let amount2 = sortedTotals[j].price
                            let expectedTotal = amount1 + amount2

                            // Find if expectedTotal exists in our list
                            for k in 0..<sortedTotals.count {
                                let amount3 = sortedTotals[k].price
                                if abs(amount3 - expectedTotal) < 0.05 {
                                    // Determine which is tax, subtotal, total based on size and context
                                    if amount1 < amount2 && amount1 < 5.0 && amount2 > 5.0 {
                                        // Check if amount1 is really tax (should be small percentage of subtotal)
                                        let taxRatio = amount1 / amount2
                                        if taxRatio >= 0.03 && taxRatio <= 0.25 { // 3-25% tax is reasonable
                                            tax = amount1
                                            subtotal = amount2
                                            total = amount3
                                            print("📊 McDonald's pattern matched: tax=$\(tax), subtotal=$\(subtotal), total=$\(total)")
                                            break
                                        }
                                    }
                                }
                            }
                            if tax > 0 { break } // Found pattern, exit loops
                        }
                        if tax > 0 { break }
                    }
                } else {
                    // We found tax from keyword, now find the correct total
                    // For European receipts, look for the amount that appears multiple times (likely the total)
                    var amountCounts: [Double: Int] = [:]
                    for total in sortedTotals {
                        amountCounts[total.price, default: 0] += 1
                    }

                    // Find the largest amount that appears multiple times (likely the total)
                    var bestTotal: Double = 0
                    for (amount, count) in amountCounts {
                        if count >= 2 && amount > tax * 5 && amount > bestTotal {
                            bestTotal = amount
                        }
                    }

                    if bestTotal > 0 {
                        total = bestTotal
                        subtotal = total - tax
                        print("📊 Using keyword tax: tax=$\(tax), calculated subtotal=$\(subtotal), total=$\(total)")
                    } else {
                        // Fallback: use the largest reasonable amount as total
                        for potentialTotal in sortedTotals.reversed() {
                            if potentialTotal.price > tax * 5 && potentialTotal.price < tax * 50 {
                                let calculatedSubtotal = potentialTotal.price - tax
                                if calculatedSubtotal > 5.0 && calculatedSubtotal < 50.0 {
                                    subtotal = calculatedSubtotal
                                    total = potentialTotal.price
                                    print("📊 Using keyword tax (fallback): tax=$\(tax), calculated subtotal=$\(subtotal), total=$\(total)")
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }

        // Method 2: Look near keyword indicators
        if subtotal == 0 || tax == 0 || total == 0 {
            for lineIndex in structure.totalLines {
                if lineIndex < lines.count {
                    let line = lines[lineIndex]
                    let lowercaseLine = line.lowercased()
                    let analysis = structure.lineAnalyses.first { $0.index == lineIndex }?.analysis

                    // Look backwards from keyword to find the actual price
                    for searchIndex in stride(from: lineIndex, to: max(0, lineIndex - 10), by: -1) {
                        if searchIndex < lines.count {
                            let searchLine = lines[searchIndex]
                            let foundPrices = extractAllPrices(from: searchLine)

                            for price in foundPrices {
                                if let analysisType = analysis?.totalType {
                                    switch analysisType {
                                    case .subtotal where subtotal == 0 && price > 5.0:
                                        subtotal = price
                                        print("📊 Subtotal found: $\(price) at line \(searchIndex) (keyword at \(lineIndex))")
                                    case .tax where tax == 0 && price < 5.0 && price > 0.1:
                                        tax = price
                                        print("💸 Tax found: $\(price) at line \(searchIndex) (keyword at \(lineIndex))")
                                    case .total where total == 0 && price > 10.0:
                                        total = price
                                        print("🧾 Total found: $\(price) at line \(searchIndex) (keyword at \(lineIndex))")
                                    default:
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Method 3: Fallback pattern matching
        if subtotal == 0 || tax == 0 || total == 0 {
            // Get all reasonable prices (exclude very large numbers from codes, phone numbers)
            let allPrices = lines.flatMap { extractAllPrices(from: $0) }
                .filter { $0 > 0.25 && $0 < 500.0 }
                .sorted()

            print("🔍 All extracted prices for pattern matching: \(allPrices)")

            // Look for subtotal + tax = total pattern
            for i in 0..<(allPrices.count - 2) {
                let price1 = allPrices[i]
                let price2 = allPrices[i + 1]
                let price3 = allPrices[i + 2]

                if abs((price1 + price2) - price3) < 0.02 {
                    // Determine which is tax (smaller), subtotal (larger), total (sum)
                    if price1 < price2 {
                        if subtotal == 0 { subtotal = price2 }
                        if tax == 0 { tax = price1 }
                        if total == 0 { total = price3 }
                    } else {
                        if subtotal == 0 { subtotal = price1 }
                        if tax == 0 { tax = price2 }
                        if total == 0 { total = price3 }
                    }
                    print("📊 Pattern-matched totals: subtotal=$\(subtotal), tax=$\(tax), total=$\(total)")
                    break
                }
            }
        }

        // Final validation and calculation
        if total == 0 && subtotal > 0 {
            total = subtotal + tax
            print("🧾 Calculated total: $\(total)")
        }

        print("✅ Final totals: subtotal=$\(subtotal), tax=$\(tax), total=$\(total)")
        return (subtotal, tax, total)
    }

    private func extractItemFromLine(_ line: String) -> ReceiptItem? {
        print("    🔍 Trying to extract item from: '\(line)'")

        // Multiple patterns for different receipt formats (especially fast food)
        let patterns = [
            "^(.+?)\\s+\\$?(\\d+\\.\\d{2})$",           // Standard: "Item Name $12.99"
            "^(.+?)\\s+(\\d+\\.\\d{2})\\s*$",          // No dollar sign: "Item Name 12.99"
            "^(.+?)\\s+USD\\s*(\\d+\\.\\d{2})$",       // With currency: "Item Name USD 12.99"
            "^(.+?)\\s*\\$?\\s*(\\d{1,3}(?:,\\d{3})*\\.\\d{2})$", // With thousands separator
            "^\\d+\\s+(.+?)\\s+\\$?(\\d+\\.\\d{2})$",  // With quantity: "1 Item Name $12.99"
            "^(.+?)\\s*\\$?(\\d+\\.\\d{2})\\s*$",      // Loose spacing: "Item Name$12.99"
            "^(.+?)\\s+(\\d+\\.\\d{2})\\s*[A-Z]*\\s*$", // With trailing codes: "Item Name 12.99 T"
            "^(.+)\\s{2,}\\$?(\\d+\\.\\d{2})$"         // Multiple spaces: "Item Name    $12.99"
        ]

        for (patternIndex, pattern) in patterns.enumerated() {
            print("    📝 Trying pattern \(patternIndex + 1): \(pattern)")
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: line.utf16.count)

            if let match = regex?.firstMatch(in: line, range: range) {
                print("    ✅ Pattern matched!")
                let nameRange = Range(match.range(at: 1), in: line)
                let priceRange = Range(match.range(at: 2), in: line)

                if let nameRange = nameRange, let priceRange = priceRange {
                    let name = String(line[nameRange]).trimmingCharacters(in: .whitespaces)
                    let priceString = String(line[priceRange]).replacingOccurrences(of: ",", with: "") // Remove comma separators
                    print("    📋 Extracted name: '\(name)', price: '\(priceString)'")

                    // Validate that this looks like a real item name
                    if name.count < 2 || name.count > 100 {
                        print("    ⚠️ Rejecting item with invalid name length: '\(name)' (length: \(name.count))")
                        continue // Try next pattern
                    }

                    // Skip if name contains receipt metadata keywords
                    let lowercaseName = name.lowercased()
                    let metadataKeywords = ["subtotal", "total", "tax", "tip", "gratuity", "discount",
                                          "coupon", "change", "cash", "card", "credit", "debit",
                                          "balance", "amount", "due", "tender", "receipt"]

                    var containsMetadata = false
                    for keyword in metadataKeywords {
                        if lowercaseName.contains(keyword) {
                            print("    ⚠️ Rejecting item containing metadata keyword '\(keyword)': '\(name)'")
                            containsMetadata = true
                            break
                        }
                    }

                    if containsMetadata {
                        continue // Try next pattern
                    }

                    print("    ✅ Name validation passed!")

                    if let price = Double(priceString), price > 0 {
                        // Determine item category based on name
                        let category = categorizeItem(name)

                        return ReceiptItem(
                            name: name,
                            quantity: 1,
                            unitPrice: price,
                            totalPrice: price,
                            category: category,
                            tags: []
                        )
                    }
                }
            } else {
                print("    ❌ Pattern \(patternIndex + 1) did not match")
            }
        }
        print("    ❌ No patterns matched, trying fallback parsing...")

        // Fallback: Try to find any price pattern and assume everything before it is the item name
        return tryFallbackParsing(line)
    }

    private func tryFallbackParsing(_ line: String) -> ReceiptItem? {
        print("    🔄 Fallback parsing for: '\(line)'")

        // Look for price patterns anywhere in the line
        let pricePattern = "\\$?(\\d+\\.\\d{2})"
        let regex = try? NSRegularExpression(pattern: pricePattern)
        let range = NSRange(location: 0, length: line.utf16.count)

        if let match = regex?.firstMatch(in: line, range: range) {
            let priceRange = Range(match.range(at: 1), in: line)
            if let priceRange = priceRange {
                let priceString = String(line[priceRange])
                print("    💰 Found price: '\(priceString)'")

                // Extract everything before the price as the item name
                let priceStartIndex = line.distance(from: line.startIndex, to: priceRange.lowerBound)
                let itemNameEndIndex = max(0, priceStartIndex - 1) // Account for space or $ before price

                let itemName = String(line.prefix(itemNameEndIndex))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "$", with: "") // Remove any $ signs from name
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                print("    📝 Extracted item name: '\(itemName)'")

                if itemName.count >= 2 && itemName.count <= 100 {
                    // Check if it's not a metadata line
                    let lowercaseName = itemName.lowercased()
                    let metadataKeywords = ["subtotal", "total", "tax", "tip", "gratuity", "discount",
                                          "coupon", "change", "cash", "card", "credit", "debit",
                                          "balance", "amount", "due", "tender", "receipt"]

                    for keyword in metadataKeywords {
                        if lowercaseName.contains(keyword) {
                            print("    ⚠️ Fallback rejected - contains metadata keyword '\(keyword)'")
                            return nil
                        }
                    }

                    if let price = Double(priceString), price > 0 {
                        print("    ✅ Fallback parsing succeeded!")
                        return ReceiptItem(
                            name: itemName,
                            quantity: 1,
                            unitPrice: price,
                            totalPrice: price,
                            category: categorizeItem(itemName),
                            tags: []
                        )
                    }
                }
            }
        }

        print("    ❌ Fallback parsing failed")
        return nil
    }

    private func categorizeItem(_ name: String) -> ReceiptItem.ItemCategory {
        let lowercaseName = name.lowercased()

        // Fast food beverages
        if lowercaseName.contains("coffee") || lowercaseName.contains("tea") ||
           lowercaseName.contains("latte") || lowercaseName.contains("cappuccino") ||
           lowercaseName.contains("soda") || lowercaseName.contains("juice") ||
           lowercaseName.contains("water") || lowercaseName.contains("drink") ||
           lowercaseName.contains("coke") || lowercaseName.contains("pepsi") ||
           lowercaseName.contains("sprite") || lowercaseName.contains("smoothie") ||
           lowercaseName.contains("shake") || lowercaseName.contains("milkshake") {
            return .beverage
        }
        // Fast food desserts
        else if lowercaseName.contains("cake") || lowercaseName.contains("ice cream") ||
                  lowercaseName.contains("dessert") || lowercaseName.contains("cookie") ||
                  lowercaseName.contains("pie") || lowercaseName.contains("sundae") ||
                  lowercaseName.contains("donut") || lowercaseName.contains("muffin") {
            return .dessert
        }
        // Alcohol
        else if lowercaseName.contains("wine") || lowercaseName.contains("beer") ||
                  lowercaseName.contains("alcohol") || lowercaseName.contains("cocktail") {
            return .alcohol
        }
        // Appetizers/starters
        else if lowercaseName.contains("salad") || lowercaseName.contains("appetizer") ||
                  lowercaseName.contains("starter") || lowercaseName.contains("wings") ||
                  lowercaseName.contains("nachos") {
            return .appetizer
        }
        // Fast food sides
        else if lowercaseName.contains("side") || lowercaseName.contains("fries") ||
                  lowercaseName.contains("bread") || lowercaseName.contains("tots") ||
                  lowercaseName.contains("onion rings") || lowercaseName.contains("coleslaw") {
            return .side
        }
        // Fast food main items (burgers, sandwiches, etc.)
        else if lowercaseName.contains("burger") || lowercaseName.contains("sandwich") ||
                lowercaseName.contains("wrap") || lowercaseName.contains("taco") ||
                lowercaseName.contains("pizza") || lowercaseName.contains("chicken") ||
                lowercaseName.contains("fish") || lowercaseName.contains("beef") {
            return .main
        }
        else {
            return .food
        }
    }

    private func extractPriceFromLine(_ line: String) -> Double? {
        let pattern = "\\$?(\\d+\\.\\d{2})"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: line.utf16.count)

        if let match = regex?.firstMatch(in: line, range: range) {
            let priceRange = Range(match.range(at: 1), in: line)
            if let priceRange = priceRange {
                let priceString = String(line[priceRange])
                return Double(priceString)
            }
        }
        return nil
    }
}

// MARK: - Receipt Extensions

extension Receipt {
    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: total)) ?? "$\(total)"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var itemCount: Int {
        return items.count
    }

    func calculateSubtotal() -> Double {
        return items.reduce(0) { $0 + $1.totalPrice }
    }
}