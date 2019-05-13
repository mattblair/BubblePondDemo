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
        
        let themesVC = ThemesViewController(style: .plain)
        
        // TODO: customize this depending on device?
        
        themesVC.modalPresentationStyle = UIModalPresentationStyle.popover
        let popover = themesVC.popoverPresentationController
        themesVC.preferredContentSize = CGSize(width: 320.0, height: 500.0)
        themesVC.delegate = scene
        popover?.sourceView = sender
        popover?.sourceRect = sender.bounds
        
        self.present(themesVC, animated: true)
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
    
    
    // MARK: - Debugging and Soundcheck
    
    // swiftline:disable:next discouraged_optional_collection
    override var keyCommands: [UIKeyCommand]? {
        
        // TODO: return nil for non-debug builds
        return [
            UIKeyCommand(input: "p",
                         modifierFlags: [], // e.g. .command
                         action: #selector(togglePlayPause),
                         discoverabilityTitle: "Toggle Physics"),
            UIKeyCommand(input: "s",
                         modifierFlags: [],
                         action: #selector(togglePhysics),
                         discoverabilityTitle: "Show Stats and Physics"),
            UIKeyCommand(input: "a",
                         modifierFlags: [],
                         action: #selector(requestArrivalSoundcheck),
                         discoverabilityTitle: "Arrival Soundcheck"),
            UIKeyCommand(input: "b",
                         modifierFlags: [],
                         action: #selector(requestCollisionBellsSoundcheck),
                         discoverabilityTitle: "Bells Soundcheck"),
            UIKeyCommand(input: "r",
                         modifierFlags: [],
                         action: #selector(requestCollisionRhodesSoundcheck),
                         discoverabilityTitle: "Rhodes Soundcheck"),
            UIKeyCommand(input: "d",
                         modifierFlags: [],
                         action: #selector(requestDepartureSoundcheck),
                         discoverabilityTitle: "Departure Soundcheck")
        ]
    }
    
    @objc
    func togglePlayPause() {
        scene?.isPaused.toggle()
    }
    
    @objc
    func togglePhysics() {
        
        if let skv = view as? SKView {
            skv.showsPhysics.toggle()
            skv.showsFPS = skv.showsPhysics
            skv.showsDrawCount = skv.showsPhysics
            skv.showsNodeCount = skv.showsPhysics
        }
    }
    
    func postSoundcheckNotification(source: SoundcheckAudioSource) {
        
        let userInfo: [String: SoundcheckAudioSource] = [ SoundcheckAudioSource.sourceKey: source ]
        
        NotificationCenter.default.post(name: .SoundcheckRequested,
                                        object: self,
                                        userInfo: userInfo)
        
        scene?.isPaused = true
        
        // TODO: observe notification to restart? or manually restart using 'p' key.
    }
    
    @objc
    func requestArrivalSoundcheck() {
        postSoundcheckNotification(source: .arrival)
    }
    
    @objc
    func requestCollisionBellsSoundcheck() {
        postSoundcheckNotification(source: .collisionBells)
    }
    
    @objc
    func requestCollisionRhodesSoundcheck() {
        postSoundcheckNotification(source: .collisionRhodes)
    }
    
    @objc
    func requestDepartureSoundcheck() {
        postSoundcheckNotification(source: .departure)
    }
}
