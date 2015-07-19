/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The custom view holding the speaking character.
 */

@import Cocoa;

extern NSString *kCharacterExpressionIdentifierSleep;
extern NSString *kCharacterExpressionIdentifierIdle;

@interface SpeakingCharacterView : NSView

- (void)setExpressionForPhoneme:(NSNumber *)phoneme;
- (void)setExpression:(NSString *)expression;

@end

