# -- MegaDrive toolchain builder --
# Coded by: Juan Ángel Moreno Fernández (@_tapule) 2024
# Github: https://github.com/tapule/
# Based on Andrew DeRosier's (andwn) Marsdev (https://github.com/andwn/marsdev)

BUILD_DIR   := $(shell pwd)/build
INSTALL_DIR ?= $(shell pwd)/toolchain

PREFIX   = $(BUILD_DIR)
PATH    := $(PREFIX)/bin:$(PATH)

# Languages supported in the toolchain
# You can override this with "make LANGS=c,c++"
LANGS   ?= c

# Some ANSI terminal color codes
COLOR_RESET      = $'\033[0m
COLOR_RED        = $'\033[1;31;49m
COLOR_GREEN      = $'\033[1;32;49m
COLOR_YELLOW     = $'\033[1;33;49m
COLOR_BLUE       = $'\033[1;34;49m
COLOR_MAGENTA    = $'\033[1;35;49m
COLOR_CYAN       = $'\033[1;36;49m
COLOR_WHITE      = $'\033[1;37;49m

# Mirrors for packages downloading
GNU_MIRROR          ?= https://ftp.gnu.org/gnu
GDB_PREREQ_MIRROR   ?= https://gcc.gnu.org/pub/gcc/infrastructure

# Packages versions
BINUTILS_VER        ?= 2.42
GCC_VER             ?= 14.1.0
NEWLIB_VER          ?= main
GDB_VER             ?= 15.1
GDB_PREREQ_GMP_VER  ?= 6.2.1
GDB_PREREQ_MPFR_VER ?= 4.1.0
SJASM_VER           ?= v0.39
SIKTOOLS_VER        ?= master

# Directory stuff
BINUTILS_DIR        := binutils-$(BINUTILS_VER)
GCC_DIR             := gcc-$(GCC_VER)
NEWLIB_DIR          := newlib-$(NEWLIB_VER)
GDB_DIR             := gdb-$(GDB_VER)
GDB_PREREQ_GMP_DIR  := gmp-$(GDB_PREREQ_GMP_VER)
GDB_PREREQ_MPFR_DIR	:= mpfr-$(GDB_PREREQ_MPFR_VER)
SJASM_DIR           := sjasm-$(SJASM_VER)
SIKTOOLS_DIR        := siktools-$(SIKTOOLS_VER)
BLASTEM_DIR         := blastem
LOG_DIR             := $(shell pwd)

BINUTILS_PKG        := $(BINUTILS_DIR).tar.xz
GCC_PKG             := $(GCC_DIR).tar.xz
NEWLIB_PKG          := $(NEWLIB_DIR)
GDB_PKG             := $(GDB_DIR).tar.xz
GDB_PREREQ_GMP_PKG  := $(GDB_PREREQ_GMP_DIR).tar.bz2
GDB_PREREQ_MPFR_PKG := $(GDB_PREREQ_MPFR_DIR).tar.bz2
SJASM_PKG           := $(SJASM_DIR)
SIKTOOLS_PKG        := $(SIKTOOLS_DIR)
BLASTEM_PKG         := $(BLASTEM_DIR)

# Needed to get Blastem's build directory
BLASTEM_BIN	    := $(BLASTEM_DIR)/blastem
BLASTEM_VER      = $(shell echo $(shell ./$(BLASTEM_BIN) -v) | awk '/blastem/ { gsub(/\r/, "", $$2); print $$2 }')
BLASTEM_SUFIX    = $(shell file $(BLASTEM_BIN) | sed -E 's/^[^:]*: [^ ]* ([0-9]*)-bit .*/\1/')
# Python version used to build blastem's dependency on glew
PYTHON  ?= python3

# Detect the number of processors for a parallel make
NPROC   := $(shell nproc --all)

.PHONY: all with-newlib

# Main targets
all: BUILD_LANGS = $(LANGS)
all: info mk-binutils mk-gcc mk-gdb mk-sjasm mk-siktools mk-blastem
with-newlib: BUILD_LANGS = c
with-newlib: info mk-binutils mk-gcc mk-gdb mk-newlib mk-gcc-newlib mk-sjasm mk-siktools mk-blastem

