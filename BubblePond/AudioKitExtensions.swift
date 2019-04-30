// swiftlint:disable file_name
//
//  AudioKitExtensions.swift
//  BubblePond
//
//  Created by Matt Blair on 4/26/19.
//  Copyright © 2019 Elsewise. All rights reserved.
//

import Foundation
import AudioKit


/// Used to configure AKFMOscillatorBank
struct FMSynthProperties: Codable {
    
    // TODO: add enum from standard wave forms?
    
    // TODO: Annotate with defaults and sensible ranges
    
    let carrierMultiplier: Double
    let modulatingMultiplier: Double
    let modulationIndex: Double
    let vibratoDepth: Double
    let vibratoRate: Double
}

struct AmplitudeEnvelope: Codable {
    
    let attackDuration: Double
    let decayDuration: Double
    let sustainLevel: Double
    let releaseDuration: Double
}



extension AKFMOscillatorBank {
    
    func configure(properties: FMSynthProperties) {
        
        // TODO: handle optionals, coalesce defaults?
        
        carrierMultiplier = properties.carrierMultiplier
        modulatingMultiplier = properties.modulatingMultiplier
        modulationIndex = properties.modulationIndex
        vibratoDepth = properties.vibratoDepth
        vibratoRate = properties.vibratoRate
    }
    
    // TODO: generalize this as an extension to a protocol that includes all
    // sound sources with envelope properties
    func configure(envelope: AmplitudeEnvelope, humanize: Double = 0.0) {
        
        attackDuration = envelope.attackDuration
        decayDuration = envelope.decayDuration
        sustainLevel = envelope.sustainLevel
        releaseDuration = envelope.releaseDuration
    }
}
