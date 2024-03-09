.POSIX:
.SUFFIXES: .d

CC := cc

CFLAGS := -std=gnu11
CFLAGS += -iquote forary

CFLAGS += -pedantic
CFLAGS += -Wp,-U_FORTIFY_SOURCE
CFLAGS += -Wformat=2

CFLAGS += -MMD -MP
CFLAGS += -fanalyzer
CFLAGS += -fno-builtin
CFLAGS += -pipe

CFLAGS += -O2 -march=native -mtune=native

CFLAGS += -Wall
CFLAGS += -Wcast-qual
CFLAGS += -Wconversion
CFLAGS += -Wdisabled-optimization
CFLAGS += -Wduplicated-branches
CFLAGS += -Wduplicated-cond
CFLAGS += -Werror=return-type
CFLAGS += -Werror=vla-larger-than=0
CFLAGS += -Wextra
CFLAGS += -Winit-self
CFLAGS += -Winline
CFLAGS += -Wlogical-op
CFLAGS += -Wmissing-prototypes
CFLAGS += -Wshadow
CFLAGS += -Wstrict-prototypes
CFLAGS += -Wsuggest-attribute=pure
CFLAGS += -Wsuggest-attribute=const
CFLAGS += -Wundef
CFLAGS += -Wunreachable-code
CFLAGS += -Wwrite-strings

# ↓ `touch .fast` to force multi-threading
ifneq ($(shell find . -name ".fast"),)
    MAKEFLAGS += -j
endif

V ?= 0
ifneq ($(V),0)
  Q :=
else
  Q := @
endif

RM ?= rm -f
AR ?= ar

ifneq ($(shell command -v tput),)
  ifneq ($(shell tput colors),0)

C_RESET := \033[00m
C_BOLD := \e[1m
C_RED := \e[31m
C_GREEN := \e[32m
C_YELLOW := \e[33m
C_BLUE := \e[34m
C_PURPLE := \e[35m
C_CYAN := \e[36m

  endif
endif

NOW = $(shell date +%s%3N)
STIME := $(call NOW)
TIME_NS = $(shell expr $(call NOW) - $(STIME))
TIME_MS = $(shell expr $(call TIME_NS))

BOXIFY = "[$(C_BLUE)$(1)$(C_RESET)] $(2)"

ifneq ($(shell command -v printf),)
  LOG_TIME = printf $(call BOXIFY, %6s , %b\n) "$(call TIME_MS)"
else
  LOG_TIME = echo -e $(call BOXIFY, $(call TIME_MS) ,)
endif

BUILD_DIR := .build

OUT := foray
LIB := libforay.so

VPATH += src
SRC_BIN := main.c

VPATH += src
SRC_LIB := wrap_malloc.c

vpath %.c $(VPATH)

OBJ_BIN := $(SRC_BIN:%.c=$(BUILD_DIR)/%.o)
OBJ_LIB := $(SRC_LIB:%.c=$(BUILD_DIR)/%.o)

DEP := $(OBJ:.o=.d)

.PHONY: all
all: $(OUT) $(LIB)

-include $(DEP)

$(LIB): CFLAGS += -fPIC -shared -z initfirst
$(LIB): $(OBJ_LIB)
	@ mkdir -p $(dir $@)
	$Q $(CC) -o $@ $(OBJ_LIB) $(CFLAGS) $(LDLIBS) $(LDFLAGS)
	@ $(LOG_TIME) "LD $(C_GREEN) $@ $(C_RESET)"

$(OUT): LDFLAGS := -fwhole-program -flto
$(OUT): $(OBJ_BIN)
	@ mkdir -p $(dir $@)
	$Q $(CC) -o $@ $(OBJ_BIN) $(CFLAGS) $(LDLIBS) $(LDFLAGS)
	@ $(LOG_TIME) "LD $(C_GREEN) $@ $(C_RESET)"

$(BUILD_DIR)/%.o: %.c
	@ mkdir -p $(dir $@)
	$Q $(CC) $(CFLAGS) -o $@ -c $< || exit 1
	@ $(LOG_TIME) "CC $(C_PURPLE) $(notdir $@) $(C_RESET)"

.PHONY: clean
clean:
	$(RM) $(OBJ_BIN) $(OBJ_LIB)
	@ $(LOG_TIME) $@

.PHONY: fclean
fclean: clean
	$(RM) -r $(BUILD_DIR) $(OUT) $(LIB)
	@ $(LOG_TIME) $@

.PHONY: re
re: fclean
	@ $(MAKE) all
