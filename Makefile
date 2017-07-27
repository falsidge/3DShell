#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

TOPDIR ?= $(CURDIR)
include $(DEVKITARM)/3ds_rules

#---------------------------------------------------------------------------------
# TARGET is the name of the output
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# DATA is a list of directories containing data files
# INCLUDES is a list of directories containing header files
#
# NO_SMDH: if set to anything, no SMDH file is generated.
# ROMFS is the directory which contains the RomFS, relative to the Makefile (Optional)
# APP_TITLE is the name of the app stored in the SMDH file (Optional)
# APP_DESCRIPTION is the description of the app stored in the SMDH file (Optional)
# APP_AUTHOR is the author of the app stored in the SMDH file (Optional)
# ICON is the filename of the icon (.png), relative to the project folder.
#   If not set, it attempts to use one of the following (in this order):
#     - <Project name>.png
#     - icon.png
#     - <libctru folder>/default_icon.png
#---------------------------------------------------------------------------------
TARGET		:=	$(notdir $(CURDIR))
BUILD		:=	build
RESOURCES   :=	resources
SOURCES		:=	source source/audio source/file source/graphics source/libnsbmp source/net source/unzip
DATA		:=	data
INCLUDES	:=	include include/audio include/file include/graphics include/libnsbmp include/net include/stb_image include/unzip
ROMFS		:=	romfs

APP_TITLE		:= 3DShell
APP_DESCRIPTION	:= Multi-purpose GUI File Manager
APP_AUTHOR		:= Joel16

VERSION_MAJOR := 2
VERSION_MINOR := 0

APP_PRODUCT_CODE 	:= CTR-3D-SHEL
APP_UNIQUE_ID 		:= 0x16200

APP_SYSTEM_MODE 	:= 64MB
APP_SYSTEM_MODE_EXT := Legacy
APP_CPU_SPEED 		:= 804MHz

APP_VERSION_MAJOR 	:= VERSION_MAJOR
APP_ROMFS_DIR		:= $(TOPDIR)/romfs

ICON 		:= $(RESOURCES)/ic_launcher_filemanager.png
BANNER 		:= $(RESOURCES)/banner.png
JINGLE 		:= $(RESOURCES)/banner.wav
LOGO 		:= resources/logo.bcma.lz

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------
ARCH	:=	-march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft

CFLAGS	:=	-g -Wall -O2 -mword-relocations \
			-fomit-frame-pointer -ffunction-sections \
			-DVERSION_MAJOR=$(VERSION_MAJOR) -DVERSION_MINOR=$(VERSION_MINOR) \
			$(ARCH)

CFLAGS	+=	$(INCLUDE) -DARM11 -D_3DS

CXXFLAGS	:= $(CFLAGS) -fno-rtti -fno-exceptions -std=gnu++11

ASFLAGS	:=	-g $(ARCH)
LDFLAGS	=	-specs=3dsx.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)

LIBS	:= -lcitro3d -lctru -lm -lpng16 -lz

OS := $(shell uname)

#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
LIBDIRS	:= $(CTRULIB) $(PORTLIBS)


#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT	:=	$(CURDIR)/$(TARGET)
export TOPDIR	:=	$(CURDIR)

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
			$(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
PICAFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.v.pica)))
SHLISTFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.shlist)))
BINFILES	:=	$(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

#---------------------------------------------------------------------------------
# use CXX for linking C++ projects, CC for standard C
#---------------------------------------------------------------------------------
ifeq ($(strip $(CPPFILES)),)
#---------------------------------------------------------------------------------
	export LD	:=	$(CC)
#---------------------------------------------------------------------------------
else
#---------------------------------------------------------------------------------
	export LD	:=	$(CXX)
#---------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------

export OFILES_SOURCES 	:=	$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)

export OFILES_BIN	:=	$(addsuffix .o,$(BINFILES)) \
			$(PICAFILES:.v.pica=.shbin.o) $(SHLISTFILES:.shlist=.shbin.o)

export OFILES := $(OFILES_BIN) $(OFILES_SOURCES)

export HFILES	:=	$(PICAFILES:.v.pica=_shbin.h) $(addsuffix .h,$(subst .,_,$(BINFILES)))

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
			$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
			-I$(CURDIR)/$(BUILD)

export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib)

ifeq ($(strip $(ICON)),)
	icons := $(wildcard *.png)
	ifneq (,$(findstring $(TARGET).png,$(icons)))
		export APP_ICON := $(TOPDIR)/$(TARGET).png
	else
		ifneq (,$(findstring icon.png,$(icons)))
			export APP_ICON := $(TOPDIR)/icon.png
		endif
	endif
else
	export APP_ICON := $(TOPDIR)/$(ICON)
endif

ifeq ($(strip $(NO_SMDH)),)
	export _3DSXFLAGS += --smdh=$(CURDIR)/$(TARGET).smdh
endif

