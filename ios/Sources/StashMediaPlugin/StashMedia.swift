import Foundation
import UIKit
import Photos
import SDWebImage

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

        // Set up global request modifier for SDWebImageDownloader
        if let userAgent = userAgent {
            let requestModifier = SDWebImageDownloaderRequestModifier { request in
                var mutableRequest = request
                mutableRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
                return mutableRequest
            }
            SDWebImageDownloader.shared.requestModifier = requestModifier
        }
    }

    private func createURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        if let userAgent = customUserAgent {
            configuration.httpAdditionalHeaders = ["User-Agent": userAgent]
        }
        return URLSession(configuration: configuration)
    }

    func copyPhotoToClipboard(from imageURLString: String, completion: @escaping (Bool, String) -> Void) {
        if let imageURL = URL(string: imageURLString) {
            let options: SDWebImageDownloaderOptions = [.preloadAllFrames]

            SDWebImageDownloader.shared.downloadImage(with: imageURL, options: options, progress: nil) { (image, data, error, _) in
                if let error = error {
                    completion(false, "Failed to fetch image: \(error.localizedDescription)")
                    return
                }

                guard let image = image else {
                    completion(false, "Failed to fetch image data")
                    return
                }

                DispatchQueue.main.async {
                    UIPasteboard.general.image = image
                    completion(true, "Image copied to clipboard")
                }
            }
        } else {
            completion(false, "Invalid URL")
        }
    }

    func fileExtension(forMimeType mimeType: String) -> String {
        if #available(iOS 14.0, *) {
            if let utType = UTType(mimeType: mimeType) {
                return utType.preferredFilenameExtension ?? ""
            }
        } else {
            switch mimeType {
                case "image/jpeg":
                    return "jpeg"
                case "image/png":
                    return "png"
                case "image/gif":
                    return "gif"
                case "image/webp":
                    return "webp"
                case "image/jxl":
                    return "jxl"
                case "image/avif":
                    return "avif"
                case "video/mp4":
                    return "mp4"
                case "video/quicktime":
                    return "mov"
                case "video/x-matroska":
                    return "mkv"
                case "video/webm":
                    return "webm"
                default:
                    return ""
            }
        }
        return ""
    }

    func shareImage(from imageURLString: String, title: String, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: imageURLString) else {
            completion(false, "Invalid URL")
            return
        }

        defaultSession.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(false, "Error downloading image: \(error)")
                return
            }

            guard let data = data else {
                completion(false, "Invalid image data")
                return
            }

            guard let mimeType = response?.mimeType else {
                completion(false, "Unable to determine MIME type")
                return
            }

            let fileExtension = self.fileExtension(forMimeType: mimeType)

            let temporaryDirectoryURL = FileManager.default.temporaryDirectory
            let temporaryFileURL = temporaryDirectoryURL
                .appendingPathComponent(title)
                .appendingPathExtension(fileExtension)

            do {
                try data.write(to: temporaryFileURL)

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
        }.resume()
    }

    func saveImageToPhotoLibrary(from imageURL: URL, completion: @escaping (Bool, String) -> Void) {
        let options: SDWebImageDownloaderOptions = [.preloadAllFrames]

        SDWebImageDownloader.shared.downloadImage(with: imageURL, options: options, progress: nil) { (image, data, error, _) in
            if let error = error {
                completion(false, "Failed to download image: \(error.localizedDescription)")
                return
            }

            guard let image = image else {
                completion(false, "Failed to download image")
                return
            }

            guard let imageData = data else {
                completion(false, "Failed to download image data from the URL")
                return
            }

            // Non-anmated image
            if image.sd_isAnimated != true {
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, error in
                    if success {
                        completion(true, "Image saved to photo library")
                    } else if let error = error {
                        completion(false, "Failed to save image: \(error.localizedDescription)")
                    } else {
                        completion(false, "Failed to save image")
                    }
                }

                return
            }

            let originalFileName = imageURL.lastPathComponent
            var fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(originalFileName)

            // Append .gif to the end of the file name
            if !originalFileName.lowercased().hasSuffix(".gif") {
                fileURL.deletePathExtension()
                fileURL.appendPathExtension("gif")
            }

            do {
                try imageData.write(to: fileURL)
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
                } completionHandler: { success, error in
                    if success {
                        completion(true, "Image saved to photo library")
                        try? FileManager.default.removeItem(at: fileURL)
                    } else if let error = error {
                        completion(false, "Failed to save image: \(error.localizedDescription)")
                    } else {
                        completion(false, "Failed to save image")
                    }
                }
            } catch {
                completion(false, "Failed to write image data to file: \(error.localizedDescription)")
            }
        }
    }

    var dataTask: URLSessionDataTask? = nil

    func downloadAndSaveVideoToGallery(videoURL: String, id: String = "default", completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .background).async {
            if let url = URL(string: videoURL) {
                let filePath = FileManager.default.temporaryDirectory.appendingPathComponent("\(id).mp4")

                self.dataTask = self.defaultSession.dataTask(with: url, completionHandler: { [weak self] data, res, err in
                    DispatchQueue.main.async {
                        if let error = err {
                            completion(false, "Error downloading video: \(error.localizedDescription)")
                            return
                        }
                        
                        do {
                            try data?.write(to: filePath)
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: filePath)
                            }) { completed, error in
                                if completed {
                                    completion(true, "Video saved to gallery")
                                } else if let error = error {
                                    completion(false, "Failed to save video: \(error.localizedDescription)")
                                } else {
                                    completion(false, "Failed to save video")
                                }
                            }
                        } catch {
                            completion(false, "Error writing video to file: \(error.localizedDescription)")
                        }
                    }
                    self?.dataTask = nil
                })
                self.dataTask?.resume()
            } else {
                completion(false, "Invalid video URL")
            }
        }
    }
}
