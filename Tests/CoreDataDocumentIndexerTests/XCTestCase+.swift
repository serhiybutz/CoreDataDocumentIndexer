import XCTest

extension XCTestCase {
    func generateTmpFileURL() -> URL {
        let fileManager = FileManager.default
        let tmpDirectory = fileManager.temporaryDirectory
        let fileName = UUID().uuidString
        let fileURL = tmpDirectory.appendingPathComponent(fileName)
        addTeardownBlock {
            do {
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                    XCTAssertFalse(fileManager.fileExists(atPath: fileURL.path))
                }
            } catch {
                XCTFail("Error while deleting temporary file: \(error)")
            }
        }
        return fileURL
    }

    func fileSize(_ filePath: String) -> UInt64? {
        var fileSize : UInt64?
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: filePath)
            fileSize = (attrs[FileAttributeKey.size] as! UInt64)
        } catch {
            return nil
        }
        return fileSize!
    }
}
