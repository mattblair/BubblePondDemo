//
//  BubbleNode.swift
//  BubblePond
//
//  Created by Matt Blair on 4/19/19.
//  Copyright © 2019 Elsewise. All rights reserved.
//

import SpriteKit


extension Notification.Name {
    
    static let BubbleWillFade = NSNotification.Name("BubbleWillFade")
}


class BubbleNode: SKSpriteNode {
    
    static let noteNameKey: String = "NoteNameKey"
    
    let noteName: String
    
    // have this vary over time and determine alpha/amplitude?
    var vitality: Float = 0.0
    var isMortal: Bool = true
    var lifeDuration: Int
    var lastSounded: Date?
    
    // Additional properties to consider:
    // collisions left
    // collision behavior...enum?
    // duration before fade
    
    
    init(noteName note: String, diameter: CGFloat, duration: Int) {
        
        print("Adding node which will last \(duration) seconds")
        
        noteName = note
        lifeDuration = duration
        
        // Use these to start
        let imageName = "sk180313-dot-\(Int.random(in: 1...7))"
        
        // make this initializer failable based on success of this?
        let texture = SKTexture(imageNamed: imageName)
        
        let dotSize = CGSize(width: diameter, height: diameter)
        
        // have to call this b/c it's the designated init, but color isn't used.
        super.init(texture: texture, color: .white, size: dotSize)
        
        name = note
        
        // TODO: separate method for configuring physics body? here? or in scene?
        // Does the physicBody have to be added to a scene before config?
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented for BubbleNode")
    }
    
    // TODO: configures physics internally?
    
    
    // MARK: - Lifecycle
    
    func age(by duration: Int = 1) {
        
        guard isMortal else { return }
        
        lifeDuration -= duration
        
        if lifeDuration < 1 {
            departTheScene()
        }
    }
    
    private func departTheScene() {
        
        run(SKAction.sequence([SKAction.fadeOut(withDuration: 2.0),
                               SKAction.removeFromParent()]))
        
        // Use this if orchestra should play this node's specific note:
        /*
        NotificationCenter.default.post(name: .BubbleWillFade,
                                        object: self,
                                        userInfo: [ BubbleNode.noteNameKey: noteName ])
        */
        
        // Use this if the orchestra chooses the note
        NotificationCenter.default.post(name: .BubbleWillFade,
                                        object: self)
    }
}