ifneq ($(ROMFS),)
	export _3DSXFLAGS += --romfs=$(CURDIR)/$(ROMFS)
endif

.PHONY: $(BUILD) clean all

#---------------------------------------------------------------------------------
all: $(BUILD)

$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

#---------------------------------------------------------------------------------
clean:
	@echo clean ...
	@rm -fr $(BUILD) $(TARGET).3dsx $(OUTPUT).smdh $(OUTPUT).elf $(OUTPUT)-stripped.elf $(OUTPUT).bin $(OUTPUT).3ds $(OUTPUT).cia icon.bin banner.bin

#---------------------------------------------------------------------------------
banner:
	@$(TOPDIR)/tools/bannertool

#---------------------------------------------------------------------------------
else

DEPENDS	:=	$(OFILES:.o=.d)

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
ifeq ($(strip $(NO_SMDH)),)
$(OUTPUT).3dsx	:	$(OUTPUT).smdh icon.bin banner.bin $(OUTPUT).elf $(OUTPUT)-stripped.elf $(OUTPUT).bin $(OUTPUT).3ds $(OUTPUT).cia
else
$(OUTPUT).3dsx	:	icon.bin banner.bin $(OUTPUT).elf $(OUTPUT)-stripped.elf $(OUTPUT).bin $(OUTPUT).3ds $(OUTPUT).cia
endif

$(OFILES_SOURCES) : $(HFILES)

$(OUTPUT).elf	:	$(OFILES)

#---------------------------------------------------------------------------------
icon.bin	:
#---------------------------------------------------------------------------------
ifeq ($(UNAME), Linux)
	@$(TOPDIR)/tools/linux/bannertool makesmdh -s $(APP_TITLE) -l $(APP_TITLE) -p $(APP_AUTHOR) -i $(TOPDIR)/$(ICON) -o $(TOPDIR)/icon.bin -f visible allow3d
else ifeq ($(UNAME), Darwin)
	@$(TOPDIR)/tools/osx/bannertool makesmdh -s $(APP_TITLE) -l $(APP_TITLE) -p $(APP_AUTHOR) -i $(TOPDIR)/$(ICON) -o $(TOPDIR)/icon.bin -f visible allow3d
else
	@$(TOPDIR)/tools/windows/bannertool.exe makesmdh -s $(APP_TITLE) -l $(APP_TITLE) -p $(APP_AUTHOR) -i $(TOPDIR)/$(ICON) -o $(TOPDIR)/icon.bin -f visible allow3d
endif

#---------------------------------------------------------------------------------
banner.bin	:
#---------------------------------------------------------------------------------
ifeq ($(UNAME), Linux)
	@$(TOPDIR)/tools/linux/bannertool makebanner -i $(TOPDIR)/$(BANNER) -a $(TOPDIR)/$(JINGLE) -o $(TOPDIR)/banner.bin
else ifeq ($(UNAME), Darwin)
	@$(TOPDIR)/tools/osx/bannertool makebanner -i $(TOPDIR)/$(BANNER) -a $(TOPDIR)/$(JINGLE) -o $(TOPDIR)/banner.bin
else
	@$(TOPDIR)/tools/windows/bannertool.exe makebanner -i $(TOPDIR)/$(BANNER) -a $(TOPDIR)/$(JINGLE) -o $(TOPDIR)/banner.bin
endif

#---------------------------------------------------------------------------------
$(OUTPUT).elf	:	$(OFILES)
#---------------------------------------------------------------------------------
$(OUTPUT)-stripped.elf : $(OUTPUT).elf

#---------------------------------------------------------------------------------
	@cp -f $(OUTPUT).elf $(OUTPUT)-stripped.elf
	@arm-none-eabi-strip $(OUTPUT)-stripped.elf

#---------------------------------------------------------------------------------
$(OUTPUT).bin	:
#---------------------------------------------------------------------------------
ifeq ($(UNAME), Linux)
	@$(TOPDIR)/tools/linux/3dstool -cvtf romfs $(OUTPUT).bin --romfs-dir $(APP_ROMFS_DIR)
else ifeq ($(UNAME), Darwin)
	@$(TOPDIR)/tools/osx/3dstool -cvtf romfs $(OUTPUT).bin --romfs-dir $(APP_ROMFS_DIR)
else
	@$(TOPDIR)/tools/windows/3dstool.exe -cvtf romfs $(OUTPUT).bin --romfs-dir $(APP_ROMFS_DIR)
endif
	@echo RomFS packaged ...

#---------------------------------------------------------------------------------
$(OUTPUT).3ds	:	$(OUTPUT)-stripped.elf $(OUTPUT).bin icon.bin banner.bin
#---------------------------------------------------------------------------------
ifeq ($(UNAME), Linux)
	@$(TOPDIR)/tools/linux/makerom -f cci -o $(OUTPUT).3ds -DAPP_ENCRYPTED=true -DAPP_UNIQUE_ID=$(APP_UNIQUE_ID) -elf $(OUTPUT)-stripped.elf -rsf "$(TOPDIR)/resources/cia.rsf" -icon $(TOPDIR)/icon.bin -banner $(TOPDIR)/banner.bin  -exefslogo -target t -romfs "$(OUTPUT).bin"
