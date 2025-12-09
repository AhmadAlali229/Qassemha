//
//  CameraCaptureView.swift
//  Qassemha
//
//  Created by Harjot Singh on 21/09/25.
//

import SwiftUI
import AVFoundation

struct CameraCaptureView: View {
    @ObservedObject var cameraManager: CameraManager
    @Binding var isPresented: Bool
    @Binding var capturedReceipt: Receipt?

    @State private var showingImagePicker = false
    @State private var showingPermissionAlert = false
    @State private var zoomFactor: CGFloat = 1.0

    init(cameraManager: CameraManager? = nil, isPresented: Binding<Bool>, capturedReceipt: Binding<Receipt?>) {
        self.cameraManager = cameraManager ?? CameraManager()
        self._isPresented = isPresented
        self._capturedReceipt = capturedReceipt
    }


    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if cameraManager.isCameraAuthorized && !cameraManager.isCameraUnavailable {
                // Camera Preview
                if cameraManager.isSessionReady, let session = cameraManager.captureSession {
                    CameraPreview(session: session)
                        .ignoresSafeArea()
                        .scaleEffect(zoomFactor)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    zoomFactor = min(max(value, 1.0), 5.0)
                                }
                        )
                } else {
                    // Loading state while camera is initializing
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        Text("Initializing Camera...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }

                // Overlay UI
                VStack {
                    // Top Controls
                    HStack {
                        // Close Button
                        Button(action: {
                            cameraManager.stopSession()
                            cameraManager.clearQRCodes()
                            isPresented = false
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.black.opacity(0.6))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }

                        Spacer()

                        // Scan Mode Selector
                        Menu {
                            Button(action: { cameraManager.scanMode = .auto }) {
                                Label("Auto (OCR + QR)", systemImage: "camera.aperture")
                            }
                            Button(action: { cameraManager.scanMode = .ocrOnly }) {
                                Label("OCR Only", systemImage: "doc.text.viewfinder")
                            }
                            Button(action: { cameraManager.scanMode = .qrOnly }) {
                                Label("QR Code Only", systemImage: "qrcode.viewfinder")
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.black.opacity(0.6))
                                    .frame(width: 44, height: 44)

                                Image(systemName: scanModeIcon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }

                        Spacer()

                        // Flash Toggle
                        Button(action: {
                            cameraManager.toggleFlash()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.black.opacity(0.6))
                                    .frame(width: 44, height: 44)

                                Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(cameraManager.isFlashOn ? .yellow : .white)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    Spacer()

                    // QR Code Detection Overlay
                    if !cameraManager.detectedQRCodes.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(cameraManager.detectedQRCodes) { qrCode in
                                ZStack(alignment: .topTrailing) {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Image(systemName: "qrcode")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.green)

                                            Text("QR Code Detected")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                        }

                                        Text(qrCode.value)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(3)
                                            .padding(.horizontal, 8)

                                        HStack(spacing: 12) {
                                            Button(action: {
                                                processQRCode(qrCode)
                                            }) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 12, weight: .medium))
                                                    Text("Use QR Code")
                                                        .font(.system(size: 14, weight: .semibold))
                                                }
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.green)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            .buttonStyle(PlainButtonStyle())

                                            Button(action: {
                                                // Copy to clipboard
                                                UIPasteboard.general.string = qrCode.value
                                            }) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "doc.on.doc")
                                                        .font(.system(size: 12, weight: .medium))
                                                    Text("Copy")
                                                        .font(.system(size: 14, weight: .semibold))
                                                }
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.blue)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(16)

                                    // Dismiss button
                                    Button(action: {
                                        // Clear QR codes immediately without animation to prevent conflicts
                                        cameraManager.clearQRCodes()
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(.white.opacity(0.3))
                                                .frame(width: 30, height: 30)

                                            Image(systemName: "xmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(8)
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.black.opacity(0.8))
                                        .shadow(color: .green.opacity(0.5), radius: 10)
                                )
                                .padding(.horizontal, 40)
                            }
        }
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: cameraManager.detectedQRCodes.isEmpty)
                    }

                    Spacer()

                    // Bottom Controls
                    HStack {
                        // Photo Library Button
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.black.opacity(0.6))
                                    .frame(width: 56, height: 56)

                                Image(systemName: "photo")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }

                        Spacer()

                        // Capture Button
                        Button(action: {
                            cameraManager.capturePhoto()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 80, height: 80)

                                Circle()
                                    .stroke(.black.opacity(0.2), lineWidth: 2)
                                    .frame(width: 70, height: 70)

                                if cameraManager.isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Circle()
                                        .fill(.black)
                                        .frame(width: 60, height: 60)
                                }
                            }
                        }
                        .disabled(cameraManager.isProcessing)

                        Spacer()

                        // Spacer for symmetry
                        Spacer()
                            .frame(width: 56)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }


            } else {
                // Permission Required or Camera Unavailable
                VStack(spacing: 24) {
                    Image(systemName: cameraManager.isCameraUnavailable ? "camera.fill.badge.ellipsis" : "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)

                    VStack(spacing: 12) {
                        Text(cameraManager.isCameraUnavailable ? "Camera Unavailable" : "Camera Access Required")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text(cameraManager.isCameraUnavailable
                             ? "Unable to access camera. Please check your device."
                             : "Allow camera access to scan receipts and barcodes")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    if !cameraManager.isCameraUnavailable {
                        VStack(spacing: 12) {
                            Button("Grant Camera Access") {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            Button("Use Photo Library Instead") {
                                showingImagePicker = true
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    Button("Cancel") {
                        cameraManager.clearQRCodes()
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
            // Clear QR codes when leaving camera screen
            cameraManager.clearQRCodes()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { image in
                cameraManager.capturedImage = image
                cameraManager.processImage(image)
            }
        }
        .onChange(of: cameraManager.extractedText) { _, text in
            if let image = cameraManager.capturedImage, !text.isEmpty {
                processScannedReceipt(image: image, text: text)
            }
        }
        .alert("Error", isPresented: .constant(cameraManager.error != nil)) {
            Button("OK") {
                cameraManager.error = nil
            }
        } message: {
            Text(cameraManager.error?.localizedDescription ?? "Unknown error occurred")
        }
    }

    private var scanModeIcon: String {
        switch cameraManager.scanMode {
        case .auto:
            return "camera.aperture"
        case .ocrOnly:
            return "doc.text.viewfinder"
        case .qrOnly:
            return "qrcode.viewfinder"
        }
    }

    private func processQRCode(_ qrCode: QRCodeData) {
        // Check if QR code contains receipt data (JSON format)
        if let receiptData = parseReceiptFromQRCode(qrCode.value) {
            cameraManager.clearQRCodes()

            // Set the receipt first, then dismiss after a brief delay
            DispatchQueue.main.async {
                self.capturedReceipt = receiptData

                // Give time for the binding to propagate before dismissing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.isPresented = false
                }
            }
            return
        }

        // Check if it's a URL
        if let url = URL(string: qrCode.value), UIApplication.shared.canOpenURL(url) {
            // Could open URL in Safari or process if it's a receipt service URL
            return
        }
    }

    private func parseReceiptFromQRCode(_ qrString: String) -> Receipt? {
        // First, check if the QR code exists in the database
        if let receipt = ReceiptDataService.shared.fetchReceipt(forQRCode: qrString) {
            print("✅ Found receipt in database for QR code: \(receipt.storeName)")
            return receipt
        }

        // Check for partial matches (for backward compatibility)
        if qrString.contains("aGF3YXJtYSBIb3VzZSBDb21wYW55") {
            let taqwarmaQR = "ARZTaGF3YXJtYSBIb3VzZSBDb21wYW55Ag8zMTA0NjQ5MDEyMDAwMDMDFDIwMjUtMTAtMDUgMTU6Mzk6MjFaBAYxNjcuMDAFBTIxLjc4"
            if let receipt = ReceiptDataService.shared.fetchReceipt(forQRCode: taqwarmaQR) {
                return receipt
            }
        }

        if qrString.contains("2KrZgtin2LfZiti5INmI2K3Zhdin2YU") {
            let taqatuHamamQR = "ATzZhdit2YQg2KrZgtin2LfZiti5INmI2K3Zhdin2YUg2YTZhNiq2KzYp9ix2YcgLSDYp9mE2YHYsdi5IDMCDzMwMDcwNTUyMTgwMDAwMwMUMjAyNS0wOS0zMFQyMDowNDowNVoEAzE1OAUFMjAuNjI="
            if let receipt = ReceiptDataService.shared.fetchReceipt(forQRCode: taqatuHamamQR) {
                return receipt
            }
        }

        // Try to parse as JSON receipt data
        guard let data = qrString.data(using: .utf8) else { return nil }

        do {
            // Attempt to decode as a receipt JSON structure
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Check if it contains receipt-like fields
                if let storeName = json["store_name"] as? String ?? json["storeName"] as? String ?? json["merchant"] as? String,
                   let total = json["total"] as? Double {

                    let items = (json["items"] as? [[String: Any]])?.compactMap { itemDict -> ReceiptItem? in
                        guard let name = itemDict["name"] as? String,
                              let price = itemDict["price"] as? Double else { return nil }
                        let quantity = itemDict["quantity"] as? Double ?? 1.0
                        let unitPrice = itemDict["unitPrice"] as? Double ?? price
                        let totalPrice = itemDict["totalPrice"] as? Double ?? (unitPrice * quantity)

                        // Try to parse category, default to .other
                        let categoryStr = itemDict["category"] as? String ?? "other"
                        let category = ReceiptItem.ItemCategory(rawValue: categoryStr) ?? .other

                        let tags = itemDict["tags"] as? [String] ?? []

                        return ReceiptItem(
                            name: name,
                            quantity: quantity,
                            unitPrice: unitPrice,
                            totalPrice: totalPrice,
                            category: category,
                            tags: tags,
                            notes: itemDict["notes"] as? String
                        )
                    } ?? []

                    let receipt = Receipt(
                        storeName: storeName,
                        storeAddress: json["address"] as? String ?? json["storeAddress"] as? String,
                        date: Date(), // Could parse from JSON if available
                        items: items,
                        subtotal: json["subtotal"] as? Double ?? total,
                        tax: json["tax"] as? Double ?? 0,
                        tip: json["tip"] as? Double ?? 0,
                        total: total,
                        currency: json["currency"] as? String ?? "USD",
                        receiptNumber: json["receipt_number"] as? String ?? json["receiptNumber"] as? String,
                        imageData: nil,
                        scanType: .qrCode,
                        category: .other
                    )

                    print("✅ Successfully parsed receipt from QR code!")
                    return receipt
                }
            }
        } catch {
            // Failed to parse as JSON
        }

        return nil
    }

    private func processScannedReceipt(image: UIImage, text: String) {
        // Convert image to data
        let imageData = image.jpegData(compressionQuality: 0.8)

        // Parse the extracted text
        if let parsedReceipt = DemoReceiptData.shared.parseReceiptText(text) {
            var receipt = parsedReceipt
            receipt.imageData = imageData
            receipt.scanType = .camera

            cameraManager.clearQRCodes()
            capturedReceipt = receipt
            isPresented = false
        } else {
            // If parsing fails, create a basic receipt structure
            let receipt = Receipt(
                storeName: "Unknown Store",
                storeAddress: nil,
                date: Date(),
                items: [],
                subtotal: 0,
                tax: 0,
                tip: 0,
                total: 0,
                currency: "USD",
                receiptNumber: nil,
                imageData: imageData,
                scanType: .camera,
                category: .other
            )

            cameraManager.clearQRCodes()
            capturedReceipt = receipt
            isPresented = false
        }
    }
}


// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    CameraCaptureView(cameraManager: nil, isPresented: .constant(true), capturedReceipt: .constant(nil))
}