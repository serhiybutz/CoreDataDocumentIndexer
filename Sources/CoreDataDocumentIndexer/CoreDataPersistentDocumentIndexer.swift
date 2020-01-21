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

/// A persistent (on-disk) Core Data-aware document indexer that is a wrapper around Search Kit's `SKIndex`.
///
/// - See Also: [Search Kit](https://developer.apple.com/documentation/coreservices/search_kit), [SKIndex](https://developer.apple.com/documentation/coreservices/skindex), [SKIndexCreateWithURL](https://developer.apple.com/documentation/coreservices/1446111-skindexcreatewithurl), [SKIndexOpenWithURL](https://developer.apple.com/documentation/coreservices/1449017-skindexopenwithurl)
open class CoreDataPersistentDocumentIndexer: CoreDataDocumentIndexer {
    // MARK: - Initialization
    
    /// Creates a new instance of a persistent (on-disk) Core Data-aware document indexer at the `url` or returns `nil` on failure.
    ///
    /// This document indexer is a wrapper around `SKIndex` (see more [SKIndex](https://developer.apple.com/documentation/coreservices/skindex)).
    ///
    /// - Parameters:
    ///   - url: The URL of the index location.
    ///   - persistentStoreCoordinator: The persistent store coordinator managing the document store.
    ///   - indexType: The type of the index.
    ///   - autoflushStrategy: The auto-flush policy.
    ///   - textAnalysisProperties: The text analysis properties.
    ///   - fragmentationStatePreserver: The fragmentation state provider.
    ///
    /// - See Also: [SKIndex](https://developer.apple.com/documentation/coreservices/skindex), [SKIndexCreateWithURL](https://developer.apple.com/documentation/coreservices/1446111-skindexcreatewithurl)
    public init?(creatingAtURL url: URL,
                 persistentStoreCoordinator: NSPersistentStoreCoordinator,
                 indexType: IndexType = .inverted,
                 autoflushStrategy: AutoflushStrategy = .none,
                 textAnalysisProperties: TextAnalysisProperties = .default,
                 fragmentationStatePreserver: FragmentationStatePreserver? = nil)
    {
        guard let documentIndexer = PersistentDocumentIndexer(
                creatingAtURL: url,
                indexType: indexType,
                autoflushStrategy: autoflushStrategy,
                textAnalysisProperties: textAnalysisProperties,
                fragmentationStatePreserver: fragmentationStatePreserver) else { return nil }
        super.init(documentIndexer: documentIndexer, persistentStoreCoordinator: persistentStoreCoordinator)
    }
    
    /// Opens an existing persistent (on-disk) Core Data-aware document indexer at the `url` or returns `nil` on failure.
    ///
    /// This document indexer is a wrapper around `SKIndex` (see more [SKIndex](https://developer.apple.com/documentation/coreservices/skindex).
    ///
    /// - Parameters:
    ///   - url: The URL of the index location.
    ///   - persistentStoreCoordinator: The persistent store coordinator managing the document store.
    ///   - autoflushStrategy: The auto-flush policy.
    ///   - fragmentationStatePreserver: The fragmentation state provider.
    ///
    /// - See Also: [SKIndex](https://developer.apple.com/documentation/coreservices/skindex), [SKIndexOpenWithURL](https://developer.apple.com/documentation/coreservices/1449017-skindexopenwithurl)
    public init?(openingAtURL url: URL,
                 persistentStoreCoordinator: NSPersistentStoreCoordinator,
                 autoflushStrategy: AutoflushStrategy = .none,
                 fragmentationStatePreserver: FragmentationStatePreserver? = nil)
    {
        guard let documentIndexer = PersistentDocumentIndexer(
                openingAtURL: url,
                autoflushStrategy: autoflushStrategy,
                fragmentationStatePreserver: fragmentationStatePreserver) else { return nil }
        super.init(documentIndexer: documentIndexer, persistentStoreCoordinator: persistentStoreCoordinator)
    }
}
