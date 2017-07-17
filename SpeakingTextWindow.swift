//
//  SpeakingTextWindow.swift
//  CocoaSpeechSynthesisExample
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/7/18.
//
//
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 The main window hosting all the apps speech features.
 */

import Cocoa

typealias SRefCon = UnsafeRawPointer

private let kWordCallbackParamPosition = "ParamPosition"
private let kWordCallbackParamLength = "ParamLength"

@objc(SpeakingTextWindow)
class SpeakingTextWindow: NSDocument {
    
    
    // Main window outlets
    @IBOutlet private var fWindow: NSWindow!
    @IBOutlet private var fSpokenTextView: NSTextView!
    @IBOutlet private var fStartStopButton: NSButton!
    @IBOutlet private var fPauseContinueButton: NSButton!
    @IBOutlet private var fSaveAsFileButton: NSButton!
    
    // Options panel outlets
    @IBOutlet private var fImmediatelyRadioButton: NSButton!
    @IBOutlet private var fAfterWordRadioButton: NSButton!
    @IBOutlet private var fAfterSentenceRadioButton: NSButton!
    @IBOutlet private var fVoicesPopUpButton: NSPopUpButton!
    @IBOutlet private var fCharByCharCheckboxButton: NSButton!
    @IBOutlet private var fDigitByDigitCheckboxButton: NSButton!
    @IBOutlet private var fPhonemeModeCheckboxButton: NSButton!
    @IBOutlet private var fDumpPhonemesButton: NSButton!
    @IBOutlet private var fUseDictionaryButton: NSButton!
    
    // Parameters panel outlets
    @IBOutlet private var fRateDefaultEditableField: NSTextField!
    @IBOutlet private var fPitchBaseDefaultEditableField: NSTextField!
    @IBOutlet private var fPitchModDefaultEditableField: NSTextField!
    @IBOutlet private var fVolumeDefaultEditableField: NSTextField!
    @IBOutlet private var fRateCurrentStaticField: NSTextField!
    @IBOutlet private var fPitchBaseCurrentStaticField: NSTextField!
    @IBOutlet private var fPitchModCurrentStaticField: NSTextField!
    @IBOutlet private var fVolumeCurrentStaticField: NSTextField!
    @IBOutlet private var fResetButton: NSButton!
    
    // Callbacks panel outlets
    @IBOutlet private var fHandleWordCallbacksCheckboxButton: NSButton!
    @IBOutlet private var fHandlePhonemeCallbacksCheckboxButton: NSButton!
    @IBOutlet private var fHandleSyncCallbacksCheckboxButton: NSButton!
    @IBOutlet private var fHandleErrorCallbacksCheckboxButton: NSButton!
    @IBOutlet private var fHandleSpeechDoneCallbacksCheckboxButton: NSButton!
    @IBOutlet private var fHandleTextDoneCallbacksCheckboxButton: NSButton!
    @IBOutlet private var fCharacterView: SpeakingCharacterView!
    
    // Misc. instance variables
    private var fOrgSelectionRange: NSRange = NSRange()
    private var fSelectedVoiceID: OSType = 0
    private var fSelectedVoiceCreator: OSType = 0
    private var fCurSpeechChannel: SpeechChannel? = nil
    private var fOffsetToSpokenText: Int = 0
    private var fLastErrorCode: Int = 0
    private var fLastSpeakingValue: Bool = false
    private var fLastPausedValue: Bool = false
    private var fCurrentlySpeaking: Bool = false
    private var fCurrentlyPaused: Bool = false
    private var fSavingToFile: Bool = false
    private var fTextData: Data!
    private let fErrorFormatString: String = NSLocalizedString("Error #%d (0x%0X) returned.", comment: "Error #%d (0x%0X) returned.")
    
    // Getters/Setters
    private var textDataType: String = ""
    
    
    //MARK: - Constants
    
    private let kPlainTextDataTypeString = "Plain Text"
    private let kDefaultWindowTextString = "Welcome to Cocoa Speech Synthesis Example. " +
    "This application provides an example of using Apple's speech synthesis technology in a Cocoa-based application."
    
    private let kErrorCallbackParamPosition = "ParamPosition"
    private let kErrorCallbackParamError = "ParamError"
    
    @objc(_getValue:forType:)
    func getValue(val: Any, forType type: Any) {
        Swift.print(val, type)
    }
    
    //MARK: - Prototypes
    
    
    //MARK: -
    
    /*----------------------------------------------------------------------------------------
     init
     
     Set the default text of the window.
     ----------------------------------------------------------------------------------------*/
    override init() {
        super.init()
        // set our default window text
        self.textData = kDefaultWindowTextString.data(using: .utf8)!
        self.textDataType = kPlainTextDataTypeString
        
    }
    
    /*----------------------------------------------------------------------------------------
     close
     
     Make sure to stop speech when closing.
     ----------------------------------------------------------------------------------------*/
    override func close() {
        self.startStopButtonPressed(fStartStopButton)
    }
    
    /*----------------------------------------------------------------------------------------
     setTextData:
     
     Set our text data variable and update text in window if showing.
     ----------------------------------------------------------------------------------------*/
    private var textData: Data {
        set(theData) {
            fTextData = theData
            // If the window is showing, update the text view.
            if fSpokenTextView != nil {
                if self.textDataType == "RTF Document" {
                    fSpokenTextView.replaceCharacters(in: NSRange(0..<fSpokenTextView.string.utf16.count), withRTF: self.textData)
                } else {
                    fSpokenTextView.replaceCharacters(in: NSRange(0..<fSpokenTextView.string.utf16.count),
                                                      with: String(data: self.textData, encoding: .utf8)!)
                }
            }
        }
        
        /*----------------------------------------------------------------------------------------
         textData
         
         Returns autoreleased copy of text data.
         ----------------------------------------------------------------------------------------*/
        get {
            return fTextData
        }
    }
    
    /*----------------------------------------------------------------------------------------
     setTextDataType:
     
     Set our text data type variable.
     ----------------------------------------------------------------------------------------*/
    //- (void)setTextDataType:(NSString *)theType {
    //    fTextDataType = theType;
    //} // setTextDataType
    //
    /*----------------------------------------------------------------------------------------
     textDataType
     
     Returns autoreleased copy of text data.
     ----------------------------------------------------------------------------------------*/
    //- (NSString *)textDataType {
    //    return ([fTextDataType copy]);
    //}
    
    /*----------------------------------------------------------------------------------------
     textDataType
     
     Returns reference to character view for callbacks.
     ----------------------------------------------------------------------------------------*/
    fileprivate var characterView: SpeakingCharacterView! {
        return fCharacterView
    }
    
