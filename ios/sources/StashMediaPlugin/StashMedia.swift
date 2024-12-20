import Foundation
import UIKit
import Photos
import SDWebImage

class StashMedia {
    func copyPhotoToClipboard(from imageURLString: String, completion: @escaping (Bool, String) -> Void) {
        if let imageURL = URL(string: imageURLString) {
            DispatchQueue.global(qos: .background).async {
                if let imageData = try? Data(contentsOf: imageURL),
                   let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        UIPasteboard.general.image = image
                        completion(true, "Image copied to clipboard")
                    }
                } else {
                    completion(false, "Failed to fetch image data")
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

        URLSession.shared.dataTask(with: url) { data, response, error in
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

    func saveMediaToPhotoLibrary(from mediaURL: URL, isVideo: Bool, completion: @escaping (Bool, String) -> Void) {
        let session = URLSession.shared
        let downloadTask = session.dataTask(with: mediaURL) { data, response, error in
            if let error = error {
                completion(false, "Failed to download media: \(error.localizedDescription)")
                return
            }

            guard let mediaData = data else {
                completion(false, "Failed to download media data from the URL")
                return
            }

            let temporaryDirectoryURL = FileManager.default.temporaryDirectory
            let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(mediaURL.lastPathComponent)

            do {
                try mediaData.write(to: temporaryFileURL)

                PHPhotoLibrary.shared().performChanges {
                    if isVideo {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: temporaryFileURL)
                    } else {
                        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: temporaryFileURL)
                    }
                } completionHandler: { success, error in
                    if success {
                        completion(true, "Media saved to photo library")
                        try? FileManager.default.removeItem(at: temporaryFileURL)
                    } else if let error = error {
                        completion(false, "Failed to save media: \(error.localizedDescription)")
                    } else {
                        completion(false, "Failed to save media")
                    }
                }
            } catch {
                completion(false, "Failed to write media data to file: \(error.localizedDescription)")
            }
        }
        downloadTask.resume()
    }
}
