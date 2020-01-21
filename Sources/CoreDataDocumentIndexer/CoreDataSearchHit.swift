///
/// This file is part of the CoreDataDocumentIndexer package.
/// (c) Serge Bouts <sergebouts@gmail.com>
///
/// For the full copyright and license information, please view the LICENSE
/// file that was distributed with this source code.
///

import CoreData
import Foundation

/// A search hit.
public struct CoreDataSearchHit {
    /// A managed object-restricted document URL object.
    public let documentURL: ManagedObjectDocumentURL
    /// A relevance score (not normilized).
    public let score: Float
    
    public init(documentURL: ManagedObjectDocumentURL, score: Float) {
        self.documentURL = documentURL
        self.score = score
    }
}
