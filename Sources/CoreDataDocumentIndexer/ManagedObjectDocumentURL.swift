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

/// A Core Data managed object-restricted wrapper around Search Kit's document URL object.
///
/// - See Also: [SKDocument](https://developer.apple.com/documentation/coreservices/skdocument)
public struct ManagedObjectDocumentURL: DocumentURLProtocol {
    // MARK: - State

    public let wrappee: SKDocument

    /// A managed object id that this document URL object represents.
    public let managedObjectID: NSManagedObjectID

    // MARK: - Initialization

    /// Create an instance of `ManagedObjectDocumentURL` from managed object id.
    /// - Parameter objectID: The document's managed object id.
    public init?(_ objectID: NSManagedObjectID) {
        guard !objectID.isTemporaryID else { return nil } // managed object id must be finalized
        self.managedObjectID = objectID
        guard let documentURLObject = SKDocumentCreateWithURL(objectID.uriRepresentation() as CFURL)?.takeRetainedValue() else { return nil }
        self.wrappee = documentURLObject
    }

    private init?(documentURLObject: SKDocument, objectID: NSManagedObjectID) {
        guard !objectID.isTemporaryID else { return nil } // managed object id must be finalized
        self.wrappee = documentURLObject
        self.managedObjectID = objectID
    }

    /// Create an instance of `ManagedObjectDocumentURL` from document URL object.
    ///
    /// - Parameters:
    ///   - documentURLObject: The managed object document URL object.
    ///   - persistentStoreCoordinator: The document store's persistent store coordinator.
    /// - Returns: An instance of `ManagedObjectDocumentURL` or `nil` if failed.
    public static func create(_ documentURLObject: SKDocument, persistentStoreCoordinator: NSPersistentStoreCoordinator) -> ManagedObjectDocumentURL? {
        let url = SKDocumentCopyURL(documentURLObject)!.takeRetainedValue() as URL
        guard let objectID = persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) else { return nil }
        return ManagedObjectDocumentURL(documentURLObject: documentURLObject, objectID: objectID)
    }

    /// Create an instance of `ManagedObjectDocumentURL` from URL.
    ///
    /// - Parameters:
    ///   - url: The managed object document URL.
    ///   - persistentStoreCoordinator: The document store's persistent store coordinator.
    /// - Returns: An instance of `ManagedObjectDocumentURL` or `nil` if failed.
    public static func create(_ url: URL, persistentStoreCoordinator: NSPersistentStoreCoordinator) -> ManagedObjectDocumentURL? {
        guard let documentURLObject = SKDocumentCreateWithURL(url as CFURL)?.takeRetainedValue() else { return nil }
        guard let objectID = persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) else { return nil }
        return ManagedObjectDocumentURL(documentURLObject: documentURLObject, objectID: objectID)
    }
}

// MARK: - Equatable, Comparable, Identifiable, Hashable

extension ManagedObjectDocumentURL: Equatable, Identifiable, Hashable {
    public static func == (lhs: ManagedObjectDocumentURL, rhs: ManagedObjectDocumentURL) -> Bool { lhs.id == rhs.id }
    public static func < (lhs: ManagedObjectDocumentURL, rhs: ManagedObjectDocumentURL) -> Bool { lhs.asURL.absoluteString < rhs.asURL.absoluteString }
    public var id: String { asURL.absoluteString }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
