// 11.05.2020

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else {
            return
        }

        let viewController = ViewController()
        viewController.reactor = ViewReactor()

        window = {
            let window = UIWindow(windowScene: scene)
            window.rootViewController = viewController
            window.makeKeyAndVisible()

            return window
        }()
    }
}
