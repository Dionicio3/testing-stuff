# SPDX-License-Identifier: CC0-1.0
#
# SPDX-FileContributor: Antonio Niño Díaz, 2023

BLOCKSDS	?= /opt/blocksds/core
BLOCKSDSEXT	?= /opt/blocksds/external

WONDERFUL_TOOLCHAIN	?= /opt/wonderful
ARM_NONE_EABI_PATH	?= $(WONDERFUL_TOOLCHAIN)/toolchain/gcc-arm-none-eabi/bin/

# User config
# ===========

NAME		:= $(shell basename $(CURDIR))
#funny banner & release shit
VERSION_MAJOR	:= 	0
VERSION_MINOR	:= 	0
VERSION_PATCH	:= 	0
GAME_TITLE	:=	Dionicio3's Testing Thing
GAME_ICON	:=	./icon.png
RELEASE := false
ifeq ($(RELEASE), true)
	GAME_SUBTITLE	:=	$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)
else ifeq ($(RELEASE), false)
	ifeq ($(shell git diff --quiet || echo 'dirty'), dirty)
		GAME_SUBTITLE	:=	$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH).DIRTY
	else
		GAME_SUBTITLE	:=	$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH).$(shell git rev-parse --short HEAD)
	endif
endif
GAME_AUTHOR	:=	Dionicio3
GAME_CODE   := TEST
SHORT_TITLE := DIO3TEST

# Source code paths
# -----------------

SOURCEDIRS	?= source
#INCLUDEDIRS ?= include
NITROFSDIR	?= filesystem

# Libraries
# ---------

LIBS		+= -lnflib -ldswifi9 -lnds9 -lc
LIBDIRS		+= $(BLOCKSDSEXT)/nflib \
		   $(BLOCKSDS)/libs/dswifi \
		   $(BLOCKSDS)/libs/libnds

# Build artifacts
# ---------------

BUILDDIR	:= build
ELF		:= build/$(NAME).elf
DUMP		:= build/$(NAME).dump
MAP		:= build/$(NAME).map
ROM_NDS		:= $(NAME).nds
ROM_DSI		:= $(NAME).dsi
ROM_CIA		:= $(NAME).cia

# If NITROFSDIR is set, the output of mmutil will be placed in that directory
SOUNDBANKINFODIR	:= $(BUILDDIR)/maxmod
ifeq ($(strip $(NITROFSDIR)),)
    SOUNDBANKDIR	:= $(BUILDDIR)/maxmod
else
    SOUNDBANKDIR	:= $(NITROFSDIR)
endif

# Tools
# -----

PREFIX		:= $(ARM_NONE_EABI_PATH)arm-none-eabi-
CC		:= $(PREFIX)gcc
CXX		:= $(PREFIX)g++
OBJDUMP		:= $(PREFIX)objdump
MKDIR		:= mkdir
RM		:= rm -rf

# Verbose flag
# ------------

ifeq ($(VERBOSE),1)
V		:=
else
V		:= @
endif

# Source files
# ------------

ifneq ($(BINDIRS),)
    SOURCES_BIN	:= $(shell find -L $(BINDIRS) -name "*.bin")
    INCLUDEDIRS	+= $(addprefix $(BUILDDIR)/,$(BINDIRS))
endif
ifneq ($(GFXDIRS),)
    SOURCES_PNG	:= $(shell find -L $(GFXDIRS) -name "*.png")
    INCLUDEDIRS	+= $(addprefix $(BUILDDIR)/,$(GFXDIRS))
endif
ifneq ($(AUDIODIRS),)
    SOURCES_AUDIO	:= $(shell find -L $(AUDIODIRS) -regex '.*\.\(it\|mod\|s3m\|wav\|xm\)')
    ifneq ($(SOURCES_AUDIO),)
        INCLUDEDIRS	+= $(SOUNDBANKINFODIR)
    endif
endif

SOURCES_S	:= $(shell find -L $(SOURCEDIRS) -name "*.s")
SOURCES_C	:= $(shell find -L $(SOURCEDIRS) -name "*.c")
SOURCES_CPP	:= $(shell find -L $(SOURCEDIRS) -name "*.cpp")

# Compiler and linker flags
# -------------------------

DEFINES		+= -D__NDS__ -DARM9

ARCH		:= -march=armv5te -mtune=arm946e-s

WARNFLAGS	:= -Wall

ifeq ($(SOURCES_CPP),)
    LD		:= $(CC)
    LIBS	+= -lc
else
    LD		:= $(CXX)
    LIBS	+= -lstdc++ -lc
endif

