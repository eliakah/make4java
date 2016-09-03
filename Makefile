# make4java - A Makefile for Java projects
#
# Written in 2015 by Francesco Lattanzio <franz.lattanzio@gmail.com>
#
# To the extent possible under law, the author have dedicated all
# copyright and related and neighboring rights to this software to
# the public domain worldwide. This software is distributed without
# any warranty.
#
# You should have received a copy of the CC0 Public Domain Dedication
# along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# To enabled incremental compilation you need the "jdeps" utility
# (available in OpenJDK 1.8). If not found it will revert to full
# compilation every time one or more source files are modified or
# added.
#
# NOTE: Only file modification and/or addition is supported, that is,
#       if a (re)source file is removed you have to perform a full
#       compilation ("make clean compile") in order to get rid of the
#       old classes and "filtered" resources.
#
# If you want to use jdeps but don't want to generate 1.8 bytecode,
# just add the JAVAC variable to the "localdefs.mk" file:
#
#   JAVAC := javac -source 1.7 -target 1.7 \
#            -bootclasspath /usr/lib/jvm/java-7-openjdk/jre/lib/rt.jar
#
# Choose appropriate source, target and bootclasspath's values for you
# project.
#
# NOTE: For small projects a full compilation may be faster than an
#       incremental compilation followed by a jdeps run. In such cases
#       you may wish to disable jdeps: just add "HAVE_JDEPS := false"
#       to "localdefs.mk".

-include localdefs.mk

# To change the value of the following variables, add them to
# "localdefs.mk".


#########
# Tools #
#########

# Sample optional feature -- disabled by default
ENABLE_FOO_FEATURE ?= false

# Java tools
JAR ?= jar
JAVA ?= java
JAVAC ?= javac
JAVAH ?= javah
JDEPS ?= jdeps

# Assorted tools -- every UNIX-like OS should have these (and a
# Bourne-like shell)
AWK ?= awk
CAT ?= cat
# CC ?= cc # this variable is predefined by make
CHMOD ?= chmod
# CPP ?= $(CC) -E # this variable is predefined by make
FGREP ?= fgrep
FIND ?= find
LINK ?= ln -f
MAKE_ALIAS ?= ln -s
MKDIR ?= mkdir
MKDIR_P ?= mkdir -p
MV ?= mv
OS ?= uname -o
# RM ?= rm -f # this variable is predefined by make
SED ?= sed
TAR ?= tar
XARGS ?= xargs

# Native code support -- if defined, the values of the CPPFLAGS and
# CFLAGS variables will be passed to the C compiler to compile the C
# source files into object files, whereas the value of the LDFLAGS
# variable will be used to link those object files into the native
# dynamic library.
CFLAGS ?=
CPPFLAGS ?=
LDFLAGS ?=


####################################
# Project properties and structure #
####################################

# This and the next variable are used to build the name of the package
# TAR archive
PACKAGE_NAME := foobar

# Version number of the package (each component has its own version
# number)
package.version := 1.0.3

# The name of the directory inside the built JARs, that will hold
# included JARs
resources.jars := jars

# The name of the directory inside the built JARs, that will hold
# included native libraries
resources.libs := libs


# Component-relative path to Java source files
SOURCES_PATH := src/main/java/

# Component-relative path to resource files
RESOURCES_PATH := src/main/resources/

# Component-relative path to native C source files
NATIVE_SOURCES_PATH := src/main/native/


# The name of a subdirectory of the topmost directory that holds all
# the project's dependencies (JAR files only).
# NOTE: The project's README or INSTALL file should contain a list of
#       all the dependencies required and should also instruct the user
#       to download them into this directory, optionally arranging them
#       into a hierachy of directories.
EXTERNAL_LIBRARIES_DIR := libs/


# The name of a subdirectory of the topmost directory that will hold all
# the intermediate files produced by the build process
BUILD_DIR := build/

# The name of the file that will hold the list of all the source files
SOURCE_FILES_FULL_LIST := $(BUILD_DIR)source-files

# The name of the file that will hold the .class to .java dependencies
JAVA_DEPENDENCIES := $(BUILD_DIR)java-dependencies

# The name of the file that will hold all the -sourcepath options
# for javac
JAVAC_SOURCEPATHS_LIST := $(BUILD_DIR)javac-sourcepaths

# The name of the file that will hold the list of source files
# to be compiled
JAVAC_SOURCE_FILES_LIST := $(BUILD_DIR)javac-source-files


# The name of the file that will hold the list of the class files -- and
# their respective source files -- to be processed through javah
EXPORTED_CLASSES_LIST := $(BUILD_DIR)exported-classes

# The name of the file that will hold the list of the class files to be
# reprocessed through javah, i.e., class files from the previous
# variable that were modified since last compilation
JAVAH_CLASSES_LIST := $(BUILD_DIR)javah-classes

# The name of the file that will cache javah's include directory
JDK_INCLUDE := $(BUILD_DIR)jdk-include


# The name of the directory that will hold all the class files
# compiled...
CLASSES_DIR := $(BUILD_DIR)classes/

# ... and its alias directory
CLASSES_ALIAS_DIR := $(BUILD_DIR)classes-alias

