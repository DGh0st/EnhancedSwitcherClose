export ARCHS = armv7 arm64
export TARGET = iphone:clang:11.2:9.0

PACKAGE_VERSION = 0.0.7-5

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
