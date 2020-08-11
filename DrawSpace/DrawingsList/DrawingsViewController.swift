//
//  DrawingsViewController.swift
//  talkspace_test
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit
import RealmSwift


private enum ReuseIdentifier: String {
    case drawing
}

protocol DrawingsViewControllerDelegate: class {
    func createDrawingTapped()
    func clearDrawingsTapped()
    func syncDrawings(completion: @escaping () -> Void)
    func drawingTapped(_ drawing: Drawing)
    func deleteDrawing(_ drawing: Drawing)
}

class DrawingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: Public Properties
    
    weak var delegate: DrawingsViewControllerDelegate?
    
    // MARK: Private Properties
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(syncDrawings), for: .valueChanged)
        return control
    }()
    
    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.register(DrawingCell.self, forCellReuseIdentifier: ReuseIdentifier.drawing.rawValue)
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    private let drawings: Results<Drawing>
    
    // MARK: Initialization
    
    init(drawings: Results<Drawing>) {
        self.drawings = drawings
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Drawings"
        navigationItem.setRightBarButtonItems([UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createDrawing)),
                                               UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(clearDrawings)),
                                               UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(syncDrawings))], animated: true)

        view.addSubview(tableView)

        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.backgroundView = refreshControl
        }
                
        [
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ].forEach { $0.isActive = true }
    }

    // MARK: Public Methods
    
    func update(_ changes: RealmCollectionChange<Results<Drawing>>) {
        // Update the list once the navigation controller puts this ViewController's view
        // into the view hierarchy. This ensures the tableView won't try to update offscreen and give a warning.
        // Solution from: https://stackoverflow.com/a/50532891/544252
        guard view.superview != nil else { return }

        switch changes {
        case .initial:
            // Results are now populated and can be accessed without blocking the UI
            tableView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            // Query results have changed, so apply them to the UITableView
            tableView.beginUpdates()
            // Always apply updates in the following order: deletions, insertions, then modifications.
            // Handling insertions before deletions may result in unexpected behavior.
            tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
                                 with: .automatic)
            tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                 with: .automatic)
            tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                 with: .automatic)
            tableView.endUpdates()
        case .error(let error):
            fatalError("An error occurred while opening the Realm file on the background worker thread: \(error)")
        }
    }

    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drawings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.drawing.rawValue, for: indexPath) as! DrawingCell
        cell.configure(drawing: drawings[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // The cell label is 3 lines tall at a line-height of 16px,
        // so let's pad the cell with 2 lines' worth of height.
        // Normally I'd put a constant like this in a ViewModel or a Theme struct that's passed down to all ViewControllers.
        return 16 * 5
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        delegate?.deleteDrawing(drawings[indexPath.row])
    }

    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        drawingTapped(drawings[indexPath.row])
    }

    // MARK: Private Methods
    
    @objc private func createDrawing() {
        delegate?.createDrawingTapped()
    }
    
    @objc private func clearDrawings() {
        delegate?.clearDrawingsTapped()
    }
    
    @objc private func syncDrawings() {
        delegate?.syncDrawings { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.refreshControl.isRefreshing {
                strongSelf.refreshControl.endRefreshing()
            }
        }
    }
    
    private func drawingTapped(_ drawing: Drawing) {
        delegate?.drawingTapped(drawing)
    }
}