# The name of the directory that will hold all the resource files ready
# to be stored in the JARs
RESOURCES_DIR := $(BUILD_DIR)resources/

# The name of the file holding the sed script used to filter resource
# files
RESOURCES_FILTER_SCRIPT := $(BUILD_DIR)sed-script

# The name of the directory that will hold all the JAR files built
JARS_DIR := $(BUILD_DIR)$(resources.jars)/


# The name of the directory that will hold all the object files compiled
# from native C code
OBJECTS_DIR := $(BUILD_DIR)obj/

# The name of the directory that will hold all the include files
# generated by javah
INCLUDE_DIR := $(BUILD_DIR)include/

# The name of the directory that will hold all the native library built
NATIVE_DIR := $(BUILD_DIR)$(resources.libs)/


# The name of the directory that will hold all the files to be put into
# the package TAR archive
STAGE_DIR := $(BUILD_DIR)stage/

# The name of the directory that will hold all the packages built (for
# this sample Makefile there will be only one package)
PACKAGE_DIR := packages/


# Locate jdeps and define JDEPS, unless HAVE_JDEPS is defined
ifdef HAVE_JDEPS

ifneq ($(HAVE_JDEPS),true)
JDEPS :=
endif

else # def HAVE_JDEPS

# If JDEPS contains an absolute file name, use it as is, else, if it is
# relative, convert it to an absolute file name looking up in the PATH's
# directories.
# If the file cannot be found or does not exist, JDEPS will contain an
# empty string.
JDEPS := $(firstword $(wildcard $(if $(filter /%,$(JDEPS)),$(JDEPS),$(addsuffix /$(JDEPS),$(subst :, ,$(PATH))))))

ifndef JDEPS
$(info NOTE: jdeps not found: incremental compilation disabled)
endif

endif # def HAVE_JDEPS


# The default target -- change it to whatever you want
package:

$(BUILD_DIR) $(PACKAGE_DIR):
	$(MKDIR) '$@'

$(CLASSES_DIR) $(INCLUDE_DIR) $(JARS_DIR) $(NATIVE_DIR): | $(BUILD_DIR)
	$(MKDIR) '$@'

$(CLASSES_ALIAS_DIR): | $(CLASSES_DIR)
	$(MAKE_ALIAS) "$$(basename '$|')" '$@'


###################################
# build.mk's variables and macros #
###################################

# For each external dependency (see EXTERNAL_LIBRARIES_DIR above),
# component's JAR library or native library, the following "library
# variables" will be defined:
#   <libname>.version   - version of the library
#   <libname>.basename  - file name of the library, without path
#   <libname>.buildname - file name of the library, with path relative
#                         to the project's topmost directory
#   <libname>.jarname   - file name of the library, with path relative
#                         to the root directory of an including JAR,
#                         i.e., in case this library is included within
#                         some component's JAR archive, this variable
#                         will tell where it is to be found *inside* the
#                         JAR archive
# where <libname> is the name of the JAR/native library file without the
# .jar or .so extension nor the version number.
# The PARSE_LIB_AND_VER, BUILD_MAKE_RULES and BUILD_NATIVE_MAKE_RULES
# macros will define them. They are described here as their main use is
# to be listed in the RESOURCE_PLACEHOLDERS variable (see below) to
# provide values to filter the resources with. Of course, you can employ
# them wherever you see fit, e.g., to define new rules.
# NOTE: <libname>.version and <libname>.jarname are automatically added
#       to the RESOURCE_PLACEHOLDERS variable

# Lists the variables that will be used to "filter" the resources,
# i.e., for each "varname" listed, the string "${varname}" will be
# looked for in the resources and replaced with the value of
# the variable "varname"
RESOURCE_PLACEHOLDERS := package.version resources.jars resources.libs


# The following macros are meant to be used in the components' build.mk.
# The "component base directory" is where the build.mk file is located
# (see the sample build.mk's for examples of use).

# Arguments:
#   $(1) - component base directory
FIND_SOURCES = $(shell test -d $(1)$(SOURCES_PATH) && $(FIND) $(1)$(SOURCES_PATH) -name '*.java')

# Arguments:
#   $(1) - component base directory
FIND_RESOURCES = $(shell test -d $(1)$(RESOURCES_PATH) && $(FIND) $(1)$(RESOURCES_PATH) -type f)

# Arguments:
#   $(1) - component base directory
FIND_NATIVE_SOURCES = $(shell test -d $(1)$(NATIVE_SOURCES_PATH) && $(FIND) $(1)$(NATIVE_SOURCES_PATH) -name '*.c')


######################
# External libraries #
######################

# Retrieve all the external dependencies
LIBRARIES := $(shell test -d $(EXTERNAL_LIBRARIES_DIR) && $(FIND) $(EXTERNAL_LIBRARIES_DIR) -name '*.jar')


# Convert the parsed library name (see further below) into values
# to be put into the "library variables", adds <libname>.version and
# <libname>.jarname to RESOURCE_PLACEHOLDERS and define a rule to copy
# the library into the $(JARS_DIR) directory, should the external
# library be included into some component's JAR archive.

# Arguments:
#   $(1) - parsed library name (in the <libname>:<version> format)
define PARSE_LIB_AND_VER =

