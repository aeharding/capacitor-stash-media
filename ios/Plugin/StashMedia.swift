import Foundation

@objc public class StashMedia: NSObject {
    @objc public func echo(_ value: String) -> String {
        print(value)
        return value
    }
}
