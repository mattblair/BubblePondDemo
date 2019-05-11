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

enum PondError: Error {
    case noEmptySpace
    
    // TODO: add a description?
}


class BubblePondScene: SKScene, SKPhysicsContactDelegate, ScoreEditorViewControllerDelegate {
    
    var score: BubblePondScore {
        didSet {
            let framesPerSecond: Float = 60.0
            framesPerSoundEvent = Int((60.0 / score.tempo) * framesPerSecond)
            print("Tempo in frames: \(framesPerSoundEvent)")
        }
    }
    
    let orchestra: PondOrchestra
    
    
    private var frameCount = 0
    private var framesPerSoundEvent = 60
    
    
    init?(size: CGSize, scoreName: String) {
        
        if let bpScore = BubblePondScene.loadScore(filename: scoreName) {
            score = bpScore
            orchestra = PondOrchestra(score: bpScore)
        } else {
            return nil
        }
        
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
        
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }
    
    override func didMove(to view: SKView) {
        
        print("Screen dimensions: \(view.frame.size)")
        print("Scene dimensions: \(self.frame.size)")
    }
    
    
    // MARK: - Scene Update
    
    override func update(_ currentTime: TimeInterval) {
        
        frameCount += 1
        
        // Assumption: frame rate is 60 fps
        if frameCount % 60 == 0 {
            
            let bubbles = children.compactMap { $0 as? BubbleNode }
            for bubble in bubbles { bubble.age() }
        }
        
        if frameCount % framesPerSoundEvent == 0 {
            // original:
            //    if let point = emptyPositionOnScreen() {
            //        addBubbleNodeAt(point: nil)
            //    }
        
            // syntax option 1
            /*
            let pointResult = emptyPositionOnScreen()
            
            switch pointResult {
            case .success(let point):
                addBubbleNodeAt(point: point)
            case .failure(let error):
                // fail silently in this case
                print(error)
            }
            */
            
            // syntax option 2
            
            let pointResult = emptyPositionOnScreen()
            
            do {
                let point = try pointResult.get()
                addBubbleNodeAt(point: point)
            } catch {
                // fail silently in this case
                print(error)
            }
        }
    }
    
    
    // MARK: - SKPhysicsContactDelegate methods
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        // Note: the order of these is arbitrary
        guard let bubble1 = contact.bodyA.node as? BubbleNode else { return }
        guard let bubble2 = contact.bodyB.node as? BubbleNode else { return }
        
        print("\(bubble1.collision1NoteName) hit \(bubble2.collision2NoteName)")
        
