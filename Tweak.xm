#include <SpringBoard/SpringBoard.h>
#include <SpringBoard/SBApplication.h>
#include <SpringBoard/SBMediaController.h>
#include <libcolorpicker.h>

#define kFirstActionOffset 0.1
#define kSecondActionOffset 0.2
#define kThirdActionOffset 0.3

#define kFirstActionUpOffset 0.085
#define kSecondActionUpOffset 0.170
#define kThirdActionUpOffset 0.260

#define kFirstActionDownOffset -0.09
#define kSecondActionDownOffset -0.170
#define kThirdActionDownOffset -0.260

#define kFirstAction @"FirstAction"
#define kSecondAction @"SecondAction"
#define kThirdAction @"ThirdAction"

#define kSettingsPath @"/var/mobile/Library/Preferences/com.dgh0st.enhancedswitcherclose.plist"
#define identifier @"com.dgh0st.enhancedswitcherclose"
#define kPerAppKill @"PerAppKill-"
#define kPerApp @"isAppEnabled-"
#define kOverridePerApp @"isOverrideEnabled-"
#define kQuickLaunchApps @"QuickLaunch-"

typedef enum {
	kUp = 0,
	kDown,
	kNone
} Direction;

typedef enum {
	kActionNone = 0,
	kRespring,
	kKillAll,
	kRelaunchAll,
	kLaunch,
	kDismissSwitcher,
	kClose,
	kRelaunch,
	kQuickLaunch
} Action;

typedef enum {
	kLeft = 0,
	kCenter,
	kRight
} Position;

static NSString *displayTitles[9] = {
	@"",
	@"Respring",
	@"Kill-All",
	@"Relaunch-All",
	@"Launch",
	@"Dismiss Switcher",
	@"Close",
	@"Relaunch",
	@"Quick Launch"
};

static BOOL isTweakEnabled = YES;
static BOOL isHomeEnabled = YES;
static BOOL isNowPlayingEnabled = NO;
static BOOL isAlertNowPlayingEnabled = NO;
static BOOL isWhitelistEnabled = NO;
static BOOL isAutoDismissOnKillEnabled = YES;
static BOOL isNowPlayingOnKillEnabled = NO;
static BOOL isAutoCloseSwitcherEnabled = NO;
static BOOL isDefaultAppEnabled = YES;
static Action defaultAppFirstActionDown = kLaunch;
static Action defaultAppSecondActionDown = kDismissSwitcher;
static Action defaultAppThirdActionDown = kActionNone;
static Action defaultAppFirstActionUp = kRelaunch;
static Action defaultAppSecondActionUp = kClose;
static Action defaultAppThirdActionUp = kActionNone;
static Position labelPosition = kCenter;

NSDictionary *prefs = nil;
BOOL isClosingAll = NO;

static void reloadPrefs() {
	if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) {
		CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)identifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (keyList) {
			prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, (CFStringRef)identifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			if (!prefs) {
				prefs = [NSDictionary new];
			}
			CFRelease(keyList);
		}
	} else {
		prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	}
}

static BOOL boolValueForKey(NSString *key, BOOL defaultValue) {
	return (prefs && [prefs objectForKey:key]) ? [[prefs objectForKey:key] boolValue] : defaultValue;
}

static BOOL boolValuePerApp(NSString *appId, NSString *prefix, BOOL defaultValue) { // get bool value of preference of specific application (AppList)
    if (prefs) {
		for (NSString *key in [prefs allKeys]) {
			if ([key hasPrefix:prefix]) {
				NSString *tempId = [key substringFromIndex:[prefix length]];
				if ([tempId isEqualToString:appId]) {
					return boolValueForKey(key, defaultValue);
				}
			}
		}
	}
	return defaultValue;
}

static NSInteger intValueForKey(NSString *key, NSInteger defaultValue) {
	return (prefs && [prefs objectForKey:key]) ? [[prefs objectForKey:key] intValue] : defaultValue;
}

