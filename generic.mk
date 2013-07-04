DIR = $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))
include $(DIR)/utils.mak

ifeq ($(wildcard $(CURDIR)/build/Makefile.auto),)
 $(PROJECT_NAME): $(CURDIR)/build/Makefile.auto
	$(MAKE)

 $(CURDIR)/build:
	@mkdir "$(call native_path,$(CURDIR)/build)"

 $(CURDIR)/build/Makefile.auto: $(CURDIR)/meta.xml $(CURDIR)/build
	$(META2MAKEFILE) -o $(CURDIR)/build/Makefile.auto -t $(PROJECT_NAME)_ $(CURDIR)/meta.xml
else
 $(PROJECT_NAME): $(PROJECT_NAME)_files
 include build/Makefile.auto
endif