        orchestra.playCollisionBetween(note1: bubble1.collision1NoteName,
                                       note2: bubble2.collision2NoteName)
    }
    
    
    // MARK: - Touch Interaction
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // TODO: show bruise at lower z-index if max reached, or too close to an existing bubble
        for touch in touches { addBubbleNodeAt(point: touch.location(in: self)) }
        
        // TODO: detect double taps on bubbles to depart using touch.tapcount
    }
    
    
    // MARK: - Configuration
    
    // TODO: make this a failable init of BubblePondScore?
    static func loadScore(filename: String) -> BubblePondScore? {
        
        // TODO: change score extensions to .bpscore
        if let scorePath = Bundle.main.path(forResource: filename,
                                            ofType: "json") {
            
            do {
                let scoreJSONString = try String(contentsOfFile: scorePath)
                if let jsonData = scoreJSONString.data(using: .utf8) {
                    let decoder = JSONDecoder()
                    
                    let bpScore = try decoder.decode(BubblePondScore.self,
                                                     from: jsonData)
                    print(bpScore as Any)
                    return bpScore
                } else {
                    print("Failed convert scoreJSONString to data.")
                }
            } catch {
                print("Failed to parse \(filename): \(error)")
            }
            
        } else {
            print("Couldn't find score json file: \(filename)")
        }
        return nil
    }
    
    /// Fade all bubbles over the given duration, and remove from scene.
    ///
    /// This method will not trigger departure sounds.
    func fadeBubbles(duration: TimeInterval) {
        let bubbles = children.compactMap { $0 as? BubbleNode }
        
        for bubble in bubbles {
            bubble.run(SKAction.sequence([SKAction.fadeOut(withDuration: duration),
                                          SKAction.removeFromParent()]))
        }
    }
    
    // TODO: reusable by theme selector, too.
    func adaptTo(score updatedScore: BubblePondScore) {
        
        fadeBubbles(duration: 0.3)
        
        score = updatedScore
        orchestra.score = updatedScore
        orchestra.configureForScore()
    }
    
    
    // MARK: - ScoreEditorViewControllerDelegate method
    
    func scoreEditor(_: ScoreEditorViewController, finishedWith editedScore: BubblePondScore) {
        
        adaptTo(score: editedScore)
    }
    
    
    // MARK: - Adding New Bubbles
    
    func randomScreenFraction() -> CGFloat {
        
        return CGFloat(Float.random(in: score.screenDivisorRange))
    }
    
    func maxBubbleDiameter() -> CGFloat {
        
        return bubbleDiameter(factor: CGFloat(score.screenDivisorRange.lowerBound))
    }
    
    /// Calculated as a portion of the smallest screen edge.
    ///
    /// - todo: Update names and verbiage around these calculations.
    func bubbleDiameter(factor divisor: CGFloat) -> CGFloat {
        
        // swiftlint:disable:next identifier_name
        if let s = scene {
            
            let smallestDimension = min(s.frame.size.width, s.frame.size.height)
            return floor(smallestDimension / divisor)
        }
        
        return 100.0
    }
    
    func randomPositionOnScreen() -> CGPoint {
        
        // TODO: load this as a config variable? or calculate based on max diameter?
        let edgePadding = 50
        
        // TODO: remove this by using self.frame?
        // swiftlint:disable identifier_name
        if let s = scene {
            
            let safeSceneWidth = s.frame.size.width - CGFloat(edgePadding * 2)
            let x = Int.random(in: (Int(-safeSceneWidth / 2.0))...Int(safeSceneWidth / 2.0))
            
            let safeSceneHeight = s.frame.size.height - CGFloat(edgePadding * 2)
            let y = Int.random(in: (Int(-safeSceneHeight / 2.0))...Int(safeSceneHeight / 2.0))
            
            //print("Random Point: \(x) \(y)")
            return CGPoint(x: x, y: y)
        } else {
            return .zero
        }
        // swiftlint:enable identifier_name
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
    
    func emptyPositionOnScreen() -> Result<CGPoint, PondError> {
        
        var point: CGPoint = .zero
        var positionIsEmpty: Bool = false
        
        var attempts = 0
        let maxAttempts = 40
        
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
                print("Found empty position: \(point.x), \(point.y)")
                positionIsEmpty = true
            }
            
            attempts += 1
            if attempts > maxAttempts {
                return .failure(.noEmptySpace)
            }
        }
        
        return .success(point)
    }
    
    func shouldAddBubble() -> Bool {
        
        let bubbles = children.compactMap { $0 as? BubbleNode }
        print("Bubble count: \(bubbles.count)")
        
        if bubbles.count >= score.bubbleCountRange.upperBound {
            return false
        }
        
        // check lowerBound here,too?
        
        // TODO: return false here if there is no empty space?
        
        return true
    }
    
    func addBubbleNodeAt(point: CGPoint) {
        
        guard shouldAddBubble() else { return }
        
        let bubble = BubbleNode(note1: score.randomCollision1NoteName(),
                                note2: score.randomCollision2NoteName(),
                                diameter: bubbleDiameter(factor: randomScreenFraction()),
                                duration: score.randomLifeDuration())
        bubble.position = point
        bubble.alpha = 0.0 // move inside BubbleNode if it handles its own fade
        
        self.addChild(bubble)
        
        // TODO: Did you do physics here because it has to be part of a scene first?
        
        let physicsRadius = bubble.physicsRadius(multiplier: score.physicsRadiusMultiplier)
        bubble.physicsBody = SKPhysicsBody(circleOfRadius: physicsRadius)
        
        bubble.physicsBody?.velocity = score.randomInitialVelocity()
        
        print("Bubble density: \(bubble.physicsBody?.density ?? 0.0)")
        print("Bubble default mass: \(bubble.physicsBody?.mass ?? 0.0)")
        
        bubble.physicsBody?.mass = 0.2
        
        bubble.physicsBody?.categoryBitMask = PhysicsBodyTypes.bubble.rawValue
        bubble.physicsBody?.categoryBitMask = PhysicsBodyTypes.bubble.rawValue | PhysicsBodyTypes.edge.rawValue
        bubble.physicsBody?.contactTestBitMask = PhysicsBodyTypes.bubble.rawValue | PhysicsBodyTypes.edge.rawValue
        
        // TODO: Or have it fade itself in?
        bubble.run(SKAction.fadeIn(withDuration: 2.0))
        
        orchestra.playNextArrivalNote()
    }
}