    /*----------------------------------------------------------------------------------------
     shouldDisplayWordCallbacks
     
     Returns true if user has chosen to have words hightlight during synthesis.
     ----------------------------------------------------------------------------------------*/
    fileprivate var shouldDisplayWordCallbacks: Bool {
        return fHandleWordCallbacksCheckboxButton.intValue != 0
    }
    
    /*----------------------------------------------------------------------------------------
     shouldDisplayPhonemeCallbacks
     
     Returns true if user has chosen to the character animate phonemes during synthesis.
     ----------------------------------------------------------------------------------------*/
    fileprivate var shouldDisplayPhonemeCallbacks: Bool {
        return fHandlePhonemeCallbacksCheckboxButton.intValue != 0
    }
    
    /*----------------------------------------------------------------------------------------
     shouldDisplayErrorCallbacks
     
     Returns true if user has chosen to have an alert appear in response to an error callback.
     ----------------------------------------------------------------------------------------*/
    fileprivate var shouldDisplayErrorCallbacks: Bool {
        return fHandleErrorCallbacksCheckboxButton.intValue != 0
    }
    
    /*----------------------------------------------------------------------------------------
     shouldDisplaySyncCallbacks
     
     Returns true if user has chosen to have an alert appear in response to an sync callback.
     ----------------------------------------------------------------------------------------*/
    fileprivate var shouldDisplaySyncCallbacks: Bool {
        return fHandleSyncCallbacksCheckboxButton.intValue != 0
    }
    
    /*----------------------------------------------------------------------------------------
     shouldDisplaySpeechDoneCallbacks
     
     Returns true if user has chosen to have an alert appear when synthesis is finished.
     ----------------------------------------------------------------------------------------*/
    private var shouldDisplaySpeechDoneCallbacks: Bool {
        return fHandleSpeechDoneCallbacksCheckboxButton.intValue != 0
    }
    
    /*----------------------------------------------------------------------------------------
     shouldDisplayTextDoneCallbacks
     
     Returns true if user has chosen to have an alert appear when text processing is finished.
     ----------------------------------------------------------------------------------------*/
    fileprivate var shouldDisplayTextDoneCallbacks: Bool {
        return fHandleTextDoneCallbacksCheckboxButton.intValue != 0
    }
    
    /*----------------------------------------------------------------------------------------
     updateSpeakingControlState
     
     This routine is called when appropriate to update the Start/Stop Speaking,
     Pause/Continue Speaking buttons.
     ----------------------------------------------------------------------------------------*/
    private func updateSpeakingControlState() {
        // Update controls based on speaking state
        fSaveAsFileButton.isEnabled = !fCurrentlySpeaking
        fPauseContinueButton.isEnabled = fCurrentlySpeaking
        fStartStopButton.isEnabled = !fCurrentlyPaused
        if fCurrentlySpeaking {
            fStartStopButton.title = NSLocalizedString("Stop Speaking", comment: "Stop Speaking")
            fPauseContinueButton.title = NSLocalizedString("Pause Speaking", comment: "Pause Speaking")
        } else {
            fStartStopButton.title = NSLocalizedString("Start Speaking", comment: "Start Speaking")
            fSpokenTextView.setSelectedRange(fOrgSelectionRange);  // Set selection length to zero.
        }
        if fCurrentlyPaused {
            fPauseContinueButton.title = NSLocalizedString("Continue Speaking", comment: "Continue Speaking")
        } else {
            fPauseContinueButton.title = NSLocalizedString("Pause Speaking", comment: "Pause Speaking")
        }
        
        self.enableOptionsForSpeakingState(fCurrentlySpeaking)
        
        // update parameter fields
        var valueAsNSNumber: CFTypeRef? = nil
        if CopySpeechProperty(fCurSpeechChannel!, kSpeechRateProperty, &valueAsNSNumber) == OSErr(noErr) {
            fRateCurrentStaticField.doubleValue = valueAsNSNumber!.doubleValue!
        }
        if CopySpeechProperty(fCurSpeechChannel!, kSpeechPitchBaseProperty, &valueAsNSNumber) == OSErr(noErr) {
            fPitchBaseCurrentStaticField.doubleValue = valueAsNSNumber!.doubleValue!
        }
        if CopySpeechProperty(fCurSpeechChannel!, kSpeechPitchModProperty, &valueAsNSNumber) == OSErr(noErr) {
            fPitchModCurrentStaticField.doubleValue = valueAsNSNumber!.doubleValue!
        }
        if CopySpeechProperty(fCurSpeechChannel!, kSpeechVolumeProperty, &valueAsNSNumber) == OSErr(noErr) {
            fVolumeCurrentStaticField.doubleValue = valueAsNSNumber!.doubleValue!
        }
    }
    
    /*----------------------------------------------------------------------------------------
     highlightWordWithParams:
     
     Highlights the word currently being spoken based on text position and text length
     provided in the word callback routine.
     ----------------------------------------------------------------------------------------*/
    fileprivate func highlightWordWithRange(_ range: CFRange) {
        let selectionPosition = range.location + fOffsetToSpokenText
        let wordLength = range.length
        
        fSpokenTextView.scrollRangeToVisible(NSMakeRange(selectionPosition, wordLength))
        fSpokenTextView.setSelectedRange(NSMakeRange(selectionPosition, wordLength))
        fSpokenTextView.display()
    }
    
    /*----------------------------------------------------------------------------------------
     displayErrorAlertWithParams:
     
     Displays an alert describing a text processing error provided in the error callback.
     ----------------------------------------------------------------------------------------*/
    private func displayErrorAlertWithParams(_ params: [String: Any]) {
        let errorPosition = (params[kErrorCallbackParamPosition] as! Int) + fOffsetToSpokenText
        let errorCode = params[kErrorCallbackParamError] as! Int
        
        if errorCode != fLastErrorCode {
            var theErr = OSErr(noErr)
            
            // Tell engine to pause while we display this dialog.
            theErr = PauseSpeechAt(fCurSpeechChannel!, Int32(kImmediate))
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("PauseSpeechAt",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
            
            // Select offending character
            fSpokenTextView.setSelectedRange(NSMakeRange(errorPosition, 1))
            fSpokenTextView.display()
            
            // Display error alert, and stop or continue based on user's desires
            let messageFormat = NSLocalizedString("Error #%ld occurred at position %ld in the text.",
                                                  comment: "Error #%ld occurred at position %ld in the text.")
            let theMessageStr = String(format: messageFormat,
                                       Int(errorCode), Int(errorPosition))
            let response = self.runAlertPanelWithTitle("Text Processing Error",
                                                       message: theMessageStr,
                                                       buttonTitles: ["Stop", "Continue"])
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                self.startStopButtonPressed(fStartStopButton)
            } else {
                theErr = ContinueSpeech(fCurSpeechChannel!)
                if theErr != OSErr(noErr) {
                    self.runAlertPanelWithTitle("ContinueSpeech",
                                                message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                                buttonTitles: ["Oh?"])
                }
            }
            
            fLastErrorCode = errorCode
        }
    }
    
