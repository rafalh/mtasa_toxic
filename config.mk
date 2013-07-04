META2MAKEFILE_PATH := D:\lua\tools\meta2makefile.exe
ADDUTF8BOM_PATH    := D:\lua\tools\addutf8bom.exe

ifndef VERBOSE
Q := @
else
Q :=
endif
META2MAKEFILE := $(Q)"$(META2MAKEFILE_PATH)"
LUA           := $(Q)"D:\lua\bin\lua5.1.exe"
LUAC          := $(Q)"D:\lua\bin\luac5.1.exe"
LUAPP         := $(Q)$(LUA) "D:\lua\tools\preprocess.lua"
ADDUTF8BOM    := $(Q)"$(ADDUTF8BOM_PATH)"
COPY          := $(Q)copy /Y
MKDIR         := $(Q)mkdir
RM            := $(Q)del /F /Q
CD            := $(Q)cd /D

PREPROCESS     := 1
COMPILE        := 1
RESOURCES_PATH := C:/Program\ Files\ (x86)/MTA\ San\ Andreas\ 1.3/server/mods/deathmatch/resources/
TEMP_DIR       := build