///
/// This file is part of the CoreDataDocumentIndexer package.
/// (c) Serge Bouts <sergebouts@gmail.com>
///
/// For the full copyright and license information, please view the LICENSE
/// file that was distributed with this source code.
///

import Foundation
import DocumentIndexer

public protocol CoreDataDocumentSearching {
    func makeSearch(for query: String,
                    options: SearchOptions,
                    hitsAtATime: Int,
                    maximumTime: TimeInterval) -> CoreDataSearch
    func search(for: String,
                options: SearchOptions,
                hitsAtATime: Int,
                maximumTime: TimeInterval,
                completion: (_ hits: [CoreDataSearchHit], _ hasMore: Bool, _ shouldStop: inout Bool) -> Void)
}
