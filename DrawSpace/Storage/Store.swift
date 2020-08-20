//
//  Store.swift
//  DrawSpace
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import Foundation
import RealmSwift

protocol Store {
    var realm: Realm { get }
    var drawings: Results<Drawing> { get }
    var localDrawings: Results<Drawing> { get }

    func inTransaction(block: ((_ drawingsRealm: Realm) -> Void))
    func create(drawing: Drawing)
    func deleteAllDrawings()
    func delete(drawing: Drawing)
    func setUploadState(for: Drawing, to: Drawing.UploadState)
    func sync(drawings: DrawingsNetworkLayer.FetchedDrawings)
    func merge(_ json: DrawingsNetworkLayer.FetchedDrawing, into: Drawing)
}

class LocalStore: Store {

    // MARK: Private Properties

    private let iso8601Formatter = ISO8601DateFormatter()

    // MARK: Public Properties

    let realm: Realm
    let drawingsSortDescriptors: [SortDescriptor] = [SortDescriptor(keyPath: "uploadState", ascending: true),
                                                     SortDescriptor(keyPath: "id", ascending: false)]
    
    private(set) lazy var drawings = realm.objects(Drawing.self).sorted(by: drawingsSortDescriptors)
    private(set) lazy var localDrawings = realm.objects(Drawing.self).filter("uploadState = 'failed'")

    // MARK: Initialization
    
    init() {
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 14,

            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 1) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
            })

        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        realm = try! Realm()
    }
    
    // MARK: Public Methods

    func inTransaction(block: ((_ drawingsRealm: Realm) -> Void)) {
        guard let drawingsRealm = drawings.realm else {
            fatalError("Drawings realm unreachable")
        }

        try! drawingsRealm.write {
            block(drawingsRealm)
        }

        drawingsRealm.refresh()
    }

    func create(drawing: Drawing) {
        inTransaction { drawingsRealm in drawingsRealm.add(drawing) }
    }

    func deleteAllDrawings() {
        inTransaction { drawingsRealm in drawingsRealm.deleteAll() }
    }

    func delete(drawing: Drawing) {
        inTransaction { drawingsRealm in drawingsRealm.delete(drawing) }
    }

    func setUploadState(for drawing: Drawing, to state: Drawing.UploadState) {
        inTransaction { drawingsRealm in drawing.uploadState = state.rawValue }
    }
    
    func sync(drawings jsonArray: DrawingsNetworkLayer.FetchedDrawings) {
        guard let drawingsRealm = drawings.realm else {
            fatalError("Drawings realm unreachable")
        }
        
        // Remove drawings already persisted to the server to get the latest ones.
        // We could get fancy and merge the results, but this is simpler.
        let persistedDrawings = drawingsRealm.objects(Drawing.self).filter("uploadState = 'success'")

        try! drawingsRealm.write {
            drawingsRealm.delete(persistedDrawings)
        }

        populate(drawings: jsonArray)
        
        realm.refresh()
    }

    func merge(_ json: DrawingsNetworkLayer.FetchedDrawing, into drawing: Drawing) {
        guard let drawingsRealm = drawings.realm else {
            fatalError("Drawings realm unreachable")
        }
        
        guard let id = json["id"] as? Int,
            let createdAtString = json["createdAt"] as? String,
            let drawingDurationSeconds = json["drawingDurationSeconds"] as? Double,
            let width = json["width"] as? Double,
            let height = json["height"] as? Double,
            let steps = json["steps"] as? Array<[String: Any]> else {
                assertionFailure("Drawing returned from server wasn't validated")
                return
        }

        try! drawingsRealm.write {
            let stepList = List<DrawStep>()
            stepList.append(objectsIn: steps.compactMap { DrawStep.fromJSON($0) })

            drawing.id = id
            drawing.createdAt = iso8601Formatter.date(from: createdAtString) ?? Date()
            drawing.drawingDurationSeconds = drawingDurationSeconds
            drawing.width = width
            drawing.height = height
            drawing.steps = stepList
            drawing.uploadState = Drawing.UploadState.success.rawValue
            mergeImageJson(json, into: drawing)
        }
        
        drawingsRealm.refresh()
    }

    // MARK: Private Methods

    private func mergeImageJson(_ drawingJson: Dictionary<String, Any>, into drawing: Drawing) {
        guard let imageId = drawingJson["imageId"] as? String,
            let resourceUrl = drawingJson["imageUrl"] as? String else {
                return
        }

        let img = Image()
        img.id = imageId
        // TODO: This URL should be passed straight through from the server, not modified on the client.
        //       The reason I did this is because the server can be a local Docker container or a real server,
        //       and a local Docker container may not know the right baseUrl needed by the client, since that
        //       depends on the particular `docker-compose.yml` configuration.
        img.resourceUrl = "\(DrawingsNetworkLayer.baseUrl)\(resourceUrl)"

        drawing.image = img
    }

    private func populate(drawings jsonArray: DrawingsNetworkLayer.FetchedDrawings) {
        jsonArray.forEach { drawingJson in
            let drawing = Drawing()
            merge(drawingJson, into: drawing)
            drawing.uploadState = Drawing.UploadState.success.rawValue
            inTransaction { drawingsRealm in drawingsRealm.add(drawing) }
        }
    }
}
