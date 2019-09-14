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
#define kColorPath @"/var/mobile/Library/Preferences/com.dgh0st.enhancedswitcherclose.color.plist"
#define identifier @"com.dgh0st.enhancedswitcherclose"
#define kPerApp @"isAppEnabled-"
#define kOverridePerApp @"isOverrideEnabled-"

#define kDefaultSwitcherCardScale 0.75

typedef NS_ENUM(NSInteger, Direction) {
	kUp = 0,
	kDown,
	kNone
};

typedef NS_ENUM(NSInteger, Action) {
	kActionNone = 0,
	kRespring,
	kKillAll,
	kRelaunchAll,
	kLaunch,
	kDismissSwitcher,
	kClose,
	kRelaunch,
	kQuickLaunch,
	kSafemode
};

typedef NS_ENUM(NSInteger, Position) {
	kLeft = 0,
	kCenter,
	kRight
};

static NSString *displayTitles[10] = {
	@"",
	@"Respring",
	@"Kill-All",
	@"Relaunch-All",
	@"Launch",
	@"Dismiss Switcher",
	@"Close",
	@"Relaunch",
	@"Quick Launch",
	@"Safemode"
};

static BOOL isTweakEnabled = YES;
static BOOL isHomeEnabled = YES;
static BOOL isHomeSwipeDownEnabled = YES;
static BOOL isHomeSwipeUpEnabled = YES;
static BOOL isNowPlayingEnabled = NO;
static BOOL isAlertNowPlayingEnabled = NO;
static BOOL isWhitelistEnabled = NO;
static BOOL isAutoDismissOnKillEnabled = YES;
static BOOL isNowPlayingOnKillEnabled = NO;
static BOOL isAutoCloseSwitcherEnabled = NO;
static BOOL isDefaultAppEnabled = YES;
static BOOL isDefaultAppSwipeDownEnabled = YES;
static BOOL isDefaultAppSwipeUpEnabled = YES;
static Action defaultAppFirstActionDown = kLaunch;
static Action defaultAppSecondActionDown = kDismissSwitcher;
static Action defaultAppThirdActionDown = kActionNone;
static Action defaultAppFirstActionUp = kRelaunch;
static Action defaultAppSecondActionUp = kClose;
static Action defaultAppThirdActionUp = kActionNone;
static Position labelPosition = kCenter;

NSDictionary *prefs = nil;
BOOL isClosingAll = NO;
UIAlertController *alert = nil;
BOOL isUpdatingScrollContentSize = NO;

static void reloadPrefs() {
	if (prefs != nil) {
		[prefs release];
		prefs = nil;
	}

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
	NSString *temp = [[NSDictionary dictionaryWithContentsOfFile:kColorPath] objectForKey:key];
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
	isHomeSwipeDownEnabled = boolValueForKey(@"isHomeSwipeDownEnabled", YES);
	isHomeSwipeUpEnabled = boolValueForKey(@"isHomeSwipeUpEnabled", YES);
	isNowPlayingEnabled = boolValueForKey(@"isNowPlayingEnabled", NO);
	isAlertNowPlayingEnabled = boolValueForKey(@"isAlertNowPlayingEnabled", NO);
	isWhitelistEnabled = boolValueForKey(@"isWhitelistEnabled", NO);
	isAutoDismissOnKillEnabled = boolValueForKey(@"isAutoDismissOnKillEnabled", YES);
	isNowPlayingOnKillEnabled = boolValueForKey(@"isNowPlayingOnKillEnabled", NO);
	isAutoCloseSwitcherEnabled = boolValueForKey(@"isAutoCloseSwitcherEnabled", NO);
	isDefaultAppEnabled = boolValueForKey(@"isAppEnabled", YES);
	isDefaultAppSwipeDownEnabled = boolValueForKey(@"isAppSwipeDownEnabled", YES);
	isDefaultAppSwipeUpEnabled = boolValueForKey(@"isAppSwipeUpEnabled", YES);
	defaultAppFirstActionDown = (Action)intValueForKey(@"AppFirstActionDown", kLaunch);
	defaultAppSecondActionDown = (Action)intValueForKey(@"AppSecondActionDown", kDismissSwitcher);
	defaultAppThirdActionDown = (Action)intValueForKey(@"AppThirdActionDown", kActionNone);
	defaultAppFirstActionUp = (Action)intValueForKey(@"AppFirstActionUp", kRelaunch);
	defaultAppSecondActionUp = (Action)intValueForKey(@"AppSecondActionUp", kClose);
	defaultAppThirdActionUp = (Action)intValueForKey(@"AppThirdActionUp", kActionNone);
	labelPosition = (Position)intValueForKey(@"LabelPosition", kCenter);
}

// note these are not the only methods this protocol has
@protocol SBMainAppSwitcherContentViewControllerDelegate <NSObject>
@required
-(void)switcherContentController:(id)arg1 selectedAppLayout:(id)arg2; // iOS 11+
@end

// note these are not the only methods this protocol has
@protocol SBMainAppSwitcherContentViewControllerDataSource <NSObject>
@required
-(id)returnToAppLayout;
@end

