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

    // MARK: - Seed Hardcoded QR Receipts (DEPRECATED - Now using on-demand creation)

    /// Deprecated method that previously seeded hardcoded QR receipts into database
    /// Receipts are now created on-demand when QR codes are scanned for better efficiency
    func seedHardcodedQRReceipts() {
        // DEPRECATED: This function is no longer used
        // Receipts are now created on-demand when QR codes are scanned
        print("⚠️ seedHardcodedQRReceipts is deprecated - receipts are now created on-demand")
    }

    // MARK: - Clean Up Previously Seeded Receipts

    /// Removes previously seeded receipts from database during migration to on-demand system
    /// Runs once to clean up old data and prevent duplicate receipts
    func cleanupSeededReceipts() {
        // Only run cleanup once
        if UserDefaults.standard.bool(forKey: "hasCleanedSeededReceipts") {
            return
        }

        print("🧹 Starting cleanup of seeded receipts...")

        // Remove the seeded receipts that were created before on-demand approach
        let receiptNumbers = ["310464901200003", "300705521800003"]

        for receiptNumber in receiptNumbers {
            // Delete StoredReceipt
            let receiptFetchRequest: NSFetchRequest<StoredReceipt> = StoredReceipt.fetchRequest()
            receiptFetchRequest.predicate = NSPredicate(format: "receiptNumber == %@", receiptNumber)

            do {
                let receiptResults = try context.fetch(receiptFetchRequest)
                for receipt in receiptResults {
                    let receiptID = receipt.receiptID
                    context.delete(receipt)
                    print("🗑️ Deleted seeded receipt: \(receipt.storeName ?? "Unknown")")

                    // Also delete associated QRCodeReceipt
                    if let receiptID = receiptID {
                        let qrFetchRequest: NSFetchRequest<QRCodeReceipt> = QRCodeReceipt.fetchRequest()
                        qrFetchRequest.predicate = NSPredicate(format: "receipt.receiptID == %@", receiptID as CVarArg)

                        let qrResults = try context.fetch(qrFetchRequest)
                        for qrCode in qrResults {
                            context.delete(qrCode)
                            print("🗑️ Deleted associated QR code")
                        }
                    }
                }

                if !receiptResults.isEmpty {
                    try context.save()
                }
            } catch {
                print("❌ Error cleaning up seeded receipts: \(error)")
            }
        }

        // Reset the seeding flag and mark cleanup as done
        UserDefaults.standard.removeObject(forKey: "hasSeededQRReceipts")
        UserDefaults.standard.set(true, forKey: "hasCleanedSeededReceipts")
        print("✅ Cleanup complete - receipts will be created on-demand when scanned")
    }

    // MARK: - Fetch Receipt by QR Code

    /// Fetches receipt from database by QR code or creates it on-demand if hardcoded
    /// Enables seamless QR code scanning experience with automatic receipt creation
    func fetchReceipt(forQRCode qrCode: String) -> Receipt? {
        // First check if it exists in database
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

        // If not in database, check if it's one of our hardcoded QR codes
        // and create it on-demand
        return createReceiptForHardcodedQR(qrCode)
    }

    // MARK: - Create Receipt for Hardcoded QR (On-Demand)

    /// Creates receipt object for hardcoded QR codes on first scan
    /// Supports demo receipts for testing without requiring actual QR code generation service
    private func createReceiptForHardcodedQR(_ qrCode: String) -> Receipt? {
        let taqwarmaQR = "ARZTaGF3YXJtYSBIb3VzZSBDb21wYW55Ag8zMTA0NjQ5MDEyMDAwMDMDFDIwMjUtMTAtMDUgMTU6Mzk6MjFaBAYxNjcuMDAFBTIxLjc4"
        let taqatuHamamQR = "ATzZhdit2YQg2KrZgtin2LfZiti5INmI2K3Zhdin2YUg2YTZhNiq2KzYp9ix2YcgLSDYp9mE2YHYsdi5IDMCDzMwMDcwNTUyMTgwMDAwMwMUMjAyNS0wOS0zMFQyMDowNDowNVoEAzE1OAUFMjAuNjI="

        var receipt: Receipt?

        if qrCode == taqwarmaQR {
            receipt = createTaqwarmaHouseReceipt()
            print("✅ Creating Taqwarma House receipt on-demand")
        } else if qrCode == taqatuHamamQR {
            receipt = createTaqatuHamamReceipt()
            print("✅ Creating Taqatu Hamam receipt on-demand")
        }

        // Save the receipt to database now that it's been scanned
        if let receipt = receipt {
            saveReceiptWithQR(receipt: receipt, qrCode: qrCode)
        }

        return receipt
    }

    // MARK: - Check if QR Code Exists

    /// Checks if QR code exists in database or matches hardcoded demo receipts
    /// Prevents duplicate receipt creation and validates QR codes before processing
    func qrCodeExists(_ qrCode: String) -> Bool {
        // Check database first
        let fetchRequest: NSFetchRequest<QRCodeReceipt> = QRCodeReceipt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "qrCodeString == %@", qrCode)

        do {
            let count = try context.count(for: fetchRequest)
            if count > 0 {
                return true
            }
        } catch {
            print("❌ Error checking QR code existence: \(error)")
        }

        // Check if it's a hardcoded QR code
        let taqwarmaQR = "ARZTaGF3YXJtYSBIb3VzZSBDb21wYW55Ag8zMTA0NjQ5MDEyMDAwMDMDFDIwMjUtMTAtMDUgMTU6Mzk6MjFaBAYxNjcuMDAFBTIxLjc4"
        let taqatuHamamQR = "ATzZhdit2YQg2KrZgtin2LfZiti5INmI2K3Zhdin2YUg2YTZhNiq2KzYp9ix2YcgLSDYp9mE2YHYsdi5IDMCDzMwMDcwNTUyMTgwMDAwMwMUMjAyNS0wOS0zMFQyMDowNDowNVoEAzE1OAUFMjAuNjI="

        return qrCode == taqwarmaQR || qrCode == taqatuHamamQR
    }

    // MARK: - Save Receipt with QR Code

    /// Saves receipt and associated QR code to Core Data for future lookups
    /// Links QR code to receipt for instant retrieval on subsequent scans
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
        storedReceipt.receiptType = receipt.receiptType.rawValue
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

    /// Converts Core Data StoredReceipt entity to Receipt model for app use
    /// Transforms persisted data into usable business objects with proper type mapping
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
        let receiptType = Receipt.ReceiptType(rawValue: storedReceipt.receiptType ?? "Sent") ?? .sent

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
            createdAt: storedReceipt.createdAt ?? Date(),
            items: items,
            subtotal: storedReceipt.subtotal,
            tax: storedReceipt.tax,
            tip: storedReceipt.tip,
            total: storedReceipt.total,
            currency: storedReceipt.currency ?? "USD",
            receiptNumber: storedReceipt.receiptNumber,
            imageData: storedReceipt.imageData,
            scanType: scanType,
            category: category,
            receiptType: receiptType
        )
    }

    // MARK: - Hardcoded Receipt Creators

    /// Creates hardcoded Taqwarma House receipt with predefined items and totals
    /// Provides demo receipt for testing bill splitting and payment features
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
        dateFormatter.timeZone = TimeZone.current  // Use device's local timezone
        let receiptDate = dateFormatter.date(from: "2025-10-05 15:02:04") ?? Date()

        let receipt = Receipt(
            storeName: "Bait al-saharma",
            storeAddress: nil,
            date: receiptDate,
            createdAt: Date(),
            items: items,
            subtotal: 145.22,
            tax: 21.78,
            tip: 0,
            total: 167.00,
            currency: "﷼",
            receiptNumber: "310464901200003",
            imageData: nil,
            scanType: .qrCode,
            category: .food,
            receiptType: .sent
        )

        return receipt
    }

    /// Creates hardcoded Taqatu Hamam grocery receipt with Arabic item names
    /// Demonstrates multi-language support and diverse item categories
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
        dateFormatter.timeZone = TimeZone.current  // Use device's local timezone
        let receiptDate = dateFormatter.date(from: "2025-09-30T20:04:05Z") ?? Date()

        let receipt = Receipt(
            storeName: "محل تقاطع وحمام للتجارة - الفرع 3",
            storeAddress: "Riyadh, حي الهدية – شارع القلم",
            date: receiptDate,
            createdAt: Date(),
            items: items,
            subtotal: 137.38,
            tax: 20.62,
            tip: 0,
            total: 158.00,
            currency: "﷼",
            receiptNumber: "300705521800003",
            imageData: nil,
            scanType: .qrCode,
            category: .groceries,
            receiptType: .sent
        )

        return receipt
    }
}
