//
//  RootCoordinator.swift
//  DrawSpace
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit

class RootCoordinator: Coordinator, DrawingsCoordinatorDelegate {
    
    // MARK: Private Properties
    
    private let store: Store
    private let drawingsNetworkLayer: DrawingsNetworkLayer
    
    private let drawingsCoordinatorFactory: DrawingsCoordinatorFactory
    private var drawingsCoordinator: DrawingsCoordinator?

    private let activityIndicatorViewController = ActivityIndicatorViewController()
    private let navigationViewController = UINavigationController(nibName: nil, bundle: nil)
    
    // MARK: Public Properties
    
    lazy var rootViewController: UIViewController = navigationViewController

    // MARK: Initialization
    
    init(store: Store,
         drawingsNetworkLayer: DrawingsNetworkLayer,
         drawingsCoordinatorFactory: @escaping DrawingsCoordinatorFactory
        
    ) {
        self.store = store
        self.drawingsNetworkLayer = drawingsNetworkLayer
        self.drawingsCoordinatorFactory = drawingsCoordinatorFactory
    }
    
    // MARK: Coordinator
    
    func start() {
        navigationViewController.setViewControllers([activityIndicatorViewController], animated: false)
        activityIndicatorViewController.title = "Loading..."
        
        syncDrawings { [weak self] in
            self?.presentDrawings()
        }
    }
    
    // MARK: DrawingsCoordinatorDelegate
    
    func handleDrawingsCoordinatorEvent(_ event: DrawingsCoordinatorEvent) {
        switch event {
        case .sync(let completion):
            syncDrawings(completion: completion)
        }
    }
    
    // MARK: Private Methods
    
    private func syncDrawings(completion: (() -> Void)?) {
        // TODO: Create a Service/Controller pattern to do this kind of fetch & store work.
        //       Then have this call into the Service Controller to ask for the stored results.
        drawingsNetworkLayer.fetchDrawings { [weak self] result in
            switch result {
            case .success(let jsonArray):
                self?.store.sync(drawings: jsonArray)
            case .failure(let err):
                print("Network error while syncing with server: \(err)")
            }
            
            completion?()
        }
    }
    
    private func presentDrawings() {
        let coordinator = drawingsCoordinatorFactory()
        self.drawingsCoordinator = coordinator
        coordinator.delegate = self
        coordinator.start()
        navigationViewController.setViewControllers([coordinator.rootViewController], animated: false)
    }
    
}