// note these are not the only methods this protocol has
@protocol SBFluidSwitcherItemContainerDelegate <NSObject> // iOS 11+
@required
-(BOOL)isAppLayoutOfContainerRemovable:(id)arg1;
// -(CGFloat)minimumVerticalTranslationForKillingOfContainer:(id)arg1;
@end

@interface SBAppSwitcherSettings : NSObject
-(NSInteger)effectiveKillAffordanceStyle; // iOS 11+
@end

@interface SBDisplayItem : NSObject
@property (nonatomic, readonly) NSString* displayIdentifier;
@end

@interface SBAppLayout : NSObject // iOS 11+
-(NSArray *)allItems; // array of SBDisplayItems
+(id)homeScreenAppLayout;
@end

@interface SBDeckSwitcherViewController : UIViewController // iOS 9 - 10
@property(retain, nonatomic) NSArray *displayItems;
-(void)killDisplayItemOfContainer:(id)arg1 withVelocity:(CGFloat)arg2;
-(id)_itemContainerForDisplayItem:(id)arg1;
-(void)closeAllApplications:(BOOL)includeWhitelist;
-(void)killAll;
-(void)killApp:(id)container withDisplayItem:(id)item;
-(void)relaunchAll;
-(void)relaunchApp:(id)container withDisplayItem:(id)item;
-(void)dismissSwitcher;
-(void)launchApp:(id)container;
-(void)RIPCrashReporter;
-(void)performAction:(Action)action withContainer:(id)container withDisplayItem:(id)item;
-(void)performActionWithActionIndex:(NSInteger)index withContainer:(id)container withDisplayItem:(id)item withIsSpringBoard:(BOOL)isSpringBoard;
@end

@interface SBFluidSwitcherViewController : UIViewController // iOS 11+
@property (nonatomic, readonly) NSArray *appLayouts;
@property (assign, nonatomic, weak) id<SBMainAppSwitcherContentViewControllerDelegate> delegate;
@property (assign, nonatomic, weak) id<SBMainAppSwitcherContentViewControllerDataSource> dataSource;
-(CGFloat)switcherCardScale;
-(void)killAppLayoutOfContainer:(id)arg1 withVelocity:(CGFloat)arg2 forReason:(NSInteger)arg3;
-(void)selectedAppLayoutOfContainer:(id)arg1;
-(id)_itemContainerForAppLayoutIfExists:(id)arg1;
-(void)closeAllApplications:(BOOL)includeWhitelist;
-(void)killAll;
-(void)killApp:(id)container withDisplayItem:(id)item;
-(void)relaunchAll;
-(void)relaunchApp:(id)container withDisplayItem:(id)item;
-(void)dismissSwitcher;
-(void)launchApp:(id)container;
-(void)RIPCrashReporter;
-(void)performAction:(Action)action withContainer:(id)container withDisplayItem:(id)item;
-(void)performActionWithActionIndex:(NSInteger)index withContainer:(id)container withDisplayItem:(id)item withIsSpringBoard:(BOOL)isSpringBoard;
@end

@protocol EnhancedSwitcherCloseViewControllerDelegate <NSObject>
@required
-(CGRect)_frameForPageView;
-(id)displayItem;
-(void)insertEnhancedSwitcherView:(UIView *)view;
@end

@interface EnhancedSwitcherCloseViewController : NSObject
@property (nonatomic, retain) UIView *createdView;
@property (nonatomic, assign) Direction currentDirection;
@property (nonatomic, assign) BOOL _shouldPerformAction;
@property (nonatomic, assign) Action _firstAction;
@property (nonatomic, assign) Action _secondAction;
@property (nonatomic, assign) Action _thirdAction;
@property (assign, nonatomic) id<EnhancedSwitcherCloseViewControllerDelegate> delegate;
-(id)initWithDelegate:(id<EnhancedSwitcherCloseViewControllerDelegate>)arg1;
-(void)scrollViewProgressUpdated:(CGFloat)arg1 withDirection:(Direction)arg2 withIsSpringBoard:(BOOL)arg3;
-(BOOL)shouldPerformAction;
-(void)allowActionPerform;
-(Action)firstAction;
-(Action)secondAction;
-(Action)thirdAction;
@end

@interface SBDeckSwitcherItemContainer : UIView <EnhancedSwitcherCloseViewControllerDelegate> // iOS 9 - 10
@property (nonatomic, retain) EnhancedSwitcherCloseViewController *enhancedController;
@property(readonly, retain, nonatomic) SBDisplayItem *displayItem;
-(void)_handlePageViewTap:(id)arg1;
-(CGRect)_frameForPageView;
-(void)insertEnhancedSwitcherView:(UIView *)view;
@end

@interface SBFluidSwitcherItemContainer : UIView <EnhancedSwitcherCloseViewControllerDelegate> // iOS 11+
@property (nonatomic, retain) EnhancedSwitcherCloseViewController *enhancedController;
@property (nonatomic, retain) SBAppLayout *appLayout;
@property (nonatomic, weak, readonly) id<SBFluidSwitcherItemContainerDelegate> delegate;
// -(void)_handlePageViewTap:(id)arg1; // can use selectedAppLayoutOfContainer: (for app tap) or switcherContentController:selectedAppLayout: (for switcher dismiss)
-(CGRect)_frameForPageView;
-(id)displayItem;
-(void)insertEnhancedSwitcherView:(UIView *)view;
@end

