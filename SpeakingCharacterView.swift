//
//  SpeakingCharacterView.swift
//  CocoaSpeechSynthesisExample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/7/15.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 The custom view holding the speaking character.
 */

import Cocoa


// Expression Identifiers
enum CharacterExpressionIdentifier: String {
    case Sleep = "ExpressionIdentifierSleep"
    case Idle = "ExpressionIdentifierIdle"
    
    case Consonant = "ExpressionIdentifierConsonant"
    case Vowel = "ExpressionIdentifierVowel"
}

// Frame dictionary keys
enum CharacterExpressionFrame: String {
    case DurationKey = "FrameDuration";   // TimeInterval
    case ImageFileNameKey = "FrameImageFileName"
}

@objc(SpeakingCharacterView)
class SpeakingCharacterView: NSView {
    private var _currentExpression: CharacterExpressionIdentifier!
    private var _idleStartTimer: NSTimer?
    private var _expressionFrameTimer: NSTimer?
    private var _curFrameIndex: Int = 0
    private var _curFrameArray: [[String : AnyObject]] = []
    private var _curFrameImage: NSImage!
    private var _characterDescription: NSDictionary!
    private var _imageCache: [String: NSImage] = [:]
    
    
    //MARK: -
    
    /*----------------------------------------------------------------------------------------
    initWithFrame:
    
    Our designated initializer.  We load the default character and set the expression to sleep.
    ----------------------------------------------------------------------------------------*/
    override init(frame: NSRect) {
        super.init(frame: frame)
        self.loadChacaterByName("Buster")
        self.setExpression(.Sleep)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*----------------------------------------------------------------------------------------
    initWithFrdrawRectame:
    
    Our main draw routine.
    ----------------------------------------------------------------------------------------*/
    override func drawRect(rect: NSRect) {
        var thePointToDraw = NSPoint()
        let sourceSize = _curFrameImage.size
        let destSize = rect.size
        
        if destSize.width >= sourceSize.width {
            thePointToDraw.x = (destSize.width - sourceSize.width) / 2
        } else {
            thePointToDraw.x = 0
        }
        if destSize.height >= sourceSize.height {
            thePointToDraw.y = (destSize.height - sourceSize.height) / 2
        } else {
            thePointToDraw.y = 0
        }
        
        _curFrameImage!.drawAtPoint(thePointToDraw, fromRect: NSZeroRect, operation: .CompositeSourceOver, fraction: 1.0)
    }
    
    /*----------------------------------------------------------------------------------------
    setExpressionForPhoneme:
    
    Sets the current expression to the expression corresponding to the given phoneme ID.
    ----------------------------------------------------------------------------------------*/
    func setExpressionForPhoneme(phoneme: NSNumber) {
        let phonemeValue = phoneme.shortValue
        
        if phonemeValue == 0 || phonemeValue == 1 {
            self.setExpression(.Idle)
        } else if phonemeValue >= 2 && phonemeValue <= 17 {
            self.setExpression(.Vowel)
        } else {
            self.setExpression(.Consonant)
        }
    }
    
    /*----------------------------------------------------------------------------------------
    setExpression:
    
    Sets the current expression to the named expresison identifier, then forces the
    character image on screen to be updated.
    ----------------------------------------------------------------------------------------*/
    func setExpression(expression: CharacterExpressionIdentifier) {
        // Set up to begin animating the frames
        _expressionFrameTimer?.invalidate()
        _expressionFrameTimer = nil
        _currentExpression = expression
        _curFrameArray = _characterDescription[_currentExpression.rawValue]! as! [[String : AnyObject]]
        _curFrameIndex = 0
        self.animateNextExpressionFrame()
        // If the expression we just set is NOT the idle or sleep expression, then set up the idle start timer.
        if !(expression == .Idle ||
            expression == .Sleep) {
                _idleStartTimer?.invalidate()
                _idleStartTimer = NSTimer(timeInterval: 0.5,
                    target: self,
                    selector: #selector(SpeakingCharacterView.startIdleExpression),
                    userInfo: nil,
                    repeats: false
                )
        } else {
            _idleStartTimer?.invalidate()
            _idleStartTimer = nil
        }
    }
    
    /*----------------------------------------------------------------------------------------
    animateNextExpressionFrame
    
    Determines the next frame to animate, loads the image and forces it to be drawn.  If
    the expression contains multiple frames, sets up timer for the next frame to be drawn.
    ----------------------------------------------------------------------------------------*/
    func animateNextExpressionFrame() {
        _expressionFrameTimer = nil
        
        guard _curFrameArray.count > 0 else {return} //###
        let frameDictionary = _curFrameArray[_curFrameIndex]
        
        // Grab image and force draw.  Use cache to reduce disk hits
        let frameImageName = frameDictionary[CharacterExpressionFrame.ImageFileNameKey.rawValue] as! String
        _curFrameImage = _imageCache[frameImageName]
        if _curFrameImage == nil {
            _curFrameImage = NSImage(contentsOfFile: NSBundle.mainBundle().pathForResource(frameImageName, ofType: "")!)
            _imageCache[frameImageName] = _curFrameImage
        }
        
        self.display()
        // If there is more than one frame, then schedule drawing of the next and increment our frame index.
        if _curFrameArray.count > 1/*### 0*/ {
            _curFrameIndex += 1
            _curFrameIndex %= _curFrameArray.count
            _expressionFrameTimer =
                NSTimer(timeInterval: frameDictionary[CharacterExpressionFrame.DurationKey.rawValue] as! NSTimeInterval,
                    target: self,
                    selector:
                    #selector(SpeakingCharacterView.animateNextExpressionFrame),
                    userInfo: nil,
                    repeats: false)
        }
    }
    
    /*----------------------------------------------------------------------------------------
    startIdleExpression
    
    Starts the idle expression.  Called by the idle timer after certain expressions (mainly
    phoneme expressions) expire.
    ----------------------------------------------------------------------------------------*/
    @objc private func startIdleExpression() {
        _idleStartTimer = nil
        
        self.setExpression(.Idle)
    }
    
    /*----------------------------------------------------------------------------------------
    loadChacaterByName:
    
    Loads description dictionary for the named character and flushes any cached images.
    ----------------------------------------------------------------------------------------*/
    private func loadChacaterByName(name: String) {
        _characterDescription = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource(name, ofType: "plist")!)
    }
    
}