static NSInteger intValuePerApp(NSString *appId, NSString *prefix, NSInteger defaultValue) { // get int value of preference of specific application (AppList)
	if (prefs) {
		for (NSString *key in [prefs allKeys]) {
			if ([key hasPrefix:prefix]) {
				NSString *tempId = [key substringFromIndex:[prefix length]];
				if ([tempId isEqualToString:appId]) {
					return intValueForKey(key, defaultValue);
				}
			}
		}
	}
	return defaultValue;
}

static NSString *stringValueForKey(NSString *key, NSString *defaultValue) {
	NSString *temp = [[NSDictionary dictionaryWithContentsOfFile:kSettingsPath] objectForKey:key];
	if (temp == nil) {
		temp = defaultValue;
	}
	return temp;
}

static NSMutableArray *prefixApps(NSString *prefix) { // get app identifiers that match the prefix from preference of quick launch (AppList)
	NSMutableArray *result = [[NSMutableArray alloc] init];
	if (prefs) {
		for (NSString *key in [prefs allKeys]) {
			if ([key hasPrefix:prefix]) {
				NSString *tempId = [key substringFromIndex:[prefix length]];
				if ([prefs objectForKey:key] && [[prefs objectForKey:key] boolValue]) {
					[result addObject:tempId];
				}
			}
		}
	}
	return result;
}

static void preferencesChanged() {
	CFPreferencesAppSynchronize((CFStringRef)identifier);
	reloadPrefs();

	isTweakEnabled = boolValueForKey(@"isEnabled", YES);
	isHomeEnabled = boolValueForKey(@"isHomeEnabled", YES);
	isNowPlayingEnabled = boolValueForKey(@"isNowPlayingEnabled", NO);
	isAlertNowPlayingEnabled = boolValueForKey(@"isAlertNowPlayingEnabled", NO);
	isWhitelistEnabled = boolValueForKey(@"isWhitelistEnabled", NO);
	isAutoDismissOnKillEnabled = boolValueForKey(@"isAutoDismissOnKillEnabled", YES);
	isNowPlayingOnKillEnabled = boolValueForKey(@"isNowPlayingOnKillEnabled", NO);
	isAutoCloseSwitcherEnabled = boolValueForKey(@"isAutoCloseSwitcherEnabled", NO);
	isDefaultAppEnabled = boolValueForKey(@"isAppEnabled", YES);
	defaultAppFirstActionDown = (Action)intValueForKey(@"AppFirstActionDown", kLaunch);
	defaultAppSecondActionDown = (Action)intValueForKey(@"AppSecondActionDown", kDismissSwitcher);
	defaultAppThirdActionDown = (Action)intValueForKey(@"AppThirdActionDown", kActionNone);
	defaultAppFirstActionUp = (Action)intValueForKey(@"AppFirstActionUp", kRelaunch);
	defaultAppSecondActionUp = (Action)intValueForKey(@"AppSecondActionUp", kClose);
	defaultAppThirdActionUp = (Action)intValueForKey(@"AppThirdActionUp", kActionNone);
	labelPosition = (Position)intValueForKey(@"LabelPosition", kCenter);
}

@interface SBDisplayItem : NSObject
@property (nonatomic,readonly) NSString* displayIdentifier;
@end

@interface SBDeckSwitcherViewController : UIViewController
@property(retain, nonatomic) NSArray *displayItems;
-(void)killDisplayItemOfContainer:(id)arg1 withVelocity:(CGFloat)arg2;
-(id)_itemContainerForDisplayItem:(id)arg1;
-(void)closeAllApplications:(BOOL)includeWhitelist;
-(void)launchApplications:(NSMutableArray *)arg1 withIdentifiers:(BOOL)arg2;
-(void)respring;
-(void)killAll;
-(void)killApp:(id)container withDisplayItem:(id)item;
-(void)relaunchAll;
-(void)relaunchApp:(id)container withDisplayItem:(id)item;
-(void)dismissSwitcher;
-(void)launchApp:(id)container;
-(void)quickLaunch;
-(void)performAction:(Action)action withContainer:(id)container withDisplayItem:(id)item;
-(void)performActionWithActionIndex:(NSInteger)index withContainer:(id)container withDisplayItem:(id)item withIsSpringBoard:(BOOL)isSpringBoard;
@end

