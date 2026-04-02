# tests/bringup_pipeline/Makefile
# Christian LamAlvarez
# clamalvarez@hmc.edu
# 4/1/26

XLEN       ?= 32
ARCH       ?= rv$(XLEN)i_zicsr_zmmul
ABI        ?= $(if $(findstring 64,$(XLEN)),lp64,ilp32)

TOOLPREFIX ?= riscv64-unknown-elf-
GCC        ?= $(TOOLPREFIX)gcc

LINKER     ?= $(CURDIR)/link.ld
WORK_DIR   ?= $(CURDIR)/work

CFLAGS  := -march=$(ARCH) -mabi=$(ABI) -O0 -g -ffreestanding -ffunction-sections -fdata-sections -Wall -Wextra
LDFLAGS := -march=$(ARCH) -mabi=$(ABI) -nostdlib -Wl,--gc-sections -T $(LINKER)

# Generated pipeline test .S files
PIPELINE_TESTS_DIR ?= $(CURDIR)/pipeline_tests
PIPELINE_TESTS     := $(sort $(wildcard $(PIPELINE_TESTS_DIR)/*.S))

# All sources: everything directly in bringup_pipeline/ + generated tests
SRC := $(sort \
  $(shell find $(CURDIR) -maxdepth 1 -type f \( -name "*.S" -o -name "*.c" \)) \
  $(PIPELINE_TESTS) \
)

define require_linker
$(if $(strip $(LINKER)),,$(error LINKER is required.))
endef

.PHONY: all
all: gen $(WORK_DIR)/bringup_pipeline.elf

# Generate .S files if pipeline_tests/ is empty
.PHONY: gen
gen:
	@if [ -z "$(wildcard $(PIPELINE_TESTS_DIR)/*.S)" ]; then \
		echo "[GEN] Generating pipeline tests..."; \
		bash $(CURDIR)/gen_pipeline_tests.sh $(PIPELINE_TESTS_DIR); \
	else \
		echo "[GEN] Pipeline tests already exist, skipping."; \
	fi

$(WORK_DIR)/bringup_pipeline.elf: $(SRC) Makefile
	@$(require_linker)
	@mkdir -p $(WORK_DIR)
	$(GCC) $(CFLAGS) $(SRC) $(LDFLAGS) -o $@

.PHONY: clean
clean:
	rm -rf $(WORK_DIR)

.PHONY: clean-tests
clean-tests:
	rm -f $(PIPELINE_TESTS_DIR)/*.S
