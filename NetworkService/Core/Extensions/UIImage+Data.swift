import UIKit.UIImage
public typealias Image = UIImage

extension Image {
    static func find(named name: String, inBundle bundle: Bundle) -> Image {
        return UIImage(named: name, in: bundle, compatibleWith: nil)!
    }

    func jpgData() -> Data? {
        return self.jpegData(compressionQuality: 1)
    }
}
