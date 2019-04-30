//
//  PondOrchestra.swift
//  BubblePond
//
//  Created by Matt Blair on 4/22/19.
//  Copyright © 2019 Elsewise. All rights reserved.
//

import AudioKit
import MusicTheorySwift


enum SamplerError: Error {
    case fileNotFound
    case fileNotReadable
}


class PondOrchestra {
    
    var score: BubblePondScore
    
    // TODO: make sure these values are reset when score changes
    var arrivalNoteIndex = 0
    var departureNoteIndex = 0
    
    let arrivalFM = AKFMOscillatorBank()
    let departureFM = AKFMOscillatorBank()
    
    let collisionBells = AKTubularBells()
    let collisionRhodes = AKRhodesPiano()
    
    // DEPRECATED?
    var activeArrivalNotes = [MIDINoteNumber]()
    var activeCollisionNotes = [MIDINoteNumber]()
    var activeDepartureNotes = [MIDINoteNumber]()
    
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
        
        configureFMSynths()
        
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
    
    // TODO: Call this after score changes
    func configureFMSynths() {
        
        // TODO: load synth config from score
        
        fadeInFM.carrierMultiplier = 2.0
        fadeInFM.configure(envelope: score.fadeInEnvelope)
        
        fadeOutFM.carrierMultiplier = 1.0
        fadeOutFM.configure(envelope: score.fadeOutEnvelope)
    }
    
    
    // MARK: - Playback
    
    func nextArrivalNoteName() -> String {
        
        if arrivalNoteIndex >= score.arrivalNoteNames.count {
            arrivalNoteIndex = 0
        }
        
        let noteName = score.arrivalNoteNames[arrivalNoteIndex]
        
        print("Fading in with \(noteName)")
        
        arrivalNoteIndex += 1
        
        return noteName
    }
    
    func playFM(synth: AKFMOscillatorBank, noteName: String, velocity: MIDIVelocity, duration: TimeInterval) {
        
        let noteNumber = MIDINoteNumber(Pitch(stringLiteral: noteName).rawValue)
        synth.play(noteNumber: noteNumber, velocity: velocity)
        
        // TODO: specify different qos?
        //DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, qos: .userInteractive, flags: []) {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            
            synth.stop(noteNumber: noteNumber)
        }
    }
    
    // DEPRECATED
    func playArrival(note noteName: String) {
        
        print("Playing fade in at \(noteName)")
        
        // name this as noteNumber?
        let midiNumber = MIDINoteNumber(Pitch(stringLiteral: noteName).rawValue)
        let velocity: MIDIVelocity = UInt8(Int.random(in: 20...120))
        
        //fadeInSampler.play(noteNumber: midiNumber,
        //                   velocity: velocity)
        
        activeArrivalNotes.append(midiNumber)
        print("Arrival notes: \(activeArrivalNotes)")
        arrivalFM.play(noteNumber: midiNumber, velocity: velocity)
        
        // Schedule stopping point -- track notes outside closure?
        // different qos?
        //DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, qos: .userInteractive, flags: []) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if let activeNotes = self?.activeArrivalNotes,
                activeNotes.count > 0,
                let noteNumber = self?.activeArrivalNotes.removeFirst() {
                
                print("Active fade in notes before stopping: \(activeNotes)")
                print("Now stopping: \(noteNumber)")
                self?.arrivalFM.stop(noteNumber: noteNumber)
            } else {
                print("Failure to find note for stopping process")
            }
        }
    }
    
    func playNextArrivalNote() {
        
        //playFadeIn(note: nextArrivalNoteName())
        playFM(synth: arrivalFM,
               noteName: nextArrivalNoteName(),
               velocity: UInt8(Int.random(in: 20...120)),
               duration: 1.0)
    }
    
    
    func playCollisionBetween(note1: String, note2: String) {
        
        let note1Number = MIDINoteNumber(Pitch(stringLiteral: note1).rawValue)
        let note2Number = MIDINoteNumber(Pitch(stringLiteral: note2).rawValue)
        
        collisionBells.trigger(frequency: note1Number.midiNoteToFrequency(),
                               amplitude: Double.random(in: 0.2...0.6))
        
        if note1Number != note2Number {
            
            collisionRhodes.trigger(frequency: note2Number.midiNoteToFrequency(),
                                    amplitude: Double.random(in: 0.2...0.6))
        }
    }
    
    func nextDepartureNoteName() -> String {
        
        if departureNoteIndex >= score.departureNoteNames.count {
            departureNoteIndex = 0
        }
        
        let noteName = score.departureNoteNames[departureNoteIndex]
        
        print("Fading out with \(noteName)")
        
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
               velocity: UInt8(Int.random(in: 20...120)),
               duration: 1.2)
    }
}
