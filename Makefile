
TOP                ?= $(shell git rev-parse --show-toplevel)
BP_SDK_DIR         ?= $(TOP)/..
BP_SDK_INSTALL_DIR ?= $(BP_SDK_DIR)/install
BP_SDK_BIN_DIR     ?= $(BP_SDK_INSTALL_DIR)/bin
BP_ZEPHYR_DIR      := $(BP_SDK_DIR)/zephyr
ZEPHYR_DIR         := $(BP_ZEPHYR_DIR)/zephyr
PATH               := $(BP_SDK_BIN_DIR):$(PATH)

WEST ?= west
BOARD ?= blackparrot
APPLICATION ?= samples/synchronization

export ZEPHYR_BASE              := $(ZEPHYR_DIR)
export ZEPHYR_TOOLCHAIN_VARIANT := cross-compile
export TOOLCHAIN                := riscv64-unknown-elf-dramfs-
export CROSS_COMPILE            := $(BP_SDK_BIN_DIR)/$(TOOLCHAIN)

ZEPHYR_ELF ?= $(ZEPHYR_DIR)/build/zephyr/zephyr.elf
all: $(ZEPHYR_ELF)

checkout:
	git submodule update --init --recursive $(ZEPHYR_DIR)
	-$(WEST) init -l $(ZEPHYR_DIR)
	cd $(ZEPHYR_DIR); $(WEST) update

$(ZEPHYR_ELF): checkout
	cd $(ZEPHYR_DIR); $(WEST) build --pristine -b $(BOARD) $(APPLICATION)

zephyr.riscv: $(ZEPHYR_ELF)
	cp $< $@

clean:
	rm -rf tools
	rm -rf modules
	rm -rf .west