@interface SBDeckSwitcherPageView // iOS 9 - 10
@end

@interface SBFluidSwitcherItemContainerHeaderView // iOS 11+
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

@interface UIView (EnhancedSwitcherClose)
-(CGSize)size;
@end

@implementation EnhancedSwitcherCloseViewController
-(id)initWithDelegate:(id<EnhancedSwitcherCloseViewControllerDelegate>)arg1 {
	self = [super init];
	if (self != nil) {
		self.delegate = arg1;

		[self removeLabels];
		self.createdView = nil;
		self.currentDirection = kNone;
		self._shouldPerformAction = NO;
		self._firstAction = kActionNone;
		self._secondAction = kActionNone;
		self._thirdAction = kActionNone;
	}
	return self;
}

-(void)addLabelWithTitle:(NSString *)arg1 withY:(CGFloat)arg2 withColor:(UIColor *)arg3 {
	CGRect pageViewFrame = [self.delegate _frameForPageView];

	UIView *leftSeparator = [[UIView alloc] initWithFrame:CGRectMake(8, arg2, pageViewFrame.size.width / 3 - 8, 2)];
	leftSeparator.backgroundColor = arg3;
	[self.createdView addSubview:leftSeparator];

	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(pageViewFrame.size.width / 3, arg2 - 8, pageViewFrame.size.width / 3, 16)];
	label.text = arg1;
	label.textColor = arg3;
	label.textAlignment = NSTextAlignmentCenter;
	[self.createdView addSubview:label];

	UIView *rightSeparator = [[UIView alloc] initWithFrame:CGRectMake(pageViewFrame.size.width / 3 * 2, arg2, pageViewFrame.size.width / 3 - 8, 2)];
	rightSeparator.backgroundColor = arg3;
	[self.createdView addSubview:rightSeparator];

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

-(void)createLabels {
	NSString *respringColor = stringValueForKey(@"respringColor", @"#FF0000");
	NSString *killAllColor = stringValueForKey(@"killAllColor", @"#FF8800");
	NSString *relaunchAllColor = stringValueForKey(@"relaunchAllColor", @"#00FF00");
	NSString *launchColor = stringValueForKey(@"launchColor", @"#00FF00");
	NSString *dismissSwitcherColor = stringValueForKey(@"dismissSwitcherColor", @"#FF8800");
	NSString *closeColor = stringValueForKey(@"closeColor", @"#FF0000");
	NSString *relaunchColor = stringValueForKey(@"relaunchColor", @"#FF8800");
	NSString *quickLaunchColor = stringValueForKey(@"quickLaunchColor", @"#00FF00");
	NSString *safemodeColor = stringValueForKey(@"safemodeColor", @"#FFFF00");

	UIColor *displayColors[10] = {
		nil,
		(UIColor *)LCPParseColorString(respringColor, @"#FF0000"),
		(UIColor *)LCPParseColorString(killAllColor, @"#FF8800"),
		(UIColor *)LCPParseColorString(relaunchAllColor, @"#00FF00"),
		(UIColor *)LCPParseColorString(launchColor, @"#00FF00"),
		(UIColor *)LCPParseColorString(dismissSwitcherColor, @"#FF8800"),
		(UIColor *)LCPParseColorString(closeColor, @"#FF0000"),
		(UIColor *)LCPParseColorString(relaunchColor, @"#FF8800"),
		(UIColor *)LCPParseColorString(quickLaunchColor, @"#00FF00"),
		(UIColor *)LCPParseColorString(safemodeColor, @"#FFFF00")
	};

	CGRect pageViewFrame = [self.delegate _frameForPageView];

	if (self.createdView == nil) {
		NSString *backgroundColor = stringValueForKey(@"backgroundColor", @"#000000");

		self.createdView = [[UIView alloc] initWithFrame:CGRectMake(pageViewFrame.origin.x, 0, pageViewFrame.size.width, pageViewFrame.size.height)];
		self.createdView.backgroundColor = (UIColor *)LCPParseColorString(backgroundColor, @"#000000");
	}
	
	if (self._firstAction != kActionNone) {
		CGFloat offset = 0.0;
		if (self.currentDirection == kUp) {
			offset = (1 - kFirstActionOffset);
		} else if (self.currentDirection == kDown) {
			offset = kFirstActionOffset;
		}
		[self addLabelWithTitle:displayTitles[self._firstAction] withY:(pageViewFrame.size.height * offset) withColor:displayColors[self._firstAction]];
	}

	if (self._secondAction != kActionNone) {
		CGFloat offset = 0.0;
		if (self.currentDirection == kUp) {
			offset = (1 - kSecondActionOffset);
		} else if (self.currentDirection == kDown) {
			offset = kSecondActionOffset;
		}
		[self addLabelWithTitle:displayTitles[self._secondAction] withY:(pageViewFrame.size.height * offset) withColor:displayColors[self._secondAction]];
	}

	if (self._thirdAction != kActionNone) {
		CGFloat offset = 0.0;
		if (self.currentDirection == kUp) {
			offset = (1 - kThirdActionOffset);
		} else if (self.currentDirection == kDown) {
			offset = kThirdActionOffset;
		}
		[self addLabelWithTitle:displayTitles[self._thirdAction] withY:(pageViewFrame.size.height * offset) withColor:displayColors[self._thirdAction]];
	}

	if (self._firstAction == kActionNone && self._secondAction == kActionNone && self._thirdAction == kActionNone) {
		[self addLabelWithTitle:@"No Actions Enabled" withY:(pageViewFrame.size.height / 2) withColor:[UIColor redColor]];
	}

	[self.delegate insertEnhancedSwitcherView:self.createdView];
}