INCLUDEFLAGS	:= $(foreach path,$(INCLUDEDIRS),-I$(path)) \
		   $(foreach path,$(LIBDIRS),-I$(path)/include)

LIBDIRSFLAGS	:= $(foreach path,$(LIBDIRS),-L$(path)/lib)

ASFLAGS		+= -x assembler-with-cpp $(DEFINES) $(ARCH) \
		   -mthumb -mthumb-interwork $(INCLUDEFLAGS) \
		   -ffunction-sections -fdata-sections

CFLAGS		+= -std=gnu11 $(WARNFLAGS) $(DEFINES) $(ARCH) \
		   -mthumb -mthumb-interwork $(INCLUDEFLAGS) -O2 \
		   -ffunction-sections -fdata-sections \
		   -fomit-frame-pointer

CXXFLAGS	+= -std=gnu++14 $(WARNFLAGS) $(DEFINES) $(ARCH) \
		   -mthumb -mthumb-interwork $(INCLUDEFLAGS) -O2 \
		   -ffunction-sections -fdata-sections \
		   -fno-exceptions -fno-rtti \
		   -fomit-frame-pointer

LDFLAGS		:= -mthumb -mthumb-interwork $(LIBDIRSFLAGS) \
		   -Wl,-Map,$(MAP) -Wl,--gc-sections -nostdlib \
		   -T$(BLOCKSDS)/sys/crts/ds_arm9.mem \
		   -T$(BLOCKSDS)/sys/crts/ds_arm9.ld \
		   -Wl,--no-warn-rwx-segments \
		   -Wl,--start-group $(LIBS) -lgcc -Wl,--end-group

# Intermediate build files
# ------------------------

OBJS_ASSETS	:= $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_BIN))) \
		   $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_PNG)))

HEADERS_ASSETS	:= $(patsubst %.bin,%_bin.h,$(addprefix $(BUILDDIR)/,$(SOURCES_BIN))) \
		   $(patsubst %.png,%.h,$(addprefix $(BUILDDIR)/,$(SOURCES_PNG)))

ifneq ($(SOURCES_AUDIO),)
    ifeq ($(strip $(NITROFSDIR)),)
        OBJS_ASSETS		+= $(SOUNDBANKDIR)/soundbank.c.o
    endif
    HEADERS_ASSETS	+= $(SOUNDBANKINFODIR)/soundbank.h
endif

OBJS_SOURCES	:= $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_S))) \
		   $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_C))) \
		   $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_CPP)))

OBJS		:= $(OBJS_ASSETS) $(OBJS_SOURCES)

DEPS		:= $(OBJS:.o=.d)

# Targets
# -------

.PHONY: all clean dump dldipatch sdimage

all: clean $(ROM_NDS) $(ROM_DSI) $(ROM_CIA)

ifneq ($(strip $(NITROFSDIR)),)
# Additional arguments for ndstool
NDSTOOL_ARGS_NTR	:= -d $(NITROFSDIR)
NDSTOOL_ARGS_TWL	:= -d $(NITROFSDIR) -u 0x00030004 -g $(GAME_CODE) 00 $(SHORT_TITLE)

# Make the NDS ROM depend on the filesystem only if it is needed
$(ROM_NDS): $(NITROFSDIR)
endif

# Combine the title strings
ifeq ($(strip $(GAME_SUBTITLE)),)
    GAME_FULL_TITLE := $(GAME_TITLE);$(GAME_AUTHOR)
else
    GAME_FULL_TITLE := $(GAME_TITLE);$(GAME_SUBTITLE);$(GAME_AUTHOR)
endif

