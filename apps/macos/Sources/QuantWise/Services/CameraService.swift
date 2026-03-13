import AVFoundation
import AppKit

@MainActor
final class CameraService: ObservableObject {
    @Published var capturedImage: NSImage?
    @Published var capturedJPEGData: Data?
    @Published var isCapturing = false
    @Published var errorMessage: String?

    private var cameraAuthorized = false

    func capturePhoto() {
        Task { await captureWithAuth() }
    }

    func clearCapture() {
        capturedImage = nil
        capturedJPEGData = nil
    }

    // MARK: - Authorization

    private func captureWithAuth() async {
        errorMessage = nil
        isCapturing = true

        if !cameraAuthorized {
            let granted = await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    cont.resume(returning: granted)
                }
            }
            cameraAuthorized = granted
            if !cameraAuthorized {
                errorMessage = "需要摄像头权限"
                isCapturing = false
                return
            }
        }

        await performCapture()
    }

    // MARK: - Capture

    private func performCapture() async {
        guard let device = AVCaptureDevice.default(for: .video) else {
            errorMessage = "未找到摄像头"
            isCapturing = false
            return
        }

        let session = AVCaptureSession()
        session.sessionPreset = .photo

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                errorMessage = "无法添加摄像头输入"
                isCapturing = false
                return
            }
            session.addInput(input)
        } catch {
            errorMessage = "摄像头错误: \(error.localizedDescription)"
            isCapturing = false
            return
        }

        let photoOutput = AVCapturePhotoOutput()
        guard session.canAddOutput(photoOutput) else {
            errorMessage = "无法添加拍照输出"
            isCapturing = false
            return
        }
        session.addOutput(photoOutput)

        session.startRunning()

        // Wait for auto-exposure/focus to stabilize
        try? await Task.sleep(nanoseconds: 500_000_000)

        let result = await withCheckedContinuation { (cont: CheckedContinuation<Data?, Never>) in
            let delegate = PhotoCaptureDelegate { data in
                cont.resume(returning: data)
            }
            // Store delegate to prevent deallocation
            objc_setAssociatedObject(photoOutput, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)

            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }

        session.stopRunning()

        if let jpegData = result {
            let compressed = Self.compressImage(jpegData: jpegData)
            capturedJPEGData = compressed
            capturedImage = NSImage(data: compressed)
        } else {
            errorMessage = "拍照失败"
        }

        isCapturing = false
    }

    // MARK: - Compression

    /// Resize to max 1024px on longest side, JPEG 80% quality
    static func compressImage(jpegData: Data) -> Data {
        guard let image = NSImage(data: jpegData) else { return jpegData }

        let maxDimension: CGFloat = 1024
        let size = image.size
        var targetSize = size

        if size.width > maxDimension || size.height > maxDimension {
            let scale = maxDimension / max(size.width, size.height)
            targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        }

        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(targetSize.width),
            pixelsHigh: Int(targetSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )

        guard let rep else { return jpegData }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(origin: .zero, size: targetSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) ?? jpegData
    }
}

// MARK: - Photo Capture Delegate

private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Data?) -> Void

    init(completion: @escaping (Data?) -> Void) {
        self.completion = completion
    }

    func photoOutput(
        _: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if error != nil {
            completion(nil)
            return
        }
        completion(photo.fileDataRepresentation())
    }
}
