import CoreData
import Foundation

class CoreDataStack {
    private static var _shared: CoreDataStack?

    static let shared = CoreDataStack()

    let persistentContainer: NSPersistentContainer

    var needsLoading: Bool = true

    private init() {
        let name = "Corpus"

        let model = NSManagedObjectModel()
        model.entities = [Document.entityDescription]

        persistentContainer = NSPersistentContainer(name: name, managedObjectModel: model)

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.url = URL(fileURLWithPath: "/dev/null")

        persistentContainer.persistentStoreDescriptions = [description]
    }

    func getPersistentContainer(completion: ((Result<NSPersistentContainer, Error>) -> Void)? = nil) {
        if needsLoading {
            var loadedCount = 0
            persistentContainer.loadPersistentStores { description, error in
                guard error == nil else {
                    completion?(.failure(error!))
                    return
                }
                loadedCount += 1
                if loadedCount >= self.persistentContainer.persistentStoreDescriptions.count {
                    self.needsLoading = false
                    completion?(.success(self.persistentContainer))
                }
            }
        } else {
            completion?(.success(persistentContainer))
        }
    }

    func wipeOut() {
        try? persistentContainer.persistentStoreCoordinator.destroyPersistentStore(
            at: URL(fileURLWithPath: "/dev/null"),
            ofType: NSInMemoryStoreType)
        needsLoading = true
    }
}

final class Document: NSManagedObject {
    @NSManaged var textContent: String

    static var managedObjectClass: NSManagedObject.Type { Self.self }

    static var entityDescription: NSEntityDescription = {
        let entity = NSEntityDescription()

        entity.managedObjectClassName = NSStringFromClass(managedObjectClass)
        entity.name = NSStringFromClass(managedObjectClass).components(separatedBy: ".").last!

        var properties = [NSPropertyDescription]()

        let textContentAttribute = NSAttributeDescription()
        textContentAttribute.name = "textContent"
        textContentAttribute.attributeType = .stringAttributeType
        textContentAttribute.isOptional = false
        properties.append(textContentAttribute)

        entity.properties = properties

        return entity
    }()
}
