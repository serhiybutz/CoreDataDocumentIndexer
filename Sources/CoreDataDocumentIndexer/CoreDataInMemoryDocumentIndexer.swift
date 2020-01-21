///
/// This file is part of the CoreDataDocumentIndexer package.
/// (c) Serge Bouts <sergebouts@gmail.com>
///
/// For the full copyright and license information, please view the LICENSE
/// file that was distributed with this source code.
///

import Foundation
import CoreData
import DocumentIndexer

/// An in-memory Core Data-aware document indexer that is a wrapper around Search Kit's `SKIndex`.
///
/// - See Also: [Search Kit](https://developer.apple.com/documentation/coreservices/search_kit), [SKIndex](https://developer.apple.com/documentation/coreservices/skindex), [SKIndexCreateWithMutableData](https://developer.apple.com/documentation/coreservices/1447500-skindexcreatewithmutabledata)
open class CoreDataInMemoryDocumentIndexer: CoreDataDocumentIndexer {
    // MARK: - Initialization
    
    /// Creates an instance of an in-memory Core Data-aware document indexer, which is a wrapper around `SKIndex` (see more [SKIndex](https://developer.apple.com/documentation/coreservices/skindex), [SKIndexCreateWithMutableData](https://developer.apple.com/documentation/coreservices/1447500-skindexcreatewithmutabledata)) or returns `nil` on failure.
    ///
    /// - Parameters:
    ///   - indexType: The type of the index.
    ///   - autoflushStrategy: The auto-flush policy.
    ///   - textAnalysisProperties: The text analysis properties.
    ///   - fragmentationStatePreserver: The fragmentation state provider.
    ///
    /// - See Also: [SKIndex](https://developer.apple.com/documentation/coreservices/skindex), [SKIndexCreateWithMutableData](https://developer.apple.com/documentation/coreservices/1447500-skindexcreatewithmutabledata)
    public init?(persistentStoreCoordinator: NSPersistentStoreCoordinator,
                 indexType: IndexType = .inverted,
                 autoflushStrategy: AutoflushStrategy = .none,
                 textAnalysisProperties: TextAnalysisProperties = .default,
                 fragmentationStatePreserver: FragmentationStatePreserver? = nil)
    {
        guard let documentIndexer = InMemoryDocumentIndexer(
                indexType: indexType,
                autoflushStrategy: autoflushStrategy,
                textAnalysisProperties: textAnalysisProperties,
                fragmentationStatePreserver: fragmentationStatePreserver) else { return nil }
        super.init(documentIndexer: documentIndexer, persistentStoreCoordinator: persistentStoreCoordinator)
    }
}
