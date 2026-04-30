//
//  GameViewController.swift
//  Free Return
//
//  Created by Chris Slowik on 4/29/26.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let scene = GameScene(size: WorldCanvas.size)
        scene.scaleMode = .aspectFill

        if let view = self.view as? SKView {
            view.presentScene(scene)
            view.ignoresSiblingOrder = true
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
