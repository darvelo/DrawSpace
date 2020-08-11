//
//  DrawingEditorCoordinator.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit
import RealmSwift

enum DrawingEditorCoordinatorEvent {
    case cancel
    case create(drawing: Drawing,
                canvasSize: CGSize,
                duration: Int,
                steps: [DrawStep],
                image: UIImage?)
    case update(drawing: Drawing,
                canvasSize: CGSize,
                duration: Int,
                steps: [DrawStep],
                image: UIImage?)
}

protocol DrawingEditorCoordinatorDelegate: class {
    func handleDrawingEditorCoordinatorEvent(_: DrawingEditorCoordinatorEvent)
}

class DrawingEditorCoordinator: Coordinator, DrawingEditorViewControllerDelegate {

    // MARK: Private Properties

    private let store: Store
    private let isUpdate: Bool

    private var currentColor = UIColor.red
    private var lastPanPoint: CGPoint?
    private var startedAt = Date()

    private var createdAt = Date()
    private var drawingDurationSeconds = 0
    private var steps = [DrawStep]()
    private lazy var drawing: Drawing = {
        let model = Drawing()
        model.createdAt = createdAt
        return model
    }()

    private lazy var drawingEditorViewController: DrawingEditorViewController = {
        let vc = DrawingEditorViewController()
        vc.delegate = self
        return vc
    }()
    
    // MARK: Public Properties
    
    weak var delegate: DrawingEditorCoordinatorDelegate?
    lazy var rootViewController: UIViewController = drawingEditorViewController
    
    // MARK: Initialization
    
    init(store: Store, drawing: Drawing?) {
        self.store = store
        self.isUpdate = drawing != nil

        if let drawing = drawing {
            self.steps = Array(drawing.steps)
            self.createdAt = drawing.createdAt
            self.drawingDurationSeconds = drawing.drawingDurationSeconds
            self.drawing = drawing
            drawingEditorViewController.update(drawing: drawing)
        }
    }
    
    // MARK: Coordinator
    
    func start() { }
    
    // MARK: DrawingEditorViewControllerDelegate
    
    func cancelTapped() {
        delegate?.handleDrawingEditorCoordinatorEvent(.cancel)
    }
    
    func doneTapped(image: UIImage?, canvasSize: CGSize) {
        let event: DrawingEditorCoordinatorEvent
        let sessionDuration = Int(Date().timeIntervalSince(startedAt))

        if isUpdate {
            let duration = drawing.drawingDurationSeconds + sessionDuration
            event = .update(drawing: drawing,
                            canvasSize: canvasSize,
                            duration: duration,
                            steps: steps,
                            image: image)
        } else {
            let duration = sessionDuration
            event = .create(drawing: drawing,
                            canvasSize: canvasSize,
                            duration: duration,
                            steps: steps,
                            image: image)
        }

        delegate?.handleDrawingEditorCoordinatorEvent(event)
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
