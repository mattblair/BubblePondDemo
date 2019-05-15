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
    
    // DEPRECATED?
    //let noteName: String
    let collision1NoteName: String
    let collision2NoteName: String
    
    // have this vary over time and determine alpha/amplitude?
    var vitality: Float = 0.0
    var isMortal: Bool = true
    var lifeDuration: Int
    var lastSounded: Date?
    
    // Additional properties to consider:
    // collisions left
    // collision behavior...enum?
    // duration before fade
    
    
    init(note1: String, note2: String, diameter: CGFloat, duration: Int) {
        
        print("Adding node which will last \(duration) seconds")
        
        //noteName = note
        collision1NoteName = note1
        collision2NoteName = note2
        lifeDuration = duration
        
        // TODO: Read these from the score, or add as init parameter
        let imageName = "sk180313-dot-\(Int.random(in: 1...7))"
        
        // make this initializer failable based on success of this?
        let texture = SKTexture(imageNamed: imageName)
        
        let dotSize = CGSize(width: diameter, height: diameter)
        
        // have to call this b/c it's the designated init, but color isn't used.
        super.init(texture: texture, color: .white, size: dotSize)
        
        // TODO: Is this used for anything? Debugging?
        name = "\(collision1NoteName)-\(collision2NoteName)"
        alpha = 0.0
        
        // TODO: separate method for configuring physics body? here? or in scene?
        // Does the physicBody have to be added to a scene before config?
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented for BubbleNode")
    }
    
    
    // MARK: - Physics
    
    func physicsRadius(multiplier: Float) -> CGFloat {
        return max(frame.size.width / 2, frame.size.height / 2) * CGFloat(multiplier)
    }
    
    func configurePhysics(score: BubblePondScore) {
        
        let radius = physicsRadius(multiplier: score.physicsRadiusMultiplier)
        physicsBody = SKPhysicsBody(circleOfRadius: radius)
        
        physicsBody?.velocity = score.randomInitialVelocity()
        
        print("Bubble density: \(physicsBody?.density ?? 0.0)")
        print("Bubble default mass: \(physicsBody?.mass ?? 0.0)")
        
        physicsBody?.mass = 0.2
        physicsBody?.linearDamping = 0.05
        
        physicsBody?.categoryBitMask = PhysicsBodyTypes.bubble.rawValue
        physicsBody?.categoryBitMask = PhysicsBodyTypes.bubble.rawValue | PhysicsBodyTypes.edge.rawValue
        physicsBody?.contactTestBitMask = PhysicsBodyTypes.bubble.rawValue | PhysicsBodyTypes.edge.rawValue
    }
    
    
    // MARK: - Lifecycle
    
    func arrive() {
        // Have this call configurePhysics?
        run(SKAction.fadeIn(withDuration: 2.0))
    }
    
    func age(by duration: Int = 1) {
        
        guard isMortal else { return }
        
        lifeDuration -= duration
        
        if lifeDuration < 1 {
            departTheScene()
        }
    }
    
    private func departTheScene() {
        
        // This may save a slight amount of energy...
        physicsBody = nil
        
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
