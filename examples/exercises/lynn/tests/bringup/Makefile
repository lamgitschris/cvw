# tests/bringup/Makefile
# James Kaden Cassidy
# kacassidy@hmc.edu
# 1/22/26
# Edited by
# Christian LamAlvarez
# 2/12/26
# clamalvarez@hmc.edu

XLEN       ?= 32
ARCH       ?= rv$(XLEN)i_zicsr
ABI        ?= $(if $(findstring 64,$(XLEN)),lp64,ilp32)

TOOLPREFIX ?= riscv64-unknown-elf-
GCC         ?= $(TOOLPREFIX)gcc

# Intentionally undefined unless caller provides it:
LINKER     ?= $(CURDIR)/link.ld

WORK_DIR   ?= $(CURDIR)/work

CFLAGS  := -march=$(ARCH) -mabi=$(ABI) -O0 -g -ffreestanding -ffunction-sections -fdata-sections -Wall -Wextra
LDFLAGS := -march=$(ARCH) -mabi=$(ABI) -nostdlib -Wl,--gc-sections -T $(LINKER)

C_TESTS_DIR ?= $(CURDIR)/../C/tests
C_TESTS     := $(sort $(wildcard $(C_TESTS_DIR)/*.S))

SRC := $(sort \
  $(shell find $(CURDIR) -type f \( -name "*.S" -o -name "*.c" \)) \
  $(C_TESTS) \
)

# Only complain when actually building
define require_linker
$(if $(strip $(LINKER)),,$(error LINKER is required. Call: make LINKER=/path/to/link.ld ...))
endef

.PHONY: all
all: $(WORK_DIR)/bringup.elf

$(WORK_DIR)/bringup.elf: $(SRC) Makefile
	@$(require_linker)
	@mkdir -p $(WORK_DIR)
	$(GCC) $(CFLAGS) $(SRC) $(LDFLAGS) -o $@

.PHONY: clean
clean:
	rm -rf $(WORK_DIR)
