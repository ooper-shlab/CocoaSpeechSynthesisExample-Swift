# CocoaSpeechSynthesisExample

## Description

A Cocoa application using the Speech Synthesis API.

It demonstrates how to use the Speech Synthesis API from within a OS X Cocoa application.
Once built, the application provides access to virtually all the features of the Speech Synthesis Framework.
The application code provides examples of the following concepts:

- Word highlighting using the word callback.
- Simple mouth animation using the phoneme callback.
- Saving of generated speech audio data to a file.
- Creation of a voice pop-up menu.
- Starting, stopping, pausing and continuing of the speech generation process.
- Use of speech dictionaries which allow your application to override a synthesizer's default pronunciations of individual words, such as names with unusual spellings.

## Requirements

### Build

OS X 10.10 SDK or later

### Runtime

OS X 10.8 or later

## Revision History

v2.1
Replaced depreciated APIs (Get/SetSpeechInfo => Copy/SetSpeechProperty, NSRunAlertPanel)
Toll-free bridged NSObjects to CFObjectRefs where-ever possible (all ARC safe).
Updated to Modern Objective C syntax (NSDictionary/NSArray literals)
Fast enumeration


Copyright (C) 2003-2015 Apple Inc. All rights reserved.
