import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(StashMediaPlugin)
public class StashMediaPlugin: CAPPlugin {
    private let stashMedia = StashMedia()

    @objc func copyPhotoToClipboard(_ call: CAPPluginCall) {
        if let urlString = call.getString("url") {
            stashMedia.copyPhotoToClipboard(from: urlString) { success, message in
                if success {
                    call.resolve(["success": true, "message": message])
                } else {
                    call.reject("COPY_FAILED", message, nil)
                }
            }
        } else {
            call.reject("INVALID_PARAMETERS", "URL parameter is missing", nil)
        }
    }

    @objc func savePhoto(_ call: CAPPluginCall) {
        if let urlString = call.getString("url"), let imageUrl = URL(string: urlString) {
            stashMedia.saveImageToPhotoLibrary(from: imageUrl) { success, message in
                if success {
                    call.resolve(["success": true, "message": message])
                } else {
                    call.reject("SAVE_FAILED", message, nil)
                }
            }
        } else {
            call.reject("INVALID_PARAMETERS", "URL parameter is missing", nil)
        }
    }

    @objc func shareImage(_ call: CAPPluginCall) {
        if let urlString = call.getString("url"), let title = call.getString("title") {
            stashMedia.shareImage(from: urlString, title: title) { success, message in
                if success {
                    call.resolve(["success": true, "message": message])
                } else {
                    call.reject("SHARE_FAILED", message, nil)
                }
            }
        } else {
            call.reject("INVALID_PARAMETERS", "URL parameter is missing", nil)
        }
    }
}
