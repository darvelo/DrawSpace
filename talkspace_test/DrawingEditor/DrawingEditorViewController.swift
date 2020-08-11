//
//  DrawingEditorViewController.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit

enum DrawPanEvent {
    case start(point: CGPoint)
    case move(point: CGPoint)
    case end(point: CGPoint)
}

protocol DrawingEditorViewControllerDelegate: class {
    func cancelTapped()
    func doneTapped(image: UIImage?)
    func handleDrawTap(point: CGPoint)
    func handleColorChange(color: UIColor)
    func handleDrawPan(event: DrawPanEvent)
}

class DrawingEditorViewController: UIViewController, ToolbarViewDelegate {

    // MARK: Private Poperties

    private var imageBuffer: UIImage?

    private lazy var imageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var toolbarView: ToolbarView = {
        let view = ToolbarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()

    private lazy var drawView: DrawView = {
        let view = DrawView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: Public Properties

    weak var delegate: DrawingEditorViewControllerDelegate?

    // MARK: Initialization

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))

        view.addSubview(imageView)
        view.addSubview(drawView)
        view.addSubview(toolbarView)

        drawView.backgroundColor = .clear
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor),
            imageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),

            drawView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            drawView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor),
            drawView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            drawView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),

            toolbarView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: Theme.toolbarView.widthFactor),
            toolbarView.heightAnchor.constraint(equalToConstant: Theme.toolbarView.height),
            toolbarView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            toolbarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: Theme.toolbarView.bottomOffset),
        ])

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        drawView.addGestureRecognizer(tapGestureRecognizer)

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        drawView.addGestureRecognizer(panGestureRecognizer)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.cancelTapped()
    }

    // MARK: ToolbarViewDelegate

    func colorTapped(_ color: UIColor) {
        delegate?.handleColorChange(color: color)
    }

    // MARK: Public Methods

    func update(drawing: Drawing?) {
    }

    func update(step: DrawStep) {
        autoreleasepool { [weak self] in
            guard let strongSelf = self else { return }
            let buffer = strongSelf.drawView.draw(step: step, imageBuffer: strongSelf.imageBuffer)
            strongSelf.imageBuffer = buffer
            strongSelf.imageView.image = buffer
        }
    }

    // MARK: Actions

    @objc private func cancelTapped() {
        delegate?.cancelTapped()
    }

    @objc private func doneTapped() {
        delegate?.doneTapped(image: nil)
    }

    @objc private func handleTap(sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }

        let point = sender.location(in: sender.view)
        delegate?.handleDrawTap(point: point)
    }

    @objc private func handlePan(sender: UIPanGestureRecognizer) {
        let point = sender.location(in: sender.view)
        switch sender.state {
        case .began:
            delegate?.handleDrawPan(event: .start(point: point))
        case .changed:
            delegate?.handleDrawPan(event: .move(point: point))
        case .ended:
            delegate?.handleDrawPan(event: .end(point: point))
        case .failed:
            delegate?.handleDrawPan(event: .end(point: point))
        case .possible:
            break
        case .cancelled:
            print("Pan canceled")
        @unknown default:
            print("Unknown pan gesture state")
        }
    }
}
