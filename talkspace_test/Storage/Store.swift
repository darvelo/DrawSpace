//
//  Store.swift
//  talkspace_test
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
            schemaVersion: 11,

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

        try! drawingsRealm.write { [weak self] in
            drawingsRealm.delete(persistedDrawings)
            self?.populate(drawings: jsonArray, into: drawingsRealm)
        }
        
        realm.refresh()
    }

    func merge(_ json: DrawingsNetworkLayer.FetchedDrawing, into drawing: Drawing) {
        guard let drawingsRealm = drawings.realm else {
            fatalError("Drawings realm unreachable")
        }
        
        guard let id = json["id"] as? Int else {
            assertionFailure("Drawing returned from server wasn't validated")
            return
        }

        try! drawingsRealm.write {
            drawing.id = id
            drawing.uploadState = Drawing.UploadState.success.rawValue
            mergeImageJson(json, into: drawing)
        }
        
        drawingsRealm.refresh()
    }
    
    private func mergeImageJson(_ drawingJson: Dictionary<String, Any>, into drawing: Drawing) {
        if let image = drawingJson["image"] as? Dictionary<String, Any> {
            let img = Image()
            
            if let id = image["id"] as? String {
                img.id = id
            }
            
            if let contentType = image["content_type"] as? String {
                img.contentType = contentType
            }
            
            if let resourceUrl = image["resource_url"] as? String {
                img.resourceUrl = resourceUrl
            }
            
            if let sizeUrls = image["size_urls"] as? Dictionary<String, String> {
                if let smallUrl = sizeUrls["small"] {
                    img.smallUrl = smallUrl
                }
                if let mediumUrl = sizeUrls["medium"] {
                    img.mediumUrl = mediumUrl
                }
                if let largeUrl = sizeUrls["large"] {
                    img.largeUrl = largeUrl
                }
            }
            
            drawing.image = img
        }
    }

    // MARK: Private Methods
    
    private func populate(drawings jsonArray: DrawingsNetworkLayer.FetchedDrawings, into drawingsRealm: Realm) {
        jsonArray.forEach { drawingJson in
            guard let id = drawingJson["id"] as? Int else {
                return
            }
            
            let drawing = Drawing()
            drawing.id = id
            drawing.uploadState = Drawing.UploadState.success.rawValue
            mergeImageJson(drawingJson, into: drawing)
            drawingsRealm.add(drawing)
        }
    }
}
