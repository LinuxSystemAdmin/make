#
#   application.make
#
#   Instance Makefile rules to build GNUstep-based applications.
#
#   Copyright (C) 1997, 2001, 2002 Free Software Foundation, Inc.
#
#   Author:  Nicola Pero <nicola@brainstorm.co.uk>
#   Author:  Ovidiu Predescu <ovidiu@net-community.com>
#   Based on the original version by Scott Christley.
#
#   This file is part of the GNUstep Makefile Package.
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation; either version 2
#   of the License, or (at your option) any later version.
#   
#   You should have received a copy of the GNU General Public
#   License along with this library; see the file COPYING.LIB.
#   If not, write to the Free Software Foundation,
#   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

#
# Include in the common makefile rules
#
ifeq ($(RULES_MAKE_LOADED),)
include $(GNUSTEP_MAKEFILES)/rules.make
endif

#
# The name of the application is in the APP_NAME variable.
# The list of application resource directories is in xxx_RESOURCE_DIRS
# The list of application resource files is in xxx_RESOURCE_FILES
# The list of localized resource files is in xxx_LOCALIZED_RESOURCE_FILES
# The list of supported languages is in xxx_LANGUAGES
# The name of the application icon (if any) is in xxx_APPLICATION_ICON
# The name of the app class is xxx_PRINCIPAL_CLASS (defaults to NSApplication).
# The name of a file containing info.plist entries to be inserted into
# Info-gnustep.plist (if any) is xxxInfo.plist
# where xxx is the application name
#

.PHONY: internal-app-all \
        internal-app-install \
        internal-app-uninstall \
        before-$(GNUSTEP_INSTANCE)-all \
        after-$(GNUSTEP_INSTANCE)-all \
        app-resource-files \
        app-localized-resource-files \
        _FORCE

ALL_GUI_LIBS =								     \
    $(shell $(WHICH_LIB_SCRIPT)						     \
     $(ALL_LIB_DIRS)							     \
     $(ADDITIONAL_GUI_LIBS) $(AUXILIARY_GUI_LIBS) $(GUI_LIBS)		     \
     $(BACKEND_LIBS) $(ADDITIONAL_TOOL_LIBS) $(AUXILIARY_TOOL_LIBS)	     \
     $(FND_LIBS) $(ADDITIONAL_OBJC_LIBS) $(AUXILIARY_OBJC_LIBS) $(OBJC_LIBS) \
     $(SYSTEM_LIBS) $(TARGET_SYSTEM_LIBS)				     \
        debug=$(debug) profile=$(profile) shared=$(shared)		     \
	libext=$(LIBEXT) shared_libext=$(SHARED_LIBEXT))

APP_DIR_NAME = $(GNUSTEP_INSTANCE:=.$(APP_EXTENSION))
APP_RESOURCE_DIRS =  $(foreach d, $(RESOURCE_DIRS), $(APP_DIR_NAME)/Resources/$(d))
ifeq ($(strip $(LANGUAGES)),)
  override LANGUAGES="English"
endif

# Support building NeXT applications
ifneq ($(OBJC_COMPILER), NeXT)
APP_FILE = \
    $(APP_DIR_NAME)/$(GNUSTEP_TARGET_LDIR)/$(GNUSTEP_INSTANCE)$(EXEEXT)
else
APP_FILE = $(APP_DIR_NAME)/$(GNUSTEP_INSTANCE)$(EXEEXT)
endif

#
# Internal targets
#

$(APP_FILE): $(OBJ_FILES_TO_LINK)
	$(LD) $(ALL_LDFLAGS) -o $(LDOUT)$@ $(OBJ_FILES_TO_LINK) \
	      $(ALL_GUI_LIBS)
ifeq ($(OBJC_COMPILER), NeXT)
	@$(TRANSFORM_PATHS_SCRIPT) $(subst -L,,$(ALL_LIB_DIRS)) \
		>$(APP_DIR_NAME)/library_paths.openapp
# This is a hack for OPENSTEP systems to remove the iconheader file
# automatically generated by the makefile package.
	rm -f $(GNUSTEP_INSTANCE).iconheader
else
	@$(TRANSFORM_PATHS_SCRIPT) $(subst -L,,$(ALL_LIB_DIRS)) \
	>$(APP_DIR_NAME)/$(GNUSTEP_TARGET_LDIR)/library_paths.openapp
endif

#
# Compilation targets
#
ifeq ($(OBJC_COMPILER), NeXT)
internal-app-all:: before-$(GNUSTEP_INSTANCE)-all \
                   $(GNUSTEP_INSTANCE).iconheader \
                   $(GNUSTEP_OBJ_DIR) \
                   $(APP_DIR_NAME) \
                   $(APP_FILE) \
                   app-resource-files \
                   after-$(GNUSTEP_INSTANCE)-all

before-$(GNUSTEP_INSTANCE)-all::

after-$(GNUSTEP_INSTANCE)-all::

$(GNUSTEP_INSTANCE).iconheader:
	@(echo "F	$(GNUSTEP_INSTANCE).$(APP_EXTENSION)	$(GNUSTEP_INSTANCE)	$(APP_EXTENSION)"; \
	  echo "F	$(GNUSTEP_INSTANCE)	$(GNUSTEP_INSTANCE)	app") >$@

$(APP_DIR_NAME):
	mkdir $@

