/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The custom view holding the speaking character.
 */

#import "SpeakingCharacterView.h"

// Expression Identifiers
NSString *kCharacterExpressionIdentifierSleep = @"ExpressionIdentifierSleep";
NSString *kCharacterExpressionIdentifierIdle = @"ExpressionIdentifierIdle";

NSString *kCharacterExpressionIdentifierConsonant = @"ExpressionIdentifierConsonant";
NSString *kCharacterExpressionIdentifierVowel = @"ExpressionIdentifierVowel";

// Frame dictionary keys
static NSString *kCharacterExpressionFrameDurationKey = @"FrameDuration";   // TimeInterval
static NSString *kCharacterExpressionFrameImageFileNameKey = @"FrameImageFileName";

@interface SpeakingCharacterView ()
{
    NSString *_currentExpression;
    NSTimer *_idleStartTimer;
    NSTimer *_expressionFrameTimer;
    int _curFrameIndex;
    NSArray *_curFrameArray;
    NSImage *_curFrameImage;
    NSDictionary *_characterDescription;
    NSMutableDictionary *_imageCache;
}

@end


#pragma mark -

@implementation SpeakingCharacterView

/*----------------------------------------------------------------------------------------
    initWithFrame:

    Our designated initializer.  We load the default character and set the expression to sleep.
   ----------------------------------------------------------------------------------------*/
- (instancetype)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self loadChacaterByName:@"Buster"];
		[self setExpression:kCharacterExpressionIdentifierSleep];
	}

	return (self);
}                                       /* initWithFrame */

/*----------------------------------------------------------------------------------------
    initWithFrdrawRectame:

    Our main draw routine.
   ----------------------------------------------------------------------------------------*/
- (void)drawRect:(NSRect)rect {
	NSPoint thePointToDraw;
	NSSize sourceSize = [_curFrameImage size];
	NSSize destSize = rect.size;

	if (destSize.width >= sourceSize.width) {
		thePointToDraw.x = (destSize.width - sourceSize.width) / 2;
	} else {
		thePointToDraw.x = 0;
	}
	if (destSize.height >= sourceSize.height) {
		thePointToDraw.y = (destSize.height - sourceSize.height) / 2;
	} else {
		thePointToDraw.y = 0;
	}

	[_curFrameImage drawAtPoint:thePointToDraw fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}                                       /* drawRect */

/*----------------------------------------------------------------------------------------
    setExpressionForPhoneme:

    Sets the current expression to the expression corresponding to the given phoneme ID.
   ----------------------------------------------------------------------------------------*/
- (void)setExpressionForPhoneme:(NSNumber *)phoneme {
	int phonemeValue = [phoneme shortValue];

	if ((phonemeValue == 0) || (phonemeValue == 1)) {
		[self setExpression:kCharacterExpressionIdentifierIdle];
	} else if ((phonemeValue >= 2) && (phonemeValue <= 17)) {
		[self setExpression:kCharacterExpressionIdentifierVowel];
	} else {
		[self setExpression:kCharacterExpressionIdentifierConsonant];
	}
}                                       /* setExpressionForPhoneme */

/*----------------------------------------------------------------------------------------
    setExpression:

    Sets the current expression to the named expresison identifier, then forces the
    character image on screen to be updated.
   ----------------------------------------------------------------------------------------*/
- (void)setExpression:(NSString *)expression {
	// Set up to begin animating the frames
	[_expressionFrameTimer invalidate];
	_expressionFrameTimer = NULL;
	_currentExpression = expression;
	_curFrameArray = _characterDescription[_currentExpression];
	_curFrameIndex = 0;
	[self animateNextExpressionFrame];
	// If the expression we just set is NOT the idle or sleep expression, then set up the idle start timer.
	if (!([expression isEqualToString:kCharacterExpressionIdentifierIdle] ||
	      [expression isEqualToString:kCharacterExpressionIdentifierSleep])) {
		[_idleStartTimer invalidate];
		_idleStartTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
		                    target	:self
		                    selector:@selector(startIdleExpression)
		                    userInfo:NULL
		                    repeats :NO
		                  ];
	} else {
		[_idleStartTimer invalidate];
		_idleStartTimer = NULL;
	}
}                                       /* setExpression */

/*----------------------------------------------------------------------------------------
    animateNextExpressionFrame

    Determines the next frame to animate, loads the image and forces it to be drawn.  If
    the expression contains multiple frames, sets up timer for the next frame to be drawn.
   ----------------------------------------------------------------------------------------*/
- (void)animateNextExpressionFrame {
	_expressionFrameTimer = NULL;

	NSDictionary *frameDictionary = _curFrameArray[_curFrameIndex];

	// Grab image and force draw.  Use cache to reduce disk hits
	NSString *frameImageName = frameDictionary[kCharacterExpressionFrameImageFileNameKey];
	_curFrameImage = _imageCache[frameImageName];
	if (_curFrameImage == NULL) {
		_curFrameImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:frameImageName ofType:@""]];
		_imageCache[frameImageName] = _curFrameImage;
	}

	[self display];
	// If there is more than one frame, then schedule drawing of the next and increment our frame index.
	if ([_curFrameArray count] > 0) {
		_curFrameIndex++;
		_curFrameIndex %= [_curFrameArray count];
		_expressionFrameTimer =
		    [NSTimer scheduledTimerWithTimeInterval:[frameDictionary[kCharacterExpressionFrameDurationKey] floatValue]
		                            target	:self
		                            selector:
		     @selector(animateNextExpressionFrame)
		                            userInfo:NULL
		                            repeats :NO];
	}
}                                       /* animateNextExpressionFrame */

/*----------------------------------------------------------------------------------------
    startIdleExpression

    Starts the idle expression.  Called by the idle timer after certain expressions (mainly
    phoneme expressions) expire.
   ----------------------------------------------------------------------------------------*/
- (void)startIdleExpression {
	_idleStartTimer = NULL;

	[self setExpression:kCharacterExpressionIdentifierIdle];
}                                       /* startIdleExpression */

/*----------------------------------------------------------------------------------------
    loadChacaterByName:

    Loads description dictionary for the named character and flushes any cached images.
   ----------------------------------------------------------------------------------------*/
- (void)loadChacaterByName:(NSString *)name {
	_imageCache = [NSMutableDictionary new];
	_characterDescription =
	    [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"plist"]];
}

@end

