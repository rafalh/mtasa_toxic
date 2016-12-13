SELF := $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))

PREPROCESS     := 1
COMPILE        := 1
UTF8_BOM       := 0
JOIN           := 1
PROTECT        := 1
LOADER_PATH    := $(SELF)loader.lua
ifeq ($(windir),)
 RESOURCES_PATH := /mnt/c/Program\ Files\ (x86)/MTA\ San\ Andreas\ 1.5/server/mods/deathmatch/resources/
else
 RESOURCES_PATH := C:/Program\ Files\ (x86)/MTA\ San\ Andreas\ 1.5/server/mods/deathmatch/resources/
endif
TEMP_DIR       := build