else

internal-app-all:: before-$(GNUSTEP_INSTANCE)-all \
                   $(GNUSTEP_OBJ_DIR) \
                   $(APP_DIR_NAME)/$(GNUSTEP_TARGET_LDIR) \
                   $(APP_FILE) \
                   $(APP_DIR_NAME)/$(GNUSTEP_INSTANCE) \
                   app-resource-files \
                   app-localized-resource-files \
                   after-$(GNUSTEP_INSTANCE)-all

before-$(GNUSTEP_INSTANCE)-all::

after-$(GNUSTEP_INSTANCE)-all::

$(APP_DIR_NAME)/$(GNUSTEP_TARGET_LDIR):
	@$(MKDIRS) $(APP_DIR_NAME)/$(GNUSTEP_TARGET_LDIR)

ifeq ($(GNUSTEP_FLATTENED),)
$(APP_DIR_NAME)/$(GNUSTEP_INSTANCE):
	cp $(GNUSTEP_MAKEFILES)/executable.template \
	   $(APP_DIR_NAME)/$(GNUSTEP_INSTANCE); \
	chmod a+x $(APP_DIR_NAME)/$(GNUSTEP_INSTANCE)
endif
endif

$(APP_RESOURCE_DIRS):
	$(MKDIRS) $(APP_RESOURCE_DIRS)

app-resource-files:: $(APP_DIR_NAME)/Resources/Info-gnustep.plist \
		     $(APP_DIR_NAME)/Resources/$(GNUSTEP_INSTANCE).desktop \
                     $(APP_RESOURCE_DIRS)
ifneq ($(strip $(RESOURCE_FILES)),)
	@(echo "Copying resources into the application wrapper..."; \
	cp -r $(RESOURCE_FILES) $(APP_DIR_NAME)/Resources;)
endif

app-localized-resource-files:: $(APP_DIR_NAME)/Resources/Info-gnustep.plist \
                               $(APP_RESOURCE_DIRS)
ifneq ($(strip $(LOCALIZED_RESOURCE_FILES)),)
	@(echo "Copying localized resources into the application wrapper..."; \
	for l in $(LANGUAGES); do \
	  if [ -d $$l.lproj ]; then \
	    $(MKDIRS) $(APP_DIR_NAME)/Resources/$$l.lproj; \
	    for f in $(LOCALIZED_RESOURCE_FILES); do \
	      if [ -f $$l.lproj/$$f ]; then \
	        cp -r $$l.lproj/$$f $(APP_DIR_NAME)/Resources/$$l.lproj; \
	      fi; \
	    done; \
	  else \
	    echo "Warning: $$l.lproj not found - ignoring"; \
	  fi; \
	done;)
endif

ifeq ($(PRINCIPAL_CLASS),)
override PRINCIPAL_CLASS = NSApplication
endif

APPLICATION_ICON = $($(GNUSTEP_INSTANCE)_APPLICATION_ICON)

$(APP_DIR_NAME)/Resources/Info-gnustep.plist: $(APP_DIR_NAME)/Resources _FORCE
	@(echo "{"; echo '  NOTE = "Automatically generated, do not edit!";'; \
	  echo "  NSExecutable = \"$(GNUSTEP_INSTANCE)\";"; \
	  if [ "$(MAIN_MODEL_FILE)" = "" ]; then \
	    echo "  NSMainNibFile = \"\";"; \
	  else \
	    echo "  NSMainNibFile = \"$(subst .gmodel,,$(subst .gorm,,$(subst .nib,,$(MAIN_MODEL_FILE))))\";"; \
	  fi; \
	  if [ "$(APPLICATION_ICON)" != "" ]; then \
	    echo "  NSIcon = \"$(APPLICATION_ICON)\";"; \
	  fi; \
	  echo "  NSPrincipalClass = \"$(PRINCIPAL_CLASS)\";"; \
	  echo "}") >$@
	  @ if [ -r "$(GNUSTEP_INSTANCE)Info.plist" ]; then \
	    plmerge $@ $(GNUSTEP_INSTANCE)Info.plist; \
	  fi

$(APP_DIR_NAME)/Resources/$(GNUSTEP_INSTANCE).desktop: \
		$(APP_DIR_NAME)/Resources/Info-gnustep.plist
	@pl2link $^ $(APP_DIR_NAME)/Resources/$(GNUSTEP_INSTANCE).desktop

$(APP_DIR_NAME)/Resources:
	@$(MKDIRS) $@

_FORCE::

internal-app-install:: $(GNUSTEP_APPS)
	rm -rf $(GNUSTEP_APPS)/$(APP_DIR_NAME); \
	$(TAR) cf - $(APP_DIR_NAME) | (cd $(GNUSTEP_APPS); $(TAR) xf -)
ifneq ($(CHOWN_TO),)
	$(CHOWN) -R $(CHOWN_TO) $(GNUSTEP_APPS)/$(APP_DIR_NAME)
endif
ifeq ($(strip),yes)
	$(STRIP) $(GNUSTEP_APPS)/$(APP_FILE)
endif


$(GNUSTEP_APPS):
	$(MKINSTALLDIRS) $(GNUSTEP_APPS)

internal-app-uninstall::
	(cd $(GNUSTEP_APPS); rm -rf $(APP_DIR_NAME))

## Local variables:
## mode: makefile
## End:
