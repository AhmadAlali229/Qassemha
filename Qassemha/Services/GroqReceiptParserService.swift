//
//  GroqReceiptParserService.swift
//  Qassemha
//
//  Dev-only OCR text -> structured receipt parsing via Groq.
//

import Foundation

final class GroqReceiptParserService {
    static let shared = GroqReceiptParserService()

    private init() {}

    private let endpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
    private let primaryModel = "llama-3.1-8b-instant"
    private let fallbackModel = "meta-llama/llama-4-scout-17b-16e-instruct"

    func parseReceiptText(_ text: String) async -> ParsedReceiptPayload? {
        guard let apiKey = loadAPIKey(), !apiKey.isEmpty else {
            print("Groq parser: missing API key")
            return nil
        }

        let primaryResult = await requestAndValidate(model: primaryModel, text: text, apiKey: apiKey)
        switch primaryResult {
        case .valid(let payload):
            return payload
        case .invalidPayload:
            print("Groq parser: primary model failed JSON/validation, trying fallback model")
            let fallbackResult = await requestAndValidate(model: fallbackModel, text: text, apiKey: apiKey)
            if case .valid(let payload) = fallbackResult {
                return payload
            }
            return nil
        case .requestFailed:
            return nil
        }
    }

    private func requestAndValidate(model: String, text: String, apiKey: String) async -> ParseOutcome {
        guard let raw = await request(model: model, text: text, apiKey: apiKey) else {
            return .requestFailed
        }

        guard let normalized = normalizeAndValidate(raw) else {
            print("Groq parser: JSON failed validation for model \(model)")
            return .invalidPayload
        }

        return .valid(normalized)
    }

    private func request(model: String, text: String, apiKey: String) async -> ParsedReceiptPayload? {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let systemPrompt = """
        You extract structured purchase receipts from OCR text.
        STRICT JSON ONLY. No markdown, no prose.
        """

        let userPrompt = """
        Parse the OCR text below and return a JSON object with this exact shape:
        {
          "store_name": "string or null",
          "store_address": "string or null",
          "receipt_date": "ISO-8601 date-time string or null",
          "currency": "ISO code like USD/SAR or symbol or null",
          "subtotal": number or null,
          "tax": number or null,
          "tip": number or null,
          "total": number or null,
          "receipt_number": "string or null",
          "items": [
            {
              "name": "string",
              "quantity": number,
              "unit_price": number or null,
              "total_price": number or null
            }
          ]
        }

        Rules:
        - items is required and must be non-empty.
        - Every item must include name and quantity.
        - Every item must include at least one of unit_price or total_price.
        - Use numbers, not strings, for numeric fields.
        - If quantity is missing, infer 1.
        - If one price is missing, infer it from the other when possible.
        - Keep uncertain fields null instead of guessing.

        OCR_TEXT:
        \(text)
        """

        let body = ChatCompletionRequest(
            model: model,
            temperature: 0,
            response_format: ResponseFormat(type: "json_object"),
            messages: [
                ChatMessage(role: "system", content: systemPrompt),
                ChatMessage(role: "user", content: userPrompt)
            ]
        )

        do {
            request.httpBody = try JSONEncoder().encode(body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                print("Groq parser: HTTP error for model \(model)")
                return nil
            }

            let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            guard
                let content = completion.choices.first?.message.content,
                let jsonData = content.data(using: .utf8)
            else {
                print("Groq parser: missing content for model \(model)")
                return nil
            }

            do {
                return try JSONDecoder().decode(ParsedReceiptPayload.self, from: jsonData)
            } catch {
                #if DEBUG
                print("Groq parser decode failure (\(model)): \(error.localizedDescription)")
                print("Groq raw response (\(model)):\n\(content)")
                #endif
                return nil
            }
        } catch {
            print("Groq parser error (\(model)): \(error.localizedDescription)")
            return nil
        }
    }

