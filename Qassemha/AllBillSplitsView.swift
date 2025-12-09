//
//  AllBillSplitsView.swift
//  Qassemha
//
//  View to display all bill splits
//

import SwiftUI

struct AllBillSplitsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var billSplitManager = BillSplitManager.shared
    @State private var allSplits: [(receipt: Receipt, config: SplitConfiguration)] = []
    @State private var selectedSplitReceipt: Receipt?
    @State private var searchText = ""

    var filteredSplits: [(receipt: Receipt, config: SplitConfiguration)] {
        if searchText.isEmpty {
            return allSplits
        }
        return allSplits.filter { split in
            split.receipt.storeName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search bill splits...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // Bill Splits List
                if filteredSplits.isEmpty {
                    // Empty State
                    VStack(spacing: 16) {
                        Spacer()

                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 64, weight: .thin))
                            .foregroundColor(.secondary)

                        Text(searchText.isEmpty ? "No Bill Splits Yet" : "No Results Found")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(searchText.isEmpty ? "Your bill splits will appear here" : "Try a different search term")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredSplits, id: \.receipt.id) { split in
                                BillSplitCard(
                                    receipt: split.receipt,
                                    configuration: split.config,
                                    onTap: {
                                        selectedSplitReceipt = split.receipt
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.05),
                        Color.cyan.opacity(0.02),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("All Bill Splits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .onAppear {
                loadAllSplits()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BillSplitUpdated"))) { _ in
                loadAllSplits()
            }
        }
        .fullScreenCover(item: $selectedSplitReceipt, onDismiss: {
            // Reload data when returning from split view
            loadAllSplits()
        }) { receipt in
            if let config = billSplitManager.getConfiguration(for: receipt.id) {
                SplitSummaryView(receipt: receipt, configuration: config)
            } else {
                BillSplitView(receipt: receipt)
            }
        }
    }

    // MARK: - Helper Methods

    private func loadAllSplits() {
        let receipts = CoreDataManager.shared.getSavedReceipts()

        allSplits = receipts.compactMap { receipt in
            if let config = billSplitManager.getConfiguration(for: receipt.id),
               !config.participants.isEmpty {
                return (receipt: receipt, config: config)
            }
            return nil
        }
        .sorted { $0.config.updatedAt > $1.config.updatedAt }
    }
}

#Preview {
    AllBillSplitsView()
}
