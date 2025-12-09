//
//  ReceiptReviewView.swift
//  Qassemha
//
//  Created by Harjot Singh on 21/09/25.
//

import SwiftUI

struct ReceiptReviewView: View {
    @Binding var receipt: Receipt
    @Binding var isPresented: Bool
    @State private var showingImageViewer = false
    @State private var isSaved = false
    @State private var showingDeleteConfirmation = false
    @State private var isSaving = false
    @State private var showSaveSuccess = false
    @State private var isDeleting = false
    @State private var selectedCategory: Receipt.ReceiptCategory
    @State private var showingCategoryPicker = false
    @State private var showingBillSplit = false

    init(receipt: Binding<Receipt>, isPresented: Binding<Bool>) {
        self._receipt = receipt
        self._isPresented = isPresented
        self._selectedCategory = State(initialValue: receipt.wrappedValue.category)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Receipt Image Preview (if available)
                    if let imageData = receipt.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Button(action: {
                            showingImageViewer = true
                        }) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                    }

                    // Receipt Header
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(receipt.storeName)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)

                                if let address = receipt.storeAddress {
                                    Text(address)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    // Category Picker Button
                                    if !isSaved {
                                        Button(action: {
                                            showingCategoryPicker = true
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: selectedCategory.icon)
                                                    .font(.system(size: 12, weight: .medium))
                                                Text(selectedCategory.rawValue)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .lineLimit(1)
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 10, weight: .medium))
                                            }
                                            .foregroundColor(selectedCategory.color)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(selectedCategory.color.opacity(0.15))
                                            .cornerRadius(8)
                                        }
                                    } else {
                                        HStack(spacing: 4) {
                                            Image(systemName: selectedCategory.icon)
                                                .font(.system(size: 12, weight: .medium))
                                            Text(selectedCategory.rawValue)
                                                .font(.system(size: 12, weight: .medium))
                                                .lineLimit(1)
                                        }
                                        .foregroundColor(selectedCategory.color)
                                    }

                                    HStack(spacing: 8) {
                                        Text(receipt.formattedDate)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)

                                        Text("•")
                                            .foregroundColor(.secondary)

                                        HStack(spacing: 4) {
                                            Image(systemName: receipt.scanType.icon)
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)

                                            Text(receipt.scanType.description)
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(receipt.formattedTotal)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)
                                    .environment(\.layoutDirection, .leftToRight)

                                Text("\(receipt.items.count) items")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Items List
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Items")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding(.horizontal, 20)

                        if receipt.items.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)

                                Text("No items detected")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.secondary)

                                Text("The receipt scan didn't detect any items.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.vertical, 40)

                        } else {
                            LazyVStack(spacing: 1) {
                                ForEach(receipt.items) { item in
                                    ReceiptItemRow(item: item, currency: receipt.currency)
                                }
                            }
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }
                    }

                    // Receipt Summary
                    VStack(spacing: 12) {
                        HStack {
                            Text("Summary")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                        }

                        VStack(spacing: 8) {
                            SummaryRow(title: "Subtotal", amount: receipt.subtotal, currency: receipt.currency)
                            SummaryRow(title: "Tax", amount: receipt.tax, currency: receipt.currency)

                            if receipt.tip > 0 {
                                SummaryRow(title: "Tip", amount: receipt.tip, currency: receipt.currency)
                            }

                            Divider()
                                .padding(.vertical, 4)

                            SummaryRow(
                                title: "Total",
                                amount: receipt.total,
                                currency: receipt.currency,
                                isTotal: true
                            )
                        }
                        .padding(16)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)

                    // Action Buttons
                    VStack(spacing: 12) {
                        if !isSaved || showSaveSuccess {
                            Button(action: {
                                saveReceipt()
                            }) {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.2)
                                    } else if showSaveSuccess {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20))
                                    } else {
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.system(size: 20))
                                    }

                                    Text(isSaving ? "Saving..." : (showSaveSuccess ? "Saved!" : "Save Receipt"))
                                }
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: (showSaveSuccess && !isSaving) ? [.green, .green.opacity(0.8)] : [.blue, .cyan]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: ((showSaveSuccess && !isSaving) ? Color.green : Color.blue).opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(isSaving || showSaveSuccess)
                            .transition(.opacity)
                        }

                        // Split Bill Button - Only show if receipt is saved
                        if isSaved && !showSaveSuccess {
                            Button(action: {
                                showingBillSplit = true
                            }) {
                                HStack {
                                    Image(systemName: "person.3.fill")
                                        .font(.system(size: 20))

                                    Text("Split Bill")
                                }
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple, .purple.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity)

                    Spacer(minLength: 40)
                }
                .padding(.vertical, 20)
            }
            .background(Color.gray.opacity(0.1))
            .navigationTitle("Receipt Review")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        DispatchQueue.main.async {
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                        }
                    }
                }

                if isSaved {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            DispatchQueue.main.async {
                                showingDeleteConfirmation = true
                            }
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .task {
                // Check if saved immediately on task start (before view appears)
                await checkIfSaved()
            }
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            if let imageData = receipt.imageData,
               let uiImage = UIImage(data: imageData) {
                ReceiptImageViewer(image: uiImage, isPresented: $showingImageViewer)
            }
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(selectedCategory: $selectedCategory, isPresented: $showingCategoryPicker)
                .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showingBillSplit) {
            BillSplitView(receipt: receipt)
        }
        .onChange(of: selectedCategory) { _, newCategory in
            receipt.category = newCategory
        }
        .alert("Delete Receipt", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                DispatchQueue.main.async {
                    showingDeleteConfirmation = false
                }
            }
            Button("Delete", role: .destructive) {
                DispatchQueue.main.async {
                    showingDeleteConfirmation = false
                    deleteReceipt()
                }
            }
        } message: {
            Text("Are you sure you want to delete this receipt? This action cannot be undone.")
        }
        .overlay {
            if isDeleting {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        Text("Deleting...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    /// Saves the receipt to Core Data with selected category
    /// Shows success feedback and auto-dismisses view after 2 seconds
    private func saveReceipt() {
        // Show saving state immediately
        withAnimation {
            isSaving = true
        }

        // Update receipt with selected category before saving
        var updatedReceipt = receipt
        updatedReceipt.category = selectedCategory

        // Perform save operation on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            CoreDataManager.shared.saveReceipt(updatedReceipt)

            // Update UI on main thread
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSaving = false
                    showSaveSuccess = true
                    isSaved = true
                }

                // Keep success message visible for 2 seconds to ensure visibility
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            }
        }
    }

    /// Checks if receipt is already saved in database
    /// Runs on background thread to avoid blocking UI
    private func checkIfSaved() async {
        // Check on background thread
        let saved = await Task.detached(priority: .userInitiated) {
            let savedReceipts = CoreDataManager.shared.getSavedReceipts()
            return savedReceipts.contains { $0.id == self.receipt.id }
        }.value

        // Update on main thread without animation to prevent layout delays
        await MainActor.run {
            self.isSaved = saved
        }
    }

    /// Deletes the receipt from Core Data
    /// Shows deleting animation and dismisses view on completion
    private func deleteReceipt() {
        // Show deleting state immediately
        withAnimation(.easeInOut(duration: 0.2)) {
            isDeleting = true
        }

        // Perform delete operation on background thread with higher priority
        DispatchQueue.global(qos: .userInitiated).async {
            CoreDataManager.shared.deleteReceipt(self.receipt)

            // Update UI on main thread and dismiss immediately
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.2)) {
                    self.isDeleting = false
                    self.isPresented = false
                }
            }
        }
    }
}