    private func normalizeAndValidate(_ payload: ParsedReceiptPayload) -> ParsedReceiptPayload? {
        var normalizedItems: [ParsedReceiptItem] = []

        for item in payload.items {
            let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { return nil }

            let quantity = item.quantity > 0 ? item.quantity : 1

            let unit = item.unit_price
            let total = item.total_price

            let normalizedUnit: Double?
            let normalizedTotal: Double?

            switch (unit, total) {
            case let (.some(u), .some(t)):
                guard u >= 0, t >= 0 else { return nil }
                normalizedUnit = u
                normalizedTotal = t
            case let (.some(u), .none):
                guard u >= 0 else { return nil }
                normalizedUnit = u
                normalizedTotal = u * quantity
            case let (.none, .some(t)):
                guard t >= 0 else { return nil }
                normalizedTotal = t
                normalizedUnit = quantity > 0 ? (t / quantity) : t
            case (.none, .none):
                return nil
            }

            normalizedItems.append(
                ParsedReceiptItem(
                    name: trimmedName,
                    quantity: quantity,
                    unit_price: normalizedUnit,
                    total_price: normalizedTotal
                )
            )
        }

        guard !normalizedItems.isEmpty else { return nil }

        let computedItemsTotal = normalizedItems.reduce(0.0) { partial, item in
            partial + (item.total_price ?? 0)
        }

        var normalizedSubtotal = payload.subtotal
        var normalizedTax = payload.tax
        var normalizedTip = payload.tip
        var normalizedTotal = payload.total

        if let total = payload.total, total > 0 {
            // Relaxed tolerance: receipts often include discounts/service/tax rounding.
            let tolerance = max(3.0, total * 0.35)
            if abs(total - computedItemsTotal) > tolerance && computedItemsTotal > 0 {
                #if DEBUG
                print("Groq parser: totals mismatch, keeping items and clearing totals as unverified")
                #endif
                normalizedSubtotal = nil
                normalizedTax = nil
                normalizedTip = nil
                normalizedTotal = nil
            }
        }

        let normalizedPayload = ParsedReceiptPayload(
            store_name: payload.store_name?.trimmedNilIfEmpty,
            store_address: payload.store_address?.trimmedNilIfEmpty,
            receipt_date: payload.receipt_date?.trimmedNilIfEmpty,
            currency: payload.currency?.trimmedNilIfEmpty,
            subtotal: normalizedSubtotal,
            tax: normalizedTax,
            tip: normalizedTip,
            total: normalizedTotal,
            receipt_number: payload.receipt_number?.trimmedNilIfEmpty,
            items: normalizedItems
        )

        #if DEBUG
        print("Groq parser: normalized \(normalizedPayload.items.count) items")
        #endif
        return normalizedPayload
    }

    private func loadAPIKey() -> String? {
        if let env = ProcessInfo.processInfo.environment["GROQ_API_KEY"], !env.isEmpty {
            return env
        }

        if let fromInfo = Bundle.main.object(forInfoDictionaryKey: "GROQ_API_KEY") as? String, !fromInfo.isEmpty {
            return fromInfo
        }

        if let url = Bundle.main.url(forResource: "GroqConfig.local", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let key = plist["GROQ_API_KEY"] as? String,
           !key.isEmpty {
            return key
        }

        return nil
    }
}

struct ParsedReceiptPayload: Decodable {
    let store_name: String?
    let store_address: String?
    let receipt_date: String?
    let currency: String?
    let subtotal: Double?
    let tax: Double?
    let tip: Double?
    let total: Double?
    let receipt_number: String?
    let items: [ParsedReceiptItem]

    enum CodingKeys: String, CodingKey {
        case store_name, storeName
        case store_address, storeAddress
        case receipt_date, receiptDate, date
        case currency, currency_code
        case subtotal, sub_total
        case tax, vat
        case tip, gratuity
        case total, grand_total
        case receipt_number, receiptNumber, invoice_number
        case items, line_items
    }

