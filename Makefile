COMMON_CONF = apache-credit

CREDIT_LOCATION = ~ "^/(?!(lib/editor))"

include $(FAB_PATH)/common/mk/turnkey/lamp.mk
include $(FAB_PATH)/common/mk/turnkey.mk
