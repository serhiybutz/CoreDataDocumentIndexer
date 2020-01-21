import XCTest
@testable import CoreDataDocumentIndexer
import CoreData

final class CoreDataDocumentIndexerTests: XCTestCase {
    var textContent1 = "foo bar"
    var textContent2 = "baz bar"
    var textContent3 = "baz foo"

    var moid1: NSManagedObjectID?
    var moid2: NSManagedObjectID?
    var moid3: NSManagedObjectID?

    // MARK: - State

    var sut: CoreDataDocumentIndexer!
    var persistentContainer: NSPersistentContainer?

    // MARK: - Life Cycle

    override func setUp() {
        let loadExpectation = expectation(description: "Persistent container stores loading")
        CoreDataStack.shared.getPersistentContainer { result in
            switch result {
            case .success(let persistentContainer):
                self.persistentContainer = persistentContainer
                loadExpectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [loadExpectation], timeout: 1)
    }

    override func tearDown() {
        CoreDataStack.shared.wipeOut()
        persistentContainer = nil // next time it's gonna be reloaded

        sut = nil
        moid1 = nil
        moid2 = nil
        moid3 = nil
    }

    // MARK: - Helpers

    @discardableResult
    func addDocument(_ textContent: String) throws -> NSManagedObjectID {
        let document = Document(context: persistentContainer!.viewContext)
        document.textContent = textContent
        try persistentContainer!.viewContext.save()
        precondition(!document.objectID.isTemporaryID) // assert a managed object id is finalized
        try sut!.indexDocument(at: ManagedObjectDocumentURL(document.objectID)!, withText: document.textContent)
        return document.objectID
    }

    func deleteDocument(for moid: NSManagedObjectID) throws {
        let document = try persistentContainer!.viewContext.existingObject(with: moid) as! Document
        persistentContainer!.viewContext.delete(document)
        try sut!.removeDocument(at: ManagedObjectDocumentURL(moid)!)
    }

    func populate() throws {
        guard let _ = sut else {
            XCTFail()
            return
        }
        moid1 = try addDocument(textContent1)
        moid2 = try addDocument(textContent2)
        moid3 = try addDocument(textContent3)
    }

    func assertPositiveResultUsingSequenceSearch(line: UInt = #line) throws {
        let resultHits = sut!.makeSearch(for: "bar").reduce([], +)

        let foundDocuments = try resultHits.map {
            (try persistentContainer!.viewContext.existingObject(with: $0.documentURL.managedObjectID) as! Document)
        }

        let expectedResult = [textContent1, textContent2]
        XCTAssertEqual(foundDocuments.map { $0.textContent }.sorted(), expectedResult.sorted(), line: line)
    }

    func assertRemoveDocumentUsingSequenceSearch(line: UInt = #line) throws {
        try deleteDocument(for: moid1!)

        let resultHits = sut!.makeSearch(for: "bar").reduce([], +)

        let foundTextContexts = resultHits.map {
            (try! persistentContainer!.viewContext.existingObject(with: $0.documentURL.managedObjectID) as! Document).textContent
        }

        let expectedResult = [textContent2]
        XCTAssertEqual(foundTextContexts.sorted(), expectedResult.sorted(), line: line)
    }

    func assertPositiveResultUsingCompletionSearch(line: UInt = #line) throws {
        var resultHits: [CoreDataSearchHit] = []

        sut!.search(for: "bar") { hits, hasMore, shouldStop in
            resultHits += hits
        }

        let foundDocuments = try resultHits.map {
            (try persistentContainer!.viewContext.existingObject(with: $0.documentURL.managedObjectID) as! Document)
        }

        let expectedResult = [textContent1, textContent2]
        XCTAssertEqual(foundDocuments.map { $0.textContent }.sorted(), expectedResult.sorted(), line: line)
    }

    func assertRemoveDocumentUsingCompletionSearch(line: UInt = #line) throws {
        try deleteDocument(for: moid1!)

        var resultHits: [CoreDataSearchHit] = []
        sut!.search(for: "bar") { hits, hasMore, shouldStop in
            resultHits += hits
        }

        let foundTextContexts = resultHits.map {
            (try! persistentContainer!.viewContext.existingObject(with: $0.documentURL.managedObjectID) as! Document).textContent
        }

        let expectedResult = [textContent2]
        XCTAssertEqual(foundTextContexts.sorted(), expectedResult.sorted(), line: line)
    }

    // MARK: - Tests

    func test_CoreDataInMemoryDocumentIndexerUsingSequenceSearch() throws {
        sut = CoreDataInMemoryDocumentIndexer(persistentStoreCoordinator: persistentContainer!.persistentStoreCoordinator,
                                              autoflushStrategy: .beforeEachSearch)
        XCTAssertNotNil(sut)

        try populate()
        try assertPositiveResultUsingSequenceSearch()
        try assertRemoveDocumentUsingSequenceSearch()
    }

    func test_CoreDataPersistentDocumentIndexerUsingSequenceSearch() throws {
        let fileURL = generateTmpFileURL()
        sut = CoreDataPersistentDocumentIndexer(creatingAtURL: fileURL,
                                                persistentStoreCoordinator: persistentContainer!.persistentStoreCoordinator,
                                                autoflushStrategy: .beforeEachSearch)
        XCTAssertNotNil(sut)

        try populate()

        sut = nil

        sut = CoreDataPersistentDocumentIndexer(openingAtURL: fileURL,
                                                persistentStoreCoordinator: persistentContainer!.persistentStoreCoordinator,
                                                autoflushStrategy: .beforeEachSearch)
        XCTAssertNotNil(sut)

        try assertPositiveResultUsingSequenceSearch()
        try assertRemoveDocumentUsingSequenceSearch()
    }

    func test_CoreDataInMemoryDocumentIndexerUsingCompletionSearch() throws {
        sut = CoreDataInMemoryDocumentIndexer(persistentStoreCoordinator: persistentContainer!.persistentStoreCoordinator,
                                              autoflushStrategy: .beforeEachSearch)
        XCTAssertNotNil(sut)

        try populate()
        try assertPositiveResultUsingCompletionSearch()
        try assertRemoveDocumentUsingCompletionSearch()
    }

    func test_CoreDataPersistentDocumentIndexerUsingCompletionSearch() throws {
        let fileURL = generateTmpFileURL()
        sut = CoreDataPersistentDocumentIndexer(creatingAtURL: fileURL,
                                                persistentStoreCoordinator: persistentContainer!.persistentStoreCoordinator,
                                                autoflushStrategy: .beforeEachSearch)
        XCTAssertNotNil(sut)

        try populate()

        sut = nil

        sut = CoreDataPersistentDocumentIndexer(openingAtURL: fileURL,
                                                persistentStoreCoordinator: persistentContainer!.persistentStoreCoordinator,
                                                autoflushStrategy: .beforeEachSearch)
        XCTAssertNotNil(sut)

        try assertPositiveResultUsingCompletionSearch()
        try assertRemoveDocumentUsingCompletionSearch()
    }
}