@interface SBDeckSwitcherItemContainer : UIView
@property(readonly, retain, nonatomic) SBDisplayItem *displayItem;
-(void)_handlePageViewTap:(id)arg1;
-(CGRect)_frameForScrollView;
-(CGRect)_frameForPageView;
-(void)addLabelWithTitle:(NSString *)arg1 withY:(CGFloat)arg2 withColor:(UIColor *)arg3;
-(void)createLabels;
-(void)removeLabels;
-(void)scrollViewProgressUpdated:(CGFloat)arg1 withDirection:(Direction)arg2 withIsSpringBoard:(BOOL)arg3;
-(BOOL)shouldPerformAction;
-(Action)firstAction;
-(Action)secondAction;
-(Action)thirdAction;
-(void)updateActionswithIsSpringBoard:(BOOL)isSpringBoard;
@end

@interface SBDeckSwitcherPageView
@end

@interface UIApplication (EnhancedSwitcherClose)
+(id)sharedApplication;
-(BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2;
@end

@interface SpringBoard (EnhancedSwitcherClose)
-(BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2;
@end

@interface FBSystemService
+(id)sharedInstance;
-(void)exitAndRelaunch:(BOOL)arg1;
@end

@interface SBApplication (EnhancedSwitcherClose)
-(id)bundleIdentifier;
@end

@interface SBMediaController (EnhancedSwitcherClose)
+(id)sharedInstance;
-(SBApplication *)nowPlayingApplication;
-(BOOL)isPlaying;
@end

%hook SBDeckSwitcherItemContainer
UIView *createdView = nil;
Direction currentDirection = kNone;
BOOL _shouldPerformAction = NO;
Action _firstAction = kActionNone;
Action _secondAction = kActionNone;
Action _thirdAction = kActionNone;

%new
-(Action)firstAction {
	return _firstAction;
}

%new
-(Action)secondAction {
	return _secondAction;
}

%new
-(Action)thirdAction {
	return _thirdAction;
}

%new
-(void)updateActionswithIsSpringBoard:(BOOL)isSpringBoard {
	BOOL isOverrideEnabled = boolValuePerApp([self displayItem].displayIdentifier, kOverridePerApp, NO);

	NSString *prefix = @"";
	NSString *itemIdentifier = @"";
	if (isSpringBoard) {
		prefix = @"Home";
		itemIdentifier = @"";
	} else {
		prefix = @"App";
		itemIdentifier = [NSString stringWithFormat:@"-%@", [self displayItem].displayIdentifier];
	}

	NSString *suffix = @"";
	Action defaultFirstAction = kActionNone;
	Action defaultSecondAction = kActionNone;
	Action defaultThirdAction = kActionNone;
	if (currentDirection == kUp) {
		suffix = @"Up";
		if (isSpringBoard) {
			defaultFirstAction = kRelaunchAll;
			defaultSecondAction = kKillAll;
			defaultThirdAction = kRespring;
		} else {
			if (isOverrideEnabled) {
				defaultFirstAction = kRelaunch;
				defaultSecondAction = kClose;
			} else {
				defaultFirstAction = defaultAppFirstActionUp;
				defaultSecondAction = defaultAppSecondActionUp;
				defaultThirdAction = defaultAppThirdActionUp;
			}
		}
	} else if (currentDirection == kDown) {
		suffix = @"Down";
		if (isSpringBoard) {
			defaultFirstAction = kLaunch;
			defaultSecondAction = kDismissSwitcher;
		} else {
			if (isOverrideEnabled) {
				defaultFirstAction = kLaunch;
				defaultSecondAction = kDismissSwitcher;
			} else {
				defaultFirstAction = defaultAppFirstActionDown;
				defaultSecondAction = defaultAppSecondActionDown;
				defaultThirdAction = defaultAppThirdActionDown;
			}
		}
	}

	if (isSpringBoard || isOverrideEnabled) {
		_firstAction = (Action)intValuePerApp(itemIdentifier, [NSString stringWithFormat:@"%@%@%@", prefix, kFirstAction, suffix], defaultFirstAction);
		_secondAction = (Action)intValuePerApp(itemIdentifier, [NSString stringWithFormat:@"%@%@%@", prefix, kSecondAction, suffix], defaultSecondAction);
		_thirdAction = (Action)intValuePerApp(itemIdentifier, [NSString stringWithFormat:@"%@%@%@", prefix, kThirdAction, suffix], defaultThirdAction);
	} else {
		_firstAction = defaultFirstAction;
		_secondAction = defaultSecondAction;
		_thirdAction = defaultThirdAction;
	}
}

%new
-(BOOL)shouldPerformAction {
	if (_shouldPerformAction) {
		_shouldPerformAction = NO;
		return YES;
	}
	return NO;
}

%new
-(void)addLabelWithTitle:(NSString *)arg1 withY:(CGFloat)arg2 withColor:(UIColor *)arg3 {
	CGRect pageViewFrame = [self _frameForPageView];

	UIView *leftSeparator = [[UIView alloc] initWithFrame:CGRectMake(8, arg2, pageViewFrame.size.width / 3 - 8, 2)];
	leftSeparator.backgroundColor = arg3;
	[createdView addSubview:leftSeparator];

	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(pageViewFrame.size.width / 3, arg2 - 8, pageViewFrame.size.width / 3, 16)];
	label.text = arg1;
	label.textColor = arg3;
	label.textAlignment = NSTextAlignmentCenter;
	[createdView addSubview:label];

	UIView *rightSeparator = [[UIView alloc] initWithFrame:CGRectMake(pageViewFrame.size.width / 3 * 2, arg2, pageViewFrame.size.width / 3 - 8, 2)];
	rightSeparator.backgroundColor = arg3;
	[createdView addSubview:rightSeparator];

	[label sizeToFit];

	CGRect labelFrame = label.frame;
	CGRect leftSeparatorFrame = leftSeparator.frame;
	CGRect rightSeparatorFrame = rightSeparator.frame;
	
	labelFrame.size.width += 16;

	if (labelPosition == kLeft) {
		labelFrame.origin.x = pageViewFrame.size.width / 16;

		leftSeparatorFrame.size.width = pageViewFrame.size.width / 16 - 8;

		rightSeparatorFrame.size.width = pageViewFrame.size.width - leftSeparatorFrame.size.width - labelFrame.size.width - 16;
	} else if (labelPosition == kRight) {
		labelFrame.origin.x = pageViewFrame.size.width * 15 / 16 - labelFrame.size.width;

		rightSeparatorFrame.size.width = pageViewFrame.size.width / 16 - 8;

		leftSeparatorFrame.size.width = pageViewFrame.size.width - rightSeparatorFrame.size.width - labelFrame.size.width - 16;
	} else {
		labelFrame.origin.x = pageViewFrame.size.width / 2 - labelFrame.size.width / 2;

		leftSeparatorFrame.size.width = pageViewFrame.size.width / 2 - labelFrame.size.width / 2 - 8;

		rightSeparatorFrame.size.width = pageViewFrame.size.width / 2 - labelFrame.size.width / 2 - 8;
	}

	rightSeparatorFrame.origin.x = labelFrame.origin.x + labelFrame.size.width;

	label.frame = labelFrame;
	leftSeparator.frame = leftSeparatorFrame;
	rightSeparator.frame = rightSeparatorFrame;
}

%new
-(void)createLabels {
	NSString *respringColor = stringValueForKey(@"respringColor", @"#FF0000");
	NSString *killAllColor = stringValueForKey(@"killAllColor", @"#FF8800");
	NSString *relaunchAllColor = stringValueForKey(@"relaunchAllColor", @"#00FF00");
	NSString *launchColor = stringValueForKey(@"launchColor", @"#00FF00");
	NSString *dismissSwitcherColor = stringValueForKey(@"dismissSwitcherColor", @"#FF8800");
	NSString *closeColor = stringValueForKey(@"closeColor", @"#FF0000");
	NSString *relaunchColor = stringValueForKey(@"relaunchColor", @"#FF8800");
	NSString *quickLaunchColor = stringValueForKey(@"quickLaunchColor", @"#00FF00");

	UIColor *displayColors[9] = {
		nil,
		(UIColor *)LCPParseColorString(respringColor, @"#FF0000"),
		(UIColor *)LCPParseColorString(killAllColor, @"#FF8800"),
		(UIColor *)LCPParseColorString(relaunchAllColor, @"#00FF00"),
		(UIColor *)LCPParseColorString(launchColor, @"#00FF00"),
		(UIColor *)LCPParseColorString(dismissSwitcherColor, @"#FF8800"),
		(UIColor *)LCPParseColorString(closeColor, @"#FF0000"),
		(UIColor *)LCPParseColorString(relaunchColor, @"#FF8800"),
		(UIColor *)LCPParseColorString(quickLaunchColor, @"#00FF00")
	};

	UIScrollView *_verticalScrollView = MSHookIvar<UIScrollView *>(self, "_verticalScrollView");
	CGRect pageViewFrame = [self _frameForPageView];

	if (createdView == nil) {
		NSString *backgroundColor = stringValueForKey(@"backgroundColor", @"#000000");

		createdView = [[UIView alloc] initWithFrame:CGRectMake(pageViewFrame.origin.x, 0, pageViewFrame.size.width, pageViewFrame.size.height)];
		createdView.backgroundColor = (UIColor *)LCPParseColorString(backgroundColor, @"000000");//[[UIColor blackColor] colorWithAlphaComponent:0.5];
	}
	
	if (_firstAction != kActionNone) {
		CGFloat offset = 0.0;
		if (currentDirection == kUp) {
			offset = (1 - kFirstActionOffset);
		} else if (currentDirection == kDown) {
			offset = kFirstActionOffset;
		}
		[self addLabelWithTitle:displayTitles[_firstAction] withY:(pageViewFrame.size.height * offset) withColor:displayColors[_firstAction]];
	}

	if (_secondAction != kActionNone) {
		CGFloat offset = 0.0;
		if (currentDirection == kUp) {
			offset = (1 - kSecondActionOffset);
		} else if (currentDirection == kDown) {
			offset = kSecondActionOffset;
		}
		[self addLabelWithTitle:displayTitles[_secondAction] withY:(pageViewFrame.size.height * offset) withColor:displayColors[_secondAction]];
	}

	if (_thirdAction != kActionNone) {
		CGFloat offset = 0.0;
		if (currentDirection == kUp) {
			offset = (1 - kThirdActionOffset);
		} else if (currentDirection == kDown) {
			offset = kThirdActionOffset;
		}
		[self addLabelWithTitle:displayTitles[_thirdAction] withY:(pageViewFrame.size.height * offset) withColor:displayColors[_thirdAction]];
	}

	if (_firstAction == kActionNone && _secondAction == kActionNone && _thirdAction == kActionNone) {
		[self addLabelWithTitle:@"No Actions Enabled" withY:(pageViewFrame.size.height / 2) withColor:[UIColor redColor]];
	}

	[self insertSubview:createdView belowSubview:_verticalScrollView];
}

%new
-(void)removeLabels {
	if (createdView != nil) {
		NSArray *subViews = [createdView subviews];
		for (UIView *view in subViews) {
			[view removeFromSuperview];
			[view release];
		}
		[createdView removeFromSuperview];
		[createdView release];
		createdView = nil;
	}
}

%new
-(void)scrollViewProgressUpdated:(CGFloat)arg1 withDirection:(Direction)arg2 withIsSpringBoard:(BOOL)arg3 {
	if (createdView != nil) {
		CGFloat alpha = fabs(arg1) * 2.5;
		if (alpha > 0.5) {
			alpha = 0.5;
		}
		createdView.backgroundColor = [createdView.backgroundColor colorWithAlphaComponent:alpha];
	}
	if (arg2 == currentDirection) {
		return;
	}
	if (currentDirection == kUp || currentDirection == kDown) {
		[self removeLabels];
	}
	currentDirection = arg2;
	if (currentDirection == kUp || currentDirection == kDown) {
		_shouldPerformAction = NO;
		[self updateActionswithIsSpringBoard:arg3];
		[self createLabels];
	}
}

-(void)scrollViewWillEndDragging:(id)arg1 withVelocity:(CGPoint)arg2 targetContentOffset:(id)arg3 {
	_shouldPerformAction = YES;
	%orig(arg1, arg2, arg3);
}
%end

%hook SBDeckSwitcherViewController
UIAlertController *alert = nil;

-(void)viewWillDisappear:(BOOL)arg1 {
	if (alert) {
		[alert dismissViewControllerAnimated:YES completion:nil];
		alert = nil;
	}
}

%new
-(void)respring {
	[[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
}

%new
-(void)killAll {
	[self closeAllApplications:YES];
	if (isAutoDismissOnKillEnabled) {
		[self dismissSwitcher];
	}
}

%new
-(void)killApp:(SBDeckSwitcherItemContainer *)container withDisplayItem:(SBDisplayItem *)item {
	NSString *nowPlayingBundleIdentifier = [[[%c(SBMediaController) sharedInstance] nowPlayingApplication] bundleIdentifier];
	if ([item.displayIdentifier isEqualToString:nowPlayingBundleIdentifier] && [[%c(SBMediaController) sharedInstance] isPlaying]) {
		if (isAlertNowPlayingEnabled) {
			// should probably avoid UIAlertControllers in SpringBoard but oh well.
			if (alert) {
				[alert dismissViewControllerAnimated:YES completion:nil];
				alert = nil;
			}

			NSString *appName = (MSHookIvar<UILabel *>(container, "_iconTitle")).text;
			NSString *displayMessage = [NSString stringWithFormat:@"%@ is currently now playing app. Are you sure you'd like to close it?", appName];
			alert = [UIAlertController alertControllerWithTitle:@"EnhancedSwitcherClose" message:displayMessage preferredStyle:UIAlertControllerStyleAlert];


			UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes, Close" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
				[self killDisplayItemOfContainer:container withVelocity:1.0];
				NSArray *items = [self displayItems];
				if ([items count] == 1 && isAutoCloseSwitcherEnabled) {
					[self dismissSwitcher];
				}
				alert = nil;
			}];
			UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No, Keep" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
				alert = nil;
			}];

			[alert addAction:yesAction];
			[alert addAction:cancelAction];

			[self presentViewController:alert animated:YES completion:nil];

			return;
		} else if (isNowPlayingEnabled) {
			return;
		}
	}
	[self killDisplayItemOfContainer:container withVelocity:1.0];
	NSArray *items = [self displayItems];
	if ([items count] == 1 && isAutoCloseSwitcherEnabled) {
		[self dismissSwitcher];
	}
}