    /*----------------------------------------------------------------------------------------
     displaySyncAlertWithMessage:
     
     Displays an alert with information about a sync command in response to a sync callback.
     ----------------------------------------------------------------------------------------*/
    fileprivate func displaySyncAlertWithMessage(_ theMessageValue: OSType) {
        var theErr = OSErr(noErr)
        var theMessageStr = ""
        
        // Tell engine to pause while we display this dialog.
        theErr = PauseSpeechAt(fCurSpeechChannel!, Int32(kImmediate))
        if theErr != OSErr(noErr) {
            self.runAlertPanelWithTitle("PauseSpeechAt",
                                        message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                        buttonTitles: ["Oh?"])
        }
        
        // Display error alert and stop or continue based on user's desires
        //let theMessageValue = messageNumber.uint32Value
        let messageFormat = NSLocalizedString("Sync embedded command was discovered containing message %ld ('%@').",
                                              comment: "Sync embedded command was discovered containing message %ld ('%@').")
        theMessageStr = String(format: messageFormat,
                               Int(theMessageValue), theMessageValue.fourCharString)
        
        let alertButtonClicked =
            self.runAlertPanelWithTitle("Sync Callback", message: theMessageStr, buttonTitles: ["Stop", "Continue"])
        if alertButtonClicked.rawValue == 1 {
            self.startStopButtonPressed(fStartStopButton)
        } else {
            theErr = ContinueSpeech(fCurSpeechChannel!)
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("ContinueSpeech",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
        }
    }
    
    /*----------------------------------------------------------------------------------------
     speechIsDone
     
     Updates user interface and optionally displays an alert when generation of speech is
     finish.
     ----------------------------------------------------------------------------------------*/
    fileprivate func speechIsDone() {
        fCurrentlySpeaking = false
        self.updateSpeakingControlState()
        self.enableCallbackControlsBasedOnSavingToFileFlag(false)
        if self.shouldDisplaySpeechDoneCallbacks {
            self.runAlertPanelWithTitle("Speech Done",
                                        message: "Generation of synthesized speech is finished.",
                                        buttonTitles: ["OK"])
        }
    }
    
    /*----------------------------------------------------------------------------------------
     displayTextDoneAlert
     
     Displays an alert in response to a text done callback.
     ----------------------------------------------------------------------------------------*/
    fileprivate func displayTextDoneAlert() {
        var theErr = OSErr(noErr)
        
        // Tell engine to pause while we display this dialog.
        theErr = PauseSpeechAt(fCurSpeechChannel!, Int32(kImmediate))
        if theErr != OSErr(noErr) {
            self.runAlertPanelWithTitle("PauseSpeechAt",
                                        message: "Generation of synthesized speech is finished.",
                                        buttonTitles: ["OK"])
        }
        
        // Display error alert, and stop or continue based on user's desires
        let response = self.runAlertPanelWithTitle("Text Done Callback",
                                                   message: "Processing of the text has completed.",
                                                   buttonTitles: ["Stop", "Continue"])
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            self.startStopButtonPressed(fStartStopButton)
        } else {
            theErr = ContinueSpeech(fCurSpeechChannel!)
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("ContinueSpeech",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
        }
    }
    
    /*----------------------------------------------------------------------------------------
     startStopButtonPressed:
     
     An action method called when the user clicks the "Start Speaking"/"Stop Speaking"
     button.     We either start or stop speaking based on the current speaking state.
     ----------------------------------------------------------------------------------------*/
    @IBAction func startStopButtonPressed(_ sender: NSButton) {
        var theErr = OSErr(noErr)
        
        if fCurrentlySpeaking {
            var whereToStop: Int32 = 0
            
            // Grab where to stop at value from radio buttons
            if fAfterWordRadioButton.intValue != 0 {
                whereToStop = kEndOfWord
            } else if fAfterSentenceRadioButton.intValue != 0 {
                whereToStop = kEndOfSentence
            } else {
                whereToStop = kImmediate
            }
            if whereToStop == kImmediate {
                // NOTE:    We could just call StopSpeechAt with kImmediate, but for test purposes
                // we exercise the StopSpeech routine.
                theErr = StopSpeech(fCurSpeechChannel!)
                if theErr != OSErr(noErr) {
                    self.runAlertPanelWithTitle("StopSpeech",
                                                message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                                buttonTitles: ["Oh?"])
                }
            } else {
                theErr = StopSpeechAt(fCurSpeechChannel!, Int32(whereToStop))
                if theErr != OSErr(noErr) {
                    self.runAlertPanelWithTitle("StopSpeechAt",
                                                message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                                buttonTitles: ["Oh?"])
                }
            }
            
            fCurrentlySpeaking = false
            self.updateSpeakingControlState()
        } else {
            self.startSpeakingTextViewToURL(nil)
        }
    }
    
    /*----------------------------------------------------------------------------------------
     saveAsButtonPressed:
     
     An action method called when the user clicks the "Save As File" button.     We ask user
     to specify where to save the file, then start speaking to this file.
     ----------------------------------------------------------------------------------------*/
    @IBAction func saveAsButtonPressed(_ sender: Any) {
        
        let theSavePanel = NSSavePanel()
        
        theSavePanel.prompt = NSLocalizedString("Save", comment: "Save")
        theSavePanel.nameFieldStringValue = "Synthesized Speech.aiff"
        if theSavePanel.runModal() == .OK {
            let selectedFileURL = theSavePanel.url
            self.startSpeakingTextViewToURL(selectedFileURL)
        }
    }
    
    /*----------------------------------------------------------------------------------------
     startSpeakingTextViewToURL:
     
     This method sets up the speech channel and begins the speech synthesis
     process, optionally speaking to a file instead playing through the speakers.
     ----------------------------------------------------------------------------------------*/
    private func startSpeakingTextViewToURL(_ url: URL?) {
        var theErr = OSErr(noErr)
        var theViewText: String? = nil
        
        // Grab the selection substring, or if no selection then grab entire text.
        fOrgSelectionRange = fSpokenTextView.selectedRange()
        if fOrgSelectionRange.length == 0 {
            theViewText = fSpokenTextView.string
            fOffsetToSpokenText = 0
        } else {
            theViewText = (fSpokenTextView.string as NSString).substring(with: fOrgSelectionRange)
            fOffsetToSpokenText = fOrgSelectionRange.location
        }
        
        // Setup our callbacks
        fSavingToFile = (url != nil)
        if theErr == OSErr(noErr) {
            typealias ErrorCFCallBackType = @convention(c) (SpeechChannel, SRefCon, CFError?)->Void
            let callback = fSavingToFile ? nil: OurErrorCFCallBackProc as ErrorCFCallBackType?
            let callbackAddr = unsafeBitCast(callback, to: UInt.self) as CFNumber
            theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechErrorCFCallBack,
                                       callbackAddr)
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("SetSpeechProperty(kSpeechErrorCFCallBack)",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
        }
        if theErr == OSErr(noErr) {
            typealias PhonemeCallBackType = @convention(c) (SpeechChannel, SRefCon, Int16)->Void
            let callback = fSavingToFile ? nil: OurPhonemeCallBackProc as PhonemeCallBackType?
            let callbackAddr = unsafeBitCast(callback, to: UInt.self) as CFNumber
            theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechPhonemeCallBack,
                                       callbackAddr)
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("SetSpeechProperty(kSpeechPhonemeCallBack)",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
        }
        if theErr == OSErr(noErr) {
            typealias DoneCallBackType = @convention(c) (SpeechChannel, SRefCon)->Void
            let callback = fSavingToFile ? nil: OurSpeechDoneCallBackProc as DoneCallBackType?
            let callbackAddr = unsafeBitCast(callback, to: UInt.self) as CFNumber
            theErr = SetSpeechProperty(fCurSpeechChannel!,
                                       kSpeechSpeechDoneCallBack,
                                       callbackAddr)
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("SetSpeechProperty(kSpeechSpeechDoneCallBack)",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
        }
        if theErr == OSErr(noErr) {
            typealias SyncCallBackType = @convention(c) (SpeechChannel, SRefCon, OSType)->Void
            let callback = fSavingToFile ? nil: OurSyncCallBackProc as SyncCallBackType?
            let callbackAddr = unsafeBitCast(callback, to: UInt.self) as CFNumber
            theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechSyncCallBack,
                                       callbackAddr)
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("SetSpeechProperty(kSpeechSyncCallBack)",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
        }
        if theErr == OSErr(noErr) {
            typealias TextDoneCallBackType = @convention(c) (SpeechChannel, SRefCon, UnsafeMutablePointer<UnsafeRawPointer?>, UnsafePointer<UInt>, UnsafePointer<Int>)->Void
            let callback = fSavingToFile ? nil: OurTextDoneCallBackProc as TextDoneCallBackType?
            let callbackAddr = unsafeBitCast(callback, to: UInt.self) as CFNumber
            theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechTextDoneCallBack,
                                       callbackAddr)
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("SetSpeechProperty(kSpeechTextDoneCallBack)",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
        }
        if theErr == OSErr(noErr) {
            typealias WordCFCallBackType = @convention(c) (SpeechChannel, SRefCon, CFString, CFRange)->Void
            let callback = fSavingToFile ? nil: OurWordCFCallBackProc as WordCFCallBackType?
            let callbackAddr = unsafeBitCast(callback, to: UInt.self) as CFNumber
            theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechWordCFCallBack,
                                       callbackAddr)
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("SetSpeechProperty(kSpeechWordCFCallBack)",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
        }
        
        // Set URL to save file to disk
        SetSpeechProperty(fCurSpeechChannel!, kSpeechOutputToFileURLProperty, url as CFURL?)
        
        // Convert NSString to cString.
        // We want the text view the active view.  Also saves any parameters currently being edited.
        fWindow.makeFirstResponder(fSpokenTextView)
        
        theErr = SpeakCFString(fCurSpeechChannel!, theViewText! as CFString, nil)
        if theErr == OSErr(noErr) {
            // Update our vars
            fLastErrorCode = 0
            fLastSpeakingValue = false
            fLastPausedValue = false
            fCurrentlySpeaking = true
            fCurrentlyPaused = false
            self.updateSpeakingControlState()
        } else {
            self.runAlertPanelWithTitle("SpeakText",
                                        message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                        buttonTitles: ["Oh?"])
        }
        
        self.enableCallbackControlsBasedOnSavingToFileFlag(fSavingToFile)
    }
    
    /*----------------------------------------------------------------------------------------
     pauseContinueButtonPressed:
     
     An action method called when the user clicks the "Pause Speaking"/"Continue Speaking"
     button.     We either pause or continue speaking based on the current speaking state.
     ----------------------------------------------------------------------------------------*/
    @IBAction func pauseContinueButtonPressed(_ sender: Any) {
        var theErr = OSErr(noErr)
        
        if fCurrentlyPaused {
            // We want the text view the active view.  Also saves any parameters currently being edited.
            fWindow.makeFirstResponder(fSpokenTextView)
            
            theErr = ContinueSpeech(fCurSpeechChannel!)
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("ContinueSpeech",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
            
            fCurrentlyPaused = false
            self.updateSpeakingControlState()
        } else {
            var whereToPause: Int32 = 0
            
            // Figure out where to stop from radio buttons
            if fAfterSentenceRadioButton.intValue != 0 {
                whereToPause = kEndOfWord
            } else if fAfterSentenceRadioButton.intValue != 0 {
                whereToPause = kEndOfSentence
            } else {
                whereToPause = kImmediate
            }
            
            theErr = PauseSpeechAt(fCurSpeechChannel!, Int32(whereToPause))
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("PauseSpeechAt",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
            
            fCurrentlyPaused = true
            self.updateSpeakingControlState()
        }
    }
    
    /*----------------------------------------------------------------------------------------
     voicePopupSelected:
     
     An action method called when the user selects a new voice from the Voices pop-up
     menu.  We ask the speech channel to use the selected voice.     If the current
     speech channel cannot use the selected voice, we close and open new speech
     channel with the selecte voice.
     ----------------------------------------------------------------------------------------*/
    @IBAction func voicePopupSelected(_ sender: NSPopUpButton) {
        var theErr = OSErr(noErr)
        let theSelectedMenuIndex = sender.indexOfSelectedItem
        
        if theSelectedMenuIndex == 0 {
            // Use the default voice from preferences.
            // Our only choice is to close and reopen the speech channel to get the default voice.
            fSelectedVoiceCreator = 0
            theErr = self.createNewSpeechChannel(nil)
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("createNewSpeechChannel",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
        } else {
            // Use the voice the user selected.
            var theVoiceSpec = VoiceSpec()
            theErr = GetIndVoice(Int16(sender.indexOfSelectedItem) - 1, &theVoiceSpec)
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("GetIndVoice",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
            if theErr == OSErr(noErr) {
                // Update our object fields with the selection
                fSelectedVoiceCreator = theVoiceSpec.creator
                fSelectedVoiceID = theVoiceSpec.id
                
                // Change the current voice.  If it needs another engine, then dispose the current channel and open another
                let voiceDict: NSDictionary = [kSpeechVoiceID: fSelectedVoiceID,
                                               kSpeechVoiceCreator: fSelectedVoiceCreator]
                
                theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechCurrentVoiceProperty, voiceDict)
                if theErr == OSErr(incompatibleVoice) {
                    theErr = self.createNewSpeechChannel(&theVoiceSpec)
                    if theErr != OSErr(noErr) {
                        self.runAlertPanelWithTitle("createNewSpeechChannel",
                                                    message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                                    buttonTitles: ["Oh?"])
                    }
                } else if theErr != OSErr(noErr) {
                    self.runAlertPanelWithTitle("SetSpeechProperty(kSpeechCurrentVoiceProperty",
                                                message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                                buttonTitles: ["Oh?"])
                }
            }
        }
        // Set editable default fields
        if fCurSpeechChannel != nil {
            self.fillInEditableParameterFields()
        }
    }
    
    /*----------------------------------------------------------------------------------------
     charByCharCheckboxSelected:
     
     An action method called when the user checks/unchecks the Character-By-Character
     mode checkbox.    We tell the speech channel to use this setting.
     ----------------------------------------------------------------------------------------*/
    @IBAction func charByCharCheckboxSelected(_ sender: Any) {
        var theErr = OSErr(noErr)
        
        if fCharByCharCheckboxButton.intValue != 0 {
            theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechCharacterModeProperty, kSpeechModeLiteral)
        } else {
            theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechCharacterModeProperty, kSpeechModeNormal)
        }
        if theErr != OSErr(noErr) {
            self.runAlertPanelWithTitle("SetSpeechProperty(kSpeechCharacterModeProperty)",
                                        message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                        buttonTitles: ["Oh?"])
        }
    }
    
    /*----------------------------------------------------------------------------------------
     digitByDigitCheckboxSelected:
     
     An action method called when the user checks/unchecks the Digit-By-Digit
     mode checkbox.    We tell the speech channel to use this setting.
     ----------------------------------------------------------------------------------------*/
    @IBAction func digitByDigitCheckboxSelected(_ sender: Any) {
        var theErr = OSErr(noErr)
        
        if fDigitByDigitCheckboxButton.intValue != 0 {
            theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechNumberModeProperty, kSpeechModeLiteral)
        } else {
            theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechNumberModeProperty, kSpeechModeNormal)
        }
        if theErr != OSErr(noErr) {
            self.runAlertPanelWithTitle("SetSpeechProperty(kSpeechNumberModeProperty)",
                                        message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                        buttonTitles: ["Oh?"])
        }
    }
    
    /*----------------------------------------------------------------------------------------
     phonemeModeCheckboxSelected:
     
     An action method called when the user checks/unchecks the Phoneme input
     mode checkbox.    We tell the speech channel to use this setting.
     ----------------------------------------------------------------------------------------*/
    @IBAction func phonemeModeCheckboxSelected(_ sender: Any) {
        var theErr = OSErr(noErr)
        
        if fPhonemeModeCheckboxButton.intValue != 0 {
            theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechInputModeProperty, kSpeechModePhoneme)
        } else {
            theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechInputModeProperty, kSpeechModeText)
        }
        if theErr != OSErr(noErr) {
            self.runAlertPanelWithTitle("SetSpeechProperty(kSpeechInputModeProperty)",
                                        message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                        buttonTitles: ["Oh?"])
        }
    }
    
    /*----------------------------------------------------------------------------------------
     dumpPhonemesSelected:
     
     An action method called when the user clicks the Dump Phonemes button.    We ask
     the speech channel for a phoneme representation of the window text then save the
     result to a text file at a location determined by the user.
     ----------------------------------------------------------------------------------------*/
    @IBAction func dumpPhonemesSelected(_ sender: Any) {
        let panel = NSSavePanel()
        
        if panel.runModal() != .cancel && panel.url != nil {
            // Get and speech text
            var phonemesCFStringRef: CFString? = nil
            let theErr = CopyPhonemesFromText(fCurSpeechChannel!, fSpokenTextView.string as CFString, &phonemesCFStringRef)
            if theErr == OSErr(noErr) {
                let phonemesString = phonemesCFStringRef! as NSString
                do {
                    try phonemesString.write(to: panel.url!, atomically: true, encoding: String.Encoding.utf8.rawValue)
                } catch let nsError as NSError {
                    let messageFormat = NSLocalizedString("writeToURL: '%@' error: %@",
                                                          comment: "writeToURL: '%@' error: %@")
                    self.runAlertPanelWithTitle("CopyPhonemesFromText",
                                                message: String(format: messageFormat, panel.url! as CVarArg, nsError),
                                                buttonTitles: ["Oh?"])
                }
            } else {
                self.runAlertPanelWithTitle("CopyPhonemesFromText",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
        }
    }
    
    /*----------------------------------------------------------------------------------------
     useDictionarySelected:
     
     An action method called when the user clicks the "Use Dictionary…" button.
     ----------------------------------------------------------------------------------------*/
    @IBAction func useDictionarySelected(_ sender: Any) {
        // Open file.
        let panel = NSOpenPanel()
        
        panel.message = "Choose a dictionary file"
        panel.allowedFileTypes = ["xml", "plist"]
        
        panel.allowsMultipleSelection = true
        
        if panel.runModal() != .cancel {
            for fileURL in panel.urls {
                // Read dictionary file into NSData object.
                if let speechDictionary = NSDictionary(contentsOf: fileURL) {
                    let theErr = UseSpeechDictionary(fCurSpeechChannel!, speechDictionary)
                    if theErr != OSErr(noErr) {
                        self.runAlertPanelWithTitle("UseSpeechDictionary",
                                                    message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                                    buttonTitles: ["Oh?"])
                    }
                } else {
                    let messageFormat = NSLocalizedString("dictionaryWithContentsOfURL:'%@' returned NULL",
                                                          comment: "dictionaryWithContentsOfURL:'%@' returned NULL")
                    self.runAlertPanelWithTitle("CopyPhonemesFromText",
                                                message: String(format: messageFormat, fileURL.path),
                                                buttonTitles: ["Oh?"])
                }
            }
        }
    }
    
    /*----------------------------------------------------------------------------------------
     rateChanged:
     
     An action method called when the user changes the rate field.  We tell the speech
     channel to use this setting.
     ----------------------------------------------------------------------------------------*/
    @IBAction func rateChanged(_ sender: Any) {
        let theErr = SetSpeechProperty(fCurSpeechChannel!,
                                       kSpeechRateProperty,
                                       fRateDefaultEditableField.doubleValue as NSNumber?)
        if theErr != OSErr(noErr) {
            self.runAlertPanelWithTitle("SetSpeechRate",
                                        message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                        buttonTitles: ["Oh?"])
        } else {
            fRateCurrentStaticField.doubleValue = fRateDefaultEditableField.doubleValue
        }
    }
    
    /*----------------------------------------------------------------------------------------
     pitchBaseChanged:
     
     An action method called when the user changes the pitch base field.     We tell the speech
     channel to use this setting.
     ----------------------------------------------------------------------------------------*/
    @IBAction func pitchBaseChanged(_ sender: Any) {
        let theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechPitchBaseProperty,
                                       fPitchBaseDefaultEditableField.doubleValue as NSNumber?)
        if theErr != OSErr(noErr) {
            self.runAlertPanelWithTitle("SetSpeechPitch",
                                        message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                        buttonTitles: ["Oh?"])
        } else {
            fPitchBaseCurrentStaticField.doubleValue = fPitchBaseDefaultEditableField.doubleValue
        }
    }
    
    /*----------------------------------------------------------------------------------------
     pitchModChanged:
     
     An action method called when the user changes the pitch modulation field.  We tell
     the speech channel to use this setting.
     ----------------------------------------------------------------------------------------*/
    @IBAction func pitchModChanged(_ sender: Any) {
        let theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechPitchModProperty,
                                       fPitchModDefaultEditableField.doubleValue as NSNumber?)
        if theErr != OSErr(noErr) {
            self.runAlertPanelWithTitle("SetSpeechProperty(kSpeechPitchModProperty)",
                                        message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                        buttonTitles: ["Oh?"])
        } else {
            fPitchModCurrentStaticField.doubleValue = fPitchModDefaultEditableField.doubleValue
        }
    }
    
    /*----------------------------------------------------------------------------------------
     volumeChanged:
     
     An action method called when the user changes the volume field.     We tell
     the speech channel to use this setting.
     ----------------------------------------------------------------------------------------*/
    @IBAction func volumeChanged(_ sender: Any) {
        let theErr = SetSpeechProperty(fCurSpeechChannel!,
                                       kSpeechVolumeProperty,
                                       fVolumeDefaultEditableField.doubleValue as NSNumber?)
        if theErr != OSErr(noErr) {
            self.runAlertPanelWithTitle("SetSpeechProperty(kSpeechVolumeProperty)",
                                        message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                        buttonTitles: ["Oh?"])
        } else {
            fVolumeCurrentStaticField.doubleValue = fVolumeDefaultEditableField.doubleValue
        }
    }
    
    /*----------------------------------------------------------------------------------------
     resetSelected:
     
     An action method called when the user clicks the Use Defaults button.  We tell
     the speech channel to use this the default settings.
     ----------------------------------------------------------------------------------------*/
    @IBAction func resetSelected(_ sender: Any) {
        let theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechResetProperty, nil)
        
        self.fillInEditableParameterFields()
        
        if theErr != OSErr(noErr) {
            self.runAlertPanelWithTitle("SetSpeechProperty(kSpeechResetProperty)",
                                        message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                        buttonTitles: ["Oh?"])
        }
    }
    
    @IBAction func wordCallbacksButtonPressed(_ sender: Any) {
        if fHandleWordCallbacksCheckboxButton.intValue == 0 {
            fSpokenTextView.setSelectedRange(fOrgSelectionRange)
        }
    }
    
    @IBAction func phonemeCallbacksButtonPressed(_ sender: Any) {
        if fHandlePhonemeCallbacksCheckboxButton.intValue != 0 {
            characterView?.setExpression(.Idle)
        } else {
            characterView?.setExpression(.Sleep)
        }
    }
    
    /*----------------------------------------------------------------------------------------
     enableOptionsForSpeakingState:
     
     Updates controls in the Option tab panel based on the passed speakingNow flag.
     ----------------------------------------------------------------------------------------*/
    private func enableOptionsForSpeakingState(_ speakingNow: Bool) {
        fVoicesPopUpButton.isEnabled = !speakingNow
        fCharByCharCheckboxButton.isEnabled = !speakingNow
        fDigitByDigitCheckboxButton.isEnabled = !speakingNow
        fPhonemeModeCheckboxButton.isEnabled = !speakingNow
        fDumpPhonemesButton.isEnabled = !speakingNow
        fUseDictionaryButton.isEnabled = !speakingNow
    }
    
    /*----------------------------------------------------------------------------------------
     enableCallbackControlsForSavingToFile:
     
     Updates controls in the Callback tab panel based on the passed savingToFile flag.
     ----------------------------------------------------------------------------------------*/
    private func enableCallbackControlsBasedOnSavingToFileFlag(_ savingToFile: Bool) {
        fHandleWordCallbacksCheckboxButton.isEnabled = !savingToFile
        fHandlePhonemeCallbacksCheckboxButton.isEnabled = !savingToFile
        fHandleSyncCallbacksCheckboxButton.isEnabled = !savingToFile
        fHandleErrorCallbacksCheckboxButton.isEnabled = !savingToFile
        fHandleTextDoneCallbacksCheckboxButton.isEnabled = !savingToFile
        if savingToFile || fHandlePhonemeCallbacksCheckboxButton.intValue == 0 {
            characterView?.setExpression(.Sleep)
        } else {
            characterView?.setExpression(.Idle)
        }
    }
    
    /*----------------------------------------------------------------------------------------
     fillInEditableParameterFields
     
     Updates "Current" fields in the Parameters tab panel based on the current state of the
     speech channel.
     ----------------------------------------------------------------------------------------*/
    private func fillInEditableParameterFields() {
        var tempDoubleValue = 0.0
        var tempNSNumber: CFTypeRef? = nil
        
        CopySpeechProperty(fCurSpeechChannel!, kSpeechRateProperty, &tempNSNumber)
        tempDoubleValue = tempNSNumber!.doubleValue!
        
        fRateDefaultEditableField.doubleValue = tempDoubleValue
        fRateCurrentStaticField.doubleValue = tempDoubleValue
        
        CopySpeechProperty(fCurSpeechChannel!, kSpeechPitchBaseProperty, &tempNSNumber)
        tempDoubleValue = tempNSNumber!.doubleValue!
        fPitchBaseDefaultEditableField.doubleValue = tempDoubleValue
        fPitchBaseCurrentStaticField.doubleValue = tempDoubleValue
        
        CopySpeechProperty(fCurSpeechChannel!, kSpeechPitchModProperty, &tempNSNumber)
        tempDoubleValue = tempNSNumber!.doubleValue!
        fPitchModDefaultEditableField.doubleValue = tempDoubleValue
        fPitchModCurrentStaticField.doubleValue = tempDoubleValue
        
        CopySpeechProperty(fCurSpeechChannel!, kSpeechVolumeProperty, &tempNSNumber)
        tempDoubleValue = tempNSNumber!.doubleValue!
        fVolumeDefaultEditableField.doubleValue = tempDoubleValue
        fVolumeCurrentStaticField.doubleValue = tempDoubleValue
    }
    
    /*----------------------------------------------------------------------------------------
     createNewSpeechChannel:
     
     Create a new speech channel for the given voice spec.  A nil voice spec pointer
     causes the speech channel to use the default voice.     Any existing speech channel
     for this window is closed first.
     ----------------------------------------------------------------------------------------*/
    @discardableResult
    private func createNewSpeechChannel(_ voiceSpec: UnsafeMutablePointer<VoiceSpec>?) -> OSErr {
        var theErr = OSErr(noErr)
        
        // Dispose of the current one, if present.
        if fCurSpeechChannel != nil {
            theErr = DisposeSpeechChannel(fCurSpeechChannel!)
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("DisposeSpeechChannel",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
            
            fCurSpeechChannel = nil
        }
        // Create a speech channel
        if theErr == OSErr(noErr) {
            theErr = NewSpeechChannel(voiceSpec, &fCurSpeechChannel)
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("NewSpeechChannel",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
        }
        // Setup our refcon to the document controller object so we have access within our Speech callbacks
        if theErr == OSErr(noErr) {
            //### !!!check memory usage!!!
            theErr = SetSpeechProperty(fCurSpeechChannel!, kSpeechRefConProperty, Int(bitPattern: Unmanaged.passRetained(self).toOpaque()) as NSNumber)
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("SetSpeechProperty(kSpeechRefConProperty)",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
        }
        
        return theErr
    }
    
    
    //MARK: - Window
    
    /*----------------------------------------------------------------------------------------
     awakeFromNib
     
     This routine is call once right after our nib file is loaded.  We build our voices
     pop-up menu, create a new speech channel and update our window using parameters from
     the new speech channel.
     ----------------------------------------------------------------------------------------*/
    override func awakeFromNib() {
        var theErr = OSErr(noErr)
        
        // Build the Voices pop-up menu
        do {
            var numOfVoices: Int16 = 0
            var voiceFoundAndSelected = false
            var theVoiceSpec = VoiceSpec()
            
            // Delete the existing voices from the bottom of the menu.
            while fVoicesPopUpButton.numberOfItems > 2 {
                fVoicesPopUpButton.removeItem(at: 2)
            }
            
            // Ask TTS API for each available voicez
            theErr = CountVoices(&numOfVoices)
            if theErr != OSErr(noErr) {
                self.runAlertPanelWithTitle("CountVoices",
                                            message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                            buttonTitles: ["Oh?"])
            }
            if theErr == OSErr(noErr) {
                for voiceIndex in 1...numOfVoices {
                    var theVoiceDesc = VoiceDescription()
                    theErr = GetIndVoice(voiceIndex, &theVoiceSpec)
                    if theErr != OSErr(noErr) {
                        self.runAlertPanelWithTitle("GetIndVoice",
                                                    message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                                    buttonTitles: ["Oh?"])
                    }
                    if theErr == OSErr(noErr) {
                        theErr = withUnsafeMutablePointer(to: &theVoiceDesc) {ptrVoiceDesc in
                            GetVoiceDescription(&theVoiceSpec, UnsafeMutablePointer(ptrVoiceDesc), MemoryLayout.size(ofValue: theVoiceDesc))
                        }
                    }
                    if theErr != OSErr(noErr) {
                        self.runAlertPanelWithTitle("GetVoiceDescription",
                                                    message: String(format: fErrorFormatString, Int32(theErr), Int32(theErr)),
                                                    buttonTitles: ["Oh?"])
                    }
                    if theErr == OSErr(noErr) {
                        // Get voice name and add it to the menu list
                        let theNameString = withUnsafePointer(to: &theVoiceDesc.name.1) {charPtr in
                            String(cString: UnsafePointer(charPtr))
                        }
                        fVoicesPopUpButton.addItem(withTitle: theNameString)
                        // Selected this item if it matches our default voice spec.
                        if (theVoiceSpec.creator == fSelectedVoiceCreator) && (theVoiceSpec.id == fSelectedVoiceID) {
                            fVoicesPopUpButton.selectItem(at: Int(voiceIndex) - 1)
                            voiceFoundAndSelected = true
                        }
                    }
                }
                // User preference default if problems.
                if !voiceFoundAndSelected && numOfVoices >= 1 {
                    // Update our object fields with the first voice
                    fSelectedVoiceCreator = 0
                    fSelectedVoiceID = 0
                    
                    fVoicesPopUpButton.selectItem(at: 0)
                }
            } else {
                fVoicesPopUpButton.selectItem(at: 0)
            }
        }
        
        // Create Speech Channel configured with our desired options and callbacks
        self.createNewSpeechChannel(nil)
        
        // Set editable default fields
        self.fillInEditableParameterFields()
        
        // Enable buttons appropriatelly
        fStartStopButton.isEnabled = true
        fPauseContinueButton.isEnabled = false
        fSaveAsFileButton.isEnabled = true
        
        // Set starting expresison on animated character
        self.phonemeCallbacksButtonPressed(fHandlePhonemeCallbacksCheckboxButton)
    }
    
    /*----------------------------------------------------------------------------------------
     windowNibName
     
     Part of the NSDocument support. Called by NSDocument to return the nib file name of
     the document.
     ----------------------------------------------------------------------------------------*/
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("SpeakingTextWindow")
    }
    
    /*----------------------------------------------------------------------------------------
     windowControllerDidLoadNib:
     
     Part of the NSDocument support. Called by NSDocument after the nib has been loaded
     to udpate window as appropriate.
     ----------------------------------------------------------------------------------------*/
    override func windowControllerDidLoadNib(_ aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Update the window text from data
        if self.textDataType == "RTF Document" {
            fSpokenTextView.replaceCharacters(in: NSRange(0..<fSpokenTextView.string.utf16.count), withRTF: self.textData)
        } else {
            fSpokenTextView.replaceCharacters(in: NSRange(0..<fSpokenTextView.string.utf16.count),
                                              with: String(data: self.textData, encoding: .utf8)!)
        }
    }
    
    
    //MARK: - NSDocument
    
    /*----------------------------------------------------------------------------------------
     dataRepresentationOfType:
     
     Part of the NSDocument support. Called by NSDocument to wrote the document.
     ----------------------------------------------------------------------------------------*/
    override func data(ofType aType: String) throws -> Data {
        // Write text to file.
        if aType == "RTF Document" {
            self.textData = fSpokenTextView.rtf(from: NSRange(0..<fSpokenTextView.string.utf16.count))!
        } else {
            self.textData = fSpokenTextView.string.data(using: .utf8)!
        }
        
        return self.textData
    }
    
    /*----------------------------------------------------------------------------------------
     loadDataRepresentation: ofType:
     
     Part of the NSDocument support. Called by NSDocument to read the document.
     ----------------------------------------------------------------------------------------*/
    override func read(from data: Data, ofType aType: String) throws {
        // Read the opened file.
        self.textData = data
        self.textDataType = aType
        
    }
    
    
    //MARK: - Utilities
    
    /*----------------------------------------------------------------------------------------
     simple replacement method for NSRunAlertPanel
     ----------------------------------------------------------------------------------------*/
    @discardableResult
    private func runAlertPanelWithTitle(_ inTitle: String,
                                        message inMessage: String,
                                        buttonTitles inButtonTitles: [String]) -> NSApplication.ModalResponse
    {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString(inTitle, comment: inTitle)
        alert.informativeText = NSLocalizedString(inMessage, comment: inMessage)
        for buttonTitle in inButtonTitles {
            alert.addButton(withTitle: NSLocalizedString(buttonTitle, comment: buttonTitle))
        }
        return alert.runModal()
    }
    
}

//MARK: - Callback routines

//
// AN IMPORTANT NOTE ABOUT CALLBACKS AND THREADS
//
// All speech synthesis callbacks, except for the Text Done callback, call their specified routine on a
// thread other than the main thread.  Performing certain actions directly from a speech synthesis callback
// routine may cause your program to crash without certain safe gaurds.     In this example, we use the NSThread
// method performSelectorOnMainThread:withObject:waitUntilDone: to safely update the user interface and
// interact with our objects using only the main thread.
//
// Depending on your needs you may be able to specify your Cocoa application is multiple threaded
// then preform actions directly from the speech synthesis callback routines.  To indicate your Cocoa
// application is mulitthreaded, call the following line before calling speech synthesis routines for
// the first time:
//
// [NSThread detachNewThreadSelector:@selector(self) toTarget:self withObject:nil];
//

/*----------------------------------------------------------------------------------------
 OurErrorCFCallBackProc
 
 Called by speech channel when an error occurs during processing of text to speak.
 ----------------------------------------------------------------------------------------*/
private func OurErrorCFCallBackProc(_ inSpeechChannel: SpeechChannel, _ inRefCon: SRefCon, _ inCFErrorRef: CFError?) {
    autoreleasepool {
        let stw = Unmanaged<SpeakingTextWindow>.fromOpaque(inRefCon).takeUnretainedValue()
        DispatchQueue.main.async {
            if stw.shouldDisplayErrorCallbacks {
                NSAlert(error: inCFErrorRef!).runModal()
            }
        }
    }
}

/*----------------------------------------------------------------------------------------
 OurTextDoneCallBackProc
 
 Called by speech channel when all text has been processed.    Additional text can be
 passed back to continue processing.
 ----------------------------------------------------------------------------------------*/
private func OurTextDoneCallBackProc(_ inSpeechChannel: SpeechChannel,
                                     _ inRefCon: SRefCon,
                                     _ inNextBuf: UnsafeMutablePointer<UnsafeRawPointer?>,
                                     _ inByteLen: UnsafePointer<UInt>,
                                     _ inControlFlags: UnsafePointer<Int>)
{
    autoreleasepool {
        let stw = Unmanaged<SpeakingTextWindow>.fromOpaque(inRefCon).takeUnretainedValue()
        inNextBuf.pointee = nil
        DispatchQueue.main.async {
            if stw.shouldDisplayTextDoneCallbacks {
                stw.displayTextDoneAlert()
            }
        }
    }
}

/*----------------------------------------------------------------------------------------
 OurSpeechDoneCallBackProc
 
 Called by speech channel when all speech has been generated.
 ----------------------------------------------------------------------------------------*/
private func OurSpeechDoneCallBackProc(_ inSpeechChannel: SpeechChannel, _ inRefCon: SRefCon) {
    autoreleasepool {
        let stw = Unmanaged<SpeakingTextWindow>.fromOpaque(inRefCon).takeUnretainedValue()
        DispatchQueue.main.async {
            stw.speechIsDone()
        }
    }
}

/*----------------------------------------------------------------------------------------
 OurSyncCallBackProc
 
 Called by speech channel when it encouters a synchronization command within an
 embedded speech comand in text being processed.
 ----------------------------------------------------------------------------------------*/
private func OurSyncCallBackProc(_ inSpeechChannel: SpeechChannel, _ inRefCon: SRefCon, _ inSyncMessage: OSType) {
    autoreleasepool {
        let stw = Unmanaged<SpeakingTextWindow>.fromOpaque(inRefCon).takeUnretainedValue()
        DispatchQueue.main.async {
            if stw.shouldDisplaySyncCallbacks {
                stw.displaySyncAlertWithMessage(inSyncMessage)
            }
        }
    }
}

/*----------------------------------------------------------------------------------------
 OurPhonemeCallBackProc
 
 Called by speech channel every time a phoneme is about to be generated.     You might use
 this to animate a speaking character.
 ----------------------------------------------------------------------------------------*/
private func OurPhonemeCallBackProc(_ inSpeechChannel: SpeechChannel, _ inRefCon: SRefCon, _ inPhonemeOpcode: Int16) {
    autoreleasepool {
        let stw = Unmanaged<SpeakingTextWindow>.fromOpaque(inRefCon).takeUnretainedValue()
        DispatchQueue.main.async {
            if stw.shouldDisplayPhonemeCallbacks {
                stw.characterView.setExpressionForPhoneme(inPhonemeOpcode)
            }
        }
    }
}

/*----------------------------------------------------------------------------------------
 OurWordCallBackProc
 
 Called by speech channel every time a word is about to be generated.  This program
 uses this callback to highlight the currently spoken word.
 ----------------------------------------------------------------------------------------*/
private func OurWordCFCallBackProc(_ inSpeechChannel: SpeechChannel, _ inRefCon: SRefCon, _ inCFStringRef: CFString, _ inWordCFRange: CFRange) {
    autoreleasepool {
        let stw = Unmanaged<SpeakingTextWindow>.fromOpaque(inRefCon).takeUnretainedValue()
        DispatchQueue.main.async {
            if stw.shouldDisplayWordCallbacks {
                stw.highlightWordWithRange(inWordCFRange)
            }
        }
    }
}
