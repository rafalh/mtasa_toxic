# MAKEFILE HACK: http://devicesoftware.blogspot.com/2010/06/handling-path-with-white-spaces-in.html
NULLSTR := # creating a null string
SPACE   := $(NULLSTR) # end of the line

# nativePath(path)
nativePath = $(subst /,\,$(subst \$(SPACE),$(SPACE),$(1)))

#createDir(path)
createDir = $(Q)if not exist "$(call nativePath,$(1))" $(MKDIR) "$(call nativePath,$(1))"

#deleteFiles(dir, pathList)
deleteFiles = $(CD) $(call nativePath,$(1)) && $(RM) $(foreach target,$(subst \$(SPACE),?,$(2)),"$(call nativePath,$(subst ?,\$(SPACE),$(target)))")

# add_lua_file(path)
define add_lua_file
 $(eval src := $(1))
 $(eval dest := $(OUTPUT)/$(1))
 $(eval temp := $(TEMP_DIR)/$(1))
 $(eval TARGETS := $(TARGETS) $(1))
 ifneq ($(PREPROCESS),0)
  $(TEMP_DIR)/$(src): $(src)
	$(call createDir,$(dir $(temp)))
	$(LUAPP) -o "$(call nativePath,$(temp))" "$(call nativePath,$(src))"
  ifneq ($(COMPILE),0)
	$(CD) $(TEMP_DIR) && $(LUAC) -o "$(call nativePath,$(src))" "$(call nativePath,$(src))"
	$(ADDUTF8BOM) "$(call nativePath,$(temp))"
  endif
  $(eval src := $(temp))
 endif
 $(dest): $(src)
	$(call createDir,$(dir $(dest)))
	$(COPY) "$(call nativePath,$(src))" "$(call nativePath,$(dest))"
endef

define add_file
 $(eval src := $(1))
 $(eval dest := $(OUTPUT)/$(1))
 $(eval TARGETS := $(TARGETS) $(1))
 $(dest): $(src)
	$(call createDir,$(dir $(dest)))
	$(COPY) "$(call nativePath,$(src))" "$(call nativePath,$(dest))"
endef

