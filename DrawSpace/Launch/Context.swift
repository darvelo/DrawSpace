//
//  Context.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import RealmSwift
import Reachability

typealias RootCoordinatorFactory = () -> RootCoordinator
typealias DrawingsCoordinatorFactory = () -> DrawingsCoordinator
typealias DrawingEditorCoordinatorFactory = (_ drawing: Drawing?) -> DrawingEditorCoordinator

class Context {
    
    // MARK: Private Properties
    
    private let drawingsNetworkLayer: DrawingsNetworkLayer
    private let reachability: Reachability
    private let store: Store
    
    // MARK: Initialization
    
    init(drawingsNetworkLayer: DrawingsNetworkLayer,
         reachability: Reachability,
         store: Store
    ) {
        self.drawingsNetworkLayer = drawingsNetworkLayer
        self.reachability = reachability
        self.store = store
    }
    
    // MARK: Factories
    
    lazy var rootCoordinatorFactory: RootCoordinatorFactory = {
        let coordinator = RootCoordinator(store: self.store,
                                          drawingsNetworkLayer: self.drawingsNetworkLayer,
                                          drawingsCoordinatorFactory: self.drawingsCoordinatorFactory)
        return coordinator
    }
    
    private lazy var drawingsCoordinatorFactory: DrawingsCoordinatorFactory = {
        let coordinator = DrawingsCoordinator(store: self.store,
                                           reachability: self.reachability,
                                           drawingsNetworkLayer: self.drawingsNetworkLayer,
                                           drawingEditorCoordinatorFactory: self.drawingEditorCoordinatorFactory)
        return coordinator
    }
    
    private lazy var drawingEditorCoordinatorFactory: DrawingEditorCoordinatorFactory = { (_ drawing: Drawing?) in
        let coordinator = DrawingEditorCoordinator(store: self.store,
                                                   drawing: drawing)
        return coordinator
    }
}
