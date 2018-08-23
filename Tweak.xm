#import <dlfcn.h>
#import <objc/runtime.h>
#import <notify.h>
#import <substrate.h>

#define NSLog(...)

@interface UIKeyboardInputMode : UITextInputMode
@end

@interface UIKeyboardInputModeController : NSObject
@property (retain) UIKeyboardInputMode * currentInputMode; 
+(id)sharedInputModeController;
-(id)activeInputModes;
-(void)setCurrentInputMode:(UIKeyboardInputMode *)arg1;
@end

@interface UIKeyboardImpl : UIView
@property (retain) UISwipeGestureRecognizer * gestureSwipeUp;
@property (retain) UISwipeGestureRecognizer * gestureSwipeDown;
@end

static BOOL Enabled;

%hook UIKeyboardInputModeController
%new
- (void)handleKeySwipe:(UISwipeGestureRecognizer*)gesture
{
	NSArray* inputs = [self activeInputModes];
	int currIdx = [inputs indexOfObject:[self currentInputMode]];
	UIKeyboardInputMode* newInput = nil;
	if(gesture.direction == UISwipeGestureRecognizerDirectionUp) {
		if((currIdx+1) >= [inputs count]) {
			newInput = [inputs objectAtIndex:0];
		} else {
			newInput = [inputs objectAtIndex:currIdx+1];
		}
	} else {
		if((currIdx-1) < 0) {
			newInput = [inputs objectAtIndex:[inputs count]-1];
		} else {
			newInput = [inputs objectAtIndex:currIdx-1];
		}
	}
	[self setCurrentInputMode:newInput];
	
}
%end

%hook UIKeyboardImpl
%property (retain) id gestureSwipeUp;
%property (retain) id gestureSwipeDown;
-(void)updateLayout
{
	%orig;
	if(!self.gestureSwipeUp) {
		self.gestureSwipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:[%c(UIKeyboardInputModeController) sharedInputModeController] action:@selector(handleKeySwipe:)];
	}
	self.gestureSwipeUp.enabled = Enabled;
    [self.gestureSwipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
	[self removeGestureRecognizer:self.gestureSwipeUp];
	[self addGestureRecognizer:self.gestureSwipeUp];
	
	if(!self.gestureSwipeDown) {
		self.gestureSwipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:[%c(UIKeyboardInputModeController) sharedInputModeController] action:@selector(handleKeySwipe:)];
	}
	self.gestureSwipeDown.enabled = Enabled;
    [self.gestureSwipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
	[self removeGestureRecognizer:self.gestureSwipeDown];
	[self addGestureRecognizer:self.gestureSwipeDown];
	
	for(UIGestureRecognizer *recognizer in self.gestureRecognizers) {
		[recognizer requireGestureRecognizerToFail:self.gestureSwipeUp];
		[recognizer requireGestureRecognizerToFail:self.gestureSwipeDown];
	}
}
%end


static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    
	@autoreleasepool {
		NSDictionary *Prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.delewhopper.keyswipeprefs.plist"]?:@{};
		Enabled = [Prefs[@"active"]?:@YES boolValue];
	}
}

%ctor
{
	prefsChanged(NULL, NULL, NULL, NULL, NULL);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &prefsChanged, (CFStringRef)@"com.delewhopper.keyswipeprefs.reloadPrefs", NULL, 0);
}