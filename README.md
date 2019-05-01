# Bubble Pond Demo

BubblePond is a work-in-progress which explores the use of physics-based interactions of 'bubbles' to trigger sound events. In this case, the bubbles are nodes in a SpriteKit scene, and they can trigger three types of sound events:

* arrival in the scene
* contact with another bubble
* departure from the scene

This demo is part of a broader set of generative music projects I'm working on which use [AudioKit](https://github.com/AudioKit/AudioKit) on iOS and tvOS, and [tone.js](https://github.com/Tonejs/Tone.js) for browser-based pieces. More to follow...


## Setting It Up

This project requires:

* Xcode 10.2
* Swift 5.0
* AudioKit 4.7

It uses [CocoaPods](https://cocoapods.org) to integrate AudioKit and other dependencies.

To take it for a spin:

* Clone the repo
* Run `pod install` using the [command line](https://guides.cocoapods.org/using/getting-started.html) or the [CocoaPods app](https://cocoapods.org/app)
* Open the `BubblePond.xcworkspace` file in Xcode, then build and run

Note that SpriteKit performance in the iOS simulator is not all that great, so running it on an actual iPhone, iPod Touch, or iPad is recommended.
