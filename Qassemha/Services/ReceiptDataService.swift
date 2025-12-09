//
//  ReceiptDataService.swift
//  Qassemha
//
//  Service to manage receipt data in Core Data
//

import Foundation
import CoreData

class ReceiptDataService {
    static let shared = ReceiptDataService()
    private let context = PersistenceController.shared.container.viewContext

    private init() {}

    // MARK: - Seed Hardcoded QR Receipts

    func seedHardcodedQRReceipts() {
        // Check if already seeded
        if UserDefaults.standard.bool(forKey: "hasSeededQRReceipts") {
            print("✅ QR Receipts already seeded")
            return
        }

        print("🌱 Seeding hardcoded QR receipts...")

        // Seed Taqwarma House receipt
        let taqwarmaQR = "ARZTaGF3YXJtYSBIb3VzZSBDb21wYW55Ag8zMTA0NjQ5MDEyMDAwMDMDFDIwMjUtMTAtMDUgMTU6Mzk6MjFaBAYxNjcuMDAFBTIxLjc4"
        let taqwarmaReceipt = createTaqwarmaHouseReceipt()
        saveReceiptWithQR(receipt: taqwarmaReceipt, qrCode: taqwarmaQR)

        // Seed Taqatu Hamam receipt
        let taqatuHamamQR = "ATzZhdit2YQg2KrZgtin2LfZiti5INmI2K3Zhdin2YUg2YTZhNiq2KzYp9ix2YcgLSDYp9mE2YHYsdi5IDMCDzMwMDcwNTUyMTgwMDAwMwMUMjAyNS0wOS0zMFQyMDowNDowNVoEAzE1OAUFMjAuNjI="
        let taqatuHamamReceipt = createTaqatuHamamReceipt()
        saveReceiptWithQR(receipt: taqatuHamamReceipt, qrCode: taqatuHamamQR)

        // Mark as seeded
        UserDefaults.standard.set(true, forKey: "hasSeededQRReceipts")
        print("✅ Successfully seeded QR receipts")
    }

    // MARK: - Fetch Receipt by QR Code

    func fetchReceipt(forQRCode qrCode: String) -> Receipt? {
        let fetchRequest: NSFetchRequest<QRCodeReceipt> = QRCodeReceipt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "qrCodeString == %@", qrCode)

        do {
            let results = try context.fetch(fetchRequest)
            if let qrCodeEntity = results.first,
               let storedReceipt = qrCodeEntity.receipt {
                return convertToReceipt(storedReceipt)
            }
        } catch {
            print("❌ Error fetching receipt for QR code: \(error)")
        }

