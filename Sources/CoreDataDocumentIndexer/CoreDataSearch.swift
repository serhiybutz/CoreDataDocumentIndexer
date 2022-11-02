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
                            category: "Core Data Search")

public final class CoreDataSearch: Sequence {
    // MARK: - Types

    final public class Iterator: IteratorProtocol {
        // MARK: - State

        let wrappee: Search.Iterator
        let coreDataSearch: CoreDataSearch

        public var isInProgress: Bool { wrappee.isInProgress }

        // MARK: - Initialization

        init(wrappee: Search.Iterator, coreDataSearch: CoreDataSearch) {
            self.wrappee = wrappee
            self.coreDataSearch = coreDataSearch
        }

        // MARK: - IteratorProtocol

        public func next() -> [CoreDataSearchHit]? {
            guard isInProgress else { return nil }
            return wrappee.next().map { hits in
                hits.compactMap {
                    guard let documentURL = ManagedObjectDocumentURL.create($0.documentURL.wrappee, persistentStoreCoordinator: coreDataSearch.coreDataDocumentIndexer.persistentStoreCoordinator)
                    else {
                        os_log("Failed to get managed object document URL for \"%s\"", log: log, type: .error, "\($0.documentURL.asURL.absoluteString)")
                        return nil
                    }
                    return CoreDataSearchHit(documentURL: documentURL, score: $0.score)
                }
            }
        }
    }

    // MARK: - State

    let query: String
    let options: SearchOptions
    let hitsAtATime: Int
    let maximumTime: TimeInterval
    let coreDataDocumentIndexer: CoreDataDocumentIndexer
    let wrappee: Search

    // MARK: - Initialization

    init(for query: String,
         options: SearchOptions,
         hitsAtATime: Int,
         maximumTime: TimeInterval,
         coreDataDocumentIndexer: CoreDataDocumentIndexer)
    {
        self.query = query
        self.options = options
        self.hitsAtATime = hitsAtATime
        self.maximumTime = maximumTime
        self.coreDataDocumentIndexer = coreDataDocumentIndexer
        self.wrappee = coreDataDocumentIndexer.wrappee.makeSearch(for: query, options: options, hitsAtATime: hitsAtATime, maximumTime: maximumTime)
    }

    // MARK: - Sequance

    public func makeIterator() -> Iterator {
        return Iterator(wrappee: wrappee.makeIterator(), coreDataSearch: self)
    }
}
