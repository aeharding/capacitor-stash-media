import Foundation
import UIKit
import Photos

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

    func saveImageToPhotoLibrary(from imageURL: URL, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .background).async {
            if let imageData = try? Data(contentsOf: imageURL),
               let image = UIImage(data: imageData) {
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
            } else {
                completion(false, "Failed to fetch image data")
            }
        }
    }
}
