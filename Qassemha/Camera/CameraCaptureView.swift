//
//  CameraCaptureView.swift
//  Qassemha
//
//  OCR receipt capture flow.
//

import SwiftUI
import AVFoundation

struct CameraCaptureView: View {
    @ObservedObject var cameraManager: CameraManager
    @Binding var isPresented: Bool
    @Binding var capturedReceipt: Receipt?

    @State private var showingImagePicker = false
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
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        Text("Initializing Camera...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }

                VStack {
                    HStack {
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

                    HStack {
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
                        Spacer()
                            .frame(width: 56)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            } else {
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
                             : "Allow camera access to scan receipts")
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

    private func parseDateFromString(_ dateString: String) -> Date? {
        let dateFormats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "dd/MM/yyyy HH:mm:ss",
            "dd/MM/yyyy HH:mm",
            "dd-MM-yyyy HH:mm:ss",
            "dd-MM-yyyy HH:mm",
            "MM/dd/yyyy HH:mm:ss",
            "MM/dd/yyyy HH:mm",
            "MM-dd-yyyy HH:mm:ss",
            "MM-dd-yyyy HH:mm",
            "yyyy-MM-dd",
            "dd/MM/yyyy",
            "dd-MM-yyyy",
            "MM/dd/yyyy",
            "MM-dd-yyyy"
        ]

        for format in dateFormats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current

            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }

    private func extractDateFromText(_ text: String) -> Date? {
        let regexPatterns = [
            "\\d{4}-\\d{2}-\\d{2}[T ]\\d{2}:\\d{2}:\\d{2}[Z]?",
            "\\d{2}/\\d{2}/\\d{4}[\\s]+\\d{2}:\\d{2}(?::\\d{2})?",
            "\\d{2}-\\d{2}-\\d{4}[\\s]+\\d{2}:\\d{2}(?::\\d{2})?",
            "\\d{4}-\\d{2}-\\d{2}",
            "\\d{2}/\\d{2}/\\d{4}",
            "\\d{2}-\\d{2}-\\d{4}"
        ]

        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            for pattern in regexPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                   let range = Range(match.range, in: line) {
                    let dateString = String(line[range])
                    if let date = parseDateFromString(dateString) {
                        return date
                    }
                }
            }
        }

        return nil
    }

    private func processScannedReceipt(image: UIImage, text: String) {
        let imageData = image.jpegData(compressionQuality: 0.8)

        if let parsedReceipt = DemoReceiptData.shared.parseReceiptText(text) {
            var receipt = parsedReceipt
            receipt.imageData = imageData
            receipt.scanType = .camera
            capturedReceipt = receipt
            isPresented = false
        } else {
            let extractedDate = extractDateFromText(text) ?? Date()
            let receipt = Receipt(
                storeName: "Unknown Store",
                storeAddress: nil,
                date: extractedDate,
                createdAt: Date(),
                items: [],
                subtotal: 0,
                tax: 0,
                tip: 0,
                total: 0,
                currency: "USD",
                receiptNumber: nil,
                imageData: imageData,
                scanType: .camera,
                category: .other,
                receiptType: .sent
            )

            capturedReceipt = receipt
            isPresented = false
        }
    }
}

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
