#include "ESCRootListController.h"

@implementation ESCRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

- (void)email {
	if ([MFMailComposeViewController canSendMail]) {
		MFMailComposeViewController *email = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
		[email setSubject:@"EnhancedSwitcherClose Support"];
		[email setToRecipients:[NSArray arrayWithObjects:@"deeppwnage@yahoo.com", nil]];
		[email addAttachmentData:[NSData dataWithContentsOfFile:@"/var/mobile/Library/Preferences/com.dgh0st.enhancedswitcherclose.plist"] mimeType:@"application/xml" fileName:@"Prefs.plist"];
		#pragma GCC diagnostic push
		#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
		system("/usr/bin/dpkg -l > /tmp/dpkgl.log");
		#pragma GCC diagnostic pop
		[email addAttachmentData:[NSData dataWithContentsOfFile:@"/tmp/dpkgl.log"] mimeType:@"text/plain" fileName:@"dpkgl.txt"];
		[self.navigationController presentViewController:email animated:YES completion:nil];
		[email setMailComposeDelegate:self];
		[email release];
	}
}

- (void)mailComposeController:(id)controller didFinishWithResult:(MFMailComposeResult)result error:(id)error {
    [self dismissViewControllerAnimated:YES completion: nil];
}

- (void)donate {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=deeppwnage%40yahoo%2ecom&lc=US&item_name=DGh0st&item_number=DGh0st%20Tweak%20Inc%20%28Wow%20I%20own%20a%20company%29&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_LG%2egif%3aNonHostedGuest"]];
}

- (void)follow {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.twitter.com/D_Gh0st"]];
}

@end

@implementation ESCHomeListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Homescreen" target:self] retain];
	}

	return _specifiers;
}

@end

@implementation ESCAppsListController

- (id)init {
	self = [super init];
	if (self) {
		CGSize size = [[UIScreen mainScreen] bounds].size;
		NSNumber *iconSize = [NSNumber numberWithUnsignedInteger:ALApplicationIconSizeSmall];

		_dataSource = [[ALApplicationTableDataSource alloc] init];
		_dataSource.sectionDescriptors = [NSArray arrayWithObjects:
			[NSDictionary dictionaryWithObjectsAndKeys:
				@"System Applications", ALSectionDescriptorTitleKey,
				@"ALDisclosureIndicatedCell", ALSectionDescriptorCellClassNameKey,
				iconSize, ALSectionDescriptorIconSizeKey,
				@YES, ALSectionDescriptorSuppressHiddenAppsKey,
				@"isSystemApplication = TRUE", ALSectionDescriptorPredicateKey
			, nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				@"User Applications", ALSectionDescriptorTitleKey,
				@"ALDisclosureIndicatedCell", ALSectionDescriptorCellClassNameKey,
				iconSize, ALSectionDescriptorIconSizeKey,
				@YES, ALSectionDescriptorSuppressHiddenAppsKey,
				@"isSystemApplication = FALSE", ALSectionDescriptorPredicateKey
			, nil]
		, nil];

		_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStyleGrouped];
		_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_tableView.delegate = self;
		_tableView.dataSource = _dataSource;
		_dataSource.tableView = _tableView;

		[_tableView reloadData];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	((UIViewController *)self).title = @"Applications";
	[self.view addSubview:_tableView];
}

- (void)dealloc {
	_tableView.delegate = nil;
	[_tableView release];
	[_dataSource release];
	[super dealloc];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = (UITableViewCell *)[_tableView cellForRowAtIndexPath:indexPath];
	NSString *appName = cell.textLabel.text;
	NSString *appIdentifier = [_dataSource displayIdentifierForIndexPath:indexPath];

	ESCPerAppController *controller = [[ESCPerAppController alloc] initWithAppName:appName displayIdentifier:appIdentifier];
	controller.rootController = self.rootController;
	controller.parentController = self;
	
	[self pushController:controller];
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end

@implementation ESCPerAppController

- (id)specifiers {
	if (!_specifiers) {
		NSMutableArray *specifiers = (NSMutableArray *)[[self loadSpecifiersFromPlistName:@"PerApp" target:self] retain];
		for (PSSpecifier *spec in specifiers) {
			NSString *key = [spec propertyForKey:@"key"];
			if (key != nil) {
				[spec setProperty:[NSString stringWithFormat:@"%@-%@", key, _displayIdentifier] forKey:@"key"];
			}
		}

		_specifiers = specifiers;
	}

	return _specifiers;
}

- (id)initWithAppName:(NSString *)appName displayIdentifier:(NSString *)displayIdentifier {
	self = [self init];
	if (self) {
		_appName = appName;
		_displayIdentifier = displayIdentifier;
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	((UIViewController *)self).title = _appName;
}

@end

@implementation ESCCustomizeListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Customize" target:self] retain];
	}

	return _specifiers;
}

@end