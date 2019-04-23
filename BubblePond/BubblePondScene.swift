//
//  BubblePondScene.swift
//  BubblePond
//
//  Created by Matt Blair on 4/19/19.
//  Copyright © 2019 Elsewise. All rights reserved.
//

import SpriteKit

enum PhysicsBodyTypes: UInt32 {
    case bubble = 1
    case edge = 2
}


class BubblePondScene: SKScene, SKPhysicsContactDelegate {
    
    // TODO: read this from currentConfig
    
    let noteNames = ["C3", "G3", "D4", "A4", "E5", "F2"]
    let minBubbleCount: Int = 3
    let maxBubbleCount: Int = 14
    
    // TODO: reference to sound orchestra
    
    private var frameCount = 0
    
    
    //init(size: CGSize, conf: SoundPond1Config, orch: SoundPondOrchestra) {
    override init(size: CGSize) {
        
        //orchestra = orch
        //config = conf
        // TODO: handle failure here? or have config return a default...
        //visualConfig = config.visualElementsFor(height: size.height)!
        
        super.init(size: size)
        
        backgroundColor = .white
        
        physicsWorld.contactDelegate = self
        
        // TODO: try with other gravity vectors
        physicsWorld.gravity = .zero
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("BubblePondScene deallocated")
    }
    
    override func sceneDidLoad() {
        
        self.anchorPoint = CGPoint(x: 0.5, y:0.5)
    }
    
    override func didMove(to view: SKView) {
        
        print("Screen dimensions: \(view.frame.size)")
        print("Scene dimensions: \(self.frame.size)")
        
        // TODO: configure scene
    }
    
    
    // MARK: - Scene Update
    
    override func update(_ currentTime: TimeInterval) {
        
        frameCount += 1
        
        if frameCount % 60 == 0 {
            
            let bubbles = children.compactMap { $0 as? BubbleNode }
            for bubble in bubbles { bubble.age() }
            
            addBubbleNodeAt(point: emptyPositionOnScreen())
        }
    }
    
    
    // MARK: - SKPhysicsContactDelegate methods
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        // Are these test necessary?
        guard let nodeAName = nodeA.name else { return }
        guard let nodeBName = nodeB.name else { return }
        
        print("\(nodeAName) hit \(nodeBName)")
        
