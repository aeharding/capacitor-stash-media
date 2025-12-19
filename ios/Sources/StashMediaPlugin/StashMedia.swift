import Foundation
import UIKit
import Photos

class StashMedia {
    private var customUserAgent: String?

    private var _session: URLSession?

    private var defaultSession: URLSession {
        if _session == nil {
            _session = createURLSession()
        }
        return _session!
    }

    init(userAgent: String? = nil) {
        customUserAgent = userAgent
    }

    private func createURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        if let userAgent = customUserAgent {
            configuration.httpAdditionalHeaders = ["User-Agent": userAgent]
        }
        return URLSession(configuration: configuration)
    }

    private func downloadImageData(from urlString: String, completion: @escaping (Result<(Data, HTTPURLResponse?), Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "StashMedia", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        defaultSession.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "StashMedia", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch image data"])))
                return
            }

            completion(.success((data, response as? HTTPURLResponse)))
        }.resume()
    }

    private func downloadImage(from urlString: String, completion: @escaping (Result<(Data, String), Error>) -> Void) {
        downloadImageData(from: urlString) { result in
            switch result {
            case .success((let data, let response)):
                guard let mimeType = response?.mimeType else {
                    completion(.failure(NSError(domain: "StashMedia", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to determine MIME type"])))
                    return
                }
                completion(.success((data, mimeType)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func copyPhotoToClipboard(from imageURLString: String, completion: @escaping (Bool, String) -> Void) {
        downloadImage(from: imageURLString) { result in
            switch result {
            case .success((let data, _)):
                DispatchQueue.main.async {
                    if let image = UIImage(data: data) {
                        UIPasteboard.general.image = image
                        completion(true, "Image copied to clipboard")
                    } else {
                        completion(false, "Failed to decode image data")
                    }
                }
            case .failure(let error):
                completion(false, error.localizedDescription)
            }
        }
    }

    func fileExtension(forMimeType mimeType: String) -> String {
        if let utType = UTType(mimeType: mimeType) {
            return utType.preferredFilenameExtension ?? ""
        }
        return ""
    }

    func shareImage(from imageURLString: String, title: String, completion: @escaping (Bool, String) -> Void) {
        downloadImage(from: imageURLString) { result in
            switch result {
            case .success((let data, let mimeType)):
                self.shareImageData(data, mimeType: mimeType, title: title, completion: completion)
            case .failure(let error):
                completion(false, error.localizedDescription)
            }
        }
    }

    private func shareImageData(_ data: Data, mimeType: String, title: String, completion: @escaping (Bool, String) -> Void) {
        // Convert AVIF to JPEG for better Messages compatibility
        let processedData: Data
        let processedExtension: String
        if mimeType == "image/avif", let image = UIImage(data: data) {
            processedData = image.jpegData(compressionQuality: 0.9) ?? data
            processedExtension = "jpg"
        } else {
            processedData = data
            processedExtension = self.fileExtension(forMimeType: mimeType)
        }

        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let temporaryFileURL = temporaryDirectoryURL
            .appendingPathComponent(title)
            .appendingPathExtension(processedExtension)

        do {
            try processedData.write(to: temporaryFileURL)

            DispatchQueue.main.async {
                let activityController = UIActivityViewController(activityItems: [temporaryFileURL], applicationActivities: nil)

                if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                    activityController.completionWithItemsHandler = { activityType, completed, _, _ in
                        // Delete the temporary file after sharing is complete
                        do {
                            try FileManager.default.removeItem(at: temporaryFileURL)
                        } catch {
                            print("Error deleting temporary file: \(error)")
                        }
                    }

                    activityController.popoverPresentationController?.sourceView = rootViewController.view
                    rootViewController.present(activityController, animated: true, completion: nil)

                    completion(true, "Image shared successfully")
                } else {
                    completion(false, "Unable to present share dialog")
                }
            }
        } catch {
            completion(false, "Error saving image to temporary file")
        }
    }

    func saveImageToPhotoLibrary(from imageURL: URL, completion: @escaping (Bool, String) -> Void) {
        downloadImage(from: imageURL.absoluteString) { result in
            switch result {
            case .success((let data, let mimeType)):
                self.saveImageToLibrary(data, mimeType: mimeType, originalURL: imageURL, completion: completion)
            case .failure(let error):
                completion(false, error.localizedDescription)
            }
        }
    }

    private func handlePhotoLibraryCompletion(success: Bool, error: Error?, fileURL: URL, successMessage: String, completion: @escaping (Bool, String) -> Void) {
        defer { try? FileManager.default.removeItem(at: fileURL) }
        if success {
            completion(true, successMessage)
        } else if let error = error {
            completion(false, "Failed to save: \(error.localizedDescription)")
        } else {
            completion(false, "Failed to save")
        }
    }

    private func saveImageToLibrary(_ data: Data, mimeType: String, originalURL: URL, completion: @escaping (Bool, String) -> Void) {
        let fileExtension = self.fileExtension(forMimeType: mimeType)
        let originalFileName = originalURL.lastPathComponent
        var fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(originalFileName)

        // Ensure correct extension
        if !originalFileName.lowercased().hasSuffix(".\(fileExtension)") {
            fileURL.deletePathExtension()
            fileURL.appendPathExtension(fileExtension)
        }

        do {
            try data.write(to: fileURL)
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
            } completionHandler: { success, error in
                self.handlePhotoLibraryCompletion(success: success, error: error, fileURL: fileURL, successMessage: "Image saved to photo library", completion: completion)
            }
        } catch {
            completion(false, "Failed to write image data to file: \(error.localizedDescription)")
        }
    }

    func downloadAndSaveVideoToGallery(videoURL: String, id: String = "default", completion: @escaping (Bool, String) -> Void) {
        downloadImage(from: videoURL) { result in
            switch result {
            case .success((let data, let mimeType)):
                self.saveVideoToLibrary(data, mimeType: mimeType, id: id, completion: completion)
            case .failure(let error):
                completion(false, error.localizedDescription)
            }
        }
    }

    private func saveVideoToLibrary(_ data: Data, mimeType: String, id: String, completion: @escaping (Bool, String) -> Void) {
        let fileExtension = self.fileExtension(forMimeType: mimeType)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(id).\(fileExtension)")

        do {
            try data.write(to: fileURL)
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
            } completionHandler: { success, error in
                self.handlePhotoLibraryCompletion(success: success, error: error, fileURL: fileURL, successMessage: "Video saved to gallery", completion: completion)
            }
        } catch {
            completion(false, "Failed to write video data to file: \(error.localizedDescription)")
        }
    }
}
