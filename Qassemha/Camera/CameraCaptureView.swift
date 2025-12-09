//
//  CameraCaptureView.swift
//  Qassemha
//
//  Created by Harjot Singh on 21/09/25.
//

import SwiftUI
import AVFoundation

struct CameraCaptureView: View {
    @StateObject private var cameraManager = CameraManager()
    @Binding var isPresented: Bool
    @Binding var capturedReceipt: Receipt?

    @State private var showingImagePicker = false
    @State private var showingPermissionAlert = false
    @State private var zoomFactor: CGFloat = 1.0


    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if cameraManager.isCameraAuthorized && !cameraManager.isCameraUnavailable {
                // Camera Preview
                if let session = cameraManager.captureSession {
                    CameraPreview(session: session)
                        .ignoresSafeArea()
                        .scaleEffect(zoomFactor)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    zoomFactor = min(max(value, 1.0), 5.0)
                                }
                        )
                }

                // Overlay UI
                VStack {
                    // Top Controls
                    HStack {
                        // Close Button
                        Button(action: {
                            cameraManager.stopSession()
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

                        // Settings/Info Button
                        Button(action: {
                            // Show tips or settings
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.black.opacity(0.6))
                                    .frame(width: 56, height: 56)

                                Image(systemName: "info.circle")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
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

    private func processScannedReceipt(image: UIImage, text: String) {
        print("🔄 Processing scanned receipt...")

        // Convert image to data
        let imageData = image.jpegData(compressionQuality: 0.8)

        // Parse the extracted text
        if let parsedReceipt = DemoReceiptData.shared.parseReceiptText(text) {
            var receipt = parsedReceipt
            receipt.imageData = imageData
            receipt.scanType = .camera

            print("✅ Receipt successfully parsed and processed!")
            print("Final receipt: \(receipt.storeName) - \(receipt.items.count) items - $\(receipt.total)")

            capturedReceipt = receipt
            isPresented = false
        } else {
            print("⚠️ Failed to parse receipt - creating basic structure")
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
    CameraCaptureView(isPresented: .constant(true), capturedReceipt: .constant(nil))
}