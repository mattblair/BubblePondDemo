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


class BubblePondScene: SKScene, SKPhysicsContactDelegate {
    
    var score: BubblePondScore
    let orchestra: PondOrchestra
    
    
    private var frameCount = 0
    private var framesPerSoundEvent = 60
    
    
    //init(size: CGSize, conf: SoundPond1Config, orch: SoundPondOrchestra) {
    init?(size: CGSize, scoreName: String) {
        
        if let bpScore = BubblePondScene.loadScore(filename: scoreName) {
            score = bpScore
            orchestra = PondOrchestra(score: bpScore)
        } else {
            return nil
        }
        
        super.init(size: size)
        
        let framesPerSecond: Float = 60.0
        framesPerSoundEvent = Int((60.0 / score.tempo) * framesPerSecond)
        print("Tempo in frames: \(framesPerSoundEvent)")
        
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
        
        // TODO: Is this the right place for this?
        //orchestra.loadCurrentSamples()
    }
    
    
    // MARK: - Scene Update
    
    override func update(_ currentTime: TimeInterval) {
        
        frameCount += 1
        
        // Assumed frame rate is 60 fps
        if frameCount % 60 == 0 {
            
            let bubbles = children.compactMap { $0 as? BubbleNode }
            for bubble in bubbles { bubble.age() }
        }
        
        // TODO: read this from score
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
        guard let bubble1 = contact.bodyA.node as? BubbleNode else { return }
        guard let bubble2 = contact.bodyB.node as? BubbleNode else { return }
        
        print("\(bubble1.noteName) hit \(bubble2.noteName)")
        
        orchestra.playCollisionBetween(note1: bubble1.noteName,
                                       note2: bubble2.noteName)
    }
    
    
    // MARK: - Touch Interaction
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches { addBubbleNodeAt(point: touch.location(in: self)) }
        
        // TODO: detect taps on bubbles, too...
    }
    
    
    // MARK: - Configuration
    
    static func loadScore(filename: String) -> BubblePondScore? {
        
        // TODO: change score names to .bpscore
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
                print("Failed to parse playlist: \(error)")
            }
            
        } else {
            print("Couldn't find playlist json file")
        }
        return nil
    }
    
    
    // MARK: - Adding New Bubbles
    
    // TODO: derive from score
    func screenFactor() -> ClosedRange<Float> {
        return 3.0...4.0
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
        
        // swiftlint:disable:next identifier_name
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
    
    // TODO: limit the number of iterations, making return value optional, or a Result?
    func emptyPositionOnScreen() -> Result<CGPoint, PondError> {
        
        var point: CGPoint = .zero
        var positionIsEmpty: Bool = false
        
        var attempts = 0
        let maxAttempts = 10
        
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
        
        // TODO: return earlier?
        return .success(point)
    }
    
    func shouldAddBubble() -> Bool {
        
        let bubbles = children.compactMap { $0 as? BubbleNode }
        print("Bubble count: \(bubbles.count)")
        
        if bubbles.count >= score.maxBubbleCount {
            return false
        }
        
        // check min here,too?
        
        // TODO: return false if there is no empty space?
        
        return true
    }
    
    func addBubbleNodeAt(point: CGPoint) {
        
        guard shouldAddBubble() else { return }
        
        // pull this from score
        //let bubble = BubbleNode(noteName: noteNames.randomElement() ?? "C4",
        let bubble = BubbleNode(noteName: score.randomCollisionNoteName(),
                                diameter: bubbleDiameter(factor: randomScreenFraction()),
                                duration: score.randomLifeDuration())
        bubble.position = point
        bubble.alpha = 0.0 // move inside BubbleNode if it handles its own fade
        
        // TODO: configure lifeDuration and action sequence here?
        // Or inside node?
        
        self.addChild(bubble)
        
        // TODO: Did you do physics here because it has to be part of a scene first?
        
        //let physicsRadius = max(n.frame.size.width / 2, n.frame.size.height / 2) * 0.8
        
        // TODO: Turn this into an instance method on node
        let physicsRadius = max(bubble.frame.size.width / 2, bubble.frame.size.height / 2) * 0.8
        bubble.physicsBody = SKPhysicsBody(circleOfRadius: physicsRadius)
        
        //bubble.physicsBody?.velocity = randomVector(deviatingBy: visualConfig.maxInitialVelocity)
        
        let dx = Float.random(in: -20.0...20.0)
        let dy = Float.random(in: -20.0...20.0)
        print("Initial vector: \(dx), \(dy)")
        
        bubble.physicsBody?.velocity = CGVector(dx: CGFloat(dx),
                                                dy: CGFloat(dy))
        
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
