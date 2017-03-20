#include <SpringBoard/SpringBoard.h>
#include <SpringBoard/SBApplication.h>
#include <SpringBoard/SBMediaController.h>

#define kFirstActionOffset 0.1
#define kSecondActionOffset 0.2
#define kThirdActionOffset 0.3

typedef enum {
	kUp,
	kDown,
	kNone
} Direction;

@interface SBDisplayItem : NSObject
@property (nonatomic,readonly) NSString* displayIdentifier;
@end

@interface SBDeckSwitcherViewController
@property(retain, nonatomic) NSArray *displayItems;
-(void)killDisplayItemOfContainer:(id)arg1 withVelocity:(CGFloat)arg2;
-(id)_itemContainerForDisplayItem:(id)arg1;
-(void)closeAllApplications;
-(void)launchApplications:(NSMutableArray *)arg1;
@end

@interface SBDeckSwitcherItemContainer : UIView
@property(readonly, retain, nonatomic) SBDisplayItem *displayItem;
-(void)_handlePageViewTap:(id)arg1;
-(CGRect)_frameForScrollView;
-(CGRect)_frameForPageView;
-(void)addLabelWithTitle:(NSString *)arg1 withY:(CGFloat)arg2 withColor:(UIColor *)arg3;
-(void)createUpwardSpringBoardLabels;
-(void)createUpwardLabels;
-(void)createDownwardLabels;
-(void)removeLabels;
-(void)scrollViewProgressUpdated:(CGFloat)arg1 withDirection:(Direction)arg2 withIsSpringBoard:(BOOL)arg3;
-(BOOL)shouldPerformAction;
@end

@interface SBDeckSwitcherPageView
@end

