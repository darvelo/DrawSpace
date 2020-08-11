//
//  DrawingEditorViewController.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit

protocol DrawingEditorViewControllerDelegate: class {
    func cancelTapped()
    func doneTapped(image: UIImage?)
}

class DrawingEditorViewController: UIViewController, ToolbarViewDelegate {

    // MARK: Public Properties

    weak var delegate: DrawingEditorViewControllerDelegate?

    // MARK: Private Poperties

    private lazy var toolbarView: ToolbarView = {
        let view = ToolbarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()

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
        
        view.addSubview(toolbarView)
        
        NSLayoutConstraint.activate([
            toolbarView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: Theme.toolbarView.widthFactor),
            toolbarView.heightAnchor.constraint(equalToConstant: Theme.toolbarView.height),
            toolbarView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            toolbarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: Theme.toolbarView.bottomOffset),
        ])
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.cancelTapped()
    }

    // MARK: ToolbarViewDelegate

    func colorTapped(_ color: UIColor) {
        print(color)
    }

    // MARK: Public Methods

    func update(drawing: Drawing?) {
    }

    // MARK: Private Methods

    @objc private func cancelTapped() {
        delegate?.cancelTapped()
    }

    @objc private func doneTapped() {
        delegate?.doneTapped(image: nil)
    }
}
