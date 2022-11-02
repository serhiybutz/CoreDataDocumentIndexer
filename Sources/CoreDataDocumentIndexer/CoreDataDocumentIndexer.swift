///
/// This file is part of the CoreDataDocumentIndexer package.
/// (c) Serhiy Butz <serhiybutz@gmail.com>
///
/// For the full copyright and license information, please view the LICENSE
/// file that was distributed with this source code.
///

import Foundation
import CoreData
import DocumentIndexer
import os.log

fileprivate let log = OSLog(subsystem: ModuleIdentifier,
                            category: "Core Data Document Indexer")

/// A base class for Core Data-aware document indexers that implement wrappers around Search Kit's `SKIndex`.
///
/// - See Also: [Search Kit](https://developer.apple.com/documentation/coreservices/search_kit), [SKIndex](https://developer.apple.com/documentation/coreservices/skindex)
open class CoreDataDocumentIndexer {
    // MARK: - State

    let persistentStoreCoordinator: NSPersistentStoreCoordinator
    let wrappee: DocumentIndexer

    // MARK: - Initialization

    init?(documentIndexer: DocumentIndexer, persistentStoreCoordinator: NSPersistentStoreCoordinator) {
        self.wrappee = documentIndexer
        self.persistentStoreCoordinator = persistentStoreCoordinator
    }
}

// MARK: - CoreDataDocumentSearching

extension CoreDataDocumentIndexer: CoreDataDocumentSearching {
    /// Creates a document searcher sequence that provides search result hits in `hitsAtATime`-sized blocks for the given `query` string.
    ///
    /// - Parameters:
    ///   - query: The search query string. For the query formatting see [SKSearchCreate](https://developer.apple.com/documentation/coreservices/1443079-sksearchcreate)
    ///   - options: The search options
    ///   - hitsAtATime: The number of hits to return at a time. If the search time has exceeded `maximumTime` seconds the returned search hits block may be incomplete. By default it is 256
    ///   - maximumTime: The maximum number of seconds to wait for the search results, whether or not `hitsAtATime` items have been found. Setting `maximumTime` to 0 tells the search to return quickly. By default it is 5 seconds
    /// - Returns: A document searcher sequence, an instance of `CoreDataSearch`.

    ///
    /// - See Also: [SKSearchCreate](https://developer.apple.com/documentation/coreservices/1443079-sksearchcreate), [SKSearchFindMatches](https://developer.apple.com/documentation/coreservices/1448608-sksearchfindmatches)
    public func makeSearch(for query: String,
                           options: SearchOptions = .default,
                           hitsAtATime: Int = 256,
                           maximumTime: TimeInterval = 5) -> CoreDataSearch
    {
        return CoreDataSearch(for: query,
                              options: options,
                              hitsAtATime: hitsAtATime,
                              maximumTime: maximumTime,
                              coreDataDocumentIndexer: self)
    }

    /// Searches the indexed documents for the given `query` string asynchronously calling the `completion` handler with the maximum of `hitsAtATime` hits at a time.
    ///
    /// - Parameters:
    ///   - query: The search query string. For the query formatting see [SKSearchCreate](https://developer.apple.com/documentation/coreservices/1443079-sksearchcreate)
    ///   - options: The search options
    ///   - hitsAtATime: The maximum number of hits to return at a time. If the search time has exceeded `maximumTime` seconds the returned search hits may be incomplete. By default it is 256
    ///   - maximumTime: The maximum number of seconds to wait for the search results, whether or not `hitsAtATime` items have been found. Setting `maximumTime` to 0 tells the search to return quickly. By default it is 5 seconds
    ///   - completion: The completion handler that is called asynchronously with the resulted `hits` array, the `hasMore` flag to indicate the search is still in progress, and the `shouldStop` flag reference for breaking the search
    ///   - hits: The search hits array
    ///   - hasMore: The flag indicating the search is still in progress
    ///   - shouldStop: The reference to the flag for breaking the search
    ///
    /// - See Also: [SKSearchCreate](https://developer.apple.com/documentation/coreservices/1443079-sksearchcreate), [SKSearchFindMatches](https://developer.apple.com/documentation/coreservices/1448608-sksearchfindmatches)
    public func search(for query: String,
                       options: SearchOptions = .default,
                       hitsAtATime: Int = 256,
                       maximumTime: TimeInterval = 5,
                       completion: ([CoreDataSearchHit], Bool, inout Bool) -> Void)
    {
        // 1. The `hitsAtATime` should be a reasonable value, because it determines the size of preallocated result arrays.
        // 2. Since `search` is designed for asynchronous work scenarios, the `completion` closure must be called *at least once*.

        guard hitsAtATime > 0 else {
            // return early
            var shouldStop = false
            completion([], false, &shouldStop)
            return
        }

        let search = makeSearch(for: query, hitsAtATime: hitsAtATime, maximumTime: maximumTime)

        var shouldStop: Bool = false
        let iterator = search.makeIterator()
        repeat {
            let hits = iterator.next()
            completion(hits ?? [], iterator.isInProgress, &shouldStop)
        } while iterator.isInProgress && !shouldStop
    }
}

