SELF := $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))

PREPROCESS     := 1
COMPILE        := 1
UTF8_BOM       := 0
JOIN           := 1
PROTECT        := 1
LOADER_PATH    := $(SELF)loader.lua
RESOURCES_PATH := C:/Program\ Files\ (x86)/MTA\ San\ Andreas\ 1.4/server/mods/deathmatch/resources/
TEMP_DIR       := build
