//
//  BubblePondScore.swift
//  BubblePond
//
//  Created by Matt Blair on 4/26/19.
//  Copyright © 2019 Elsewise. All rights reserved.
//

import Foundation
import CoreGraphics


/// Used to load .bpscore files
struct BubblePondScore: Codable {
    
    let name: String
    
    let arrivalSynthProperties: FMSynthProperties
    let arrivalEnvelope: AmplitudeEnvelope
    let arrivalVelocityRange: ClosedRange<Int>
    let arrivalDurationRange: ClosedRange<Double>
    
    // TODO: any configuration for collision sounds
    let collision1AmplitudeRange: ClosedRange<Double>
    let collision2AmplitudeRange: ClosedRange<Double>
    
    let departureSynthProperties: FMSynthProperties
    let departureEnvelope: AmplitudeEnvelope
    let departureVelocityRange: ClosedRange<Int>
    let departureDurationRange: ClosedRange<Double>
    
    // different pitch set for each audio event type
    
    let arrivalNoteNames: [String]
    let collision1NoteNames: [String]
    let collision2NoteNames: [String]
    let departureNoteNames: [String]
    
    // TODO: ground hum params
    
    let imageNames: [String]
    let screenDivisorRange: ClosedRange<Float>
    let physicsRadiusMultiplier: Float
    let velocityXRange: ClosedRange<Float>
    let velocityYRange: ClosedRange<Float>
    
    /// Defined in beats per minute.
    let tempo: Float
    
    let bubbleCountRange: ClosedRange<Int>
    
    let bubbleAgeRange: ClosedRange<Int>
    
    
    // MARK: - Random Behavior Methods
    
    // In seconds.
    func randomLifeDuration() -> Int {
        return Int.random(in: bubbleAgeRange)
    }
    
    func randomInitialVelocity() -> CGVector {
        
        let dx = Float.random(in: velocityXRange)
        let dy = Float.random(in: velocityYRange)
        
        return CGVector(dx: CGFloat(dx), dy: CGFloat(dy))
    }
    
    
    // MARK: - Random Audio Methods
    
    func randomArrivalVelocity() -> UInt8 {
        return UInt8(Int.random(in: arrivalVelocityRange))
    }
    
    func randomArrivalDuration() -> TimeInterval {
        return Double.random(in: arrivalDurationRange)
    }
    
    func randomDepartureVelocity() -> UInt8 {
        return UInt8(Int.random(in: departureVelocityRange))
    }
    
    func randomDepartureDuration() -> TimeInterval {
        return Double.random(in: departureDurationRange)
    }
    
    func randomCollisionNoteName() -> String {
        return collision1NoteNames.randomElement() ?? "C4"
    }
    
    func randomCollision1Amplitude() -> Double {
        return Double.random(in: collision1AmplitudeRange)
    }
    
    func randomCollision2Amplitude() -> Double {
        return Double.random(in: collision2AmplitudeRange)
    }
}