$(ROM_NDS): $(ELF)
	@echo "  NDSTOOL $@"
	$(V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-7 $(BLOCKSDS)/sys/default_arm7/arm7.elf -9 $(ELF) \
		-b $(GAME_ICON) "$(GAME_FULL_TITLE)" \
		$(NDSTOOL_ARGS_NTR)
        
$(ROM_DSI): $(ELF)
	@echo "  NDSTOOL $@"
	$(V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-7 $(BLOCKSDS)/sys/default_arm7/arm7.elf -9 $(ELF) \
		-b $(GAME_ICON) "$(GAME_FULL_TITLE)" \
		$(NDSTOOL_ARGS_TWL)
$(ROM_CIA): $(ROM_DSI)
	@echo "  MAKECIA $@"
	./make_cia --srl=$(ROM_DSI)
$(ELF): $(OBJS)
	@echo "  LD      $@"
	$(V)$(LD) -o $@ $(OBJS) $(BLOCKSDS)/sys/crts/ds_arm9_crt0.o $(LDFLAGS)

$(DUMP): $(ELF)
	@echo "  OBJDUMP   $@"
	$(V)$(OBJDUMP) -h -C -S $< > $@

dump: $(DUMP)

clean:
	@echo "  CLEAN"
	$(V)$(RM) $(ROM_NDS) $(ROM_DSI) $(ROM_CIA) $(DUMP) $(BUILDDIR) $(SDIMAGE) \
		$(SOUNDBANKDIR)/soundbank.bin

sdimage:
	@echo "  MKFATIMG $(SDIMAGE) $(SDROOT)"
	$(V)$(BLOCKSDS)/tools/mkfatimg/mkfatimg -t $(SDROOT) $(SDIMAGE)

dldipatch: $(ROM)
	@echo "  DLDIPATCH $(ROM)"
	$(V)$(BLOCKSDS)/tools/dldipatch/dldipatch patch \
		$(BLOCKSDS)/sys/dldi_r4/r4tf.dldi $(ROM)

# Rules
# -----

$(BUILDDIR)/%.s.o : %.s
	@echo "  AS      $<"
	@$(MKDIR) -p $(@D)
	$(V)$(CC) $(ASFLAGS) -MMD -MP -c -o $@ $<

$(BUILDDIR)/%.c.o : %.c
	@echo "  CC      $<"
	@$(MKDIR) -p $(@D)
	$(V)$(CC) $(CFLAGS) -MMD -MP -c -o $@ $<

$(BUILDDIR)/%.arm.c.o : %.arm.c
	@echo "  CC      $<"
	@$(MKDIR) -p $(@D)
	$(V)$(CC) $(CFLAGS) -MMD -MP -marm -mlong-calls -c -o $@ $<

$(BUILDDIR)/%.cpp.o : %.cpp
	@echo "  CXX     $<"
	@$(MKDIR) -p $(@D)
	$(V)$(CXX) $(CXXFLAGS) -MMD -MP -c -o $@ $<

$(BUILDDIR)/%.arm.cpp.o : %.arm.cpp
	@echo "  CXX     $<"
	@$(MKDIR) -p $(@D)
	$(V)$(CXX) $(CXXFLAGS) -MMD -MP -marm -mlong-calls -c -o $@ $<

$(BUILDDIR)/%.bin.o $(BUILDDIR)/%_bin.h : %.bin
	@echo "  BIN2C   $<"
	@$(MKDIR) -p $(@D)
	$(V)$(BLOCKSDS)/tools/bin2c/bin2c $< $(@D)
	$(V)$(CC) $(CFLAGS) -MMD -MP -c -o $(BUILDDIR)/$*.bin.o $(BUILDDIR)/$*_bin.c

$(BUILDDIR)/%.png.o $(BUILDDIR)/%.h : %.png %.grit
	@echo "  GRIT    $<"
	@$(MKDIR) -p $(@D)
	$(V)$(BLOCKSDS)/tools/grit/grit $< -ftc -W1 -o$(BUILDDIR)/$*
	$(V)$(CC) $(CFLAGS) -MMD -MP -c -o $(BUILDDIR)/$*.png.o $(BUILDDIR)/$*.c

ifneq ($(SOURCES_AUDIO),)

$(SOUNDBANKINFODIR)/soundbank.h: $(SOURCES_AUDIO)
	@echo "  MMUTIL  $^"
	@$(MKDIR) -p $(@D)
	@$(BLOCKSDS)/tools/mmutil/mmutil $^ -d \
		-o$(SOUNDBANKDIR)/soundbank.bin -h$(SOUNDBANKINFODIR)/soundbank.h

ifeq ($(strip $(NITROFSDIR)),)
$(SOUNDBANKDIR)/soundbank.c.o: $(SOUNDBANKINFODIR)/soundbank.h
	@echo "  BIN2C   soundbank.bin"
	$(V)$(BLOCKSDS)/tools/bin2c/bin2c $(SOUNDBANKDIR)/soundbank.bin \
		$(SOUNDBANKDIR)
	@echo "  CC.9    soundbank_bin.c"
	$(V)$(CC) $(CFLAGS) -MMD -MP -c -o $(SOUNDBANKDIR)/soundbank.c.o \
		$(SOUNDBANKDIR)/soundbank_bin.c
endif

endif

# All assets must be built before the source code
# -----------------------------------------------

$(SOURCES_S) $(SOURCES_C) $(SOURCES_CPP): $(HEADERS_ASSETS)

# Include dependency files if they exist
# --------------------------------------

-include $(DEPS)