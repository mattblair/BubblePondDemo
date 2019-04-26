//
//  BubblePondScore.swift
//  BubblePond
//
//  Created by Matt Blair on 4/26/19.
//  Copyright © 2019 Elsewise. All rights reserved.
//

import Foundation


/// Used to load .bpscore files
struct BubblePondScore: Codable {
    
    let name: String
    
    
    // TODO: FM configurations for fade in and fade out synths
    let fadeInEnvelope: AmplitudeEnvelope
    let fadeOutEnvelope: AmplitudeEnvelope
    
    // TODO: any configuration for collision sounds
    
    // different pitch set for each audio event type
    
    let fadeInNoteNames: [String]
    let collision1NoteNames: [String]
    let collision2NoteNames: [String]
    let fadeOutNoteNames: [String]
    
    // TODO: ground hum params
    
    let imageNames: [String]
    
    // in beats per minute
    let tempo: Float
    
    let minBubbleCount: Int
    let maxBubbleCount: Int
    
    // in seconds
    let minBubbleAge: Int
    let maxBubbleAge: Int
    
    
    // MARK: - Randomness Convenience Methods
    
    func randomLifeDuration() -> Int {
        return Int.random(in: minBubbleAge...maxBubbleAge)
    }
    
    func randomCollisionNoteName() -> String {
        return collision1NoteNames.randomElement() ?? "C4"
    }
}