    init(
        store_name: String?,
        store_address: String?,
        receipt_date: String?,
        currency: String?,
        subtotal: Double?,
        tax: Double?,
        tip: Double?,
        total: Double?,
        receipt_number: String?,
        items: [ParsedReceiptItem]
    ) {
        self.store_name = store_name
        self.store_address = store_address
        self.receipt_date = receipt_date
        self.currency = currency
        self.subtotal = subtotal
        self.tax = tax
        self.tip = tip
        self.total = total
        self.receipt_number = receipt_number
        self.items = items
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        self.store_name = try c.decodeIfPresent(String.self, forKey: .store_name)
            ?? c.decodeIfPresent(String.self, forKey: .storeName)
        self.store_address = try c.decodeIfPresent(String.self, forKey: .store_address)
            ?? c.decodeIfPresent(String.self, forKey: .storeAddress)
        self.receipt_date = try c.decodeIfPresent(String.self, forKey: .receipt_date)
            ?? c.decodeIfPresent(String.self, forKey: .receiptDate)
            ?? c.decodeIfPresent(String.self, forKey: .date)
        self.currency = try c.decodeIfPresent(String.self, forKey: .currency)
            ?? c.decodeIfPresent(String.self, forKey: .currency_code)
        self.subtotal = try c.decodeFlexibleDouble(forKeys: [.subtotal, .sub_total])
        self.tax = try c.decodeFlexibleDouble(forKeys: [.tax, .vat])
        self.tip = try c.decodeFlexibleDouble(forKeys: [.tip, .gratuity])
        self.total = try c.decodeFlexibleDouble(forKeys: [.total, .grand_total])
        self.receipt_number = try c.decodeIfPresent(String.self, forKey: .receipt_number)
            ?? c.decodeIfPresent(String.self, forKey: .receiptNumber)
            ?? c.decodeIfPresent(String.self, forKey: .invoice_number)
        self.items = try c.decodeIfPresent([ParsedReceiptItem].self, forKey: .items)
            ?? c.decodeIfPresent([ParsedReceiptItem].self, forKey: .line_items)
            ?? []
    }
}

struct ParsedReceiptItem: Decodable {
    let name: String
    let quantity: Double
    let unit_price: Double?
    let total_price: Double?

    enum CodingKeys: String, CodingKey {
        case name, item, title, description
        case quantity, qty, count
        case unit_price, unitPrice
        case total_price, totalPrice
        case price
    }

    init(name: String, quantity: Double, unit_price: Double?, total_price: Double?) {
        self.name = name
        self.quantity = quantity
        self.unit_price = unit_price
        self.total_price = total_price
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        let decodedName = try c.decodeIfPresent(String.self, forKey: .name)
        let decodedItem = try c.decodeIfPresent(String.self, forKey: .item)
        let decodedTitle = try c.decodeIfPresent(String.self, forKey: .title)
        let decodedDescription = try c.decodeIfPresent(String.self, forKey: .description)

        self.name = decodedName
            ?? decodedItem
            ?? decodedTitle
            ?? decodedDescription
            ?? ""

        let qty = try c.decodeFlexibleDouble(forKeys: [.quantity, .qty, .count]) ?? 1
        self.quantity = qty > 0 ? qty : 1

        let unit = try c.decodeFlexibleDouble(forKeys: [.unit_price, .unitPrice])
        let total = try c.decodeFlexibleDouble(forKeys: [.total_price, .totalPrice, .price])

        // If only "price" or total exists, treat as total_price.
        // If only unit_price exists, caller normalization will compute total_price.
        self.unit_price = unit
        self.total_price = total
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let temperature: Double
    let response_format: ResponseFormat
    let messages: [ChatMessage]
}

private struct ResponseFormat: Encodable {
    let type: String
}

private struct ChatMessage: Encodable {
    let role: String
    let content: String
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: AssistantMessage
    }

    struct AssistantMessage: Decodable {
        let content: String
    }
}

private extension String {
    var trimmedNilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

private enum ParseOutcome {
    case valid(ParsedReceiptPayload)
    case invalidPayload
    case requestFailed
}

private extension KeyedDecodingContainer {
    func decodeFlexibleDouble(forKeys keys: [K]) throws -> Double? {
        for key in keys {
            if let v = try decodeIfPresent(Double.self, forKey: key) {
                return v
            }
            if let i = try decodeIfPresent(Int.self, forKey: key) {
                return Double(i)
            }
            if let s = try decodeIfPresent(String.self, forKey: key) {
                let cleaned = s
                    .replacingOccurrences(of: ",", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if let d = Double(cleaned) {
                    return d
                }
            }
        }
        return nil
    }
}