%new
-(void)relaunchAll {
	NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[self displayItems]];
	if ([items count] > 1) {
		[self closeAllApplications:NO];
		[self launchApplications:items withIdentifiers:NO];
	}
	[items release];
}

%new
-(void)relaunchApp:(SBDeckSwitcherItemContainer *)container withDisplayItem:(SBDisplayItem *)item {
	NSString *nowPlayingBundleIdentifier = [[[%c(SBMediaController) sharedInstance] nowPlayingApplication] bundleIdentifier];
	if (isNowPlayingEnabled && [item.displayIdentifier isEqualToString:nowPlayingBundleIdentifier] && [[%c(SBMediaController) sharedInstance] isPlaying]) {
		return;
	}
	[self killDisplayItemOfContainer:container withVelocity:1.0];
	[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:item.displayIdentifier suspended:NO];
}

%new
-(void)dismissSwitcher {
	SBDisplayItem *returnDisplayItem = MSHookIvar<SBDisplayItem *>(self, "_returnToDisplayItem");
	SBDeckSwitcherItemContainer *returnContainer = [self _itemContainerForDisplayItem:returnDisplayItem];
	SBDeckSwitcherPageView *returnPage = MSHookIvar<SBDeckSwitcherPageView *>(returnContainer, "_pageView");
	[returnContainer _handlePageViewTap:returnPage];
}

