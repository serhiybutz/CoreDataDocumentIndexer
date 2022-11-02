///
/// This file is part of the CoreDataDocumentIndexer package.
/// (c) Serhiy Butz <serhiybutz@gmail.com>
///
/// For the full copyright and license information, please view the LICENSE
/// file that was distributed with this source code.
///

import Foundation
import CoreData

public protocol CoreDataDocumentIndexing {
    func indexDocument(at documentURL: ManagedObjectDocumentURL, withText text: String) throws
    func removeDocument(at documentURL: ManagedObjectDocumentURL) throws
    func flush() throws
    var documentCount: Int { get }
    func setDocumentProperties(at documentURL: ManagedObjectDocumentURL, properties: [AnyHashable: Any])
    func getDocumentProperties(at documentURL: ManagedObjectDocumentURL) -> [AnyHashable: Any]?
}
