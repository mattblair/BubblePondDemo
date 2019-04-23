//
//  BubbleNode.swift
//  BubblePond
//
//  Created by Matt Blair on 4/19/19.
//  Copyright © 2019 Elsewise. All rights reserved.
//

import SpriteKit

class BubbleNode: SKSpriteNode {
    
    let noteName: String
    
    // have this vary over time and determine alpha/amplitude?
    var vitality: Float = 0.0
    var isMortal: Bool = true
    var lifeDuration: Int = Int.random(in: 10...15)
    var lastSounded: Date?
    
    // Additional properties to consider:
    // collisions left
    // collision behavior...enum?
    // duration before fade
    
    
    init(noteName note: String, diameter: CGFloat) {
        
        noteName = note
        
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
    
    public func age(by duration: Int = 1) {
        
        guard isMortal else { return }
        
        lifeDuration -= duration
        
        if lifeDuration < 1 {
            run(SKAction.sequence([SKAction.fadeOut(withDuration: 2.0),
                                   SKAction.removeFromParent()]))
        }
    }
}
