//
//  PondOrchestra.swift
//  BubblePond
//
//  Created by Matt Blair on 4/22/19.
//  Copyright © 2019 Elsewise. All rights reserved.
//

import AudioKit
import MusicTheorySwift


public extension Notification.Name {
    
    static let SoundcheckRequested = NSNotification.Name("SoundcheckRequested")
}

enum SoundcheckAudioSource: String {
    
    static let sourceKey: String = "sourceKey"
    
    case arrival, collisionBells, collisionRhodes, departure
}


class PondOrchestra {
    
    /// Should call configureForScore() after setting
    ///
    /// Note: decided against a setter here, because of timing of audio graph
    /// changes when changing score.
    var score: BubblePondScore
    
    var arrivalNoteIndex = 0
    var departureNoteIndex = 0
    
    let arrivalFM = AKFMOscillatorBank()
    let departureFM = AKFMOscillatorBank()
    
    let collisionBells = AKTubularBells()
    let collisionRhodes = AKRhodesPiano()
    
    var mainMixer: AKMixer
    var booster: AKBooster
    var reverb: AKCostelloReverb
    var reverbMixer: AKDryWetMixer
    
    
    init(score pondScore: BubblePondScore) {
        
        score = pondScore
        
        AKSettings.bufferLength = .medium
        AKSettings.enableLogging = false
        
        // Allow audio to play while the iOS device is muted.
        AKSettings.playbackWhileMuted = true
        
        do {
            try AKSettings.setSession(category: .playAndRecord,
                                      with: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
        } catch {
            AKLog("Could not set session category.")
        }
        
        mainMixer = AKMixer(arrivalFM, departureFM, collisionBells, collisionRhodes)
        
        mainMixer.volume = 0.8
        
        booster = AKBooster(mainMixer, gain: 1.2)
        booster.start()
        
        // TODO: Directly output reverb? Or use one with built-in wet/dry mix?
        reverb = AKCostelloReverb(booster)
        reverb.feedback = 0.8
        
        reverbMixer = AKDryWetMixer(booster, reverb, balance: 0.5)
        
        AudioKit.output = reverbMixer
        
        configureForScore()
        
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit failed to start")
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDeparture),
                                               name: .BubbleWillFade,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSoundcheckRequest),
                                               name: .SoundcheckRequested,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleBackgrounding),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleBecomingActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    @objc
    private func handleBackgrounding() {
            
        print("Stopping AudioKit")
        do {
            try AudioKit.stop()
        } catch {
            print("AudioKit failed to stop")
        }
    }
    
    @objc
    private func handleBecomingActive() {
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit failed to start")
        }
    }
    
    
    // MARK: - Configure Sound Sources
    
    func configureForScore() {
        
        stopAllNotes()
        
        arrivalNoteIndex = 0
        departureNoteIndex = 0
        
        configureFMSynths()
    }
    
    func configureFMSynths() {
        
        // all of these values default to 1.0
        print("cm: \(arrivalFM.carrierMultiplier)")
        print("mm: \(arrivalFM.modulatingMultiplier)")
        print("mi: \(arrivalFM.modulationIndex)")
        
        // both of these default to 0.0
        print("vd: \(arrivalFM.vibratoDepth)")
        print("vr: \(arrivalFM.vibratoRate)")
        
        arrivalFM.configure(properties: score.arrivalSynthProperties)
        arrivalFM.configure(envelope: score.arrivalEnvelope)
        
        departureFM.configure(properties: score.departureSynthProperties)
        departureFM.configure(envelope: score.departureEnvelope)
    }
    
    
    // MARK: - Playback
    
    func nextArrivalNoteName() -> String {
        
        if arrivalNoteIndex >= score.arrivalNoteNames.count {
            arrivalNoteIndex = 0
        }
        
        let noteName = score.arrivalNoteNames[arrivalNoteIndex]
        
        print("Arriving with \(noteName)")
        
        arrivalNoteIndex += 1
        
        return noteName
    }
    
    func playFM(synth: AKFMOscillatorBank, noteName: String, velocity: MIDIVelocity, duration: TimeInterval) {
        
        // Temporary fix for conversion from uppercase notenames via Pitch
        let pitch = Pitch(stringLiteral: noteName.lowercased())
        print("Pitch is \(pitch)")
        let noteNumber = MIDINoteNumber(pitch.rawValue)
        print("Playing \(noteName) (\(noteNumber)) @ velocity \(velocity)")
        synth.play(noteNumber: noteNumber, velocity: velocity)
        
        // TODO: specify different qos?
        //DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, qos: .userInteractive, flags: []) {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            
            synth.stop(noteNumber: noteNumber)
        }
    }
    
    func playNextArrivalNote() {
        
        playFM(synth: arrivalFM,
               noteName: nextArrivalNoteName(),
               velocity: score.randomArrivalVelocity(),
               duration: score.randomArrivalDuration())
    }
    
    func playCollision1(note: String) {
        let noteNumber = MIDINoteNumber(Pitch(stringLiteral: note.lowercased()).rawValue)
        collisionBells.trigger(frequency: noteNumber.midiNoteToFrequency(),
                               amplitude: score.randomCollision1Amplitude())
    }
    
    func playCollision2(note: String) {
        let noteNumber = MIDINoteNumber(Pitch(stringLiteral: note.lowercased()).rawValue)
        collisionRhodes.trigger(frequency: noteNumber.midiNoteToFrequency(),
                                amplitude: score.randomCollision2Amplitude())
    }
    
    func playCollisionBetween(note1: String, note2: String) {
        
        // TODO: convenience method to make this less ugly...
        let note1Number = MIDINoteNumber(Pitch(stringLiteral: note1.lowercased()).rawValue)
        let note2Number = MIDINoteNumber(Pitch(stringLiteral: note2.lowercased()).rawValue)
        
        collisionBells.trigger(frequency: note1Number.midiNoteToFrequency(),
                               amplitude: score.randomCollision1Amplitude())
        
        /*
        // TODO: or play same note on both instruments?
        if note1Number != note2Number {
            
            collisionRhodes.trigger(frequency: note2Number.midiNoteToFrequency(),
                                    amplitude: score.randomCollision2Amplitude())
        }
        */
        
        // Always play the second note:
        collisionRhodes.trigger(frequency: note2Number.midiNoteToFrequency(),
                                amplitude: score.randomCollision2Amplitude())
    }
    
    func nextDepartureNoteName() -> String {
        
        if departureNoteIndex >= score.departureNoteNames.count {
            departureNoteIndex = 0
        }
        
        let noteName = score.departureNoteNames[departureNoteIndex]
        
        print("Departing with \(noteName)")
        
        departureNoteIndex += 1
        
        return noteName
    }
    
    @objc
    private func handleDeparture(note: Notification) {
        
        // Use this if you need to extract fade out note from notification:
        /*
        if let noteName = note.userInfo?[BubbleNode.noteNameKey] as? String {
            playFadeOut(noteName: noteName)
        }
        */
        
        playFM(synth: departureFM,
               noteName: nextDepartureNoteName(),
               velocity: score.randomDepartureVelocity(),
               duration: score.randomDepartureDuration())
    }
    
    
    // MARK: - Pause
    
    private func stopAllNotes() {
        
        for note: UInt8 in 0...127 {
            arrivalFM.stop(noteNumber: note)
            departureFM.stop(noteNumber: note)
        }
        
        collisionBells.stop()
        collisionRhodes.stop()
    }
    
    
    // MARK: - Soundcheck
    
    @objc
    func handleSoundcheckRequest(note: NSNotification) {
        
        if let source = note.userInfo?[SoundcheckAudioSource.sourceKey] as? SoundcheckAudioSource {
            
            var noteNames: [String]
            
            switch source {
            case .arrival:
                noteNames = score.arrivalNoteNames
            case .collisionBells:
                noteNames = score.collision1NoteNames
            case .collisionRhodes:
                noteNames = score.collision2NoteNames
            case .departure:
                noteNames = score.departureNoteNames
            }
            
            let interval: TimeInterval = 2.0
            var delay: TimeInterval = 0
            
            for noteName in noteNames {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    
                    switch source {
                    case .arrival, .departure:
                        
                        let synth = source == .arrival ? self.arrivalFM : self.departureFM
                        
                        self.playFM(synth: synth,
                               noteName: noteName,
                               velocity: self.score.randomDepartureVelocity(),
                               duration: self.score.randomDepartureDuration())
                    case .collisionBells:
                        self.playCollision1(note: noteName)
                    case .collisionRhodes:
                        self.playCollision2(note: noteName)
                    }
                }
                
                delay += interval
            }
        }
    }
}