MK_NAME := $(word 1,$(subst :, ,$(1)))
MK_VERSION := $(word 2,$(subst :, ,$(1)))
MK_JARNAME := $$(if $$(MK_VERSION),$$(MK_NAME)-$$(MK_VERSION).jar,$$(MK_NAME).jar)

$$(MK_NAME).version := $$(MK_VERSION)
$$(MK_NAME).basename := $$(MK_JARNAME)
$$(MK_NAME).buildname := $$(filter %/$$(MK_JARNAME),$$(LIBRARIES))
$$(MK_NAME).jarname := $(resources.jars)/$$(MK_JARNAME)

RESOURCE_PLACEHOLDERS += $$(MK_NAME).version $$(MK_NAME).jarname

$(BUILD_DIR)$$(value $$(MK_NAME).jarname): $$(value $$(MK_NAME).buildname) | $(JARS_DIR)
	$(LINK) '$$<' '$$@'

endef # PARSE_LIB_AND_VER


# For each dependency found under the $(EXTERNAL_LIBRARIES_DIR)
# directory, define the four library variables.
# First, parse the file names and convert them into <libname>:<version>
# strings, ...
LIBS_AND_VERS := $(shell echo $(basename $(notdir $(LIBRARIES))) | $(SED) 's|\([^ ]*\)-\(\([0-9.]\{1,\}\)\(-[^ ]*\)\{0,1\}\)|\1:\2|g')

# ... then for each such string define the aforementioned library
# variables.
$(foreach var,$(LIBS_AND_VERS),$(eval $(call PARSE_LIB_AND_VER,$(var))))


###################
# Java components #
###################

# Java components' JAR archives
JAR_ARCHIVES :=

# javac's -sourcepath directories list
SOURCE_DIRECTORIES :=

# Java source files
SOURCE_FILES :=

# Missing included JARs and native libraries
# NOTE: A missing Java or native library may be caused by specifying the
#       including component *before* the included component.
MISSING_INCLUDED_COMPONENTS :=

# Classpath for javac and javah
# NOTE: The "empty" variable must NOT be defined
CLASSPATH := -classpath $(subst $(empty) $(empty),:,$(strip $(CLASSES_DIR) $(LIBRARIES)))


# Verify the specified library has been defined

# Arguments:
#   $(1) - component name
define CHECK_INCLUDED =

ifndef $(1).jarname
MISSING_INCLUDED_COMPONENTS += $(1)
endif

endef # CHECK_INCLUDED


# Convert Java source file names into their corresponding alias class
# file names

# Arguments:
#   $(1) - component base directory
#   $(2) - Java source file names
SOURCES_TO_ALIAS_CLASSES = $(patsubst $(1)$(SOURCES_PATH)%.java,$(CLASSES_ALIAS_DIR)/%.class,$(2))


# Convert Java source file names into their corresponding class file
# names

# Arguments:
#   $(1) - component base directory
#   $(2) - Java source file names
SOURCES_TO_CLASSES = $(patsubst $(1)$(SOURCES_PATH)%.java,$(CLASSES_DIR)%.class,$(2))


# Compute the file names of filtered resources

# Arguments:
#   $(1) - component base directory
#   $(2) - component/JAR name
#   $(3) - unfiltered resource file names
RESOURCES_TO_JAR = $(patsubst $(1)$(RESOURCES_PATH)%,$(RESOURCES_DIR)$(2)/%,$(3))


.PHONY: compile


# Create rules to build a JAR component from Java source files.
# Define the library variables and the filtered to unfiltered resource
# dependencies and verifies that all the included libraries are defined
# (this means that the build.mk file of any included JAR or native
# library must be included in the Makefile before the including JAR's
# build.mk -- see also the "Components' build.mk files" section).
# The implicit %.class rule below will write all the classes older than
# their respective source files and/or older than any other source files
# they depends on (see the "-include $(JAVA_DEPENDENCIES)" below) to the
# $(JAVAC_SOURCE_FILES_LIST) file.
# The implicit $(RESOURCES_DIR)% rule below will filter all the resource
# files before copying them into the $(RESOURCES_DIR) directory.
# Also, note that if the JAR archive is already existing, only the
# classes, resources or included libraries modified since last build
# will be updated.

# Arguments:
#   $(1) - component/JAR name
#   $(2) - component/JAR version
#   $(3) - component base directory
#   $(4) - Java source files list
#   $(5) - resource files list
#   $(6) - JARs and/or native libraries to be included in this
#          component's JAR archive
define BUILD_MAKE_RULES =

ifeq ($(1),)
$$(error Missing jar basename)
endif

MK_JARNAME := $(if $(2),$(1)-$(2).jar,$(1).jar)

$(1).version := $(2)
$(1).basename := $$(MK_JARNAME)
$(1).buildname := $(JARS_DIR)$$(MK_JARNAME)
$(1).jarname := $(resources.jars)/$$(MK_JARNAME)

RESOURCE_PLACEHOLDERS += $(1).version $(1).jarname
JAR_ARCHIVES += $$(value $(1).buildname)
SOURCE_DIRECTORIES += $(3)
SOURCE_FILES += $(4)

