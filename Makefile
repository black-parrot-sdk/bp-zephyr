
TOP                ?= $(shell git rev-parse --show-toplevel)
BP_SDK_DIR         ?= $(TOP)/..
BP_SDK_INSTALL_DIR ?= $(BP_SDK_DIR)/install
BP_SDK_BIN_DIR     ?= $(BP_SDK_INSTALL_DIR)/bin
BP_ZEPHYR_DIR      := $(BP_SDK_DIR)/zephyr
BP_BOARD_DIR       := $(BP_ZEPHYR_DIR)/blackparrot
ZEPHYR_DIR         := $(BP_ZEPHYR_DIR)/zephyr
VENV_DIR           := $(BP_ZEPHYR_DIR)/.venv
WEST_DIR           := $(BP_ZEPHYR_DIR)/.west

ZEPHYR_SDK_DIR     := $(BP_ZEPHYR_DIR)/zephyr-sdk
ZEPHYR_SDK_VERSION := 0.16.1
ZEPHYR_SDK_HOST    := linux-x86_64
ZEPHYR_SDK_ARCH    := riscv64-zephyr-elf
ZEPHYR_SDK_ROOT    := https://github.com/zephyrproject-rtos/sdk-ng/releases/download
ZEPHYR_SDK_TAR     := zephyr-sdk-$(ZEPHYR_SDK_VERSION)_$(ZEPHYR_SDK_HOST)_minimal.tar.xz
ZEPHYR_SDK_STR     := $(ZEPHYR_SDK_ROOT)/v$(ZEPHYR_SDK_VERSION)/$(ZEPHYR_SDK_TAR)

ZEPHYR_TOOLCHAIN     := $(ZEPHYR_SDK_DIR)/$(ZEPHYR_SDK_ARCH)
ZEPHYR_TOOLCHAIN_GCC := $(ZEPHYR_TOOLCHAIN)/bin/$(ZEPHYR_SDK_ARCH)-gcc

ZEPHYR_BOARD_ROOT := $(BP_ZEPHYR_DIR)
ZEPHYR_SOC_ROOT   := $(BP_ZEPHYR_DIR)

BOARD            ?= blackparrot
APPLICATION_DIR  ?= samples
APPLICATION      ?= philosophers
ZEPHYR_BIN       ?= zephyr-$(APPLICATION).riscv

PYTHON38_VER     := 3.8.17
PYTHON38_DIR     := Python-$(PYTHON38_VER)
PYTHON38_TAR     := $(PYTHON38_DIR).tgz
PYTHON38_ROOT    := https://www.python.org/ftp/python/$(PYTHON38_VER)
PYTHON38_STR     := $(PYTHON38_ROOT)/$(PYTHON38_TAR)
PYTHON38_INSTALL := $(PYTHON38_DIR)/install
PYTHON38         := $(PYTHON38_INSTALL)/bin/python3.8

all: $(ZEPHYR_BIN)

$(PYTHON38_TAR):
	wget "$(PYTHON38_STR)"

$(PYTHON38_DIR)/configure: $(PYTHON38_TAR)
	tar --touch -xzvf $<

$(PYTHON38_DIR)/Makefile: $(PYTHON38_DIR)/configure
	cd $(<D); ./$(<F) --enable-optimizations --prefix=$(BP_ZEPHYR_DIR)/$(PYTHON38_INSTALL)

$(PYTHON38): $(PYTHON38_DIR)/Makefile
	$(MAKE) -C $(PYTHON38_DIR) altinstall

$(VENV_DIR): $(PYTHON38)
	$< -m venv $(VENV_DIR)

ZEPHYR_BOARD_URL := https://github.com/black-parrot-sdk/bp-zephyr-board
ZEPHYR_BOARD_REF := master

$(ZEPHYR_DIR): $(VENV_DIR)
	source $(VENV_DIR)/bin/activate \
		&& pip install west && west init && west update && west zephyr-export
	sed -i "s/pyocd/#pyocd/g" $(ZEPHYR_DIR)/scripts/requirements-run-test.txt
	source $(VENV_DIR)/bin/activate \
		&& pip install -r $(ZEPHYR_DIR)/scripts/requirements.txt
		
$(ZEPHYR_SDK_TAR):
	wget "$(ZEPHYR_SDK_STR)"

$(ZEPHYR_SDK_DIR)/setup.sh: $(ZEPHYR_SDK_TAR)
	mkdir -p $(@D)
	tar --touch --strip-components=1 -xvf $< -C $(@D)

$(ZEPHYR_TOOLCHAIN_GCC): $(ZEPHYR_SDK_DIR)/setup.sh
	sed -i "s/--show-progress//g" $<
	$< -t $(ZEPHYR_SDK_ARCH) -h -c
	touch -m $(ZEPHYR_TOOLCHAIN_GCC)

export BOARD_ROOT := $(BP_ZEPHYR_DIR)
export SOC_ROOT   := $(BP_ZEPHYR_DIR)
$(ZEPHYR_BIN): $(ZEPHYR_DIR) $(ZEPHYR_TOOLCHAIN_GCC)
	source $(VENV_DIR)/bin/activate; \
	cd $(ZEPHYR_DIR); \
		west build -p always \
		-b $(BOARD) $(APPLICATION_DIR)/$(APPLICATION)
	mv $(ZEPHYR_DIR)/build/zephyr/zephyr.elf $@

# To allow to build in-tree
PATH := $(BP_SDK_BIN_DIR):$(PATH)

clean:
	rm -rf $(ZEPHYR_SDK_TAR)
	rm -rf $(PYTHON38_TAR)
	rm -rf $(PYTHON38_DIR)
	rm -rf bootloader/
	rm -rf modules/
	rm -rf tools/
	rm -rf .west/
	rm -rf .venv/
	#rm -rf zephyr/
	#rm -rf zephyr-sdk/

