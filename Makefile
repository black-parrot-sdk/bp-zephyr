
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

export ZEPHYR_TOOLCHAIN_VARIANT := cross-compile
export TOOLCHAIN                := riscv64-unknown-elf-dramfs-
export CROSS_COMPILE            := $(BP_SDK_BIN_DIR)/$(TOOLCHAIN)

ZEPHYR_URL := https://github.com/black-parrot-sdk/zephyr
ZEPHYR_BRANCH := blackparrot_mods

build: $(ZEPHYR_RISCV)

.PHONY: zephyr
zephyr:
	git submodule update --init --recursive $(ZEPHYR_DIR)
	rm -rf $(ZEPHYR_DIR)/.west
	cd $(ZEPHYR_DIR); $(WEST) init -m $(ZEPHYR_URL) --mr $(ZEPHYR_BRANCH)
	cd $(ZEPHYR_DIR); $(WEST) update

ZEPHYR_ELF ?= $(ZEPHYR_DIR)/build/zephyr/zephyr.elf

$(ZEPHYR_ELF): $(ZEPHYR_DIR)
	cd $(ZEPHYR_DIR); $(WEST) build --pristine -b $(BOARD) $(APPLICATION)

zephyr.riscv: $(ZEPHYR_ELF)
	cp $< $@

clean:
	rm -rf tools
	rm -rf modules
	rm -rf .west
