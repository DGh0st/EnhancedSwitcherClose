#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <AppList/AppList.h>

@interface ESCRootListController : PSListController <MFMailComposeViewControllerDelegate>

@end

@interface ESCHomeListController : PSListController

@end

@interface ESCDefaultAppsListController : PSListController

@end

@interface ESCAppsListController : PSViewController <UITableViewDelegate> {
	UITableView *_tableView;
	ALApplicationTableDataSource *_dataSource;
}
@end

@interface ESCPerAppController : PSListController {
	NSString *_appName;
	NSString *_displayIdentifier;
}
- (id)initWithAppName:(NSString *)appName displayIdentifier:(NSString *)displayIdentifier;
@end

@interface ESCCustomizeListController : PSListController

@end