mk-binutils: BINUTILS_BUILD_DIR=$(BINUTILS_DIR)/build
mk-binutils: $(BINUTILS_DIR)
	@echo "$(COLOR_GREEN)>> Building binutils for m68k...$(COLOR_RESET)"
	mkdir -p $(BINUTILS_BUILD_DIR)
	cd $(BINUTILS_BUILD_DIR) && \
		../configure --target=m68k-elf --prefix=$(PREFIX) --with-cpu=m68000 \
		--libdir=$(BUILD_DIR)/lib \
		--libexecdir=$(BUILD_DIR)/libexec \
		--enable-install-libbfd --enable-shared=no --disable-werror \
		> $(LOG_DIR)/binutils.log 2>&1
	make -C $(BINUTILS_BUILD_DIR) all -j$(NPROC) >> $(LOG_DIR)/binutils.log 2>&1
	make -C $(BINUTILS_BUILD_DIR) install-strip  >> $(LOG_DIR)/binutils.log 2>&1
	@rm -rf $(BINUTILS_BUILD_DIR)
	@touch mk-binutils

mk-gcc: GCC_BUILD_DIR=$(GCC_DIR)/build
mk-gcc: $(GCC_DIR) mk-binutils
	@echo "$(COLOR_GREEN)>> Building gcc for m68k...$(COLOR_RESET)"
	cd $(GCC_DIR) && \
		./contrib/download_prerequisites > $(LOG_DIR)/gcc.log 2>&1
	@mkdir -p $(GCC_BUILD_DIR)
	cd $(GCC_BUILD_DIR) && \
		../configure --target=m68k-elf --prefix=$(PREFIX) --with-cpu=m68000 \
		--libdir=$(BUILD_DIR)/lib \
		--libexecdir=$(BUILD_DIR)/libexec \
		--enable-languages=$(BUILD_LANGS) \
		--without-headers --disable-libssp --disable-threads --disable-tls \
		--disable-multilib --enable-shared=no --disable-werror \
		>> $(LOG_DIR)/gcc.log 2>&1
	make -C $(GCC_BUILD_DIR) all -j$(NPROC) >> $(LOG_DIR)/gcc.log 2>&1
	make -C $(GCC_BUILD_DIR) install-strip  >> $(LOG_DIR)/gcc.log 2>&1
	@rm -rf $(GCC_BUILD_DIR)
	@touch mk-gcc

mk-gdb: GDB_BUILD_DIR=$(GDB_DIR)/build
mk-gdb: $(GDB_DIR) mk-gcc
	@echo "$(COLOR_GREEN)>> Building gdb for m68k...$(COLOR_RESET)"
	@mkdir -p $(GDB_BUILD_DIR)
	cd $(GDB_BUILD_DIR) && \
		../configure --target=m68k-elf --prefix=$(PREFIX) --with-cpu=m68000 \
		--libdir=$(BUILD_DIR)/lib \
		--libexecdir=$(BUILD_DIR)/libexec \
		--enable-languages=$(LANGS) \
		--disable-multilib --disable-tls --disable-werror \
		> $(LOG_DIR)/gdb.log 2>&1
	make -C $(GDB_BUILD_DIR) all -j$(NPROC) >> $(LOG_DIR)/gdb.log 2>&1
	make -C $(GDB_BUILD_DIR) install >> $(LOG_DIR)/gdb.log 2>&1
	@rm -rf $(GDB_BUILD_DIR)
	@touch mk-gdb

mk-newlib: NEWLIB_BUILD_DIR=$(NEWLIB_DIR)/build
mk-newlib: $(NEWLIB_PKG) mk-gcc
	@echo "$(COLOR_GREEN)>> Building newlib for m68k...$(COLOR_RESET)"
	@mkdir -p $(NEWLIB_BUILD_DIR)
	cd $(NEWLIB_BUILD_DIR) && \
		../configure --target=m68k-elf --prefix=$(PREFIX) --with-cpu=m68000 \
		--libdir=$(BUILD_DIR)/lib \
		--libexecdir=$(BUILD_DIR)/libexec \
		--disable-multilib --disable-werror \
		> $(LOG_DIR)/newlib.log 2>&1
	make -C $(NEWLIB_BUILD_DIR) all -j$(NPROC) CFLAGS_FOR_TARGET="-fpermissive -g -O2" >> $(LOG_DIR)/newlib.log 2>&1
	make -C $(NEWLIB_BUILD_DIR) install >> $(LOG_DIR)/newlib.log 2>&1
	@rm -rf $(NEWLIB_BUILD_DIR)
	@touch mk-newlib

