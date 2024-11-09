
TOP                ?= $(shell git rev-parse --show-toplevel)
BP_SDK_DIR         ?= $(TOP)/..
BP_SDK_INSTALL_DIR ?= $(BP_SDK_DIR)/install
BP_SDK_BIN_DIR     ?= $(BP_SDK_INSTALL_DIR)/bin

# To allow to build in-tree
PATH := $(BP_SDK_BIN_DIR):$(PATH)

BP_ZEPHYR_DIR      := $(BP_SDK_DIR)/zephyr

ZEPHYR_DIR         := $(BP_ZEPHYR_DIR)/zephyr
VENV_DIR           := $(BP_ZEPHYR_DIR)/.venv
WEST_DIR           := $(BP_ZEPHYR_DIR)/.west

ZEPHYR_SDK_DIR     := $(BP_ZEPHYR_DIR)/zephyr-sdk
ZEPHYR_SDK_VERSION := 0.17.0
ZEPHYR_SDK_HOST    := linux-x86_64
ZEPHYR_SDK_ARCH    := riscv64-zephyr-elf
ZEPHYR_SDK_ROOT    := https://github.com/zephyrproject-rtos/sdk-ng/releases/download
ZEPHYR_SDK_TAR     := zephyr-sdk-$(ZEPHYR_SDK_VERSION)_$(ZEPHYR_SDK_HOST)_minimal.tar.xz
ZEPHYR_SDK_URL     := $(ZEPHYR_SDK_ROOT)/v$(ZEPHYR_SDK_VERSION)/$(ZEPHYR_SDK_TAR)

ZEPHYR_TOOLCHAIN     := $(ZEPHYR_SDK_DIR)/$(ZEPHYR_SDK_ARCH)
ZEPHYR_TOOLCHAIN_GCC := $(ZEPHYR_TOOLCHAIN)/bin/$(ZEPHYR_SDK_ARCH)-gcc

BOARD            ?= riscv_blackparrot
APPLICATION_DIR  ?= samples
APPLICATION      ?= philosophers
ZEPHYR_BIN       ?= zephyr-$(APPLICATION).riscv

all: $(ZEPHYR_BIN)

$(VENV_DIR)/bin/activate:
	python3 -m venv $(VENV_DIR)

$(ZEPHYR_DIR)/west.yml: $(VENV_DIR)/bin/activate
	source $(VENV_DIR)/bin/activate && \
		pip install west && \
		west init $(BP_ZEPHYR_DIR) && \
		west update && \
		west zephyr-export
	sed -i "s/pyocd/#pyocd/g" $(ZEPHYR_DIR)/scripts/requirements-run-test.txt
	source $(VENV_DIR)/bin/activate \
		&& pip install -r $(ZEPHYR_DIR)/scripts/requirements.txt

$(ZEPHYR_SDK_DIR)/setup.sh: $(ZEPHYR_DIR)/west.yml
	mkdir -p $(@D)
	wget "$(ZEPHYR_SDK_URL)"
	tar -xvf $(ZEPHYR_SDK_TAR) -C $(@D) --strip-components=1 --touch
	sed -i "s/--show-progress//g" $@

$(ZEPHYR_TOOLCHAIN_GCC): $(ZEPHYR_SDK_DIR)/setup.sh
	$< -t $(ZEPHYR_SDK_ARCH) -h -c
	touch $@; # Update modification time

#export ZEPHYR_SDK_INSTALL_ROOT := $(ZEPHYR_SDK_DIR)
$(ZEPHYR_BIN): $(ZEPHYR_TOOLCHAIN_GCC)
	source $(VENV_DIR)/bin/activate && \
		west build -p always -b $(BOARD) $(ZEPHYR_DIR)/$(APPLICATION_DIR)/$(APPLICATION) -- \
		-DBOARD_ROOT=$(BP_ZEPHYR_DIR) \
		-DSOC_ROOT=$(BP_ZEPHYR_DIR)
	mv $(ZEPHYR_DIR)/build/zephyr/zephyr.elf $@

test: $(ZEPHYR_BIN)

clean:
	rm -rf $(ZEPHYR_SDK_TAR)
	rm -rf $(PYTHON38_TAR)
	rm -rf $(PYTHON38_DIR)
	rm -rf bootloader/
	rm -rf modules/
	rm -rf tools/
	rm -rf .west/
	rm -rf .venv/
	rm -rf zephyr/
	rm -rf zephyr-sdk/

