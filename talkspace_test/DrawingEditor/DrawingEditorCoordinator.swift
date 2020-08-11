//
//  DrawingEditorCoordinator.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit

enum DrawingEditorCoordinatorEvent {
    case cancel
    case done(image: UIImage?)
}

protocol DrawingEditorCoordinatorDelegate: class {
    func handleDrawingEditorCoordinatorEvent(_: DrawingEditorCoordinatorEvent)
}

class DrawingEditorCoordinator: Coordinator, DrawingEditorViewControllerDelegate {

    // MARK: Private Properties
    
    private lazy var drawingEditorViewController: DrawingEditorViewController = {
        let vc = DrawingEditorViewController()
        vc.delegate = self
        return vc
    }()
    
    // MARK: Public Properties
    
    weak var delegate: DrawingEditorCoordinatorDelegate?
    lazy var rootViewController: UIViewController = drawingEditorViewController
    
    // MARK: Initialization
    
    init(drawing: Drawing?) {
        drawingEditorViewController.update(drawing: drawing)
    }
    
    // MARK: Coordinator
    
    func start() { }
    
    // MARK: DrawingEditorViewControllerDelegate
    
    func cancelTapped() {
        delegate?.handleDrawingEditorCoordinatorEvent(.cancel)
    }
    
    func doneTapped(image: UIImage?) {
        delegate?.handleDrawingEditorCoordinatorEvent(.done(image: image))
    }
}
