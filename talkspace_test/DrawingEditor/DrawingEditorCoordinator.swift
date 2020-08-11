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

    private var currentColor = UIColor.red
    private var lastPanPoint: CGPoint?
    private var steps = [DrawStep]()
    
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

    func handleColorChange(color: UIColor) {
        currentColor = color
    }

    func handleDrawTap(point: CGPoint) {
        assert(lastPanPoint == nil, "Expected lastPanPoint to be nil on draw tap")

        guard let step = DrawStep.from(color: currentColor.cgColor, startPoint: point, endPoint: nil) else {
            assertionFailure("Failed to create step for draw tap event")
            return
        }

        steps.append(step)
        drawingEditorViewController.update(step: step)
    }

    func handleDrawPan(event: DrawPanEvent) {
        switch event {
        case .start(let point):
            lastPanPoint = point
        case .move(let point):
            guard let lastPoint = lastPanPoint,
                let step = DrawStep.from(color: currentColor.cgColor, startPoint: lastPoint, endPoint: point) else {
                assertionFailure("Failed to create step for pan move event")
                return
            }

            steps.append(step)
            lastPanPoint = point
            drawingEditorViewController.update(step: step)
        case .end(let point):
            guard let lastPoint = lastPanPoint,
                let step = DrawStep.from(color: currentColor.cgColor, startPoint: lastPoint, endPoint: point) else {
                    assertionFailure("Failed to create step for pan move event")
                    return
            }

            steps.append(step)
            lastPanPoint = nil
            drawingEditorViewController.update(step: step)
        }
    }
}