// MARK: - CoreDataDocumentIndexing

extension CoreDataDocumentIndexer: CoreDataDocumentIndexing {
    /// Performs an operation of document (re)indexing by adding a managed object ID (safe to use across managed object contexts), and the associated document’s textual content `text`, to an index.
    ///
    /// - Parameters:
    ///     - objectID: The managed object ID that the (re)indexed document is associated with.
    ///     - text: The textual document content to index.
    /// - Throws:
    ///     - `DocumentIndexingError.failedToIndex(DocumentURL)`
    ///     in case of failure.
    ///
    /// - See Also: [SKIndexAddDocumentWithText](https://developer.apple.com/documentation/coreservices/1444518-skindexadddocumentwithtext)
    public func indexDocument(at documentURL: ManagedObjectDocumentURL, withText text: String) throws {
        try wrappee.indexDocument(at: documentURL, withText: text)
    }

    /// Performs an operation of removing of a document and its children, if any, from an index.
    ///
    /// - Parameter objectID: The managed object ID that the removed document is associated with.
    /// - Throws:
    ///     - `DocumentIndexingError.failedToRemove(DocumentURL)`
    ///     in case of failure.
    ///
    /// - See Also: [SKIndexRemoveDocument](https://developer.apple.com/documentation/coreservices/1444375-skindexremovedocument)
    public func removeDocument(at documentURL: ManagedObjectDocumentURL) throws {
        try wrappee.removeDocument(at: documentURL)
    }

    /// Commits all in-memory changes to backing store.
    ///
    /// - Throws:
    ///     - `DocumentIndexingError.failedToFlush`
    ///     in case of failure.
    ///
    /// - See Also: [SKIndexFlush](https://developer.apple.com/documentation/coreservices/1450667-skindexflush)
    public func flush() throws {
        try wrappee.flush()
    }

    /// Gets the total number of documents represented in an index.
    ///
    /// - See Also: [SKIndexGetDocumentCount](https://developer.apple.com/documentation/coreservices/1449093-skindexgetdocumentcount)
    public var documentCount: Int {
        wrappee.documentCount
    }

    /// Sets the custom (application-defined) properties of a document that the given managed object ID represents.
    ///
    /// - Parameters:
    ///     - objectID: The managed object ID.
    ///     - properties: A dictionary containing the properties to apply to the document URL object.
    ///
    /// - See Also: [SKIndexSetDocumentProperties](https://developer.apple.com/documentation/coreservices/1444576-skindexsetdocumentproperties)
    public func setDocumentProperties(at documentURL: ManagedObjectDocumentURL, properties: [AnyHashable : Any]) {
        wrappee.setDocumentProperties(at: documentURL, properties: properties)
    }

    /// Obtains the custom (application-defined) properties of an indexed document.
    ///
    /// - Parameter objectID: The managed object ID.
    /// - Returns: A dictionary containing the document’s properties, or `nil` if no custom properties have been set on the specified managed object ID.
    ///
    /// - See Also: [SKIndexCopyDocumentProperties](https://developer.apple.com/documentation/coreservices/1449500-skindexcopydocumentproperties)
    public func getDocumentProperties(at documentURL: ManagedObjectDocumentURL) -> [AnyHashable : Any]? {
        return wrappee.getDocumentProperties(at: documentURL)
    }
}

// MARK: - DocumentIndexingExtra

extension CoreDataDocumentIndexer: DocumentIndexingExtra {
    /// If the fragmentation state preservation is maintained by the user it tells how many uncompacted documents are tracked at the moment of calling, or returns `nil` otherwise.
    ///
    /// To maintain fragmentation state preservation, the user has to implement protocol `FragmentationStatePreserver` and provide an instance of the preserver at the time of creating (and for a persistent (on-disk) indexer - further - opening as well) of the document indexer. The preserver's only responsibility is to persist the provided piece of information in any way, by being able of storing and then restoring it.
    public var uncompactedDocuments: Int? {
        wrappee.uncompactedDocuments
    }

    /// The highest-numbered document ID in an index.
    ///
    /// - See Also: [SKIndexGetMaximumDocumentID](https://developer.apple.com/documentation/coreservices/1444628-skindexgetmaximumdocumentid)
    public var maximumDocumentID: Int {
        wrappee.maximumDocumentID
    }

    /// Compacts the search index to reduce fragmentation and commits changes to backing store.
    ///
    /// - Warning: Compacting can take a considerable amount of time, so it's not recommended to call this method on the main thread.
    /// - See Also: [SKIndexCompact](https://developer.apple.com/documentation/coreservices/1443628-skindexcompact)
    public func compact() throws {
        try wrappee.compact()
    }
}
