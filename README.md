<p align="center">
    <img src="https://img.shields.io/badge/Swift-4.2-orange" alt="Swift" />
    <img src="https://img.shields.io/badge/platform-osx-orange" alt="Platform" />
    <img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-orange" alt="SPM" />
    <a href="https://github.com/SergeBouts/CoreDataDocumentIndexer/blob/master/LICENSE">
        <img src="https://img.shields.io/badge/licence-MIT-orange" alt="License" />
    </a>
</p>

# Core Data Document Indexer

A *Core Data*-aware document indexer, a convenient *Swifty* wrapper for *Apple's Search Kit*.

*Search Kit* is *Apple*'s content indexing and searching solution which is widely used in *OS X*, for example in *System Preferences*, *Address Book*, *Help Viewer*, *Xcode*, *Mail* and even *Spotlight* is built on top of it. *Search Kit* features:

 - Fast indexing and asynchronous searching
- Google-like query syntax, including phrase-based, prefix/suffix/substring, and Boolean searching
- Text summarization
- Control over index characteristics, like minimum term length, stopwords, synonyms, and substitutions
- Flexible management of document hierarchies and indexes
- Unicode support
- Relevance ranking and statistical analysis of documents
- Thread-safe

Basically, **Core Data Document Indexer** builds up a layer around [Document Indexer](https://github.com/SergeBouts/DocumentIndexer) to provide *Core Data*-based document indexing and searching functionality, so that it can be used in a more *Swift*-friendly way. 

 ## Usage

Since **Core Data Document Indexer** borrows the capablities of the [Document Indexer](https://github.com/SergeBouts/DocumentIndexer) module, the usage illustrates only those aspects that differ. For more details refer to the documentation for [Document Indexer](https://github.com/SergeBouts/DocumentIndexer) itself.

### Creating an in-memory Core Data-aware document index

```swift
import CoreDataDocumentIndexer
...
let persistentStoreCoordinator: NSPersistentStoreCoordinator = ... // the document store's persistent store coordinator
// By default it creates an inverted index
let indexer = CoreDataInMemoryDocumentIndexer(persistentStoreCoordinator: persistentStoreCoordinator)
```
### Creating a persistent (on-disk) Core Data-aware document index

```swift
import CoreDataDocumentIndexer
...
let persistentStoreCoordinator: NSPersistentStoreCoordinator = ... // the document store's persistent store coordinator
let fileURL = "file:/INDEX_STORAGE_PATH"
// By default it creates an inverted index
let indexer = CoreDataPersistentDocumentIndexer(creatingAtURL: fileURL, persistentStoreCoordinator: persistentStoreCoordinator)
```


### Opening a persistent (on-disk) Core Data-aware document index

```swift
import CoreDataDocumentIndexer
...
let persistentStoreCoordinator: NSPersistentStoreCoordinator = ... // the document store's persistent store coordinator
let fileURL = "file:/INDEX_STORAGE_PATH"
let indexer = CoreDataPersistentDocumentIndexer(openingAtURL: fileURL,
                                               persistentStoreCoordinator: persistentStoreCoordinator)
```

### Indexing a Core Data-based document

```swift
import CoreDataDocumentIndexer
...
let managedObjectContext: NSManagedObjectContext = ... // the document store's managed object context
// Create a new document's managed object
let document = Document(context: managedObjectContext)
document.textContent = "Lorem ipsum ..."
try managedObjectContext.save()
// Index the new document
try indexer.indexDocument(forObjectID: ManagedObjectDocumentURL(document.objectID)!, withText: document.textContent)
// Commit all in-memory changes to backing store
try indexer.flush()
```
Note: for an external usage of a manage object id, like in this scenario, ensure it's *finalized* (i.e. the managed object is saved in the persistent store)! You can check for this condition with `isTemporaryId`.

### Searching

The **Core Data Document Indexer** provides two ways of searching: sequence-based search and completion-based search. 
A good practice is not to present all the search results at once, but rather provide them gradually, in blocks. Thus Search Kit's search is block-oriented.

**Core Data Document Indexer** allows specifying the number of hits in a block with the `hitsAtATime` parameter. Other than that you can also provide the search options and the maximum search time. 

The hits (or hit objects) are represented by the `CoreDataSearchHit` struct, which contains a managed object-restricted document URL object, `documentURL`, and a not normalized hit relevance score, `score`.

For query format description see [Search Kit - Queries](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/SearchKitConcepts/searchKit_concepts/searchKit_concepts.html#//apple_ref/doc/uid/TP40002844-BABIHICA).

#### Sequence-based search

```swift
import CoreDataDocumentIndexer
...
for hits in indexer.makeSearch(for: "foo bar") {
    hits.forEach { print("\($0.documentURL) \($0.score)") }
}
```

The `makeSearch` method returns a searcher sequence that provides search result hits in `hitsAtATime`-sized blocks of hit objects for the given `query` string. If you don't need the search results broken into blocks, the following one-liner demonstrates getting a search result's hits all at once:

```swift
let allHits = indexer.makeSearch(for: "foo bar").reduce([], +)
```

The searcher sequence that the `makeSearch` method returns does support laziness and if used in a 'lazy' context it performs the actual searching for the next hits block only on demand.

#### Completion-based search

```swift
import CoreDataDocumentIndexer
...
let managedObjectContext: NSManagedObjectContext = ... // the document store's managed object context
indexer.search(for: "foo bar") { hits, hasMore, shouldStop in
    let foundDocuments = try hits.map {
        (try managedObjectContext.existingObject(with: $0.documentURL.objectID) as! Document) // `Document` is a managed object representing a text document
    }
    foundDocuments.forEach { print($0.textContent) }
}
```
The search completion closure receives the results in the form of a hit object array. 

`Search Kit` is thread-safe and was developed with asynchronous work scenarios in mind, so wrapping the search query with a *DispatchQueue* block is a way to go.

## Installation

### Swift Package as dependency in Xcode 11+

1. Go to "File" -> "Swift Packages" -> "Add Package Dependency"
2. Paste Core Data Document Indexer repository URL into the search field:

`https://github.com/SergeBouts/CoreDataDocumentIndexer.git`

3. Click "Next"

4. Ensure that the "Rules" field is set to something like this: "Version: Up To Next Major: 1.0.0"

5. Click "Next" to finish

For more info, check out [here](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app).

## License

This project is licensed under the MIT license.

## Resources
- [Search Basics](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/SearchKitConcepts/searchKit_basics/searchKit_basics.html)
- [Search Kit Programming Guide](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/SearchKitConcepts/searchKit_intro/searchKit_intro.html)
- [Search Kit Concepts](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/SearchKitConcepts/searchKit_concepts/searchKit_concepts.html)
- [Search Kit Reference](https://developer.apple.com/documentation/coreservices/search_kit)