$$(foreach var,$(6),$$(eval $$(call CHECK_INCLUDED,$$(var))))


$$(foreach var,$(4),$$(eval $$(call SOURCES_TO_ALIAS_CLASSES,$(3),$$(var)): $$(var)))

run-javac: $$(call SOURCES_TO_ALIAS_CLASSES,$(3),$(4))

# The empty recipe force reevaluation of target timestamp after
# run-javac has been processed
$$(foreach var,$(4),$$(eval $$(call SOURCES_TO_CLASSES,$(3),$$(var)): run-javac;))

compile: $$(call SOURCES_TO_CLASSES,$(3),$(4))

$$(foreach var,$(5),$$(eval $$(call RESOURCES_TO_JAR,$(3),$(1),$$(var)): $$(var)))

$$(value $(1).buildname): $$(call SOURCES_TO_CLASSES,$(3),$(4)) \
                          $$(call RESOURCES_TO_JAR,$(3),$(1),$(5)) \
                          $$(foreach var,$(6),$$(addprefix $(BUILD_DIR),$$(value $$(var).jarname))) | $(JARS_DIR)
	if test -f '$$@'; then cmd=u; else cmd=c; fi && \
	$(JAR) $$$${cmd}vf '$$@' \
	  $$(addprefix -C $(CLASSES_DIR) ,$$(patsubst $(CLASSES_DIR)%,'%',$$(filter $(CLASSES_DIR)%,$$?) \
	                                                                  $$(wildcard $$(patsubst %.class,%$$$$*.class,$$(filter $(CLASSES_DIR)%,$$?))))) \
	  $$(addprefix -C $(RESOURCES_DIR)$(1) ,$$(patsubst $(RESOURCES_DIR)$(1)/%,'%',$$(filter $(RESOURCES_DIR)%,$$?))) \
	  $$(addprefix -C $(BUILD_DIR) ,$$(patsubst $(BUILD_DIR)%,'%',$$(filter $(JARS_DIR)%,$$?)))

endef # BUILD_MAKE_RULES


# Store a list of -sourcepath directories -- the .PHONY special target
# ensures that it is rebuilt at every run

.PHONY: $(JAVAC_SOURCEPATHS_LIST)

$(JAVAC_SOURCEPATHS_LIST): | $(BUILD_DIR)
	@echo 'Building $@' \
	$(file >$@) \
	$(foreach var,$(SOURCE_DIRECTORIES),$(file >>$@,-sourcepath $(var)$(SOURCES_PATH)))


# Store the list of all the Java source files -- the .PHONY special
# target ensures that it is rebuilt at every run

.PHONY: $(SOURCE_FILES_FULL_LIST)

$(SOURCE_FILES_FULL_LIST): | $(BUILD_DIR)
	@echo 'Building $@' \
	$(file >$@) \
	$(foreach var,$(SOURCE_FILES),$(file >>$@,$(var)))


# Clean-up the list of to-be-compiled Java source files (it will be
# filled-up by the next rule) -- the .PHONY special target ensures that
# it is always cleaned-up

.PHONY: $(JAVAC_SOURCE_FILES_LIST)

$(JAVAC_SOURCE_FILES_LIST): | $(BUILD_DIR)
	@: >'$@'


# Take note of the source files to be compiled (see also
# the BUILD_MAKE_RULES macro below)
$(CLASSES_ALIAS_DIR)/%.class: | $(JAVAC_SOURCE_FILES_LIST)
	echo '$<' >>'$(JAVAC_SOURCE_FILES_LIST)'


# Build the sed script used to filter the resources -- for it must be
# created once at every run, we need the .PHONY special target.
# The script will parse the resource files looking for strings of the
# form "${varname}" and will substitute those strings with the value of
# the make variable named "varname".
# Only the varnames listed in RESOURCE_PLACEHOLDERS will be substituted -- any
# string of the form "${varname}" where varname is not listed in
# RESOURCE_PLACEHOLDERS will be left untouched.

.PHONY: $(RESOURCES_FILTER_SCRIPT)

$(RESOURCES_FILTER_SCRIPT): | $(BUILD_DIR)
	@echo 'Building $@' \
	$(file >$@) \
	$(foreach var,$(RESOURCE_PLACEHOLDERS),$(file >>$@,s|$${$(var)}|$($(var))|g))


# This rule applies the aforementioned sed script to the resource files.
# NOTE: For text-only files this is good enough, but for binary,
#       especially *big* binary files, this could cause some trouble.
#       A possible solution would be to split the resources into two
#       distinct directories -- one for resources to filter and the
#       other for resources to keep as are.

$(RESOURCES_DIR)%: | $(RESOURCES_FILTER_SCRIPT)
	$(MKDIR_P) "$$(dirname '$@')" && \
	$(SED) -f '$(RESOURCES_FILTER_SCRIPT)' '$<' >'$@'


# The following rule will actually compile the code and extract
# the dependencies (if jdeps is available and enabled).
# The difficult part is dependencies extraction:
# 1) first the newly compiled classes are removed from the
#    $(JAVA_DEPENDENCIES) files
# 2) then an AWK script is built to convert partial (without component
#    name) source file names into full (comlete with component name)
#    file names
# 3) afterward jdeps is run against the newly compiled classes and each
#    class to class dependency it outputs is converted into a class file
#    name to partial source file name depencency
# 4) finally the AWK script is run through the class file name to
#    partial source file name depencencies to convert them into class
#    file name to component-complete source file name dependencies