@interface UIApplication (AlertClose)
+(id)sharedApplication;
-(BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2;
@end

@interface SpringBoard (AlertClose)
-(BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2;
@end

@interface FBSystemService
+(id)sharedInstance;
-(void)exitAndRelaunch:(BOOL)arg1;
@end

@interface SBApplication (AlertClose)
-(id)bundleIdentifier;
@end

@interface SBMediaController (AlertClose)
+(id)sharedInstance;
-(SBApplication *)nowPlayingApplication;
@end

%hook SBDeckSwitcherItemContainer
UIView *createdView = nil;
Direction currentDirection = kNone;
BOOL _shouldPerformAction = NO;

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

	UIView *rightSeparator = [[UIView alloc] initWithFrame:CGRectMake(pageViewFrame.size.width * 2  / 3, arg2, pageViewFrame.size.width / 3 - 8, 2)];
	rightSeparator.backgroundColor = arg3;
	[createdView addSubview:rightSeparator];
}

%new
-(void)createUpwardSpringBoardLabels {
	UIScrollView *_verticalScrollView = MSHookIvar<UIScrollView *>(self, "_verticalScrollView");
	CGRect pageViewFrame = [self _frameForPageView];

	createdView = [[UIView alloc] initWithFrame:CGRectMake(pageViewFrame.origin.x, pageViewFrame.origin.y - pageViewFrame.size.height / 2, pageViewFrame.size.width, pageViewFrame.size.height)];
	createdView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
	
	[self addLabelWithTitle:@"Respring" withY:(pageViewFrame.size.height * (1 - kThirdActionOffset)) withColor:[UIColor redColor]];
	[self addLabelWithTitle:@"Kill-All" withY:(pageViewFrame.size.height * (1 - kSecondActionOffset)) withColor:[UIColor orangeColor]];
	[self addLabelWithTitle:@"Relaunch-All" withY:(pageViewFrame.size.height * (1 - kFirstActionOffset)) withColor:[UIColor greenColor]];

	[self insertSubview:createdView belowSubview:_verticalScrollView];
}

%new
-(void)createUpwardLabels {
	UIScrollView *_verticalScrollView = MSHookIvar<UIScrollView *>(self, "_verticalScrollView");
	CGRect pageViewFrame = [self _frameForPageView];

	createdView = [[UIView alloc] initWithFrame:CGRectMake(pageViewFrame.origin.x, pageViewFrame.origin.y - pageViewFrame.size.height / 2, pageViewFrame.size.width, pageViewFrame.size.height)];
	createdView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
	
	[self addLabelWithTitle:@"Close" withY:(pageViewFrame.size.height * (1 - kSecondActionOffset)) withColor:[UIColor redColor]];
	[self addLabelWithTitle:@"Relaunch" withY:(pageViewFrame.size.height * (1 - kFirstActionOffset)) withColor:[UIColor orangeColor]];

	[self insertSubview:createdView belowSubview:_verticalScrollView];
}

%new
-(void)createDownwardLabels {
	UIScrollView *_verticalScrollView = MSHookIvar<UIScrollView *>(self, "_verticalScrollView");
	CGRect pageViewFrame = [self _frameForPageView];

	createdView = [[UIView alloc] initWithFrame:CGRectMake(pageViewFrame.origin.x, pageViewFrame.origin.y - pageViewFrame.size.height / 2, pageViewFrame.size.width, pageViewFrame.size.height)];
	createdView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
	
	[self addLabelWithTitle:@"Dismiss Switcher" withY:(pageViewFrame.size.height * kSecondActionOffset) withColor:[UIColor orangeColor]];
	[self addLabelWithTitle:@"Launch" withY:(pageViewFrame.size.height * kFirstActionOffset) withColor:[UIColor greenColor]];

	[self insertSubview:createdView belowSubview:_verticalScrollView];
}

%new
-(void)removeLabels {
	if (createdView) {
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
	if (arg2 == currentDirection) {
		return;
	}
	if (currentDirection == kUp || currentDirection == kDown) {
		[self removeLabels];
	}
	currentDirection = arg2;
	if (currentDirection == kUp) {
		_shouldPerformAction = NO;
		if (arg3) {
			[self createUpwardSpringBoardLabels];
		} else {
			[self createUpwardLabels];
		}
	} else if (currentDirection == kDown) {
		_shouldPerformAction = NO;
		[self createDownwardLabels];
	}
}

-(void)scrollViewWillEndDragging:(id)arg1 withVelocity:(CGPoint)arg2 targetContentOffset:(id)arg3 {
	_shouldPerformAction = YES;
}
%end

%hook SBDeckSwitcherViewController
-(void)scrollViewKillingProgressUpdated:(CGFloat)arg1 ofContainer:(SBDeckSwitcherItemContainer *)arg2 {
	SBDisplayItem *selected = [arg2 displayItem];
	BOOL isSpringBoard = [selected.displayIdentifier isEqualToString:@"com.apple.springboard"];

	if (arg1 > 0.0f) {
		[arg2 scrollViewProgressUpdated:arg1 withDirection:kUp withIsSpringBoard:isSpringBoard];
		if ([arg2 shouldPerformAction]) {
			if (arg1 > kThirdActionOffset) { // respring
				if (isSpringBoard) { // respring
					[[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
				}
			}
			if (arg1 > kSecondActionOffset) { // close or kill-all
				if (isSpringBoard) { // kill-all
					[self closeAllApplications];
					SBDisplayItem *returnDisplayItem = MSHookIvar<SBDisplayItem *>(self, "_returnToDisplayItem");
					SBDeckSwitcherItemContainer *returnContainer = [self _itemContainerForDisplayItem:returnDisplayItem];
					SBDeckSwitcherPageView *returnPage = MSHookIvar<SBDeckSwitcherPageView *>(returnContainer, "_pageView");
					[returnContainer _handlePageViewTap:returnPage];
				} else { // close
					[self killDisplayItemOfContainer:arg2 withVelocity:1.0];
					NSArray *items = [self displayItems];
					if ([items count] == 1) {
						SBDisplayItem *returnDisplayItem = MSHookIvar<SBDisplayItem *>(self, "_returnToDisplayItem");
						SBDeckSwitcherItemContainer *returnContainer = [self _itemContainerForDisplayItem:returnDisplayItem];
						SBDeckSwitcherPageView *returnPage = MSHookIvar<SBDeckSwitcherPageView *>(returnContainer, "_pageView");
						[returnContainer _handlePageViewTap:returnPage];
					}
				}
			} else if (arg1 > kFirstActionOffset) { // relaunch or relaunch-all
				if (isSpringBoard) { // relaunch-all
					NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[self displayItems]];
					if ([items count] > 1) {
						[self closeAllApplications];
						[self launchApplications:items];
					}
					[items release];
				} else { // relaunch
					[self killDisplayItemOfContainer:arg2 withVelocity:1.0];
					[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:selected.displayIdentifier suspended:NO];
				}
			}
		}
	} else if (arg1 < 0.0f) {
		[arg2 scrollViewProgressUpdated:arg1 withDirection:kDown withIsSpringBoard:isSpringBoard];
		if ([arg2 shouldPerformAction]) {
			if (arg1 < -kSecondActionOffset) { // dismiss switcher
				SBDisplayItem *returnDisplayItem = MSHookIvar<SBDisplayItem *>(self, "_returnToDisplayItem");
				SBDeckSwitcherItemContainer *returnContainer = [self _itemContainerForDisplayItem:returnDisplayItem];
				SBDeckSwitcherPageView *returnPage = MSHookIvar<SBDeckSwitcherPageView *>(returnContainer, "_pageView");
				[returnContainer _handlePageViewTap:returnPage];
			} else if (arg1 < -kFirstActionOffset) { // launch
				SBDeckSwitcherPageView *returnPage = MSHookIvar<SBDeckSwitcherPageView *>(arg2, "_pageView");
				[arg2 _handlePageViewTap:returnPage];
			}
		}
	} else {
		[arg2 scrollViewProgressUpdated:arg1 withDirection:kNone withIsSpringBoard:isSpringBoard];
	}
	%orig(arg1, arg2);
}

-(_Bool)isDisplayItemOfContainerRemovable:(id)arg1 {
	return NO;
}

%new
-(void)closeAllApplications {
	NSString *nowPlayingBundleIdentifier = [[[%c(SBMediaController) sharedInstance] nowPlayingApplication] bundleIdentifier];
	NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[self displayItems]];
	[items removeObjectAtIndex:0]; // remove springboard
	for(SBDisplayItem *item in items) { // close applications
		if ([item.displayIdentifier isEqualToString:nowPlayingBundleIdentifier]) {
			continue;
		} else {
			[self killDisplayItemOfContainer:[self _itemContainerForDisplayItem:item] withVelocity:1.0];
		}
	}
	[items release];
}

%new
-(void)launchApplications:(NSMutableArray *)itemsToRun {
	for (SBDisplayItem *item in itemsToRun) { // launch applications
		[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:item.displayIdentifier suspended:NO];
	}
}
%end