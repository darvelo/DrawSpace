//
//  DrawingsCoordinator.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit
import RealmSwift
import Reachability

enum DrawingsCoordinatorEvent {
    case sync(completion: () -> Void)
}

protocol DrawingsCoordinatorDelegate: class {
    func handleDrawingsCoordinatorEvent(_: DrawingsCoordinatorEvent)
}

class DrawingsCoordinator: Coordinator, DrawingsViewControllerDelegate, DrawingEditorCoordinatorDelegate {
    
    // MARK: Private Properties
    
    private let store: Store
    private let reachability: Reachability
    private let drawingsNetworkLayer: DrawingsNetworkLayer
    private var realmNotificationToken: NotificationToken?

    private lazy var drawingsViewController: DrawingsViewController = {
        let vc = DrawingsViewController(drawings: store.drawings)
        vc.delegate = self
        return vc
    }()
    
    private let drawingEditorCoordinatorFactory: DrawingEditorCoordinatorFactory
    private var drawingEditorCoordinator: DrawingEditorCoordinator?

    // MARK: Public Properties
    
    weak var delegate: DrawingsCoordinatorDelegate?
    lazy var rootViewController: UIViewController = drawingsViewController
    
    // MARK: Initialization
    
    init(store: Store,
         reachability: Reachability,
         drawingsNetworkLayer: DrawingsNetworkLayer,
         drawingEditorCoordinatorFactory: @escaping DrawingEditorCoordinatorFactory) {
        self.store = store
        self.reachability = reachability
        self.drawingsNetworkLayer = drawingsNetworkLayer
        self.drawingEditorCoordinatorFactory = drawingEditorCoordinatorFactory
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        realmNotificationToken?.invalidate()
    }
    
    // MARK: Coordinator

    func start() {
        // Observe network reachability.
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(notification:)), name: .reachabilityChanged, object: reachability)

        // Observe Results Notifications
        realmNotificationToken = store.drawings.observe { [weak self] (changes: RealmCollectionChange<Results<Drawing>>) in
            self?.drawingsViewController.update(changes)
        }
    }
    
    // MARK: DrawingEditorCoordinatorDelegate
    
    func handleDrawingEditorCoordinatorEvent(_ event: DrawingEditorCoordinatorEvent) {
        // TODO: We shouldn't assume we're in a UINavigationController.
        rootViewController.navigationController?.popViewController(animated: true)
        drawingEditorCoordinator = nil

        var handler: (() -> Void)? = nil

        switch event {
        case .cancel:
            break
        case let .create(drawing, canvasSize, duration, steps, image):
            handler = { [weak self] in
                self?.createDrawing(drawing,
                                    canvasSize: canvasSize,
                                    duration: duration,
                                    steps: steps,
                                    image: image)
            }
        case let .update(drawing, canvasSize, duration, steps, image):
            handler = { [weak self] in
                self?.updateDrawing(drawing,
                                    canvasSize: canvasSize,
                                    duration: duration,
                                    steps: steps,
                                    image: image)
            }
        }

        guard let eventHandler = handler else { return }

        // Create the drawing once the navigation controller puts the rootViewController's view
        // into the view hierarchy. This ensures the tableView won't try to update offscreen and give a warning.
        // Solution from: https://stackoverflow.com/a/50532891/544252
        //
        // TODO: We shouldn't assume we're in a UINavigationController.
        rootViewController.navigationController?.transitionCoordinator?.animate(alongsideTransition: nil) { [weak self] _ in
            eventHandler()
        }
    }
    
    // MARK: DrawingsViewControllerDelegate
    
    func createDrawingTapped() {
        presentDrawing(drawing: nil)
    }
    
    func clearDrawingsTapped() {
        guard let realm = store.drawings.realm else {
            fatalError("Unable to get drawings realm")
        }
    
        try! realm.write {
            realm.deleteAll()
        }
    }

    func syncDrawings(completion: @escaping () -> Void) {
        delegate?.handleDrawingsCoordinatorEvent(.sync(completion: completion))
    }
    
    func drawingTapped(_ drawing: Drawing) {
        if Drawing.UploadState(rawValue: drawing.uploadState) != .success {
            persist(drawing: drawing)
        }

        presentDrawing(drawing: drawing)
    }
    
    // MARK: Private Methods
    
    private func storeImage(image: UIImage?) -> URL? {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first

        guard let image = image,
            let imagePath = documentsPath?.appendingPathComponent("\(UUID()).jpg"),
            let data = image.jpegData(compressionQuality: 0.0) else {
                return nil
        }
        
        do {
            try data.write(to: imagePath)
            return imagePath
        } catch {
            return nil
        }
    }

    private func removeImage(at path: String) {
        guard let url = URL(string: path) else {
            assertionFailure("Failed to construct URL for local filepath at: \(path)")
            return
        }

        let fileManager = FileManager.default
        try? fileManager.removeItem(at: url)
    }

    private func update(drawing: Drawing, canvasSize: CGSize, duration: Int, steps: [DrawStep], image: UIImage?) {
        drawing.height = Double(canvasSize.height)
        drawing.width = Double(canvasSize.width)
        drawing.drawingDurationSeconds = duration
        drawing.steps.append(objectsIn: steps)

        // Remove the current image.
        if let currentImageUrl = drawing.image?.localUrl {
            removeImage(at: currentImageUrl)
        }

        // Store the new image if we have one.
        if let imageLocalUrl = storeImage(image: image) {
            let img = Image()
            img.localUrl = imageLocalUrl.absoluteString
            drawing.image = img
        }
    }

    private func createDrawing(_ drawing: Drawing, canvasSize: CGSize, duration: Int, steps: [DrawStep], image: UIImage?) {
        update(drawing: drawing, canvasSize: canvasSize, duration: duration, steps: steps, image: image)
        store.create(drawing: drawing)
        persist(drawing: drawing)
    }

    private func updateDrawing(_ drawing: Drawing, canvasSize: CGSize, duration: Int, steps: [DrawStep], image: UIImage?) {
        store.inTransaction { [weak self] in
            self?.update(drawing: drawing, canvasSize: canvasSize, duration: duration, steps: steps, image: image)
        }
        persist(drawing: drawing)
    }
    
    private func persist(drawing: Drawing) {
        store.setUploadState(for: drawing, to: .sending)
        drawingsNetworkLayer.create(drawing: drawing) { [weak self] result in
            switch result {
            case .success(let json):
                self?.store.merge(json, into: drawing)
            case .failure(let error):
                print("Network error persisting drawing: \(error)")
                self?.store.setUploadState(for: drawing, to: .failed)
            }
        }
    }
    
    @objc private func reachabilityChanged(notification: Notification) {
        switch reachability.connection {
        case .wifi, .cellular:
            store.localDrawings.forEach { self.persist(drawing: $0) }
        case .unavailable, .none:
            print("Network not reachable")
        }
    }
    
    private func presentDrawing(drawing: Drawing?) {
        let coordinator = drawingEditorCoordinatorFactory(drawing)
        coordinator.delegate = self
        coordinator.start()
        drawingEditorCoordinator = coordinator
        // TODO: We shouldn't assume we're in a UINavigationController.
        rootViewController.navigationController?.pushViewController(coordinator.rootViewController, animated: true)
    }
}