.PHONY: run-javac

run-javac: | $(CLASSES_ALIAS_DIR) $(JAVAC_SOURCEPATHS_LIST) $(SOURCE_FILES_FULL_LIST)
ifdef JDEPS
	@if test -s $(JAVAC_SOURCE_FILES_LIST); then \
	  echo "$(JAVAC) -Xlint:deprecation,unchecked -d '$(CLASSES_DIR)' $(CLASSPATH) '@$(JAVAC_SOURCEPATHS_LIST)' '@$(JAVAC_SOURCE_FILES_LIST)'" && \
	  $(JAVAC) -Xlint:deprecation,unchecked -d '$(CLASSES_DIR)' $(CLASSPATH) '@$(JAVAC_SOURCEPATHS_LIST)' '@$(JAVAC_SOURCE_FILES_LIST)' && \
	  if test -f '$(JAVA_DEPENDENCIES)'; then \
	    echo "Updating $(JAVA_DEPENDENCIES)" && \
	    $(FIND) -H '$(CLASSES_ALIAS_DIR)' -name '*.class' -cnewer '$(JAVA_DEPENDENCIES)' >'$(JAVA_DEPENDENCIES).tmp' && \
	    $(CAT) '$(JAVA_DEPENDENCIES).tmp' | while read cf; do \
	      cf=$$(echo $$cf | $(SED) 's|\$$|\\$$|g'); \
	      $(SED) "\|^$$cf: |d" '$(JAVA_DEPENDENCIES)' >'$(JAVA_DEPENDENCIES).bak' && \
	      $(MV) '$(JAVA_DEPENDENCIES).bak' '$(JAVA_DEPENDENCIES)'; \
	    done \
	  else \
	    echo "Building $(JAVA_DEPENDENCIES)" && \
	    $(FIND) -H '$(CLASSES_ALIAS_DIR)' -name '*.class' >'$(JAVA_DEPENDENCIES).tmp'; \
	  fi && \
	  echo "BEGIN {" >'$(SOURCE_FILES_FULL_LIST).awk' && \
	  $(SED) 's|^.*\(/$(SOURCES_PATH).*\)$$|sf["\1"]="&"|' '$(SOURCE_FILES_FULL_LIST)' >>'$(SOURCE_FILES_FULL_LIST).awk' && \
	  echo "}" >>'$(SOURCE_FILES_FULL_LIST).awk' && \
	  echo '{ if (sf[$$2]) print $$1 " " sf[$$2] }' >>'$(SOURCE_FILES_FULL_LIST).awk' && \
	  echo "$(CAT) '$(JAVA_DEPENDENCIES).tmp' | $(XARGS) $(JDEPS) -v" && \
	  $(CAT) '$(JAVA_DEPENDENCIES).tmp' | $(XARGS) $(JDEPS) -v | \
	    $(SED) -n 's|\.|/|g;s|^  *\([^ ]\{1,\}\) *-> *\([^ ]\{1,\}\).*$$|$(CLASSES_ALIAS_DIR)/\1.class: /$(SOURCES_PATH)\2.java|p' | \
	    $(AWK) -f '$(SOURCE_FILES_FULL_LIST).awk' >>'$(JAVA_DEPENDENCIES)' && \
	  $(RM) '$(SOURCE_FILES_FULL_LIST).awk' '$(JAVA_DEPENDENCIES).tmp'; \
	fi
else # def JDEPS
	@if test -s '$(SOURCE_FILES_FULL_LIST)' -a  -s '$(JAVAC_SOURCE_FILES_LIST)'; then \
	  echo "$(JAVAC) -Xlint:deprecation,unchecked -d '$(CLASSES_DIR)' $(CLASSPATH) '@$(JAVAC_SOURCEPATHS_LIST)' '@$(SOURCE_FILES_FULL_LIST)'" && \
	  $(JAVAC) -Xlint:deprecation,unchecked -d '$(CLASSES_DIR)' $(CLASSPATH) '@$(JAVAC_SOURCEPATHS_LIST)' '@$(SOURCE_FILES_FULL_LIST)'; \
	fi
endif # def JDEPS


#####################
# Native components #
#####################

# Native components' libraries
NATIVE_LIBRARIES :=

# Class names to be processed through javah
JAVAH_CLASS_NAMES :=

# Current architecture -- $(ARCHITECTURE) must expand to the name of an
# architecture supported by javah, it is used to access
# architecture-specific javah include files
ifeq ($(shell $(OS)),GNU/Linux)
ARCHITECTURE := linux
else ifeq ($(shell $(OS)),FreeBSD)
ARCHITECTURE := freebsd
else
ARCHITECTURE := unknown
endif


# Convert C source file names into the names of their respective object
# files

# Arguments:
#   $(1) - component/native library name
#   $(2) - component base directory
#   $(3) - C source file names
SOURCES_TO_OBJECTS = $(patsubst $(2)$(NATIVE_SOURCES_PATH)%.c,$(OBJECTS_DIR)$(1)/%.o,$(3))


