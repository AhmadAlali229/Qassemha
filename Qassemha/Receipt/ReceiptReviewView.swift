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

                                HStack(spacing: 8) {
                                    Image(systemName: receipt.category.icon)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(receipt.category.color)

                                    Text(receipt.category.rawValue)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(receipt.category.color)

                                    Text("•")
                                        .foregroundColor(.secondary)

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
                                    }
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(receipt.formattedTotal)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)

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
                                    ReceiptItemRow(item: item)
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
                            SummaryRow(title: "Subtotal", amount: receipt.subtotal)
                            SummaryRow(title: "Tax", amount: receipt.tax)

                            if receipt.tip > 0 {
                                SummaryRow(title: "Tip", amount: receipt.tip)
                            }

                            Divider()
                                .padding(.vertical, 4)

                            SummaryRow(
                                title: "Total",
                                amount: receipt.total,
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
                        Button("Continue to Split Bill") {
                            // Navigate to bill splitting
                            isPresented = false
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .cyan]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)

                        Button("Save for Later") {
                            // Save receipt
                            isPresented = false
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 20)

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
                    Button("Back") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Retake Photo") {
                            // Return to camera
                        }

                        Button("Share Receipt") {
                            // Share functionality
                        }

                        Button("Delete", role: .destructive) {
                            // Delete confirmation
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            if let imageData = receipt.imageData,
               let uiImage = UIImage(data: imageData) {
                ReceiptImageViewer(image: uiImage, isPresented: $showingImageViewer)
            }
        }
    }
}

struct ReceiptItemRow: View {
    let item: ReceiptItem

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
                        Text("\(item.quantity, specifier: "%.0f") × $\(item.unitPrice, specifier: "%.2f")")
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
                Text("$\(item.totalPrice, specifier: "%.2f")")
                    .font(.system(size: 16, weight: .bold))

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
    let isTotal: Bool

    init(title: String, amount: Double, isTotal: Bool = false) {
        self.title = title
        self.amount = amount
        self.isTotal = isTotal
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: isTotal ? 18 : 16, weight: isTotal ? .bold : .medium))
                .foregroundColor(isTotal ? .primary : .secondary)

            Spacer()

            Text("$\(amount, specifier: "%.2f")")
                .font(.system(size: isTotal ? 18 : 16, weight: isTotal ? .bold : .medium))
                .foregroundColor(.primary)
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

#Preview {
    ReceiptReviewView(
        receipt: .constant(DemoReceiptData.shared.sampleReceipts[0]),
        isPresented: .constant(true)
    )
}