struct ReceiptItemRow: View {
    let item: ReceiptItem
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.category.color.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: item.category.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(item.category.color)
            }

            // Item Details
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)

                HStack {
                    if item.quantity != 1 {
                        Text("\(item.quantity, specifier: "%.0f") × \(currency == "﷼" ? "\u{202D}" : "")\(currency)\(currency == "﷼" ? "\u{00A0}" : " ")\(item.unitPrice, specifier: "%.2f")\(currency == "﷼" ? "\u{202C}" : "")")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    if !item.tags.isEmpty {
                        Text("• \(item.tags.joined(separator: ", "))")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Price
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(currency == "﷼" ? "\u{202D}" : "")\(currency)\(currency == "﷼" ? "\u{00A0}" : " ")\(item.totalPrice, specifier: "%.2f")\(currency == "﷼" ? "\u{202C}" : "")")
                    .font(.system(size: 16, weight: .bold))
                    .environment(\.layoutDirection, .leftToRight)

                if item.isEdited {
                    Text("edited")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SummaryRow: View {
    let title: String
    let amount: Double
    let currency: String
    let isTotal: Bool

    init(title: String, amount: Double, currency: String, isTotal: Bool = false) {
        self.title = title
        self.amount = amount
        self.currency = currency
        self.isTotal = isTotal
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: isTotal ? 18 : 16, weight: isTotal ? .bold : .medium))
                .foregroundColor(isTotal ? .primary : .secondary)

            Spacer()

            Text("\(currency == "﷼" ? "\u{202D}" : "")\(currency)\(currency == "﷼" ? "\u{00A0}" : " ")\(amount, specifier: "%.2f")\(currency == "﷼" ? "\u{202C}" : "")")
                .font(.system(size: isTotal ? 18 : 16, weight: isTotal ? .bold : .medium))
                .foregroundColor(.primary)
                .environment(\.layoutDirection, .leftToRight)
        }
    }
}

struct ReceiptImageViewer: View {
    let image: UIImage
    @Binding var isPresented: Bool

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                            withAnimation(.spring()) {
                                if scale < 1 {
                                    scale = 1
                                    lastScale = 1
                                } else if scale > 4 {
                                    scale = 4
                                    lastScale = 4
                                }
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring()) {
                        if scale > 1 {
                            scale = 1
                            lastScale = 1
                        } else {
                            scale = 2
                            lastScale = 2
                        }
                    }
                }

            VStack {
                HStack {
                    Spacer()
                    Button("Done") {
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()

                Spacer()
            }
        }
    }
}

// MARK: - Extensions

extension Receipt.ScanType {
    var icon: String {
        switch self {
        case .camera: return "camera"
        case .manual: return "pencil"
        case .barcode: return "barcode"
        case .qrCode: return "qrcode"
        }
    }

    var description: String {
        switch self {
        case .camera: return "Camera"
        case .manual: return "Manual"
        case .barcode: return "Barcode"
        case .qrCode: return "QR Code"
        }
    }
}

// MARK: - Category Picker View

struct CategoryPickerView: View {
    @Binding var selectedCategory: Receipt.ReceiptCategory
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                ForEach(Receipt.ReceiptCategory.allCases, id: \.self) { category in
                    Button(action: {
                        withAnimation {
                            selectedCategory = category
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 16) {
                            // Category Icon
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(category.color.opacity(0.15))
                                    .frame(width: 44, height: 44)

                                Image(systemName: category.icon)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(category.color)
                            }

                            // Category Name
                            Text(category.rawValue)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.primary)

                            Spacer()

                            // Checkmark if selected
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(category.color)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(selectedCategory == category ? category.color.opacity(0.08) : Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    ReceiptReviewView(
        receipt: .constant(DemoReceiptData.shared.sampleReceipts[0]),
        isPresented: .constant(true)
    )
}