mk-gcc-newlib: GCC_BUILD_DIR=$(GCC_DIR)/build
mk-gcc-newlib: $(GCC_DIR) mk-newlib
	@echo "$(COLOR_GREEN)>> Building gcc with newlib for m68k...$(COLOR_RESET)"
	@mkdir -p $(GCC_BUILD_DIR)
	cd $(GCC_BUILD_DIR) && \
		../configure --target=m68k-elf --prefix=$(PREFIX) --with-cpu=m68000 \
		--libdir=$(BUILD_DIR)/lib \
		--libexecdir=$(BUILD_DIR)/libexec \
		--enable-languages=$(LANGS) \
		--without-headers --with-newlib --disable-hosted-libstdxx \
		--disable-libssp --disable-threads --disable-tls --disable-multilib \
		--enable-shared=no --disable-werror \
		> $(LOG_DIR)/gcc-newlib.log 2>&1
	make -C $(GCC_BUILD_DIR) all -j$(NPROC) >> $(LOG_DIR)/gcc-newlib.log 2>&1
	make -C $(GCC_BUILD_DIR) install-strip  >> $(LOG_DIR)/gcc-newlib.log 2>&1
	@rm -rf $(GCC_BUILD_DIR)
	@touch mk-gcc-newlib

mk-sjasm: $(SJASM_PKG)
	@echo "$(COLOR_GREEN)>> Building Sjasm...$(COLOR_RESET)"
	@mkdir -p $(BUILD_DIR)/bin
	cd $(SJASM_DIR)/Sjasm && make > $(LOG_DIR)/sjasm.log 2>&1
	cp -f $(SJASM_DIR)/Sjasm/sjasm $(BUILD_DIR)/bin
	@touch mk-sjasm

mk-siktools: $(SIKTOOLS_PKG)
	@echo "$(COLOR_GREEN)>> Building Sik tools...$(COLOR_RESET)"
	@mkdir -p $(BUILD_DIR)/bin
	make -C $(SIKTOOLS_DIR)/echo2vgm >> $(LOG_DIR)/siktools.log 2>&1
	make -C $(SIKTOOLS_DIR)/eif2tfi/tool >> $(LOG_DIR)/siktools.log 2>&1
	make -C $(SIKTOOLS_DIR)/headgen/tool >> $(LOG_DIR)/siktools.log 2>&1
	make -C $(SIKTOOLS_DIR)/mdtiler/tool >> $(LOG_DIR)/siktools.log 2>&1
	make -C $(SIKTOOLS_DIR)/midi2esf >> $(LOG_DIR)/siktools.log 2>&1
	make -C $(SIKTOOLS_DIR)/mml2esf/tool >> $(LOG_DIR)/siktools.log 2>&1
	make -C $(SIKTOOLS_DIR)/pcm2ewf/tool >> $(LOG_DIR)/siktools.log 2>&1
	make -C $(SIKTOOLS_DIR)/romfix >> $(LOG_DIR)/siktools.log 2>&1
	make -C $(SIKTOOLS_DIR)/slz/tool >> $(LOG_DIR)/siktools.log 2>&1
	make -C $(SIKTOOLS_DIR)/tfi2eif/tool >> $(LOG_DIR)/siktools.log 2>&1
	make -C $(SIKTOOLS_DIR)/uftc/tool >> $(LOG_DIR)/siktools.log 2>&1
	make -C $(SIKTOOLS_DIR)/vgi2eif/tool >> $(LOG_DIR)/siktools.log 2>&1
	cp -f $(SIKTOOLS_DIR)/echo2vgm/echo2vgm $(BUILD_DIR)/bin
	cp -f $(SIKTOOLS_DIR)/eif2tfi/tool/eif2tfi $(BUILD_DIR)/bin
	cp -f $(SIKTOOLS_DIR)/headgen/tool/headgen $(BUILD_DIR)/bin
	cp -f $(SIKTOOLS_DIR)/mdtiler/tool/mdtiler $(BUILD_DIR)/bin
	cp -f $(SIKTOOLS_DIR)/midi2esf/midi2esf $(BUILD_DIR)/bin
	cp -f $(SIKTOOLS_DIR)/mml2esf/tool/mml2esf $(BUILD_DIR)/bin
	cp -f $(SIKTOOLS_DIR)/pcm2ewf/tool/pcm2ewf $(BUILD_DIR)/bin
	cp -f $(SIKTOOLS_DIR)/romfix/romfix $(BUILD_DIR)/bin
	cp -f $(SIKTOOLS_DIR)/slz/tool/slz $(BUILD_DIR)/bin
	cp -f $(SIKTOOLS_DIR)/tfi2eif/tool/tfi2eif $(BUILD_DIR)/bin
	cp -f $(SIKTOOLS_DIR)/uftc/tool/uftc $(BUILD_DIR)/bin
	cp -f $(SIKTOOLS_DIR)/vgi2eif/tool/vgi2eif $(BUILD_DIR)/bin
	@touch mk-siktools

