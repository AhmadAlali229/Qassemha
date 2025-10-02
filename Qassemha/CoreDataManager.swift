//
//  CoreDataManager.swift
//  Qassemha
//
//  Created by Harjot Singh on 27/09/25.
//

import Foundation
import CoreData

extension Notification.Name {
    static let receiptSaved = Notification.Name("receiptSaved")
    static let receiptDeleted = Notification.Name("receiptDeleted")
}

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Qassemha")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData error: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }

    // For now, we'll save receipts as JSON to UserDefaults until we can update the CoreData model
    func saveReceipt(_ receipt: Receipt) {
        var savedReceipts = getSavedReceipts()

        // Check if receipt already exists (by ID), if so update it
        if let existingIndex = savedReceipts.firstIndex(where: { $0.id == receipt.id }) {
            savedReceipts[existingIndex] = receipt
            print("Receipt updated: \(receipt.storeName)")
        } else {
            savedReceipts.append(receipt)
            print("Receipt saved: \(receipt.storeName)")
        }

        // Keep only the most recent 50 receipts
        if savedReceipts.count > 50 {
            savedReceipts = Array(savedReceipts.suffix(50))
        }

        // Optimize encoding with compression quality already applied to imageData
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(savedReceipts) {
            UserDefaults.standard.set(encoded, forKey: "SavedReceipts")
            print("✅ Receipt saved successfully: \(receipt.storeName), ID: \(receipt.id)")

            // Post notification to refresh UI (must be on main thread)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .receiptSaved, object: receipt)
            }
        }
    }

    func getSavedReceipts() -> [Receipt] {
        guard let data = UserDefaults.standard.data(forKey: "SavedReceipts"),
              let receipts = try? JSONDecoder().decode([Receipt].self, from: data) else {
            return []
        }
        return receipts.sorted { $0.date > $1.date } // Most recent first
    }

    func getRecentReceipts(limit: Int = 10) -> [Receipt] {
        let allReceipts = getSavedReceipts()
        return Array(allReceipts.prefix(limit))
    }

    func deleteReceipt(_ receiptToDelete: Receipt) {
        var savedReceipts = getSavedReceipts()

        // Remove the receipt with matching ID
        let countBefore = savedReceipts.count
        savedReceipts.removeAll { $0.id == receiptToDelete.id }
        let countAfter = savedReceipts.count

        if countBefore > countAfter {
            if let encoded = try? JSONEncoder().encode(savedReceipts) {
                UserDefaults.standard.set(encoded, forKey: "SavedReceipts")
                print("✅ Receipt deleted successfully: \(receiptToDelete.storeName), ID: \(receiptToDelete.id)")

                // Post notification to refresh UI (must be on main thread)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .receiptDeleted, object: receiptToDelete)
                }
            }
        } else {
            print("⚠️ Receipt not found for deletion: \(receiptToDelete.storeName), ID: \(receiptToDelete.id)")
        }
    }

    private init() {}
}