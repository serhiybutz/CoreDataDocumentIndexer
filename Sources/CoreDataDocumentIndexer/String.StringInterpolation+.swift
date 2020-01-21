///
/// This file is part of the CoreDataDocumentIndexer package.
/// (c) Serge Bouts <sergebouts@gmail.com>
///
/// For the full copyright and license information, please view the LICENSE
/// file that was distributed with this source code.
///

import Foundation

extension String.StringInterpolation {
    mutating func appendInterpolation<T>(_ value: Optional<T>) {
        if let val = value {
            appendLiteral("\(val)")
        } else {
            appendLiteral("nil")
        }
    }
}