        // TODO: trigger sounds
    }
    
    
    // MARK: - Touch Interaction
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches { addBubbleNodeAt(point: touch.location(in: self)) }
        
        // TODO: detect taps on bubbles, too...
    }
    
    
    // MARK: Adding New Bubbles
    
    // TODO: derive from score
    func screenFactor() -> ClosedRange<Float> {
        return 4.0...5.0
    }
    
    func randomScreenFraction() -> CGFloat {
        
        return CGFloat(Float.random(in: screenFactor()))
    }
    
    func maxBubbleDiameter() -> CGFloat {
        
        return bubbleDiameter(factor: CGFloat(screenFactor().lowerBound))
    }
    
    /// Calculated as a portion of the smallest screen edge.
    ///
    /// - todo: Update names and verbiage around these calculations.
    func bubbleDiameter(factor divisor: CGFloat) -> CGFloat {
        
        if let s = scene {
            
            // TODO: read divisor from score
            // TODO: randomize here? Or in the bubble?
            
            let smallestDimension = min(s.frame.size.width, s.frame.size.height)
            //let divisor = CGFloat(Float.random(in: screenFactorRange))
            return floor(smallestDimension / divisor)
        }
        
        return 100.0
    }
    
    func randomPositionOnScreen() -> CGPoint {
        
        // TODO: load this as a config variable? or calculate based on max diameter?
        let edgePadding = 50
        
        // TODO: remove this by using self.frame?
        if let s = scene {
            
            let safeSceneWidth = s.frame.size.width - CGFloat(edgePadding * 2)
            let x = Int.random(in: (Int(-safeSceneWidth/2.0))...Int(safeSceneWidth/2.0))
            
            let safeSceneHeight = s.frame.size.height - CGFloat(edgePadding * 2)
            let y = Int.random(in: (Int(-safeSceneHeight/2.0))...Int(safeSceneHeight/2.0))
            
            print("Random Point: \(x) \(y)")
            return CGPoint(x: x, y: y)
        } else {
            return .zero
        }
    }
    
    func bubblesWithin(radius: CGFloat, of point: CGPoint) -> [BubbleNode] {
        
        var bubblesWithin = [BubbleNode]()
        
        let bubbles = children.compactMap { $0 as? BubbleNode }
        
        // So we can compare distances without using sqrt()
        let radiusSquared = radius * radius
        
        for bubble in bubbles {
            
            let distanceSquared = (bubble.position.x - point.x) * (bubble.position.x - point.x) +
                (bubble.position.y - point.y) * (bubble.position.y - point.y)
            
            if distanceSquared < radiusSquared {
                bubblesWithin.append(bubble)
            }
        }
        
        return bubblesWithin
    }
    
    // TODO: limit the number of iterations, making return value optional, or a Result?
    func emptyPositionOnScreen() -> CGPoint {
        
        var point: CGPoint = .zero
        var positionIsEmpty: Bool = false
        
        while !positionIsEmpty {
            
            point = randomPositionOnScreen()
            
            // this approach is not precise enough.
            // They can still be close enough to jostle neighbors when added.
            /*
            let nodesAtPoint = nodes(at: point)
            
            if nodesAtPoint.count == 0 {
                positionIsEmpty = true
            }
            */
            
            if bubblesWithin(radius: maxBubbleDiameter(),
                             of: point).count == 0 {
                positionIsEmpty = true
            }
        }
        
        return point
    }
    
    func shouldAddBubble() -> Bool {
        
        let bubbles = children.compactMap { $0 as? BubbleNode }
        print("Bubble count: \(bubbles.count)")
        
        if bubbles.count >= maxBubbleCount {
            return false
        }
        
        // check min here,too?
        
        // TODO: return false if there is no empty space?
        
        return true
    }
    
    func addBubbleNodeAt(point: CGPoint) {
        
        guard shouldAddBubble() else { return }
        
        let bubble = BubbleNode(noteName: noteNames.randomElement() ?? "C4",
                                diameter: bubbleDiameter(factor: randomScreenFraction()))
        bubble.position = point
        bubble.alpha = 0.0 // move inside BubbleNode if it handles its own fade
        
        // TODO: configure lifeDuration and action sequence here?
        // Or inside node?
        
        self.addChild(bubble)
        
        // TODO: Did you do physics here because it has to be part of a scene first?
        
        //let physicsRadius = max(n.frame.size.width / 2, n.frame.size.height / 2) * 0.8
        
        // TODO: Turn this into an instance method on node
        let physicsRadius = max(bubble.frame.size.width / 2, bubble.frame.size.height / 2) * 0.9
        bubble.physicsBody = SKPhysicsBody(circleOfRadius: physicsRadius)
        
        //bubble.physicsBody?.velocity = randomVector(deviatingBy: visualConfig.maxInitialVelocity)
        
        let dx = Float.random(in: -10.0...10.0)
        let dy = Float.random(in: -10.0...10.0)
        print("Initial vector: \(dx), \(dy)")
        
        bubble.physicsBody?.velocity = CGVector(dx: CGFloat(dx),
                                                dy: CGFloat(dy))
        
        print("Bubble density: \(bubble.physicsBody?.density)")
        print("Bubble default mass: \(bubble.physicsBody?.mass)")
        
        bubble.physicsBody?.mass = 0.2
        
        bubble.physicsBody?.categoryBitMask = PhysicsBodyTypes.bubble.rawValue
        bubble.physicsBody?.categoryBitMask = PhysicsBodyTypes.bubble.rawValue | PhysicsBodyTypes.edge.rawValue
        bubble.physicsBody?.contactTestBitMask = PhysicsBodyTypes.bubble.rawValue | PhysicsBodyTypes.edge.rawValue
        
        // TODO: Or have it fade itself in?
        bubble.run(SKAction.fadeIn(withDuration: 2.0))
    }
}
