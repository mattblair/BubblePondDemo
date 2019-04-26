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


struct AmplitudeEnvelope: Codable {
    
    let attackDuration: Double
    let decayDuration: Double
    let sustainLevel: Double
    let releaseDuration: Double
}

// TODO: generalize this as an extension to a protocol that includes all
// sound sources with envelope properties

extension AKFMOscillatorBank {
    
    func configure(envelope: AmplitudeEnvelope, humanize: Double = 0.0) {
        
        attackDuration = envelope.attackDuration
        decayDuration = envelope.decayDuration
        sustainLevel = envelope.sustainLevel
        releaseDuration = envelope.releaseDuration
    }
}