%new
-(void)launchApp:(SBDeckSwitcherItemContainer *)container {
	SBDeckSwitcherPageView *returnPage = MSHookIvar<SBDeckSwitcherPageView *>(container, "_pageView");
	[container _handlePageViewTap:returnPage];
}

%new
-(void)quickLaunch {
	NSMutableArray *items = prefixApps(kQuickLaunchApps);
	if ([items count] > 0) {
		[self launchApplications:items withIdentifiers:YES];
	}
	[items release];
}

%new
-(void)performAction:(Action)action withContainer:(SBDeckSwitcherItemContainer *)container withDisplayItem:(SBDisplayItem *)item {
	switch (action) {
		case kActionNone:
			return;
		case kRespring:
			[self respring];
			return;
		case kKillAll:
			[self killAll];
			return;
		case kRelaunchAll:
			[self relaunchAll];
			return;
		case kLaunch:
			[self launchApp:container];
			return;
		case kDismissSwitcher:
			[self dismissSwitcher];
			return;
		case kClose:
			[self killApp:container withDisplayItem:item];
			return;
		case kRelaunch:
			[self relaunchApp:container withDisplayItem:item];
			return;
		case kQuickLaunch:
			[self quickLaunch];
			return;
		default:
			return;
	}
}

%new
-(void)performActionWithActionIndex:(NSInteger)index withContainer:(SBDeckSwitcherItemContainer *)container withDisplayItem:(SBDisplayItem *)item withIsSpringBoard:(BOOL)isSpringBoard {
	if (isSpringBoard && !isHomeEnabled) {
		return;
	}
	Action currentActions[3] = {[container firstAction], [container secondAction], [container thirdAction]};
	while (index >= 0) {
		if (currentActions[index] != kActionNone) {
			break;
		}
		index--;
	}
	if (index < 0) {
		return;
	}
	[self performAction:currentActions[index] withContainer:container withDisplayItem:item];
}