-(void)removeLabels {
	if (self.createdView != nil) {
		NSArray *subViews = [self.createdView subviews];
		for (UIView *view in subViews) {
			[view removeFromSuperview];
			[view release];
		}
		[self.createdView removeFromSuperview];
		[self.createdView release];
		self.createdView = nil;
	}
}

-(void)scrollViewProgressUpdated:(CGFloat)arg1 withDirection:(Direction)arg2 withIsSpringBoard:(BOOL)arg3 {
	if (self.createdView != nil) {
		CGFloat alpha = fabs(arg1) * 3;
		if (alpha > 0.66) {
			alpha = 0.66;
		}
		self.createdView.backgroundColor = [self.createdView.backgroundColor colorWithAlphaComponent:alpha];
	}
	if (arg2 == self.currentDirection) {
		return;
	}
	if (self.currentDirection == kUp || self.currentDirection == kDown) {
		[self removeLabels];
	}
	self.currentDirection = arg2;
	if (self.currentDirection == kUp || self.currentDirection == kDown) {
		self._shouldPerformAction = NO;
		[self updateActionswithIsSpringBoard:arg3];
		[self createLabels];
	}
}

-(BOOL)shouldPerformAction {
	if (self._shouldPerformAction) {
		self._shouldPerformAction = NO;
		return YES;
	}
	return NO;
}

-(void)allowActionPerform {
	self._shouldPerformAction = YES;
}

-(Action)firstAction {
	return self._firstAction;
}

-(Action)secondAction {
	return self._secondAction;
}

-(Action)thirdAction {
	return self._thirdAction;
}

-(void)updateActionswithIsSpringBoard:(BOOL)isSpringBoard {
	BOOL isOverrideEnabled = NO;

	NSString *prefix = @"";
	NSString *itemIdentifier = @"";
	if (isSpringBoard) {
		prefix = @"Home";
		itemIdentifier = @"";
	} else {
		SBDisplayItem *displayItem = [self.delegate displayItem];
		isOverrideEnabled = boolValuePerApp(displayItem.displayIdentifier, kOverridePerApp, NO);
		prefix = @"App";
		itemIdentifier = [NSString stringWithFormat:@"-%@", displayItem.displayIdentifier];
	}

	NSString *suffix = @"";
	Action defaultFirstAction = kActionNone;
	Action defaultSecondAction = kActionNone;
	Action defaultThirdAction = kActionNone;
	if (self.currentDirection == kUp) {
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
	} else if (self.currentDirection == kDown) {
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
		self._firstAction = (Action)intValuePerApp(itemIdentifier, [NSString stringWithFormat:@"%@%@%@", prefix, kFirstAction, suffix], defaultFirstAction);
		self._secondAction = (Action)intValuePerApp(itemIdentifier, [NSString stringWithFormat:@"%@%@%@", prefix, kSecondAction, suffix], defaultSecondAction);
		self._thirdAction = (Action)intValuePerApp(itemIdentifier, [NSString stringWithFormat:@"%@%@%@", prefix, kThirdAction, suffix], defaultThirdAction);
	} else {
		self._firstAction = defaultFirstAction;
		self._secondAction = defaultSecondAction;
		self._thirdAction = defaultThirdAction;
	}
}

-(void)dealloc {
	[self removeLabels];

	[super dealloc];
}
@end