# Convert C source file names into the names of their respective
# dependencies files -- files used to store the names of all the files
# recursively #include'd

# Arguments:
#   $(1) - component/native library name
#   $(2) - component base directory
#   $(3) - C source file names
SOURCES_TO_DEPENDENCIES = $(patsubst $(2)$(NATIVE_SOURCES_PATH)%.c,$(OBJECTS_DIR)$(1)/%.d,$(3))


# Convert a classname into the corresponding class file name

# Arguments:
#   $(1) - classname (in the package.subpackage.classname format)
CLASSNAME_TO_CLASSFILE = $(patsubst %,$(CLASSES_DIR)%.class,$(subst .,/,$(1)))


# Convert a classname into the corresponding source file name
# NOTE: The source file name computed is not complete -- the path to
#       the component's directory is missing

# Arguments:
#   $(1) - classname (in the package.subpackage.classname format)
CLASSNAME_TO_SOURCEFILE = $(patsubst %,/$(SOURCES_PATH)%.java,$(subst .,/,$(1)))


# Convert a classname into the corresponding JNI include file name
# NOTE: We need two convertion macros to solve a chicken-egg dependency
#       issue.
#       When compiling for the first time, or after a clean, the
#       dependencies files included by the 'include' directive in the
#       BUILD_NATIVE_COMPILE_RULES macro don't exist and must be created
#       by the rule next to the 'include' directive. But the JNI headers
#       they depend on don't exist either and if it were not for the
#       '-MG' option the recipe would fail. Instead the dependencies
#       files are created despite the error, but using file names for
#       the JNI headers taken from the C '#include' directives, that is,
#       in their "short" version -- without full path. To allow 'make'
#       to build the JNI header files, despite the wrong file names
#       used, we must define targets for the JNI header files using the
#       wrong "short" names -- that's what the first macro is used for.
#       Once the JNI header files are built, the dependencies files will
#       be rebuilt, this time, however, the JNI header files do exist
#       enabling the C preprocessor to compute the correct "full" names
#       of the headers. So now we need a different set of targets to
#       deal with the "full" version of the file names -- that's the
#       purpose of the second macro.

# Arguments:
#   $(1) - classname (in the package.subpackage.classname format)
CLASSNAME_TO_SHORT_INCLUDEFILE = $(patsubst %,%.h,$(subst .,_,$(1)))

# Arguments:
#   $(1) - classname (in the package.subpackage.classname format)
CLASSNAME_TO_FULL_INCLUDEFILE = $(patsubst %,$(INCLUDE_DIR)%.h,$(subst .,_,$(1)))


# Define the rules to compile object files (.o) and dependencies files
# (.d).
# Including the dependency files into the Makefile ensures that they
# will be built if non existent or older than the C source file or any
# other object file's dependency -- in fact, each dependency file will
# declare both the object file and itself as dependant from all the
# files (recursively) included in the C source file.
# NOTE: I've tested this rules with both gcc and clang. Other
#       compilers may require some tweak, especially in the recipes.

# Arguments:
#   $(1) - component/native library name
#   $(2) - component base directory
#   $(3) - component-specific CFLAGS
#   $(4) - C source file name
define BUILD_NATIVE_COMPILE_RULES =

ifeq ($(ARCHITECTURE),unknown)
$$(error Unsupported OS: $(shell $(OS)))
endif

# The conditional avoids to compile the Java code (to build the JNI
# header files the .d file depends on) when cleaning an already clean
# source tree
ifneq ($(MAKECMDGOALS),clean)
include $$(call SOURCES_TO_DEPENDENCIES,$(1),$(2),$(4))
endif


$$(call SOURCES_TO_DEPENDENCIES,$(1),$(2),$(4)): | $(JDK_INCLUDE)
	$(MKDIR_P) "$$$$(dirname '$$@')" && \
	JDK_INCLUDE_DIR="$$$$(cat '$(JDK_INCLUDE)')" && \
	$(CPP) $(CPPFLAGS) -I "$$$$JDK_INCLUDE_DIR" \
	  -I "$$$$JDK_INCLUDE_DIR/$(ARCHITECTURE)" -I '$(INCLUDE_DIR)' \
	  -MT '$$(call SOURCES_TO_OBJECTS,$(1),$(2),$(4)) $$(call SOURCES_TO_DEPENDENCIES,$(1),$(2),$(4))' \
	  -M -MG -MF '$$@' '$(4)'

$$(call SOURCES_TO_OBJECTS,$(1),$(2),$(4)): | $(JDK_INCLUDE)
	$(MKDIR_P) "$$$$(dirname '$$@')" && \
	JDK_INCLUDE_DIR="$$$$(cat '$(JDK_INCLUDE)')" && \
	$(CC) $(CPPFLAGS) $(CFLAGS) -I "$$$$JDK_INCLUDE_DIR" \
	  -I "$$$$JDK_INCLUDE_DIR/$(ARCHITECTURE)" -I '$(INCLUDE_DIR)' \
	  $(3) -c -o '$$@' '$(4)'

endef # BUILD_NATIVE_COMPILE_RULES


