include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = EnhancedSwitcherClose
EnhancedSwitcherClose_FILES = ESCRootListController.mm
EnhancedSwitcherClose_INSTALL_PATH = /Library/PreferenceBundles
EnhancedSwitcherClose_FRAMEWORKS = UIKit MessageUI
EnhancedSwitcherClose_PRIVATE_FRAMEWORKS = Preferences
EnhancedSwitcherClose_LIBRARIES = applist colorpicker

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/EnhancedSwitcherClose.plist$(ECHO_END)
