export ARCHS = armv7 arm64
export TARGET = iphone:clang:8.1:latest

PACKAGE_VERSION = 0.0.6~Beta-3

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EnhancedSwitcherClose
EnhancedSwitcherClose_FILES = Tweak.xm
EnhancedSwitcherClose_FRAMEWORKS = UIKit
EnhancedSwitcherClose_LDFLAGS += -Wl,-segalign,4000
EnhancedSwitcherClose_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += enhancedswitcherclose
include $(THEOS_MAKE_PATH)/aggregate.mk