# Create rules to build a native library from C source files.
# Define the library variables, the library link rule, the source and
# dependencies files compile rules and build the list of classes to
# process through javah, storing them in the JAVAH_CLASS_NAMES
# variable.

# Arguments:
#   $(1) - component/native library name
#   $(2) - component/native library version
#   $(3) - component base directory
#   $(4) - C source files list
#   $(5) - C compiler flags (CFLAGS)
#   $(6) - linker flags (LDFLAGS)
#   $(7) - javah classes (in the package.subpackage.classname format)
define BUILD_NATIVE_MAKE_RULES =

ifeq ($(1),)
$$(error Missing library basename)
endif

MK_LIBNAME := $(if $(2),$(1)-$(2).so,$(1).so)

$(1).version := $(2)
$(1).basename := $$(MK_LIBNAME)
$(1).buildname := $(NATIVE_DIR)$$(MK_LIBNAME)
$(1).jarname := $(resources.libs)/$$(MK_LIBNAME)

RESOURCE_PLACEHOLDERS += $(1).version $(1).jarname
NATIVE_LIBRARIES += $$(value $(1).buildname)
JAVAH_CLASS_NAMES += $(7)


compile: $$(call SOURCES_TO_OBJECTS,$(1),$(3),$(4))

run-javah: $$(call CLASSNAME_TO_CLASSFILE,$(7))

$$(call CLASSNAME_TO_SHORT_INCLUDEFILE,$(7)): run-javah

# The empty recipe force reevaluation of target timestamp after
# run-javah has been processed
$$(call CLASSNAME_TO_FULL_INCLUDEFILE,$(7)): run-javah;

$$(foreach var,$(4),$$(eval $$(call BUILD_NATIVE_COMPILE_RULES,$(1),$(3),$(5),$$(var))))

$$(value $(1).buildname): $$(call SOURCES_TO_OBJECTS,$(1),$(3),$(4)) | $(NATIVE_DIR)
	$(CC) $(LDFLAGS) $(6) -o '$$@' $$(patsubst %,'%',$$^)

endef # BUILD_NATIVE_MAKE_RULES


# Store the list of class files to be processed through javah and the
# Java source files they are compiled from -- the .PHONY special target
# ensures that the list is rebuilt at every run
# NOTE: The path to the source file is relative to the component
#       directory -- it will be further processed in the run-javah
#       recipe to compute the complete path relative to the project's
#       topmost directory

.PHONY: $(EXPORTED_CLASSES_LIST)

$(EXPORTED_CLASSES_LIST): | $(BUILD_DIR)
	@echo "Building $@" \
	$(file >$@) \
	$(foreach var,$(JAVAH_CLASS_NAMES),$(file >>$@,$(call CLASSNAME_TO_SOURCEFILE,$(var)) $(var)))


# Find out where javah include files are stored.
# For this is an expensive operation, we cache the result into
# the $(JDK_INCLUDE) file.
# For the $(JDK_INCLUDE) file is included as a dependency in every
# native object and dependency file rule (see the
# BUILD_NATIVE_COMPILE_RULES macro above), it will be built only if
# needed.
$(JDK_INCLUDE): | $(BUILD_DIR)
	@echo "Building $@" && \
	dir="$$($(JAVA) -XshowSettings:properties 2>&1 | $(SED) -n 's|^ *java\.home *= *\(.*\)$$|\1/../include|p')" && \
	if test -n "$$dir"; then \
	  (cd "$$dir" && pwd) >'$@'; \
	else \
	  echo "ERROR: Cannot find JDK include directory"; \
	  exit 1; \
	fi


# The next rule will run javah to build the JNI header files -- only the
# classes whose source file was modified since last run will be
# processed through javah

.PHONY: run-javah

run-javah: | $(EXPORTED_CLASSES_LIST) $(INCLUDE_DIR)
	@if test -s '$(EXPORTED_CLASSES_LIST)'; then \
	  echo "Building $(JAVAH_CLASSES_LIST)"; \
	  $(CAT) '$(EXPORTED_CLASSES_LIST)' | while read sf cn; do \
	    if $(FGREP) -q "$$sf" '$(JAVAC_SOURCE_FILES_LIST)'; then \
	      echo "$$cn"; \
	    fi \
	  done >'$(JAVAH_CLASSES_LIST)'; \
	  if test -s '$(JAVAH_CLASSES_LIST)'; then \
	    echo "Building JNI headers"; \
	    echo "$(CAT) '$(JAVAH_CLASSES_LIST)' | $(XARGS) $(JAVAH) -d '$(INCLUDE_DIR)' $(CLASSPATH)" && \
	    $(CAT) '$(JAVAH_CLASSES_LIST)' | $(XARGS) $(JAVAH) -d '$(INCLUDE_DIR)' $(CLASSPATH); \
	  fi \
	fi


##############################
# Components' build.mk files #
##############################

# Here are included all the build.mk files of the project.
# Order is not important, unless some component's JAR archive is going
# to include some other component's JAR archive or native library, e.g.,
# for the sixth argument to the BUILD_MAKE_RULES macro in bar's build.mk
# references the foo component, foo's build.mk must be included before
# bar's.

include foo/java/build.mk
include bar/build.mk

