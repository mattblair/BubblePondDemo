//
//  ViewController.swift
//  BubblePond
//
//  Created by Matt Blair on 4/19/19.
//  Copyright © 2019 Elsewise. All rights reserved.
//

import UIKit
import SpriteKit


class ViewController: UIViewController {

    var scene: BubblePondScene?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scoreName = "bpscore2" // "bpscore-example"
        
        scene = BubblePondScene.init(size: view.bounds.size,
                                     scoreName: scoreName)
        
        scene?.scaleMode = .resizeFill
        
        if let view = self.view as? SKView {
            
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = false
            view.showsNodeCount = false
            //view.showsPhysics = true
        }
        
        // keep the screen on
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    deinit {
        print("PondVC deallocated")
    }
}
