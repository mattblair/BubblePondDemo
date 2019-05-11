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
    
    @IBOutlet weak var themesButton: UIButton!
    @IBOutlet weak var notesButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: hide edit button for release builds
        
        // TODO: Load previously played theme, or first one from playlist
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
    
    
    // MARK: - Handle Button Taps
    
    @IBAction func themesButtonTapped(_ sender: UIButton) {
        // TODO: modal/popover presentation of themes
    }
    
    @IBAction func notesButtonTapped(_ sender: UIButton) {
        // TODO: Full screen presentation of liner notes
    }
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        
        let scoreEditorVC = ScoreEditorViewController(nibName: nil, bundle: nil)
        
        scoreEditorVC.score = scene?.score
        scoreEditorVC.delegate = scene
        
        let navVC = UINavigationController(rootViewController: scoreEditorVC)
        present(navVC, animated: true, completion: nil)
    }
}