mk-blastem: mk-blastem-build
#   We need a different target to do the copy due to sufix and version variables
	cp -f -r $(BLASTEM_DIR)/blastem$(BLASTEM_SUFIX)-$(BLASTEM_VER) $(BUILD_DIR)/blastem
	@touch mk-blastem

mk-blastem-build: $(BLASTEM_PKG)
	@echo "$(COLOR_GREEN)>> Building Blastem...$(COLOR_RESET)"
	cd $(BLASTEM_DIR)/glew/auto && make PYTHON=$(PYTHON) > $(LOG_DIR)/glew.log 2>&1
	cd $(BLASTEM_DIR) && sh build_release > $(LOG_DIR)/blastem.log 2>&1
	@touch mk-blastem-build

# Packages download
$(BINUTILS_PKG):
	@echo "$(COLOR_GREEN)>> Downloading binutils...$(COLOR_RESET)"
	@wget $(GNU_MIRROR)/binutils/$(BINUTILS_PKG)

$(GCC_PKG):
	@echo "$(COLOR_GREEN)>> Downloading gcc...$(COLOR_RESET)"
	@wget $(GNU_MIRROR)/gcc/gcc-$(GCC_VER)/$(GCC_PKG)

$(GDB_PKG):
	@echo "$(COLOR_GREEN)>> Downloading gdb...$(COLOR_RESET)"
	@wget $(GNU_MIRROR)/gdb/$(GDB_PKG)
	@echo "$(COLOR_GREEN)>> Downloading gdb prerequisites...$(COLOR_RESET)"
	@wget $(GDB_PREREQ_MIRROR)/$(GDB_PREREQ_GMP_PKG)
	@wget $(GDB_PREREQ_MIRROR)/$(GDB_PREREQ_MPFR_PKG)

$(NEWLIB_PKG):
	@echo "$(COLOR_GREEN)>> Downloading newlib...$(COLOR_RESET)"
	@git clone https://sourceware.org/git/newlib-cygwin.git --depth=1 --branch $(NEWLIB_VER) $(NEWLIB_DIR)

$(SJASM_PKG):
	@rm -rf $(SJASM_DIR)
	@echo "$(COLOR_GREEN)>> Downloading Sjasm...$(COLOR_RESET)"
	@git clone https://github.com/konamiman/sjasm --depth=1 --branch $(SJASM_VER) $(SJASM_DIR)

$(SIKTOOLS_PKG):
	@rm -rf $(SIKTOOLS_DIR)
	@echo "$(COLOR_GREEN)>> Downloading Sik tools...$(COLOR_RESET)"
	@git clone https://github.com/sikthehedgehog/mdtools --depth=1 --branch $(SIKTOOLS_VER) $(SIKTOOLS_DIR)