# Specifying optional components is as simple as adding a single
# conditional
ifeq ($(ENABLE_FOO_FEATURE),true)
include foo/native/build.mk
endif


# If variable MISSING_INCLUDED_COMPONENTS is not empty, then some
# component's JAR archive is including some undefined JAR archive or
# native library.
# This may also happen if the build.mk file defining the included
# JAR/native library is included *after* the build.mk file referencing
# the included JAR/native library (see previous comments).

ifdef MISSING_INCLUDED_COMPONENTS
$(error Missing included component(s): $(MISSING_INCLUDED_COMPONENTS))
endif


# Include Java classes dependencies.
# If the file $(JAVA_DEPENDENCIES) does not exist, then we are compiling
# for the first time or right after a clean-up, which means we are going
# to compile everything, then we don't need to track dependencies
# anyway.

-include $(JAVA_DEPENDENCIES)


# A convenience target to build all the components of the project,
# without packaging them

.PHONY: components

components: $(JAR_ARCHIVES) $(NATIVE_LIBRARIES)


#############
# Packaging #
#############

# This section contains rules to collect the JARs and native libraries
# into a package.
# This is just an example -- you can (and should) customize them to your
# taste, e.g., collecting them into multiple packages or maybe just
# moving the JARs into some predefined directory.


# The following variables are used to list the files that will build the
# package -- we need one variable for each directory inside the package
# (there's no need for the directory structure inside the package to
# match project's)

BAR_BIN_BUILD_LIST := bin/run.sh

BAR_DOC_BUILD_LIST := doc/README

BAR_JAR_BUILD_LIST := $(bar.buildname)

FOO_NATIVE_BUILD_LIST :=

ifeq ($(ENABLE_FOO_FEATURE),true)
FOO_NATIVE_BUILD_LIST += $(libfoo-linux.buildname)
endif


# Convert the file names listed in the *_BUILD_LIST variables into their
# respective file names under the specified stage subdirectory

# Arguments:
#   $(1) - stage subdirectory (must end with '/' or be empty)
#   $(2) - stage files
INTO_STAGE = $(addprefix $(STAGE_DIR)$(1),$(notdir $(2)))


# Create rules to build stage subdirectories and define dependencies
# between the stage files and their respective *_BUILD_LIST files.
# All the stage file names are collected in a variable whose name is
# specified in the second argument -- it will be used to define the
# package's prerequisites.
# The '$(STAGE_DIR)%' and '$(STAGE_DIR)%.sh' rules below will copy the
# files into their place under the stage directory.
# NOTE: The intended use is to invoke this macro for each directory in
#       the package and with the list of files to put in it.

# Arguments:
#   $(1) - build list files
#   $(2) - stage files variable name
#   $(3) - stage subdirectory (must end with '/' or be empty)
define ADD_PACKAGE_RULES =

$(2) += $$(call INTO_STAGE,$(3),$(1))

$(STAGE_DIR)$(3):
	$(MKDIR_P) '$$@'

$$(foreach var,$(1),$$(eval $$(call INTO_STAGE,$(3),$$(var)): $$(var) | $(STAGE_DIR)$(3)))

endef # ADD_PACKAGE_RULES


# Hard links are faster to build than copying files around
$(STAGE_DIR)%:
	$(LINK) $(patsubst %,'%',$^) '$@'

# *.sh files are treated specially: they are both filtered as resources
# are and made executable
$(STAGE_DIR)%.sh: | $(RESOURCES_FILTER_SCRIPT)
	$(SED) -f '$(RESOURCES_FILTER_SCRIPT)' '$<' >'$@' && \
	$(CHMOD) a+x '$@'


# PACKAGE_STAGE_LIST will hold the list of the files that build up the
# package -- it is used to specify the prerequisites of the package
PACKAGE_STAGE_LIST :=

$(eval $(call ADD_PACKAGE_RULES,$(BAR_BIN_BUILD_LIST),PACKAGE_STAGE_LIST,bin/))
$(eval $(call ADD_PACKAGE_RULES,$(BAR_DOC_BUILD_LIST),PACKAGE_STAGE_LIST,doc/))
$(eval $(call ADD_PACKAGE_RULES,$(BAR_JAR_BUILD_LIST),PACKAGE_STAGE_LIST,lib/))
$(eval $(call ADD_PACKAGE_RULES,$(FOO_NATIVE_BUILD_LIST),PACKAGE_STAGE_LIST,native/))


$(PACKAGE_DIR)$(PACKAGE_NAME)-$(package.version).tar.gz: $(PACKAGE_STAGE_LIST) | $(PACKAGE_DIR)
	$(RM) '$@' && \
	$(TAR) -czv -f '$@' -C '$(STAGE_DIR)' $(patsubst $(STAGE_DIR)%,'%',$^)

.PHONY: package

package: $(PACKAGE_DIR)$(PACKAGE_NAME)-$(package.version).tar.gz


############
# Clean-up #
############

.PHONY: clean

# Everything this Makefile builds is stored under $(BUILD_DIR)
# or $(PACKAGE_DIR)
clean:
	$(RM) -r '$(BUILD_DIR)' '$(PACKAGE_DIR)'
