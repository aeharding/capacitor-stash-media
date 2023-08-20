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

            let fileExtension = url.pathExtension
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
}