$(BLASTEM_PKG):
	@rm -rf $(BLASTEM_DIR)
	@echo "$(COLOR_GREEN)>> Downloading Blastem emulator...$(COLOR_RESET)"
	hg clone https://www.retrodev.com/repos/blastem -r tip $(BLASTEM_DIR)
	@echo "$(COLOR_GREEN)>> Downloading Blastem emulator prerequisites...$(COLOR_RESET)"
	git clone --branch SDL2 --recurse-submodules https://github.com/libsdl-org/SDL $(BLASTEM_DIR)/sdl
	git clone https://github.com/nigels-com/glew.git $(BLASTEM_DIR)/glew

# Packages extraction
$(BINUTILS_DIR): $(BINUTILS_PKG)
	tar xf $(BINUTILS_PKG)

$(GCC_DIR): $(GCC_PKG)
	tar xf $(GCC_PKG)

$(GDB_DIR): $(GDB_PKG)
	tar xf $(GDB_PKG)
	tar xf $(GDB_PREREQ_GMP_PKG) -C $(GDB_DIR)
	tar xf $(GDB_PREREQ_MPFR_PKG) -C $(GDB_DIR)
	cd $(GDB_DIR) && ln -s $(GDB_PREREQ_GMP_DIR) gmp
	cd $(GDB_DIR) && ln -s $(GDB_PREREQ_MPFR_DIR) mpfr


# Help
.PHONY: help
help:
	@echo "$(COLOR_MAGENTA)== Mega Drive toolchain builder ==$(COLOR_RESET)"
	@echo "$(COLOR_WHITE)    make help            display this help"
	@echo "    make info            prints prefix and other flags"
	@echo "    make all             builds toolchain"
	@echo "    make with-newlib     builds toolchain with newlib support"
	@echo "    make install         builds and installs toolchain"
	@echo "    make clean           removes tempory files and build dir"

# Info
.PHONY: info
info:
	@echo "$(COLOR_MAGENTA)== Mega Drive toolchain builder info ==$(COLOR_RESET)"
	@echo "$(COLOR_WHITE)    * Paths:"
	@echo "        BUILD_DIR: $(BUILD_DIR)"
	@echo "        INSTALL_DIR: $(INSTALL_DIR)"
	@echo "        LOG_DIR: $(LOG_DIR)"
	@echo "    * Packages:"
	@echo "        BINUTILS_VER $(BINUTILS_VER)"
	@echo "        GCC_VER $(GCC_VER)"
	@echo "        NEWLIB_VER $(NEWLIB_VER)"
	@echo "        GDB_VER $(GDB_VER)"
	@echo "        SJASM_VER $(SJASM_VER)"
	@echo "        SIKTOOLS_VER $(SIKTOOLS_VER)"
	@echo "        BLASTEM_VER tip"
	@echo "    * Build langs:"
	@echo "        LANGS $(LANGS)"
	@echo "    * Other flags:"
	@echo "        PREFIX $(PREFIX)"
	@echo "        PATH $(PATH)"

# Install
.PHONY: install
install: all
	@echo "$(COLOR_YELLOW)> Installing toolchain...$(COLOR_RESET)"
	@mkdir -p $(INSTALL_DIR)
	cp -rf $(BUILD_DIR)/* $(INSTALL_DIR)
	@echo "$(COLOR_GREEN)> Toolchain installed to $(INSTALL_DIR).$(COLOR_RESET)"

# Cleaning
.PHONY: clean
clean:
	@echo "$(COLOR_MAGENTA)> Cleaning...$(COLOR_RESET)"
	rm -rf $(BINUTILS_DIR)
	rm -rf $(GCC_DIR)
	rm -rf $(NEWLIB_DIR)
	rm -rf $(GDB_DIR)
	rm -rf $(SJASM_DIR)
	rm -rf $(SIKTOOLS_DIR)
	rm -rf $(BLASTEM_DIR)
	rm -f mk-binutils mk-gcc mk-newlib mk-gcc-newlib mk-gdb mk-sjasm \
		mk-siktools mk-blastem mk-blastem-build
	rm -f binutils.log gcc.log newlib.log gcc-newlib.log gdb.log sjasm.log \
		siktools.log blastem.log glew.log
	rm -rf $(BUILD_DIR)
