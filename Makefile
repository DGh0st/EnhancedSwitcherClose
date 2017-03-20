export ARCHS = armv7 arm64
export TARGET = iphone:clang:latest:latest

PACKAGE_VERSION = 0.0.1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EnhancedSwitcherClose
EnhancedSwitcherClose_FILES = Tweak.xm
EnhancedSwitcherClose_FRAMEWORKS = UIKit
EnhancedSwitcherClose_LDFLAGS += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