static void respring() {
	[[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
}

static void launchApplications(NSMutableArray *itemsToRun, BOOL areIdentifiers) {
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

static void quickLaunch() {
	NSMutableArray *items = prefixApps(@"QuickLaunch-");
	if ([items count] > 0)
		launchApplications(items, YES);
	[items release];
}

%group iOS9And10
%hook SBDeckSwitcherItemContainer
%property (nonatomic, retain) EnhancedSwitcherCloseViewController *enhancedController;

-(id)initWithFrame:(CGRect)arg1 displayItem:(id)arg2 delegate:(id)arg3 {
	self = %orig(arg1, arg2, arg3);
	if (self != nil)
		self.enhancedController = [[EnhancedSwitcherCloseViewController alloc] initWithDelegate:self];
	return self;
}

%new
-(void)insertEnhancedSwitcherView:(UIView *)view {
	UIScrollView *_verticalScrollView = MSHookIvar<UIScrollView *>(self, "_verticalScrollView");
	[self insertSubview:view belowSubview:_verticalScrollView];
}

-(void)scrollViewWillEndDragging:(id)arg1 withVelocity:(CGPoint)arg2 targetContentOffset:(id)arg3 {
	[self.enhancedController allowActionPerform];
	%orig(arg1, arg2, arg3);
}

-(void)dealloc {
	[self.enhancedController release];
	self.enhancedController = nil;

	%orig();
}
%end

%hook SBDeckSwitcherViewController
-(void)viewWillDisappear:(BOOL)arg1 {
	%orig(arg1);
	
	if (alert) {
		[alert dismissViewControllerAnimated:YES completion:nil];
		alert = nil;
	}
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
		launchApplications(items, NO);
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
-(void)performAction:(Action)action withContainer:(SBDeckSwitcherItemContainer *)container withDisplayItem:(SBDisplayItem *)item {
	switch (action) {
		case kActionNone:
			return;
		case kRespring:
			respring();
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
			quickLaunch();
			return;
		case kSafemode:
			[self RIPCrashReporter];
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
	EnhancedSwitcherCloseViewController *enhancedController = container.enhancedController;
	Action currentActions[3] = {[enhancedController firstAction], [enhancedController secondAction], [enhancedController thirdAction]};
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

		if (isSpringBoard) {
			if (!isHomeEnabled || (arg1 > 0.0 && !isHomeSwipeUpEnabled) || (arg1 < 0.0 && !isHomeSwipeDownEnabled)) {
				%orig(arg1, arg2);
				return;
			}
		} else {
			BOOL isAppEnabled = isDefaultAppEnabled;
			BOOL isAppSwipeUpEnabled = isDefaultAppSwipeUpEnabled;
			BOOL isAppSwipeDownEnabled = isDefaultAppSwipeDownEnabled;
			if (boolValuePerApp(selected.displayIdentifier, kOverridePerApp, NO)) {
				isAppEnabled = boolValuePerApp(selected.displayIdentifier, kPerApp, YES);
				isAppSwipeUpEnabled = boolValuePerApp(selected.displayIdentifier, @"isAppSwipeUpEnabled-", YES);
				isAppSwipeDownEnabled = boolValuePerApp(selected.displayIdentifier, @"isAppSwipeDownEnabled-", YES);
			}

			if (!isAppEnabled || (arg1 > 0.0 && !isAppSwipeUpEnabled) || (arg1 < 0.0 && !isAppSwipeDownEnabled)) {
				%orig(arg1, arg2);
				return;
			}
		}

		EnhancedSwitcherCloseViewController *enhancedController = arg2.enhancedController;

		if (arg1 > 0.0) {
			[enhancedController scrollViewProgressUpdated:arg1 withDirection:kUp withIsSpringBoard:isSpringBoard];
			if ([enhancedController shouldPerformAction]) {
				if (arg1 > kThirdActionUpOffset) {
					[self performActionWithActionIndex:2 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				} else if (arg1 > kSecondActionUpOffset) {
					[self performActionWithActionIndex:1 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				} else if (arg1 > kFirstActionUpOffset) {
					[self performActionWithActionIndex:0 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				}
				[enhancedController scrollViewProgressUpdated:arg1 withDirection:kNone withIsSpringBoard:isSpringBoard];
			}
		} else if (arg1 < 0.0) {
			[enhancedController scrollViewProgressUpdated:arg1 withDirection:kDown withIsSpringBoard:isSpringBoard];
			if ([enhancedController shouldPerformAction]) {
				if (arg1 < kThirdActionDownOffset) {
					[self performActionWithActionIndex:2 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				} else if (arg1 < kSecondActionDownOffset) {
					[self performActionWithActionIndex:1 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				} else if (arg1 < kFirstActionDownOffset) {
					[self performActionWithActionIndex:0 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				}
				[enhancedController scrollViewProgressUpdated:arg1 withDirection:kNone withIsSpringBoard:isSpringBoard];
			}
		} else {
			[enhancedController scrollViewProgressUpdated:arg1 withDirection:kNone withIsSpringBoard:isSpringBoard];
		}
	}

	%orig(arg1, arg2);
}

-(_Bool)isDisplayItemOfContainerRemovable:(id)arg1 {
	SBDisplayItem *selected = [arg1 displayItem];
	BOOL isSpringBoard = [selected.displayIdentifier isEqualToString:@"com.apple.springboard"];

	if (isSpringBoard || !isTweakEnabled) {
		return %orig(arg1);
	} else {
		BOOL isAppEnabled = isDefaultAppEnabled;
		BOOL isAppSwipeUpEnabled = isDefaultAppSwipeUpEnabled;
		if (boolValuePerApp(selected.displayIdentifier, kOverridePerApp, NO)) {
			isAppEnabled = boolValuePerApp(selected.displayIdentifier, kPerApp, YES);
			isAppSwipeUpEnabled = boolValuePerApp(selected.displayIdentifier, @"isAppSwipeUpEnabled-", YES);
		}

		if (isAppEnabled && isAppSwipeUpEnabled) {
			return NO;
		}
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
			if (!isWhitelistEnabled || !boolValuePerApp(item.displayIdentifier, @"PerAppKill-", NO)) {
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
%end
%end

%group iOS11Plus
%hook SBFluidSwitcherItemContainer
%property (nonatomic, retain) EnhancedSwitcherCloseViewController *enhancedController;

-(id)initWithFrame:(CGRect)arg1 appLayout:(id)arg2 delegate:(id)arg3 active:(BOOL)arg4 {
	self = %orig(arg1, arg2, arg3, arg4);
	if (self != nil)
		self.enhancedController = [[EnhancedSwitcherCloseViewController alloc] initWithDelegate:self];
	return self;
}

-(void)_updateScrollEnabled {
	%orig(); // don't disable scrolling completely

	if (isTweakEnabled) {
		SBDisplayItem *selected = [self.appLayout allItems][0];
		BOOL isSpringBoard = [selected.displayIdentifier isEqualToString:@"com.apple.springboard"];

		if (isSpringBoard && (!isHomeEnabled || (!isHomeSwipeUpEnabled && !isHomeSwipeDownEnabled)))
			return; // don't re-enable scroll if home is not enabled

		BOOL isAppEnabled = isDefaultAppEnabled;
		BOOL isAppSwipeUpEnabled = isDefaultAppSwipeUpEnabled;
		BOOL isAppSwipeDownEnabled = isDefaultAppSwipeDownEnabled;
		if (boolValuePerApp(selected.displayIdentifier, kOverridePerApp, NO)) {
			isAppEnabled = boolValuePerApp(selected.displayIdentifier, kPerApp, YES);
			isAppSwipeUpEnabled = boolValuePerApp(selected.displayIdentifier, @"isAppSwipeUpEnabled-", YES);
			isAppSwipeDownEnabled = boolValuePerApp(selected.displayIdentifier, @"isAppSwipeDownEnabled-", YES);
		}

		if (!isAppEnabled || (!isAppSwipeUpEnabled && !isAppSwipeDownEnabled))
			return; // don't re-enable scroll if app is not enabled

		// fix vertical scroll being completely disabled
		if (![self.delegate isAppLayoutOfContainerRemovable:self]) {
			UIScrollView *_verticalScrollView = MSHookIvar<UIScrollView *>(self, "_verticalScrollView");
			SBAppSwitcherSettings *_settings = MSHookIvar<SBAppSwitcherSettings *>(self, "_settings");
			BOOL killingEnabled = [_settings effectiveKillAffordanceStyle] - 2 < 3;
			[_verticalScrollView setScrollEnabled:killingEnabled];
		}
	}
}

-(void)layoutSubviews {
	BOOL previousIsUpdatingScrollContentSize = isUpdatingScrollContentSize;
	if (isTweakEnabled)
		isUpdatingScrollContentSize = YES;

	%orig(); // need to let it calculate _verticalScrollView's contentSize correctly

	isUpdatingScrollContentSize = previousIsUpdatingScrollContentSize;
}

%new
-(void)insertEnhancedSwitcherView:(UIView *)view {
	UIScrollView *_verticalScrollView = MSHookIvar<UIScrollView *>(self, "_verticalScrollView");
	[self insertSubview:view belowSubview:_verticalScrollView];
}

%new
-(id)displayItem {
	return [self.appLayout allItems][0];
}

-(void)scrollViewWillEndDragging:(id)arg1 withVelocity:(CGPoint)arg2 targetContentOffset:(id)arg3 {
	[self.enhancedController allowActionPerform];
	%orig(arg1, arg2, arg3);
}

-(void)dealloc {
	[self.enhancedController release];
	self.enhancedController = nil;

	%orig();
}
%end

%hook SBFluidSwitcherViewController
-(void)viewWillDisappear:(BOOL)arg1 {
	%orig(arg1);
	
	if (alert) {
		[alert dismissViewControllerAnimated:YES completion:nil];
		alert = nil;
	}
}

%new
-(void)killAll {
	[self closeAllApplications:YES];
	if (isAutoDismissOnKillEnabled) {
		[self dismissSwitcher]; // not really required since default switcher does this already
	}
}

%new
-(void)killApp:(SBFluidSwitcherItemContainer *)container withDisplayItem:(SBDisplayItem *)item {
	NSString *nowPlayingBundleIdentifier = [[[%c(SBMediaController) sharedInstance] nowPlayingApplication] bundleIdentifier];
	if ([item.displayIdentifier isEqualToString:nowPlayingBundleIdentifier] && [[%c(SBMediaController) sharedInstance] isPlaying]) {
		if (isAlertNowPlayingEnabled) {
			// should probably avoid UIAlertControllers in SpringBoard but oh well.
			if (alert) {
				[alert dismissViewControllerAnimated:YES completion:nil];
				alert = nil;
			}

			SBFluidSwitcherItemContainerHeaderView *_iconAndLabelHeader = MSHookIvar<SBFluidSwitcherItemContainerHeaderView *>(container, "_iconAndLabelHeader");
			NSString *appName = (MSHookIvar<UILabel *>(_iconAndLabelHeader, "_firstIconTitle")).text;
			NSString *displayMessage = [NSString stringWithFormat:@"%@ is currently now playing app. Are you sure you'd like to close it?", appName];
			alert = [UIAlertController alertControllerWithTitle:@"EnhancedSwitcherClose" message:displayMessage preferredStyle:UIAlertControllerStyleAlert];

			UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes, Close" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
				[self killAppLayoutOfContainer:container withVelocity:1.0 forReason:1];
				NSArray *items = [self appLayouts];
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
	[self killAppLayoutOfContainer:container withVelocity:1.0 forReason:1];
	NSArray *items = [self appLayouts];
	if ([items count] == 1 && isAutoCloseSwitcherEnabled) {
		[self dismissSwitcher];
	}
}

%new
-(void)relaunchAll {
	NSMutableArray *items = [[NSMutableArray alloc] init];
	NSMutableArray *appLayouts = [[NSMutableArray alloc] initWithArray:[self appLayouts]];
	[appLayouts removeObject:[%c(SBAppLayout) homeScreenAppLayout]]; // remove springboard if exist
	for (SBAppLayout *item in appLayouts)
		[items addObject:[item allItems][0]];
	if ([items count] > 0) {
		[self closeAllApplications:NO];
		launchApplications(items, NO);
	}
	[appLayouts release];
	[items release];
}

%new
-(void)relaunchApp:(SBFluidSwitcherItemContainer *)container withDisplayItem:(SBDisplayItem *)item {
	NSString *nowPlayingBundleIdentifier = [[[%c(SBMediaController) sharedInstance] nowPlayingApplication] bundleIdentifier];
	if (isNowPlayingEnabled && [item.displayIdentifier isEqualToString:nowPlayingBundleIdentifier] && [[%c(SBMediaController) sharedInstance] isPlaying]) {
		return;
	}
	[self killAppLayoutOfContainer:container withVelocity:1.0 forReason:1];
	[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:item.displayIdentifier suspended:NO];
}

%new
-(void)dismissSwitcher {
	[self.delegate switcherContentController:self selectedAppLayout:[self.dataSource returnToAppLayout]];
}

%new
-(void)launchApp:(SBFluidSwitcherItemContainer *)container {
	[self selectedAppLayoutOfContainer:container];
}

%new
-(void)performAction:(Action)action withContainer:(SBFluidSwitcherItemContainer *)container withDisplayItem:(SBDisplayItem *)item {
	switch (action) {
		case kActionNone:
			return;
		case kRespring:
			respring();
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
			quickLaunch();
			return;
		case kSafemode:
			[self RIPCrashReporter];
			return;
		default:
			return;
	}
}

%new
-(void)performActionWithActionIndex:(NSInteger)index withContainer:(SBFluidSwitcherItemContainer *)container withDisplayItem:(SBDisplayItem *)item withIsSpringBoard:(BOOL)isSpringBoard {
	if (isSpringBoard && !isHomeEnabled) {
		return;
	}
	EnhancedSwitcherCloseViewController *enhancedController = container.enhancedController;
	Action currentActions[3] = {[enhancedController firstAction], [enhancedController secondAction], [enhancedController thirdAction]};
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

-(void)scrollViewKillingProgressUpdated:(CGFloat)arg1 ofContainer:(SBFluidSwitcherItemContainer *)arg2 {
	if (isTweakEnabled && !isClosingAll) {
		SBDisplayItem *selected = [arg2.appLayout allItems][0];
		BOOL isSpringBoard = [selected.displayIdentifier isEqualToString:@"com.apple.springboard"];

		if (isSpringBoard) {
			if (!isHomeEnabled || (arg1 > 0.0 && !isHomeSwipeUpEnabled) || (arg1 < 0.0 && !isHomeSwipeDownEnabled)) {
				%orig(arg1, arg2);
				return;
			}
		} else {
			BOOL isAppEnabled = isDefaultAppEnabled;
			BOOL isAppSwipeUpEnabled = isDefaultAppSwipeUpEnabled;
			BOOL isAppSwipeDownEnabled = isDefaultAppSwipeDownEnabled;
			if (boolValuePerApp(selected.displayIdentifier, kOverridePerApp, NO)) {
				isAppEnabled = boolValuePerApp(selected.displayIdentifier, kPerApp, YES);
				isAppSwipeUpEnabled = boolValuePerApp(selected.displayIdentifier, @"isAppSwipeUpEnabled-", YES);
				isAppSwipeDownEnabled = boolValuePerApp(selected.displayIdentifier, @"isAppSwipeDownEnabled-", YES);
			}

			if (!isAppEnabled || (arg1 > 0.0 && !isAppSwipeUpEnabled) || (arg1 < 0.0 && !isAppSwipeDownEnabled)) {
				%orig(arg1, arg2);
				return;
			}
		}

		EnhancedSwitcherCloseViewController *enhancedController = arg2.enhancedController;

		if (arg1 > 0.0) {
			[enhancedController scrollViewProgressUpdated:arg1 withDirection:kUp withIsSpringBoard:isSpringBoard];
			if ([enhancedController shouldPerformAction]) {
				if (arg1 > kThirdActionUpOffset) {
					[self performActionWithActionIndex:2 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				} else if (arg1 > kSecondActionUpOffset) {
					[self performActionWithActionIndex:1 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				} else if (arg1 > kFirstActionUpOffset) {
					[self performActionWithActionIndex:0 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				}
				[enhancedController scrollViewProgressUpdated:arg1 withDirection:kNone withIsSpringBoard:isSpringBoard];
			}
		} else if (arg1 < 0.0) {
			[enhancedController scrollViewProgressUpdated:arg1 withDirection:kDown withIsSpringBoard:isSpringBoard];
			if ([enhancedController shouldPerformAction]) {
				if (arg1 < kThirdActionDownOffset) {
					[self performActionWithActionIndex:2 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				} else if (arg1 < kSecondActionDownOffset) {
					[self performActionWithActionIndex:1 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				} else if (arg1 < kFirstActionDownOffset) {
					[self performActionWithActionIndex:0 withContainer:arg2 withDisplayItem:selected withIsSpringBoard:isSpringBoard];
				}
				[enhancedController scrollViewProgressUpdated:arg1 withDirection:kNone withIsSpringBoard:isSpringBoard];
			}
		} else {
			[enhancedController scrollViewProgressUpdated:arg1 withDirection:kNone withIsSpringBoard:isSpringBoard];
		}
	}

	%orig(arg1, arg2);
}

-(BOOL)isAppLayoutOfContainerRemovable:(SBFluidSwitcherItemContainer *)arg1 {
	if (isUpdatingScrollContentSize)
		return %orig(arg1);

	SBDisplayItem *selected = [arg1.appLayout allItems][0];
	BOOL isSpringBoard = [selected.displayIdentifier isEqualToString:@"com.apple.springboard"];

	if (isSpringBoard || !isTweakEnabled) {
		return %orig(arg1);
	} else {
		BOOL isAppEnabled = isDefaultAppEnabled;
		BOOL isAppSwipeUpEnabled = isDefaultAppSwipeUpEnabled;
		if (boolValuePerApp(selected.displayIdentifier, kOverridePerApp, NO)) {
			isAppEnabled = boolValuePerApp(selected.displayIdentifier, kPerApp, YES);
			isAppSwipeUpEnabled = boolValuePerApp(selected.displayIdentifier, @"isAppSwipeUpEnabled-", YES);
		}

		if (isAppEnabled && isAppSwipeUpEnabled) {
			return NO;
		}
	}
	return %orig(arg1);
}

-(CGFloat)minimumVerticalTranslationForKillingOfContainer:(SBFluidSwitcherItemContainer *)arg1 {
	if (!isUpdatingScrollContentSize)
		return %orig(arg1);

	SBDisplayItem *selected = [arg1.appLayout allItems][0];
	BOOL isSpringBoard = [selected.displayIdentifier isEqualToString:@"com.apple.springboard"];

	if (isSpringBoard || !isTweakEnabled) {
		return %orig(arg1);
	} else {
		BOOL isAppEnabled = isDefaultAppEnabled;
		BOOL isAppSwipeUpEnabled = isDefaultAppSwipeUpEnabled;
		if (boolValuePerApp(selected.displayIdentifier, kOverridePerApp, NO)) {
			isAppEnabled = boolValuePerApp(selected.displayIdentifier, kPerApp, YES);
			isAppSwipeUpEnabled = boolValuePerApp(selected.displayIdentifier, @"isAppSwipeUpEnabled-", YES);
		}

		if (isAppEnabled && isAppSwipeUpEnabled) {
			return -[arg1 _frameForPageView].size.height * [self switcherCardScale] / kDefaultSwitcherCardScale;
		}
	}
	return %orig(arg1);
}

%new
-(void)closeAllApplications:(BOOL)includeWhitelist  {
	isClosingAll = YES;
	NSString *nowPlayingBundleIdentifier = [[[%c(SBMediaController) sharedInstance] nowPlayingApplication] bundleIdentifier];
	NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[self appLayouts]];
	[items removeObject:[%c(SBAppLayout) homeScreenAppLayout]]; // remove springboard if exist
	for(SBAppLayout *item in items) { // close applications
		SBDisplayItem *displayItem = [item allItems][0];
		if (includeWhitelist) {
			if (!isWhitelistEnabled || !boolValuePerApp(displayItem.displayIdentifier, @"PerAppKill-", NO)) {
				if (isNowPlayingOnKillEnabled && [displayItem.displayIdentifier isEqualToString:nowPlayingBundleIdentifier] && [[%c(SBMediaController) sharedInstance] isPlaying]) {
					continue;
				}
				[self killAppLayoutOfContainer:[self _itemContainerForAppLayoutIfExists:item] withVelocity:1.0 forReason:1];
			}
		} else {
			[self killAppLayoutOfContainer:[self _itemContainerForAppLayoutIfExists:item] withVelocity:1.0 forReason:1];
		}
	}
	isClosingAll = NO;
	[items release];
}
%end
%end

%dtor {
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, CFSTR("com.dgh0st.enhancedswitcherclose/settingschanged"), NULL);

	if (prefs != nil) {
		[prefs release];
		prefs = nil;
	}
}

%ctor {
	preferencesChanged();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)preferencesChanged, CFSTR("com.dgh0st.enhancedswitcherclose/settingschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

	if (%c(SBFluidSwitcherViewController))
		%init(iOS11Plus);
	else if (%c(SBDeckSwitcherViewController))
		%init(iOS9And10);
}