import Foundation
extension NetworkLayer {
    func cacheOrPurgeJSON(object: Any?,
                          path: String,
                          cacheName: String?,
                          cachingType: CachingType) throws {
        guard let destinationURL = try? self.destinationURL(for: path, cacheName: cacheName) else {
            fatalError("Couldn't get destination URL for path: \(path) and cacheName: \(String(describing: cacheName))")
        }

        if let unwrappedObject = object {
            switch cachingType {
            case .memory:
                self.cache.setObject(unwrappedObject as AnyObject,
                                     forKey: destinationURL.absoluteString as AnyObject)
            case .memoryAndFile:

                let convertedData = try JSONSerialization.data(
                    withJSONObject: unwrappedObject,
                    options: []
                )
                _ = try convertedData.write(to: destinationURL, options: [.atomic])
                self.cache.setObject(unwrappedObject as AnyObject,
                                     forKey: destinationURL.absoluteString as AnyObject)
            case .none:
                break
            }
        } else {
            self.cache.removeObject(forKey: destinationURL.absoluteString as AnyObject)
        }
    }

    func cacheOrPurgeImage(data: Data?,
                           path: String,
                           cacheName: String?,
                           cachingType: CachingType) -> Image? {
        guard let destinationURL = try? self.destinationURL(for: path, cacheName: cacheName) else {
            fatalError("Couldn't get destination URL for path: \(path) and cacheName: \(String(describing: cacheName))")
        }

        var image: Image?
        if let data = data, let nonOptionalImage = Image(data: data), data.count > 0 {
            switch cachingType {
            case .memory:
                self.cache.setObject(nonOptionalImage, forKey: destinationURL.absoluteString as AnyObject)
            case .memoryAndFile:
                _ = try? data.write(to: destinationURL, options: [.atomic])
                self.cache.setObject(nonOptionalImage, forKey: destinationURL.absoluteString as AnyObject)
            case .none:
                break
            }
            image = nonOptionalImage
        } else {
            self.cache.removeObject(forKey: destinationURL.absoluteString as AnyObject)
        }
        return image
    }

    func cacheOrPurgeData(data: Data?,
                          path: String,
                          cacheName: String?,
                          cachingType: CachingType) {
        guard let destinationURL = try? self.destinationURL(for: path, cacheName: cacheName) else {
            fatalError("Couldn't get destination URL for path: \(path) and cacheName: \(String(describing: cacheName))")
        }

        if let returnedData = data, returnedData.count > 0 {
            switch cachingType {
            case .memory:
                self.cache.setObject(returnedData as AnyObject, forKey: destinationURL.absoluteString as AnyObject)
            case .memoryAndFile:
                _ = try? returnedData.write(to: destinationURL, options: [.atomic])
                self.cache.setObject(returnedData as AnyObject, forKey: destinationURL.absoluteString as AnyObject)
            case .none:
                break
            }
        } else {
            self.cache.removeObject(forKey: destinationURL.absoluteString as AnyObject)
        }
    }
}