else ifeq ($(UNAME), Darwin)
	@$(TOPDIR)/tools/osx/makerom -f cci -o $(OUTPUT).3ds -DAPP_ENCRYPTED=true -DAPP_UNIQUE_ID=$(APP_UNIQUE_ID) -elf $(OUTPUT)-stripped.elf -rsf "$(TOPDIR)/resources/cia.rsf" -icon $(TOPDIR)/icon.bin -banner $(TOPDIR)/banner.bin -exefslogo -target t -romfs "$(OUTPUT).bin"
else
	@$(TOPDIR)/tools/windows/makerom.exe -f cci -o $(OUTPUT).3ds -DAPP_ENCRYPTED=true -DAPP_UNIQUE_ID=$(APP_UNIQUE_ID) -elf $(OUTPUT)-stripped.elf -rsf "$(TOPDIR)/resources/cia.rsf" -icon $(TOPDIR)/icon.bin -banner $(TOPDIR)/banner.bin  -exefslogo -target t -romfs "$(OUTPUT).bin"
endif
	@echo 3DS packaged ...

#---------------------------------------------------------------------------------
$(OUTPUT).cia	:	$(OUTPUT)-stripped.elf $(OUTPUT).bin icon.bin banner.bin
#---------------------------------------------------------------------------------
ifeq ($(UNAME), Linux)
	@$(TOPDIR)/tools/linux/makerom -f cia -o $(OUTPUT).cia -DAPP_ENCRYPTED=false -DAPP_UNIQUE_ID=$(APP_UNIQUE_ID) -elf $(OUTPUT)-stripped.elf -rsf "$(TOPDIR)/resources/cia.rsf" -icon $(TOPDIR)/icon.bin -logo "$(TOPDIR)/resources/logo.bcma.lz" -banner $(TOPDIR)/banner.bin  -exefslogo -target t -romfs "$(OUTPUT).bin"
else ifeq ($(UNAME), Darwin)
	@$(TOPDIR)/tools/osx/makerom -f cia -o $(OUTPUT).cia -DAPP_ENCRYPTED=false -DAPP_UNIQUE_ID=$(APP_UNIQUE_ID) -elf $(OUTPUT)-stripped.elf -rsf "$(TOPDIR)/resources/cia.rsf" -icon $(TOPDIR)/icon.bin -logo "$(TOPDIR)/resources/logo.bcma.lz" -banner $(TOPDIR)/banner.bin -exefslogo -target t -romfs "$(OUTPUT).bin"
else
	@$(TOPDIR)/tools/windows/makerom.exe -f cia -o $(OUTPUT).cia -DAPP_ENCRYPTED=false -DAPP_UNIQUE_ID=$(APP_UNIQUE_ID) -elf $(OUTPUT)-stripped.elf -rsf "$(TOPDIR)/resources/cia.rsf" -icon $(TOPDIR)/icon.bin -logo "$(TOPDIR)/resources/logo.bcma.lz" -banner $(TOPDIR)/banner.bin  -exefslogo -target t -romfs "$(OUTPUT).bin"
endif
	@echo CIA packaged ...

#---------------------------------------------------------------------------------
# you need a rule like this for each extension you use as binary data
#---------------------------------------------------------------------------------
%.png.o	%_png.h :	%.png
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)

#---------------------------------------------------------------------------------
# rules for assembling GPU shaders
#---------------------------------------------------------------------------------
define shader-as
	$(eval CURBIN := $*.shbin)
	$(eval DEPSFILE := $(DEPSDIR)/$*.shbin.d)
	echo "$(CURBIN).o: $< $1" > $(DEPSFILE)
	echo "extern const u8" `(echo $(CURBIN) | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`"_end[];" > `(echo $(CURBIN) | tr . _)`.h
	echo "extern const u8" `(echo $(CURBIN) | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`"[];" >> `(echo $(CURBIN) | tr . _)`.h
	echo "extern const u32" `(echo $(CURBIN) | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`_size";" >> `(echo $(CURBIN) | tr . _)`.h
	picasso -o $(CURBIN) $1
	bin2s $(CURBIN) | $(AS) -o $*.shbin.o
endef

%.shbin.o %_shbin.h : %.v.pica %.g.pica
	@echo $(notdir $^)
	@$(call shader-as,$^)

%.shbin.o %_shbin.h : %.v.pica
	@echo $(notdir $<)
	@$(call shader-as,$<)

%.shbin.o %_shbin.h : %.shlist
	@echo $(notdir $<)
	@$(call shader-as,$(foreach file,$(shell cat $<),$(dir $<)$(file)))
	@$(call shader-as,$<)

-include $(DEPENDS)

#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------