-(void)scrollViewKillingProgressUpdated:(CGFloat)arg1 ofContainer:(SBDeckSwitcherItemContainer *)arg2 {
	if (isTweakEnabled && !isClosingAll) {
		SBDisplayItem *selected = [arg2 displayItem];
		BOOL isSpringBoard = [selected.displayIdentifier isEqualToString:@"com.apple.springboard"];

		if (isSpringBoard && !isHomeEnabled) {
			%orig(arg1, arg2);
			return;
		}

		BOOL isAppEnabled = isDefaultAppEnabled;
		if (boolValuePerApp(selected.displayIdentifier, kOverridePerApp, NO)) {
			isAppEnabled = boolValuePerApp(selected.displayIdentifier, kPerApp, YES);
		}

		if (!isAppEnabled) {
			%orig(arg1, arg2);
			return;
		}

		if (arg1 > 0.0) {
			[arg2 scrollViewProgressUpdated:arg1 withDirection:kUp withIsSpringBoard:isSpringBoard];
			if ([arg2 shouldPerformAction]) {
				if (arg1 > kThirdActionUpOffset) {
					[self performActionWithActionIndex:2 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				} else if (arg1 > kSecondActionUpOffset) {
					[self performActionWithActionIndex:1 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				} else if (arg1 > kFirstActionUpOffset) {
					[self performActionWithActionIndex:0 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				}
				[arg2 scrollViewProgressUpdated:arg1 withDirection:kNone withIsSpringBoard:isSpringBoard];
			}
		} else if (arg1 < 0.0) {
			[arg2 scrollViewProgressUpdated:arg1 withDirection:kDown withIsSpringBoard:isSpringBoard];
			if ([arg2 shouldPerformAction]) {
				if (arg1 < kThirdActionDownOffset) {
					[self performActionWithActionIndex:2 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				} else if (arg1 < kSecondActionDownOffset) {
					[self performActionWithActionIndex:1 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				} else if (arg1 < kFirstActionDownOffset) {
					[self performActionWithActionIndex:0 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				}
				[arg2 scrollViewProgressUpdated:arg1 withDirection:kNone withIsSpringBoard:isSpringBoard];
			}
		} else {
			[arg2 scrollViewProgressUpdated:arg1 withDirection:kNone withIsSpringBoard:isSpringBoard];
		}
	}

	%orig(arg1, arg2);
}

-(_Bool)isDisplayItemOfContainerRemovable:(id)arg1 {
	BOOL isAppEnabled = isDefaultAppEnabled;
	if (boolValuePerApp([arg1 displayItem].displayIdentifier, kOverridePerApp, NO)) {
		isAppEnabled = boolValuePerApp([arg1 displayItem].displayIdentifier, kPerApp, YES);
	}

	if (isTweakEnabled && isAppEnabled) {
		return NO;
	}
	return %orig(arg1);
}

%new
-(void)closeAllApplications:(BOOL)includeWhitelist  {
	isClosingAll = YES;
	NSString *nowPlayingBundleIdentifier = [[[%c(SBMediaController) sharedInstance] nowPlayingApplication] bundleIdentifier];
	NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[self displayItems]];
	[items removeObjectAtIndex:0]; // remove springboard
	for(SBDisplayItem *item in items) { // close applications
		if (includeWhitelist) {
			if (!isWhitelistEnabled || !boolValuePerApp(item.displayIdentifier, kPerAppKill, NO)) {
				if (isNowPlayingOnKillEnabled && [item.displayIdentifier isEqualToString:nowPlayingBundleIdentifier] && [[%c(SBMediaController) sharedInstance] isPlaying]) {
					continue;
				}
				[self killDisplayItemOfContainer:[self _itemContainerForDisplayItem:item] withVelocity:1.0];
			}
		} else {
			[self killDisplayItemOfContainer:[self _itemContainerForDisplayItem:item] withVelocity:1.0];
		}
	}
	isClosingAll = NO;
	[items release];
}

%new
-(void)launchApplications:(NSMutableArray *)itemsToRun withIdentifiers:(BOOL)areIdentifiers {
	if (areIdentifiers) {
		for (NSString *iden in itemsToRun) { // launch applications
			[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:iden suspended:NO];
		}
	} else {
		for (SBDisplayItem *item in itemsToRun) { // launch applications
			[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:item.displayIdentifier suspended:NO];
		}
	}
}
%end

%dtor {
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CFSTR("com.dgh0st.enhancedswitcherclose/settingschanged"), NULL);
}

%ctor {
	preferencesChanged();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)preferencesChanged, CFSTR("com.dgh0st.enhancedswitcherclose/settingschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}