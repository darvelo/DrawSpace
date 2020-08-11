//
//  AppDelegate.swift
//  DrawSpace
//
//  Created by David Arvelo on 8/10/20.
//  Copyright © 2020 David Arvelo. All rights reserved.
//

import UIKit
import Alamofire
import Reachability

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var context: Context?
    var rootCoordinator: Coordinator?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Create Network Layer
        let serverTrustManager = ServerTrustManager(evaluators: ["env-develop.saturn.engineering": DefaultTrustEvaluator()])
        let sessionManager = Alamofire.Session(configuration: URLSessionConfiguration.af.default,
                                               serverTrustManager: serverTrustManager)
        let drawingsNetworkLayer = DrawingsNetworkLayer(sessionManager: sessionManager)
        
        // Create Local Storage Layer
        let store = LocalStore()
        
        // Create Initial Objects
        let reachability = try! Reachability()
        let context = Context(drawingsNetworkLayer: drawingsNetworkLayer,
                              reachability: reachability,
                              store: store)
        let coordinator = context.rootCoordinatorFactory()
        coordinator.start()
        
        // Present the First Screen.
        let window = UIWindow()
        window.rootViewController = coordinator.rootViewController
        window.makeKeyAndVisible()
        
        self.window = window
        self.context = context
        self.rootCoordinator = coordinator
        
        try! reachability.startNotifier()

        return true
    }
    
}