        return nil
    }

    // MARK: - Check if QR Code Exists

    func qrCodeExists(_ qrCode: String) -> Bool {
        let fetchRequest: NSFetchRequest<QRCodeReceipt> = QRCodeReceipt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "qrCodeString == %@", qrCode)

        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("❌ Error checking QR code existence: \(error)")
            return false
        }
    }

    // MARK: - Save Receipt with QR Code

    func saveReceiptWithQR(receipt: Receipt, qrCode: String) {
        // Create StoredReceipt entity
        let storedReceipt = StoredReceipt(context: context)
        storedReceipt.receiptID = receipt.id
        storedReceipt.storeName = receipt.storeName
        storedReceipt.storeAddress = receipt.storeAddress
        storedReceipt.date = receipt.date
        storedReceipt.subtotal = receipt.subtotal
        storedReceipt.tax = receipt.tax
        storedReceipt.tip = receipt.tip
        storedReceipt.total = receipt.total
        storedReceipt.currency = receipt.currency
        storedReceipt.receiptNumber = receipt.receiptNumber
        storedReceipt.imageData = receipt.imageData
        storedReceipt.scanType = receipt.scanType.rawValue
        storedReceipt.category = receipt.category.rawValue
        storedReceipt.createdAt = Date()

        // Create items
        for item in receipt.items {
            let storedItem = StoredReceiptItem(context: context)
            storedItem.itemID = item.id
            storedItem.name = item.name
            storedItem.quantity = item.quantity
            storedItem.unitPrice = item.unitPrice
            storedItem.totalPrice = item.totalPrice
            storedItem.category = item.category.rawValue
            storedItem.tags = item.tags.joined(separator: ",")
            storedItem.notes = item.notes
            storedItem.isEdited = item.isEdited
            storedItem.receipt = storedReceipt
        }

        // Create QR code entity
        let qrCodeEntity = QRCodeReceipt(context: context)
        qrCodeEntity.qrCodeID = UUID()
        qrCodeEntity.qrCodeString = qrCode
        qrCodeEntity.createdAt = Date()
        qrCodeEntity.receipt = storedReceipt

        // Save context
        do {
            try context.save()
            print("✅ Saved receipt with QR code: \(receipt.storeName)")
        } catch {
            print("❌ Error saving receipt: \(error)")
        }
    }

    // MARK: - Convert StoredReceipt to Receipt

    private func convertToReceipt(_ storedReceipt: StoredReceipt) -> Receipt? {
        guard let receiptID = storedReceipt.receiptID,
              let storeName = storedReceipt.storeName,
              let date = storedReceipt.date,
              let scanTypeStr = storedReceipt.scanType,
              let categoryStr = storedReceipt.category else {
            return nil
        }

        let scanType = Receipt.ScanType(rawValue: scanTypeStr) ?? .qrCode
        let category = Receipt.ReceiptCategory(rawValue: categoryStr) ?? .other

        // Convert items
        let items = (storedReceipt.items?.allObjects as? [StoredReceiptItem] ?? []).compactMap { storedItem -> ReceiptItem? in
            guard let itemID = storedItem.itemID,
                  let name = storedItem.name,
                  let categoryStr = storedItem.category else {
                return nil
            }

            let itemCategory = ReceiptItem.ItemCategory(rawValue: categoryStr) ?? .other
            let tags = storedItem.tags?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []

            return ReceiptItem(
                id: itemID,
                name: name,
                quantity: storedItem.quantity,
                unitPrice: storedItem.unitPrice,
                totalPrice: storedItem.totalPrice,
                category: itemCategory,
                tags: tags,
                notes: storedItem.notes,
                isEdited: storedItem.isEdited
            )
        }

        return Receipt(
            id: receiptID,
            storeName: storeName,
            storeAddress: storedReceipt.storeAddress,
            date: date,
            items: items,
            subtotal: storedReceipt.subtotal,
            tax: storedReceipt.tax,
            tip: storedReceipt.tip,
            total: storedReceipt.total,
            currency: storedReceipt.currency ?? "USD",
            receiptNumber: storedReceipt.receiptNumber,
            imageData: storedReceipt.imageData,
            scanType: scanType,
            category: category
        )
    }

    // MARK: - Hardcoded Receipt Creators

    private func createTaqwarmaHouseReceipt() -> Receipt {
        let items = [
            ReceiptItem(
                name: "Mix Chicken Shawarma Rice",
                quantity: 1.0,
                unitPrice: 23.00,
                totalPrice: 23.00,
                category: .main,
                tags: []
            ),
            ReceiptItem(
                name: "Honey BBQ Sauce",
                quantity: 1.0,
                unitPrice: 3.00,
                totalPrice: 3.00,
                category: .side,
                tags: []
            ),
            ReceiptItem(
                name: "Roll Nashville",
                quantity: 1.0,
                unitPrice: 12.00,
                totalPrice: 12.00,
                category: .food,
                tags: []
            ),
            ReceiptItem(
                name: "Smoky House Box (no tomato)",
                quantity: 2.0,
                unitPrice: 39.00,
                totalPrice: 78.00,
                category: .main,
                tags: [],
                notes: "no tomato"
            ),
            ReceiptItem(
                name: "Soft Drinks (Pepsi Diet Can)",
                quantity: 3.0,
                unitPrice: 6.00,
                totalPrice: 18.00,
                category: .beverage,
                tags: []
            ),
            ReceiptItem(
                name: "Strips Nashville Box",
                quantity: 1.0,
                unitPrice: 33.00,
                totalPrice: 33.00,
                category: .main,
                tags: [],
                notes: "potato, lollo, BBQ sauce, dipper"
            )
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Riyadh")
        let receiptDate = dateFormatter.date(from: "2025-10-05 15:02:04") ?? Date()

        let receipt = Receipt(
            storeName: "All Alhussain",
            storeAddress: nil,
            date: receiptDate,
            items: items,
            subtotal: 145.22,
            tax: 21.78,
            tip: 0,
            total: 167.00,
            currency: "﷼",
            receiptNumber: "310464901200003",
            imageData: nil,
            scanType: .qrCode,
            category: .food
        )

        return receipt
    }

    private func createTaqatuHamamReceipt() -> Receipt {
        let items = [
            ReceiptItem(
                name: "حمام فرنسي روز جامبو",
                quantity: 2.0,
                unitPrice: 36.00,
                totalPrice: 72.00,
                category: .food,
                tags: []
            ),
            ReceiptItem(
                name: "غاز 500 جرام",
                quantity: 2.0,
                unitPrice: 15.00,
                totalPrice: 30.00,
                category: .food,
                tags: []
            ),
            ReceiptItem(
                name: "لبن النرجس 900جم",
                quantity: 1.0,
                unitPrice: 9.00,
                totalPrice: 9.00,
                category: .beverage,
                tags: []
            ),
            ReceiptItem(
                name: "صاصه البصل المحمص",
                quantity: 1.0,
                unitPrice: 12.00,
                totalPrice: 12.00,
                category: .food,
                tags: []
            ),
            ReceiptItem(
                name: "زيت الزيتون الجوف 250مل",
                quantity: 1.0,
                unitPrice: 16.00,
                totalPrice: 16.00,
                category: .food,
                tags: []
            ),
            ReceiptItem(
                name: "خضار مقطعة",
                quantity: 10.0,
                unitPrice: 1.00,
                totalPrice: 10.00,
                category: .food,
                tags: []
            ),
            ReceiptItem(
                name: "صحن سلطة وسط",
                quantity: 1.0,
                unitPrice: 2.00,
                totalPrice: 2.00,
                category: .food,
                tags: []
            ),
            ReceiptItem(
                name: "بهارات 50 غرام",
                quantity: 1.0,
                unitPrice: 1.00,
                totalPrice: 1.00,
                category: .food,
                tags: []
            ),
            ReceiptItem(
                name: "زبدة المراعي 10 جرام",
                quantity: 1.0,
                unitPrice: 1.00,
                totalPrice: 1.00,
                category: .food,
                tags: []
            ),
            ReceiptItem(
                name: "صحن بلاستيك رقم 1",
                quantity: 1.0,
                unitPrice: 5.00,
                totalPrice: 5.00,
                category: .other,
                tags: []
            )
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Riyadh")
        let receiptDate = dateFormatter.date(from: "2025-09-30T20:04:05Z") ?? Date()

        let receipt = Receipt(
            storeName: "محل تقاطع وحمام للتجارة - الفرع 3",
            storeAddress: "Riyadh, حي الهدية – شارع القلم",
            date: receiptDate,
            items: items,
            subtotal: 137.38,
            tax: 20.62,
            tip: 0,
            total: 158.00,
            currency: "﷼",
            receiptNumber: "300705521800003",
            imageData: nil,
            scanType: .qrCode,
            category: .groceries
        )

        return receipt
    }
}
