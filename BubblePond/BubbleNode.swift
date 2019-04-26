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
        
        noteName = note
        lifeDuration = duration
        
        // Use these to start
        let imageName = "sk180313-dot-\(Int.random(in: 1...7))"
        
        // make this initializer failable based on success of this?
        let texture = SKTexture(imageNamed: imageName)
        
        let dotSize = CGSize(width: diameter, height: diameter)
        
        // have to call this b/c designated init, but don't want color?
        super.init(texture: texture, color: .white, size: dotSize)
        
        name = note
        //alpha = 0.0 // invisible when first added
        
        // TODO: separate method for configuring physics body? here? or in scene?
        // Does the physicBody have to be added to a scene before config?
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented for BubbleNode")
    }
    
    // TODO: configures physics internally?
    
    func age(by duration: Int = 1) {
        
        guard isMortal else { return }
        
        lifeDuration -= duration
        
        if lifeDuration < 1 {
            fadeAway()
        }
    }
    
    private func fadeAway() {
        
        run(SKAction.sequence([SKAction.fadeOut(withDuration: 2.0),
                               SKAction.removeFromParent()]))
        
        NotificationCenter.default.post(name: .BubbleWillFade,
                                        object: self,
                                        userInfo: [ BubbleNode.noteNameKey: noteName ])
        
        NotificationCenter.default.post(name: .BubbleWillFade,
                                        object: self)
    }
}
