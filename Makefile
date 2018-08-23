include $(THEOS)/makefiles/common.mk

TWEAK_NAME = KeySwipe

KeySwipe_FILES = /mnt/d/codes/keyswipe/Tweak.xm
KeySwipe_FRAMEWORKS = CydiaSubstrate UIKit CoreGraphics
KeySwipe_PRIVATE_FRAMEWORKS = 
KeySwipe_LDFLAGS = -Wl,-segalign,4000

export ARCHS = armv7 arm64
KeySwipe_ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk
	
all::
